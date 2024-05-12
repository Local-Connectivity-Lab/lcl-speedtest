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

public struct SpeedTestClient {

    public var onUploadProgress: ((MeasurementProgress) -> Void)?
    public var onUploadMeasurement: ((SpeedTestMeasurement) -> Void)?
    public var onDownloadProgress: ((MeasurementProgress) -> Void)?
    public var onDownloadMeasurement: ((SpeedTestMeasurement) -> Void)?

    private var downloader: DownloadClient?
    private var uploader: UploadClient?

    public init() { }

    public mutating func start(with type: TestType) async throws {
        do {
            let testServers = try await TestServer.discover()
            switch type {
            case .download:
                try await runDownloadTest(using: testServers)
            case .upload:
                try await runUploadTest(using: testServers)
            case .downloadAndUpload:
                try await runDownloadTest(using: testServers)
                try await runUploadTest(using: testServers)
            }
        } catch {
            throw error
        }
    }

    public func cancel() throws {
        try downloader?.stop()
        try uploader?.stop()
    }

    private mutating func runDownloadTest(using testServers: [TestServer]) async throws {
        guard let downloadPath = testServers.first?.urls.downloadPath,
                let downloadURL = URL(string: downloadPath) else {
            throw SpeedTestError.invalidTestURL("Cannot locate URL for download test")
        }

        downloader = DownloadClient(url: downloadURL)
        downloader?.onProgress = self.onDownloadProgress
        downloader?.onMeasurement = self.onDownloadMeasurement
        try await downloader?.start().get()
    }

    private mutating func runUploadTest(using testServers: [TestServer]) async throws {
        guard let uploadPath = testServers.first?.urls.uploadPath, let uploadURL = URL(string: uploadPath) else {
            throw SpeedTestError.invalidTestURL("Cannot locate URL for upload test")
        }

        uploader = UploadClient(url: uploadURL)
        uploader?.onProgress = self.onUploadProgress
        uploader?.onMeasurement = self.onUploadMeasurement
        try await uploader?.start().get()
    }
}
