//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 3/1/24.
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
        self.eventloop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
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
    
    var onMeasurement: ((Measurement) -> Void)?
    
    var onProgress: ((MeasurementProgress) -> Void)?
    
    var onFinish: ((MeasurementProgress, Error?) -> Void)?
    
    func start() throws -> NIOCore.EventLoopFuture<Void> {
        let promise = self.eventloop.next().makePromise(of: Void.self)
        try WebSocket.connect(to: self.url.absoluteString, headers: self.httpHeaders, configuration: self.configuration, on: self.eventloop) { ws in
            print("websocket connected")
            self.startTime = Date.nowInMicroSecond
            
            ws.onText(self.onText)
            ws.onBinary(self.onBinary)
            ws.onClose.whenComplete { result in
                let closeResult = self.onClose(closeCode: ws.closeCode ?? .unknown(WebSocketErrorCode.missingErrorCode), closingResult: result)
                switch closeResult {
                case .success:
                    if let onFinish = self.onFinish {
                        onFinish(UploadClient.generateMeasurementProgress(startTime: self.startTime, numBytes: self.numBytes, direction: .upload), nil)
                    }
                    ws.close(code: .normalClosure, promise: promise)
                case .failure(let error):
                    if let onFinish = self.onFinish {
                        onFinish(UploadClient.generateMeasurementProgress(startTime: self.startTime, numBytes: self.numBytes, direction: .upload), error)
                    }
                    ws.close(code: .goingAway, promise: promise)
                }
            }
            
            self.upload(using: ws)
        }.wait()
        return promise.futureResult
    }
    
    func stop() throws {
        try self.eventloop.next().close()
    }
    
    func onText(ws: WebSocketKit.WebSocket, text: String) {
        let buffer = ByteBuffer(string: text)
        do {
            let measurement: Measurement = try jsonDecoder.decode(Measurement.self, from: buffer)
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
    
    private func upload(using ws: WebSocket) {
        let start = Date.nowInMicroSecond
        var currentLoad = MIN_MESSAGE_SIZE
        while Date.nowInMicroSecond - start < MEASUREMENT_DURATION {
            let load = generateLoad(with: currentLoad)
            ws.send(load)
            currentLoad = load.readableBytes
            self.numBytes += Int64(currentLoad)
            
            let current = Date.nowInMicroSecond
            if let onProgress = self.onProgress {
                if current - previousTimeMark >= MEASUREMENT_REPORT_INTERVAL {
                    onProgress(UploadClient.generateMeasurementProgress(startTime: self.startTime, numBytes: self.numBytes, direction: .upload))
                    previousTimeMark = current
                }
            }
        }
    }
    
    private func generateLoad(with size: Int) -> ByteBuffer {
        var loadSize = size
        if loadSize * 2 < MAX_MESSAGE_SIZE && loadSize < (self.numBytes / 16) {
            loadSize *= 2
        }
        return ByteBuffer(repeating: 0, count: loadSize)
    }
}
