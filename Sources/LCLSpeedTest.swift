//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/24/24.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import WebSocketKit

internal class SpeedTestClient {
    private let url: URL
    private let eventLoop: MultiThreadedEventLoopGroup
    
    private var startTime: TimeInterval = Date().timeIntervalSince1970
    private var previous: TimeInterval = 0.0
    private var numBytes: Int64 = 0
    
    var onMeasurement: ((Measurement) -> Void)
    var onProgress: ((ClientResponse) -> Void)
    var onFinish: ((ClientResponse, Error?) -> Void)
    
    init(url: URL,
         onMeasurement: @escaping (Measurement) -> Void,
         onProgress: @escaping (ClientResponse) -> Void,
         onFinish: @escaping (ClientResponse, Error?) -> Void
    ) {
        self.url = url
        self.eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.onMeasurement = onMeasurement
        self.onProgress = onProgress
        self.onFinish = onFinish
    }
    
    deinit {
        do {
            try self.eventLoop.syncShutdownGracefully()
        } catch {
            fatalError("Failed to close channel gracefully: \(error)")
        }
    }
    
    func start() throws -> EventLoopFuture<Void> {
        let promise = self.eventLoop.next().makePromise(of: Void.self)
        let httpHeaders = HTTPHeaders([("Sec-Websocket-Protocol", "net.measurementlab.ndt.v7")])
        var configuration = WebSocketClient.Configuration()
        configuration.maxFrameSize = MAX_MESSAGE_SIZE
        configuration.minNonFinalFragmentSize = MIN_MESSAGE_SIZE
        
        try WebSocket.connect(to: url.absoluteString, headers: httpHeaders, configuration: configuration, on: self.eventLoop) { ws in
            print("websocket connected")
            
            ws.eventLoop.next().scheduleTask(in: .seconds(10)) {
                print("will close the event loop")
                ws.close(code: .normalClosure).cascade(to: promise)
            }

            ws.onText { ws, text in
                self.numBytes += Int64(text.utf8.count)
                self.reportProgress()
                let buffer = ByteBuffer(string: text)
                do {
                    print(text)
                    let measurement = try JSONDecoder().decode(Measurement.self, from: buffer)
                    self.onMeasurement(measurement)
                } catch {
                    print("error: \(error)")
                }
            }

            ws.onBinary { ws, bytes in
                self.numBytes += Int64(bytes.readableBytes)
                self.reportProgress()
            }
            
            ws.onClose.whenComplete { closingResult in
                do {
                    switch closingResult {
                    case .success:
                        switch ws.closeCode {
                        case .normalClosure:
                            self.onFinish(ClientResponse.create(elapedTime: Date().timeIntervalSince1970 - self.startTime, numBytes: self.numBytes, direction: .download), nil)
                        default:
                            self.onFinish(ClientResponse.create(elapedTime: Date().timeIntervalSince1970 - self.startTime, numBytes: self.numBytes, direction: .download), SpeedTestError.websocketCloseFailed(ws.closeCode))
                        }
                        try ws.close(code: .normalClosure).wait()
                        promise.succeed()
                    case .failure(let error):
                        try ws.close().wait()
                        promise.fail(error)
                    }
                } catch {
                    print("closing failed: \(error)")
                }
            }
            
        }.wait()
        
        return promise.futureResult
    }
    
    private func reportProgress() {
        let now = Date().timeIntervalSince1970
        if (now - self.previous) * 1000 > MEASUREMENT_INTERVAL {
            self.previous = now
            self.onProgress(ClientResponse.create(elapedTime: now - self.startTime, numBytes: self.numBytes, direction: .download))
        }
    }
    
    func stop() throws {
        try self.eventLoop.next().close()
    }
}
