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
    static func fetch(from urlString: String, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeout: TimeInterval = 60, retry: UInt8 = 0) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw SpeedTestError.invalidURL
        }
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        var retryCount = min(retry, MAX_RETRY_COUNT) + 1
        while retryCount != 0 {
            retryCount -= 1
            do {
                return try await fetch(from: request)
            } catch SpeedTestError.fetchContentFailed(let statusCode) {
                if 400...499 ~= statusCode {
                    throw SpeedTestError.fetchContentFailed(statusCode)
                }
            } catch SpeedTestError.testServersOutOfCapacity {
                return Data()
            }
        }
        
        print(2)
        throw SpeedTestError.noDataFromServer
    }
    
    static func fetch(from request: URLRequest) async throws -> Data {
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
                case 204:
                    continuation.resume(throwing: SpeedTestError.testServersOutOfCapacity)
                case 200...299:
                    continuation.resume(returning: data)
                default:
                    continuation.resume(throwing: SpeedTestError.fetchContentFailed(statusCode))
                }
            }
            
            task.resume()
        }
    }
}
