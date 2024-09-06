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

/// The types of test supported by `LCL Speedtest`.
/// Caller should specify one of the test type to initialize the test environment.
public enum TestType: String {

    /// Conduct download speed test.
    case download

    /// Conduct upload speed test.
    case upload

    /// Conduct download and upload tests.
    case downloadAndUpload
}
