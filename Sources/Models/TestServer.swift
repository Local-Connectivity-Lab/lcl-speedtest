//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/22/24.
//

import Foundation

#if os(Linux)
import FoundationNetworking
#endif

internal struct TestServerLocation: Codable {
    let country: String?
    let city: String?
}

internal struct TestServerURLs: Codable {
    let downloadPath: String
    let uploadPath: String
    let insecureDownloadPath: String
    let insecureUploadPath: String
    
    enum CodingKeys: String, CodingKey {
        case downloadPath = "wss:///ndt/v7/download"
        case uploadPath = "wss:///ndt/v7/upload"
        case insecureDownloadPath = "ws:///ndt/v7/download"
        case insecureUploadPath = "ws:///ndt/v7/upload"
    }
}

internal struct TestServer: Codable {
    let machine: String
    let location: TestServerLocation
    let urls: TestServerURLs
}

internal struct TestServerResponse: Codable {
    let results: [TestServer]
}

extension TestServer {
    internal static func discover() async throws -> [TestServer] {
        let result = try await Networking.fetch(from: DISCOVER_SERVER_URL)
        let response = try JSONDecoder().decode(TestServerResponse.self, from: result)
        return response.results
    }
}
