// //
// // This source file is part of the LCL open source project
// //
// // Copyright (c) 2021-2024 Local Connectivity Lab and the project authors
// // Licensed under Apache License v2.0
// //
// // See LICENSE for license information
// // See CONTRIBUTORS for the list of project authors
// //
// // SPDX-License-Identifier: Apache-2.0
// //

// import Foundation

// /// The network measurement unit used by the speed test framework
// enum NDT7MeasurementUnit: String, CaseIterable, Identifiable {

//     case Mbps
//     case MBps

//     var id: Self {self}

//     var toString: String {
//         switch self {
//         case .Mbps:
//             return "mbps"
//         case .MBps:
//             return "MB/s"
//         }
//     }
// }

// extension MeasurementProgress {

//     /// data in Mbps
//     var defaultValueInMegaBits: Double {
//         get {
//             self.convertTo(unit: .Mbps)
//         }
//     }

//     /// data in MB/s
//     var defaultValueInMegaBytes: Double {
//         get {
//             self.convertTo(unit: .MBps)
//         }
//     }

//     /**
//      Convert the measurement data to the given unit
     
//      - Parameters:
//         unit: the target unit to convert to
//      - Returns: the value in `Double` under the specified unit measurement
//      */
//     func convertTo(unit: NDT7MeasurementUnit) -> Double {
//         let elapsedTime = appInfo.elapsedTime
//         let numBytes = appInfo.numBytes
//         if elapsedTime != 0 {
//             let time = Float64(elapsedTime) / 1000000
//             var speed = Float64(numBytes) / time
//             switch unit {
//             case .Mbps:
//                 speed *= 8
//             case .MBps:
//                 speed *= 1
//             }

//             speed /= 1000000
//             return speed
//         }

//         return .zero
//     }
// }

// extension Double {

//     /**
//      Round the double number to given decimal digits
     
//      - Precondition: digit has to be >= 0
//      - Parameters:
//         - to: the number of decimal digits to round to
//      - Returns: the value, rounded to the given digits
//      */
//     func rounded(to: Int) -> Double {
//         let divisor = pow(10.0, Double(to))
//         return (self * divisor).rounded() / divisor
//     }
// }
