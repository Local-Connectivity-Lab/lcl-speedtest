//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/22/24.
//

import Foundation
import NIOWebSocket

enum SpeedTestError: Error {
    case fetchContentFailed(Int)
    case noDataFromServer
    case invalidURL
    
    case notImplemented
    case websocketCloseFailed(WebSocketErrorCode?)
}
