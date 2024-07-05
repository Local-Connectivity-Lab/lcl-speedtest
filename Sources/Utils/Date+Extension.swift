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

extension Date {

    /// Get the current time in microsecond
    ///
    /// - Returns: current time in microsecond.
    static var nowInMicroSecond: Int64 {
        if #available(macOS 12, iOS 15, *) {
            Int64(Date.now.timeIntervalSince1970 * 1000_000)
        } else {
            Int64(Date().timeIntervalSince1970 * 1000_000)
        }
    }
}
