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
import NIOWebSocket

enum SpeedTestError: Error {
  case fetchContentFailed(Int)
  case noDataFromServer
  case testServersOutOfCapacity
  case invalidURL
  case invalidTestURL(String)

  case notImplemented
  case websocketCloseFailed(WebSocketErrorCode?)
  case websocketCloseWithError(Error)
}

extension SpeedTestError: CustomStringConvertible {
  var description: String {
    switch self {
    case .fetchContentFailed(let int):
      return "Cannot fetch content. Code (\(int)."
    case .noDataFromServer:
      return "No data from server."
    case .testServersOutOfCapacity:
      return "Test servers are out of capacity. Please try again later."
    case .invalidURL:
      return "URL is invalid."
    case .invalidTestURL(let string):
      return "Test target is invalid. Reason: \(string)"
    case .notImplemented:
      return "Not implemented yet."
    case .websocketCloseFailed(let webSocketErrorCode):
      return "Cannot close websocket gracefully. Code (\(String(describing: webSocketErrorCode))."
    case .websocketCloseWithError(let error):
      return "Websocket closed with error: \(error)."
    }
  }

}
