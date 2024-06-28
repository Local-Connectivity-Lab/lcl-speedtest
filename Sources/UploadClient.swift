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

    func start() throws -> NIOCore.EventLoopFuture<Void> {
        let promise = self.eventloop.next().makePromise(of: Void.self)
        try WebSocket.connect(
            to: self.url,
            headers: self.httpHeaders,
            queueSize: 1 << 26,
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
                            UploadClient.generateMeasurementProgress(
                                startTime: self.startTime,
                                numBytes: self.numBytes,
                                direction: .upload
                            ),
                            nil
                        )
                    }
                    ws.close(code: .normalClosure, promise: promise)
                case .failure(let error):
                    if let onFinish = self.onFinish {
                        onFinish(
                            UploadClient.generateMeasurementProgress(
                                startTime: self.startTime,
                                numBytes: self.numBytes,
                                direction: .upload
                                ),
                                error
                            )
                    }
                    ws.close(code: .goingAway, promise: promise)
                }
            }

            self.upload(using: ws)
        }.wait()
        return promise.futureResult
    }

    func stop() throws {
        var itr = self.eventloop.makeIterator()
        while let next = itr.next() {
            try next.close()
        }
    }

    func onText(ws: WebSocketKit.WebSocket, text: String) {
        let buffer = ByteBuffer(string: text)
        do {
            let measurement: SpeedTestMeasurement = try jsonDecoder.decode(SpeedTestMeasurement.self, from: buffer)
            if let onMeasurement = self.onMeasurement {
                onMeasurement(measurement)
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
    private func upload(using ws: WebSocket) {
        let start = Date.nowInMicroSecond
        var currentLoad = MIN_MESSAGE_SIZE
        while Date.nowInMicroSecond - start < MEASUREMENT_DURATION {
            let loadSize = calibrateLoadSize(initial: currentLoad, ws: ws)

            if ws.bufferedBytes < 7 * loadSize {
                let payload = ByteBuffer(repeating: 0, count: loadSize)
                ws.send(payload)
                currentLoad = loadSize
                self.numBytes += Int64(currentLoad)
            }
            reportToClient(currentBufferSize: ws.bufferedBytes)
        }
    }

    /// report the current measurement result to the caller using the current buffer size
    /// if the time elapsed from the last report is greater than `MEASUREMENT_REPORT_INTERVAL`.
    private func reportToClient(currentBufferSize: Int) {
        let current = Date.nowInMicroSecond
        if let onProgress = self.onProgress {
            if current - previousTimeMark >= MEASUREMENT_REPORT_INTERVAL {
                onProgress(
                    UploadClient.generateMeasurementProgress(
                        startTime: self.startTime,
                        numBytes: self.numBytes - Int64(currentBufferSize),
                        direction: .upload
                    )
                )
                previousTimeMark = current
            }
        }
    }

    /// Calibrate the buffer size that will be sent to the server according to the initial buffer size and the amount of buffer
    /// currently queued in the websocket pipeline.
    ///
    /// The new size increment by a factor of 16 by default. However, if the new size exceeds the `MAX_MESSAGE_SIZE` limit,
    /// then the size will be set to `MAX_MESSAGE_SIZE`.
    /// If there are sufficient amount of spaces available in the websocket buffer, then the system will double the buffer size to maximize the network load.
    ///
    /// - Parameters:
    ///     - initial: the initial buffer size
    ///     - ws: the websocket object that knows the number of bytes currently queued in the system.
    ///
    /// - Returns: the number of bytes for next round of upload.
    private func calibrateLoadSize(initial size: Int, ws: WebSocket) -> Int {
        let nextSizeIncrement: Int = size >= MAX_MESSAGE_SIZE ? MAX_MESSAGE_SIZE : 16 * size
        return (self.numBytes - Int64(ws.bufferedBytes) >= nextSizeIncrement) ? size * 2 : size
    }
}
