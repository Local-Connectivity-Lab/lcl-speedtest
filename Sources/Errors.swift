//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/22/24.
//

import Foundation

enum SpeedTestError: Error {
    case fetchContentFailed(Int)
    case noDataFromServer
    
    case notImplemented
}
