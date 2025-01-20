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
import LCLWebSocket
import NIOCore
import NIOPosix
import NIOWebSocket

internal final class UploadClient: SpeedTestable {
  private let url: URL
  private let eventloopGroup: MultiThreadedEventLoopGroup

  private var startTime: NIODeadline
  private var totalBytes: Int
  private var previousTimeMark: NIODeadline
  private var deviceName: String?
  private let jsonDecoder: JSONDecoder
  private let emitter = DispatchQueue(label: "uploader", qos: .userInteractive)

  required init(url: URL) {
    self.url = url
    self.eventloopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    self.startTime = .now()
    self.previousTimeMark = .now()
    self.totalBytes = 0
    self.jsonDecoder = JSONDecoder()
    self.deviceName = nil
  }

  convenience init(url: URL, deviceName: String?) {
    self.init(url: url)
    self.deviceName = deviceName
  }

  var websocketConfiguration: LCLWebSocket.Configuration {
    .init(
      maxFrameSize: maxMessageSize, minNonFinalFragmentSize: minMessageSize,
      deviceName: self.deviceName)
  }

  var onMeasurement: ((SpeedTestMeasurement) -> Void)?

  var onProgress: ((MeasurementProgress) -> Void)?

  var onFinish: ((MeasurementProgress, Error?) -> Void)?

  func start() throws -> EventLoopFuture<Void> {
    let promise = self.eventloopGroup.next().makePromise(of: Void.self)
    var client = LCLWebSocket.client(on: self.eventloopGroup)
    client.onOpen { ws in
      print("websocket connected")
      self.upload(using: ws).cascadeFailure(to: promise)
    }
    client.onText(self.onText(ws:text:))
    client.onBinary(self.onBinary(ws:bytes:))
    client.onClosing { closeCode, _ in
      let result = self.onClose(closeCode: closeCode)
      switch result {
      case .success:
        if let onFinish = self.onFinish {
          self.emitter.async {
            onFinish(
              UploadClient.generateMeasurementProgress(
                startTime: self.startTime,
                numBytes: self.totalBytes,
                direction: .upload
              ),
              nil
            )
          }
        }
      case .failure(let error):
        if let onFinish = self.onFinish {
          self.emitter.async {
            onFinish(
              UploadClient.generateMeasurementProgress(
                startTime: self.startTime,
                numBytes: self.totalBytes,
                direction: .upload
              ),
              error
            )
          }
        }
      }
    }

    client.connect(to: self.url, headers: self.httpHeaders, configuration: self.configuration)
      .cascade(to: promise)

    return promise.futureResult
  }

  func stop() throws {
    var itr = self.eventloopGroup.makeIterator()
    while let next = itr.next() {
      try next.close()
    }
  }

  @Sendable
  func onText(ws: WebSocket, text: String) {
    let buffer = ByteBuffer(string: text)
    do {
      let measurement: SpeedTestMeasurement = try self.jsonDecoder.decode(
        SpeedTestMeasurement.self, from: buffer)
      if let onMeasurement = self.onMeasurement {
        self.emitter.async {
          onMeasurement(measurement)
        }
      }
    } catch {
      print("onText Error: \(error)")
    }
  }

  @Sendable
  func onBinary(ws: WebSocket, bytes: ByteBuffer) {
    do {
      // this should not be invoked in upload test
      try ws.close(code: .policyViolation).wait()
    } catch {
      print("Cannot close connection due to policy violation")
    }
  }

  /// Send as many bytes to the server as possible within the `measurementDuration`.
  /// Start the message size from `minMessageSize` and increment the size according to the number of bytes queued.
  /// We always assume that the buffer size in the websocket is 7 times the current load.
  /// The system will always try to send as many bytes as possible, and will try to update the progress to the caller.
  private func upload(using ws: WebSocket) -> EventLoopFuture<Void> {
    self.startTime = NIODeadline.now()

    let el = self.eventloopGroup.next()
    let promise = el.makePromise(of: Void.self)

    func send(newLoadSize: Int) {
      guard NIODeadline.now() - self.startTime < TimeAmount.seconds(measurementDuration) else {
        promise.succeed()
        return
      }
      let el = self.eventloopGroup.next()
      ws.bufferedAmount.hop(to: el).map { bufferedBytes in
        let nextIncrementSize =
          newLoadSize > maxMessageSize ? maxMessageSize : scalingFactor * newLoadSize
        let loadSize =
          (self.totalBytes - bufferedBytes > nextIncrementSize) ? newLoadSize * 2 : newLoadSize
        if bufferedBytes < 7 * loadSize {

          let payload = ws.channel.allocator.buffer(repeating: 0, count: loadSize)
          let p = el.makePromise(of: Void.self)
          ws.send(payload, opcode: .binary, promise: p)
          p.futureResult.cascadeFailure(to: promise)
          self.totalBytes += loadSize
        }

        ws.bufferedAmount.hop(to: el).map { buffered in
          self.reportToClient(currentBufferSize: buffered)
        }.cascadeFailure(to: promise)

        send(newLoadSize: loadSize)
      }.cascadeFailure(to: promise)
    }

    self.previousTimeMark = .now()
    send(newLoadSize: minMessageSize)

    return promise.futureResult
  }

  /// report the current measurement result to the caller using the current buffer size
  /// if the time elapsed from the last report is greater than `measurementReportInterval`.
  private func reportToClient(currentBufferSize: Int) {
    guard let onProgress = self.onProgress else {
      return
    }

    let current = NIODeadline.now()
    if (current - self.previousTimeMark) > TimeAmount.milliseconds(measurementReportInterval) {
      self.emitter.async {
        onProgress(
          UploadClient.generateMeasurementProgress(
            startTime: self.startTime,
            numBytes: self.totalBytes - currentBufferSize,
            direction: .upload
          )
        )
      }
      self.previousTimeMark = current
    }
  }
}
