//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/23/24.
//

import Foundation

let MAX_RETRY_COUNT: UInt8 = 5
let DISCOVER_SERVER_URL = "https://locate.measurementlab.net/v2/nearest/ndt/ndt7?client_name=ndt7-client-ios"
let MAX_MESSAGE_SIZE: Int = 1 << 24
let MIN_MESSAGE_SIZE: Int = 1 << 13
let MEASUREMENT_REPORT_INTERVAL: Int64 = 250000 // 250 ms in microsecond
let MEASUREMENT_DURATION: Int64 = 10000000 // 10 second in microsecond
