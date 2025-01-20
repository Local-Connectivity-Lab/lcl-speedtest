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

/// Maximum retry count
let maxRetryCount: UInt8 = 5

/// M-Lab discover server URL
let discoverServerURL =
  "https://locate.measurementlab.net/v2/nearest/ndt/ndt7?client_name=ndt7-client-ios"

/// Maximum message size to send in one websocket frame.
let maxMessageSize: Int = 1 << 23

/// Minimum message size to send in one websocket frame.
let minMessageSize: Int = 1 << 13

/// The number of second to update measurement report to the caller
let measurementReportInterval: Int64 = 250  // 250 ms

/// The number of second to measure the throughput.
let measurementDuration: Int64 = 10  // 10 seconds

let scalingFactor = 16
