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
    private let eventloop: MultiThreadedEventLoopGroup

    private var startTime: Int64
    private var numBytes: Int64
    private var previousTimeMark: Int64
    private let jsonDecoder: JSONDecoder

    required init(url: URL) {
        self.url = url
        self.eventloop = MultiThreadedEventLoopGroup.singleton
        self.startTime = 0
        self.previousTimeMark = 0
        self.numBytes = 0
        self.jsonDecoder = JSONDecoder()
    }

    deinit {
        do {
            try self.eventloop.syncShutdownGracefully()
        } catch {
            fatalError("Failed to close channel gracefully: \(error)")
        }
    }

    var onMeasurement: ((SpeedTestMeasurement) -> Void)?
    var onProgress: ((MeasurementProgress) -> Void)?
    var onFinish: ((MeasurementProgress, Error?) -> Void)?

    func start() throws -> EventLoopFuture<Void> {
        let promise = self.eventloop.next().makePromise(of: Void.self)
        try WebSocket.connect(
            to: self.url,
            headers: self.httpHeaders,
            configuration: self.configuration,
            on: self.eventloop
        ) { ws in
            print("websocket connected")
            self.startTime = Date.nowInMicroSecond

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
                        onFinish(
                            DownloadClient.generateMeasurementProgress(
                                startTime: self.startTime,
                                numBytes: self.numBytes,
                                direction: .download
                            ),
                            nil
                        )
                    }
                    ws.close(code: .normalClosure, promise: promise)
                case .failure(let error):
                    if let onFinish = self.onFinish {
                        onFinish(
                            DownloadClient.generateMeasurementProgress(
                                startTime: self.startTime,
                                 numBytes: self.numBytes,
                                  direction: .download
                            ),
                            error
                        )
                    }
                    ws.close(code: .goingAway, promise: promise)
                }
            }
        }.wait()
        return promise.futureResult
    }

    func stop() throws {
        var itr = self.eventloop.makeIterator()
        while let next = itr.next() {
            try next.close()
        }
    }

    func onText(ws: WebSocket, text: String) {
        let buffer = ByteBuffer(string: text)
        do {
            let measurement: SpeedTestMeasurement = try jsonDecoder.decode(SpeedTestMeasurement.self, from: buffer)
            self.numBytes += Int64(buffer.readableBytes)
            if let onMeasurement = self.onMeasurement {
                onMeasurement(measurement)
            }
        } catch {
            print("onText Error: \(error)")
        }
    }

    func onBinary(ws: WebSocket, bytes: ByteBuffer) {
        self.numBytes += Int64(bytes.readableBytes)
        if let onProgress = self.onProgress {
            let current = Date.nowInMicroSecond
            if current - previousTimeMark >= MEASUREMENT_REPORT_INTERVAL {
                onProgress(
                    DownloadClient.generateMeasurementProgress(
                        startTime: self.startTime,
                         numBytes: self.numBytes,
                         direction: .download
                    )
                )
                previousTimeMark = current
            }
        }
    }
}
