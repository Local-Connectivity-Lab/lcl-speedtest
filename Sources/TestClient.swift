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

struct SpeedTestClient {
    
    var onProgress: ((MeasurementProgress) -> Void)?
    var onMeasurement: ((Measurement) -> Void)?
    
    public func start(with type: TestType) async throws {
        let testServers = try await TestServer.discover()
        if testServers.isEmpty {
            print("No available servers for testing. Exit")
            return
        }
        
        switch type {
        case .download:
            try await runDownloadTest(using: testServers)
        case .upload:
            try await runUploadTest(using: testServers)
        case .downloadAndUpload:
            try await runDownloadTest(using: testServers)
            try await runUploadTest(using: testServers)
        }
    }
    
    private func runDownloadTest(using testServers: [TestServer]) async throws {
        guard let downloadPath = testServers.first?.urls.downloadPath, let downloadURL = URL(string: downloadPath) else {
            throw SpeedTestError.invalidTestURL("Cannot locate URL for download test")
        }

        let downloader = DownloadClient(url: downloadURL)
        downloader.onProgress = self.onProgress
        downloader.onMeasurement = self.onMeasurement
        try await downloader.start().get()
    }
    
    private func runUploadTest(using testServers: [TestServer]) async throws {
        guard let uploadPath = testServers.first?.urls.uploadPath, let uploadURL = URL(string: uploadPath) else {
            throw SpeedTestError.invalidTestURL("Cannot locate URL for upload test")
        }

        let uploader = UploadClient(url: uploadURL)
        uploader.onProgress = self.onProgress
        uploader.onMeasurement = self.onMeasurement
        try await uploader.start().get()
    }
}

