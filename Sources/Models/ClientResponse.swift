//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/28/24.
//

import Foundation

public struct ClientResponse: Codable {
    let appInfo: AppInfo
    let origin: String
    let test: String
    
    enum CodingKeys: String, CodingKey {
        case appInfo = "AppInfo"
        case origin = "Origin"
        case test = "Test"
    }
}

extension ClientResponse {
    public static func create(elapedTime: TimeInterval, numBytes: Int64, direction: TestDirection) -> ClientResponse {
        return ClientResponse(appInfo: AppInfo(elapsedTime: Int64(elapedTime), numBytes: numBytes), origin: "client", test: direction.rawValue)
    }
}
