// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@main
struct TestClient {
    public static func main() async throws {
        let testServers = try await TestServer.discover()
        let downloadPath = URL(string: testServers[0].urls.downloadPath)
        
        var testClient = SpeedTestClient(url: downloadPath!) { measurement in
            print(measurement)
        } onProgress: { progress in
            print(progress)
        } onFinish: { finish, error in
            print(finish)
        }
        
        try testClient.stop()

        try await testClient.start().get()
    }
}

