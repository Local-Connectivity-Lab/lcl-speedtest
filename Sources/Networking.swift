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

internal struct Networking {
    static func send(request: URLRequest) async throws -> [TestServer] {
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: SpeedTestError.noDataFromServer)
                    return
                }
                
                let statusCode = (response as! HTTPURLResponse).statusCode
                switch statusCode {
                case 200...299:
                    do {
                        let testServers = try JSONDecoder().decode([TestServer].self, from: data)
                        continuation.resume(returning: testServers)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                default:
                    continuation.resume(throwing: SpeedTestError.fetchContentFailed(statusCode))
                }
            }
        }
    }
}
