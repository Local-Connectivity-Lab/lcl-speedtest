//
// This source file is part of the LCLPing open source project
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

extension WebSocket {
    public static func connect(
        to url: String,
        headers: HTTPHeaders = [:],
        configuration: WebSocketClient.Configuration = .init(),
        on eventloopGroup: EventLoopGroup
    ) async throws -> WebSocket {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try self.connect(to: url, headers: headers, configuration: configuration, on: eventloopGroup) { ws in
                    continuation.resume(returning: ws)
                }.wait()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

extension WebSocketClient {

}
