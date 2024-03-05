//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 3/1/24.
//

import Foundation
import WebSocketKit
import NIOWebSocket
import NIOCore

public protocol SpeedTestable {
    
    init(url: URL)
    var onMeasurement: ((Measurement) -> Void)? { get set }
    var onProgress: ((MeasurementProgress) -> Void)? { get set }
    var onFinish: ((MeasurementProgress, Error?) -> Void)? { get set }
    
    func start() throws -> EventLoopFuture<Void>
    func stop() throws
    
    func onText(ws: WebSocket, text: String)
    func onBinary(ws: WebSocket, bytes: ByteBuffer)
}

extension SpeedTestable {
    var httpHeaders: HTTPHeaders {
        return HTTPHeaders([("Sec-Websocket-Protocol", "net.measurementlab.ndt.v7")])
    }
    
    var configuration: WebSocketClient.Configuration {
        var config = WebSocketClient.Configuration()
        config.maxFrameSize = MAX_MESSAGE_SIZE
        config.minNonFinalFragmentSize = MIN_MESSAGE_SIZE
        return config
    }
}

extension SpeedTestable {
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
    
    static func generateMeasurementProgress(startTime: Int64, numBytes: Int64, direction: TestDirection) -> MeasurementProgress {
        return MeasurementProgress.create(elapedTime: Date.nowInMicroSecond - startTime, numBytes: numBytes, direction: direction)
    }
}