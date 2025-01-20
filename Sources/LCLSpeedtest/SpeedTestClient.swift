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

/// The speed test client that will perform the upload, download, or both upload and download speed test
/// using the [M-Lab NDT7 protocol](https://www.measurementlab.net/tests/ndt/ndt7/).
public struct SpeedTestClient {

  /// Callback function that will be invoked during the upload test
  /// when an intermediate test progress is available.
  public var onUploadProgress: ((MeasurementProgress) -> Void)?

  /// Callback function that will be invoked during the upload test
  /// when a measurement result is available.
  public var onUploadMeasurement: ((SpeedTestMeasurement) -> Void)?

  /// Callback function that will be invoked during the donwload test
  /// when an intermediate test progress is available.
  public var onDownloadProgress: ((MeasurementProgress) -> Void)?

  /// Callback function that will be invoked during the download test
  /// when a measurement result is available.
  public var onDownloadMeasurement: ((SpeedTestMeasurement) -> Void)?

  /// The download test client
  private var downloader: DownloadClient?

  /// The upload client
  private var uploader: UploadClient?

  public init() {}

  /// Start the speed test according to the test type asynchronously.
  public mutating func start(with type: TestType, deviceName: String? = nil) async throws {
    do {
      let testServers = try await TestServer.discover()
      switch type {
      case .download:
        try await runDownloadTest(using: testServers, deviceName: deviceName)
      case .upload:
        try await runUploadTest(using: testServers, deviceName: deviceName)
      case .downloadAndUpload:
        try await runDownloadTest(using: testServers, deviceName: deviceName)
        try await runUploadTest(using: testServers, deviceName: deviceName)
      }
    } catch {
      throw error
    }
  }

  /// Stop and cancel the remaining test.
  /// Cancellation will be cooperative, but the system will try its best to stop the best.
  public func cancel() throws {
    try downloader?.stop()
    try uploader?.stop()
  }

  /// Run the download test using the available test servers
  private mutating func runDownloadTest(using testServers: [TestServer], deviceName: String? = nil)
    async throws
  {
    guard let downloadPath = testServers.first?.urls.downloadPath,
      let downloadURL = URL(string: downloadPath)
    else {
      throw SpeedTestError.invalidTestURL("Cannot locate URL for download test")
    }

    downloader = DownloadClient(url: downloadURL, deviceName: deviceName)
    downloader?.onProgress = self.onDownloadProgress
    downloader?.onMeasurement = self.onDownloadMeasurement
    try await downloader?.start().get()
  }

  /// Run the upload test using the available test servers
  private mutating func runUploadTest(using testServers: [TestServer], deviceName: String? = nil)
    async throws
  {
    guard let uploadPath = testServers.first?.urls.uploadPath,
      let uploadURL = URL(string: uploadPath)
    else {
      throw SpeedTestError.invalidTestURL("Cannot locate URL for upload test")
    }

    uploader = UploadClient(url: uploadURL, deviceName: deviceName)
    uploader?.onProgress = self.onUploadProgress
    uploader?.onMeasurement = self.onUploadMeasurement
    try await uploader?.start().get()
  }
}
