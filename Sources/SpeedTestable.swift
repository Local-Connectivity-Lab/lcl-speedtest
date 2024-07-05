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
import NIOWebSocket
import NIOCore

/// This protocol defines callbacks to monitor the speed test progress, including the measurement progress,
/// measurement result, and potential errors when test finishes.
/// This protocol also defines methods to start and stop the speed test.
/// Implementation of this protocol need to accept an URL, which is the URL of the test server
public protocol SpeedTestable {

    init(url: URL)

    /// Callback functions that will be invoked when the measurement result is available.
    var onMeasurement: ((SpeedTestMeasurement) -> Void)? { get set }

    /// Callback function that will be invoked when the measurement progress result is available.
    var onProgress: ((MeasurementProgress) -> Void)? { get set }

    /// Callback function that will be invooked when the speed test finishes. Final measurement progress and potential
    /// errors will be provided.
    var onFinish: ((MeasurementProgress, Error?) -> Void)? { get set }

    /// Start a speed test.
    ///
    /// - Returns: a EventLoopFuture which will be resolved when the test completes
    func start() throws -> EventLoopFuture<Void>

    /// Stops the speed test.
    func stop() throws

    /// Callback function that handles the text data from the websocket
    func onText(ws: WebSocket, text: String)

    /// Callback function that handles the binary data from the websocket
    func onBinary(ws: WebSocket, bytes: ByteBuffer)
}

extension SpeedTestable {

    /// HTTP headers that will be used to identify speed test protocol with M-Lab server.
    var httpHeaders: HTTPHeaders {
        return HTTPHeaders([("Sec-Websocket-Protocol", "net.measurementlab.ndt.v7")])
    }

    /// Default Websocket configuration using the `MAX_MESSAGE_SIZE` for max frame size
    /// and `MIN_MESSAGE_SIZE` for min final fragment size.
    var configuration: WebSocketClient.Configuration {
        var config = WebSocketClient.Configuration()
        config.maxFrameSize = MAX_MESSAGE_SIZE
        config.minNonFinalFragmentSize = MIN_MESSAGE_SIZE
        return config
    }
}

extension SpeedTestable {

    /// Default implementation to properly close websocket.
    func onClose(closeCode: WebSocketErrorCode, closingResult: Result<Void, Error>) -> Result<Void, SpeedTestError> {
        switch closingResult {
        case .success:
            switch closeCode {
            case .normalClosure:
                return .success(())
            default:
                return .failure(.websocketCloseFailed(closeCode))
            }
        case .failure(let error):
            return .failure(.websocketCloseWithError(error))
        }
    }

    /// Generate measurement progress
    ///
    /// - Parameters:
    ///     - startTime: the test start time
    ///     - numBytes: the number of bytes transmitted during the the sampling period.
    ///     - direction: the direction of the test
    ///
    /// - Returns: a `MeasurementProgress` containing the sampling period, number of bytes transmitted and test direction.
    static func generateMeasurementProgress(
        startTime: Int64,
        numBytes: Int64,
        direction: TestDirection
    ) -> MeasurementProgress {
        return MeasurementProgress.create(
            elapedTime: Date.nowInMicroSecond - startTime,
            numBytes: numBytes,
            direction: direction
        )
    }
}
