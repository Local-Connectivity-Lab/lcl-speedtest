//
// This source file is part of the LCL open source project
//
// Copyright (c) 2021-2024 Local Connectivity Lab and the project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of project authors
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import WebSocketKit
import NIOCore
import NIOPosix
import NIOWebSocket

internal final class DownloadClient: SpeedTestable {
    private let url: URL
    private let eventloopGroup: MultiThreadedEventLoopGroup

    private var startTime: NIODeadline
    private var totalBytes: Int
    private var previousTimeMark: NIODeadline
    private let jsonDecoder: JSONDecoder
    private let emitter = DispatchQueue(label: "downloader", qos: .userInteractive)

    required init(url: URL) {
        self.url = url
        self.eventloopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        self.startTime = .now()
        self.previousTimeMark = .now()
        self.totalBytes = 0
        self.jsonDecoder = JSONDecoder()
    }

    var onMeasurement: ((SpeedTestMeasurement) -> Void)?
    var onProgress: ((MeasurementProgress) -> Void)?
    var onFinish: ((MeasurementProgress, Error?) -> Void)?

    func start() throws -> EventLoopFuture<Void> {
        let promise = self.eventloopGroup.next().makePromise(of: Void.self)
        WebSocket.connect(
            to: self.url,
            headers: self.httpHeaders,
            configuration: self.configuration,
            on: self.eventloopGroup
        ) { ws in
            print("websocket connected")

            self.startTime = .now()

            ws.onText(self.onText)
            ws.onBinary(self.onBinary)
            ws.onClose.whenComplete { result in
                let closeResult = self.onClose(
                    closeCode: ws.closeCode ?? .unknown(WebSocketErrorCode.missingErrorCode),
                    closingResult: result
                )

                switch closeResult {
                case .success:
                    if let onFinish = self.onFinish {
                        self.emitter.async {
                            onFinish(
                                DownloadClient.generateMeasurementProgress(
                                    startTime: self.startTime,
                                    numBytes: self.totalBytes,
                                    direction: .download
                                ),
                                nil
                            )
                        }
                    }
                    ws.close(code: .normalClosure, promise: promise)
                case .failure(let error):
                    if let onFinish = self.onFinish {
                        self.emitter.async {
                            onFinish(
                                DownloadClient.generateMeasurementProgress(
                                    startTime: self.startTime,
                                     numBytes: self.totalBytes,
                                      direction: .download
                                ),
                                error
                            )
                        }
                    }
                    ws.close(code: .goingAway, promise: promise)
                }
            }
        }.cascadeFailure(to: promise)
        return promise.futureResult
    }

    func stop() throws {
        var itr = self.eventloopGroup.makeIterator()
        while let next = itr.next() {
            try next.close()
        }
    }

    func onText(ws: WebSocket, text: String) {
        let buffer = ByteBuffer(string: text)
        do {
            let measurement: SpeedTestMeasurement = try jsonDecoder.decode(SpeedTestMeasurement.self, from: buffer)
            self.totalBytes += buffer.readableBytes
            if let onMeasurement = self.onMeasurement {
                self.emitter.async {
                    onMeasurement(measurement)
                }
            }
        } catch {
            print("onText Error: \(error)")
        }
    }

    func onBinary(ws: WebSocket, bytes: ByteBuffer) {
        self.totalBytes += bytes.readableBytes
        if let onProgress = self.onProgress {
            let current = NIODeadline.now()
            if (current - self.previousTimeMark) > TimeAmount.milliseconds(MEASUREMENT_REPORT_INTERVAL) {
                self.emitter.async {
                    onProgress(
                        DownloadClient.generateMeasurementProgress(
                            startTime: self.startTime,
                            numBytes: self.totalBytes,
                            direction: .download
                        )
                    )
                }
                self.previousTimeMark = current
            }
        }
    }
}
