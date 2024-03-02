//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 3/1/24.
//

import Foundation
import WebSocketKit
import NIOCore

extension WebSocket {
    public static func connect(to url: String, headers: HTTPHeaders = [:], configuration: WebSocketClient.Configuration = .init(), on eventloopGroup: EventLoopGroup) async throws -> WebSocket {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try self.connect(to: url, headers: headers, configuration: configuration, on: eventloopGroup) { ws in
                    print("received ws connection")
                    continuation.resume(returning: ws)
                }.wait()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
