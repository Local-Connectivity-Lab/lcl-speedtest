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
        if result.isEmpty {
            throw SpeedTestError.testServersOutOfCapacity
        }
        let response = try JSONDecoder().decode(TestServerResponse.self, from: result)
        return response.results
    }
}
