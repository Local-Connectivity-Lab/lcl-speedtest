// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@main
struct TestClient {
    
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
            print("Cannot locate URL for download test")
            return
        }
        let downloader = DownloadClient(url: downloadURL)
        downloader.onProgress = { measurementProgress in
            print("speed: \(measurementProgress.convertTo(unit: .Mbps))")
        }
        downloader.onMeasurement = { measurement in
        }
        try await downloader.start().get()
    }
    
    private func runUploadTest(using testServers: [TestServer]) async throws {
        guard let uploadPath = testServers.first?.urls.uploadPath, let uploadURL = URL(string: uploadPath) else {
            print("Cannot locate URL for upload test")
            return
        }
        let uploader = UploadClient(url: uploadURL)
        uploader.onProgress = { measurementProgress in
            print("speed: \(measurementProgress.convertTo(unit: .Mbps))")
        }
        uploader.onMeasurement = { measurement in

        }
        try await uploader.start().get()
    }
    
    public static func main() async throws {
        let testClient = TestClient()
        try await testClient.start(with: .upload)
    }
}

