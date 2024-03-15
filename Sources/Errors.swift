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
