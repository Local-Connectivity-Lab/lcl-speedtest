//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/29/24.
//

import Foundation

extension Date {
    static var nowInMicroSecond: Int64 {
        if #available(macOS 12, *) {
            Int64(Date.now.timeIntervalSince1970 * 1000_000)
        } else {
            Int64(Date().timeIntervalSince1970 * 1000_000)
        }
    }
}
