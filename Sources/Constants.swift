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
let MAX_RETRY_COUNT: UInt8 = 5

/// M-Lab discover server URL
let DISCOVER_SERVER_URL = "https://locate.measurementlab.net/v2/nearest/ndt/ndt7?client_name=ndt7-client-ios"

/// Maximum message size to send in one websocket frame.
let MAX_MESSAGE_SIZE: Int = 1 << 24

/// Minimum message size to send in one websocket frame.
let MIN_MESSAGE_SIZE: Int = 1 << 13

/// The number of second to update measurement report to the caller
let MEASUREMENT_REPORT_INTERVAL: Int64 = 250000 // 250 ms in microsecond

/// The number of second to measure the throughput.
let MEASUREMENT_DURATION: Int64 = 10000000 // 10 second in microsecond
