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

internal final class UploadClient: SpeedTestable {
    private let url: URL
    private let eventloopGroup: MultiThreadedEventLoopGroup

    private var startTime: NIODeadline
    private var totalBytes: Int
    private var previousTimeMark: NIODeadline
    private let jsonDecoder: JSONDecoder
    private let emitter = DispatchQueue(label: "uploader", qos: .userInteractive)

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
            queueSize: 1 << 26,
            configuration: self.configuration,
            on: self.eventloopGroup
        ) { ws in
            print("websocket connected")

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
                                UploadClient.generateMeasurementProgress(
                                    startTime: self.startTime,
                                    numBytes: self.totalBytes,
                                    direction: .upload
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
                                UploadClient.generateMeasurementProgress(
                                    startTime: self.startTime,
                                    numBytes: self.totalBytes,
                                    direction: .upload
                                ),
                                error
                            )
                        }
                    }
                    ws.close(code: .goingAway, promise: promise)
                }
            }

            self.upload(using: ws).cascadeFailure(to: promise)
        }.cascadeFailure(to: promise)
        return promise.futureResult
    }

    func stop() throws {
        var itr = self.eventloopGroup.makeIterator()
        while let next = itr.next() {
            try next.close()
        }
    }

    func onText(ws: WebSocketKit.WebSocket, text: String) {
        let buffer = ByteBuffer(string: text)
        do {
            let measurement: SpeedTestMeasurement = try self.jsonDecoder.decode(SpeedTestMeasurement.self, from: buffer)
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
        do {
            // this should not be invoked in upload test
            try ws.close(code: .policyViolation).wait()
        } catch {
            print("Cannot close connection due to policy violation")
        }
    }

    /// Send as many bytes to the server as possible within the `MEASUREMENT_DURATION`.
    /// Start the message size from `MIN_MESSAGE_SIZE` and increment the size according to the number of bytes queued.
    /// We always assume that the buffer size in the websocket is 7 times the current load.
    /// The system will always try to send as many bytes as possible, and will try to update the progress to the caller.
    private func upload(using ws: WebSocket) -> EventLoopFuture<Void> {
        self.startTime = NIODeadline.now()

        let el = self.eventloopGroup.next()
        let promise = el.makePromise(of: Void.self)

        func send(newLoadSize: Int) {
            guard NIODeadline.now() - self.startTime < TimeAmount.seconds(MEASUREMENT_DURATION) else {
                promise.succeed()
                return
            }
            let el = self.eventloopGroup.next()
            ws.getBufferedBytes().hop(to: el).map { bufferedBytes in
                let nextIncrementSize = newLoadSize > MAX_MESSAGE_SIZE ? MAX_MESSAGE_SIZE : SCALING_FACTOR * newLoadSize
                let loadSize = (self.totalBytes - bufferedBytes > nextIncrementSize) ? newLoadSize * 2 : newLoadSize
                if bufferedBytes < 7 * loadSize {
                    let payload = ws.allocator.buffer(repeating: 0, count: loadSize)
                    let p = el.makePromise(of: Void.self)
                    ws.send(payload, promise: p)
                    p.futureResult.cascadeFailure(to: promise)
                    self.totalBytes += loadSize
                }

                ws.getBufferedBytes().hop(to: el).map { buffered in
                    self.reportToClient(currentBufferSize: buffered)
                }.cascadeFailure(to: promise)

                send(newLoadSize: loadSize)
            }.cascadeFailure(to: promise)
        }

        self.previousTimeMark = .now()
        send(newLoadSize: MIN_MESSAGE_SIZE)

        return promise.futureResult
    }

    /// report the current measurement result to the caller using the current buffer size
    /// if the time elapsed from the last report is greater than `MEASUREMENT_REPORT_INTERVAL`.
    private func reportToClient(currentBufferSize: Int) {
        guard let onProgress = self.onProgress else {
            return
        }

        let current = NIODeadline.now()
        if (current - self.previousTimeMark) > TimeAmount.milliseconds(MEASUREMENT_REPORT_INTERVAL) {
            self.emitter.async {
                onProgress(
                    UploadClient.generateMeasurementProgress(
                        startTime: self.startTime,
                        numBytes: self.totalBytes - currentBufferSize,
                        direction: .upload
                    )
                )
            }
            self.previousTimeMark = current
        }
    }
}
