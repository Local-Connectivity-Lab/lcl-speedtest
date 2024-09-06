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

internal struct Networking {

    /// Fetch data from the given url asynchronously.
    ///
    /// - Parameters:
    ///     - from: the URL string from which the data will be fetched.
    ///     - cachePolicy: the cache policy used when fetching content from the URL. Default to using protocol cache policy.
    ///     - timeout: the number of time, in second, interval for the request. The default is 60.0s.
    ///     - retry: the number of retry before giving up fetching content from the given URL.
    /// - Returns: the raw data queried from the endpoint.
    /// - Throws: `SpeedTestError.invalidURL` is given URL string is invalid. `SpeedTestError.fetchContentFailed` if fetching from
    /// the target server failed. `SpeedTestError.testServersOutOfCapacity` is test servers are out of capacity. `SpeedTestError.noDataFromServer` if server returns no data.
    static func fetch(
        from urlString: String,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        timeout: TimeInterval = 60,
        retry: UInt8 = 0
    ) async throws -> Data {
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
                throw SpeedTestError.testServersOutOfCapacity
            }
        }

        throw SpeedTestError.noDataFromServer
    }

    /// Fetch data from the given request asynchronously.
    ///
    /// - Parameters:
    ///     - from: the `URLRequest` that defines the endpoint from which the data will be fetched.
    ///
    /// - Returns: the raw data queried from the endpoint according to the `URLRequest`.
    /// - Throws: `SpeedTestError.testServersOutOfCapacity` if server returns 204.
    /// `SpeedTestError.fetchContentFailed` if server returns status code not in the 200-299 range.
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
