import Foundation
import LCLSpeedtest

@main
struct Client {
    static func main() async throws {
        var client = SpeedTestClient()

        client.onDownloadProgress = { progress in
            print("progress: \(progress.convertTo(unit: .Mbps)) mbps")
        }

        try await client.start(with: .download)
    }
}

enum MeasurementUnit: String, CaseIterable, Identifiable, Encodable {

    case Mbps
    case MBps

    var id: Self { self }

    var string: String {
        switch self {
        case .Mbps:
            return "mbps"
        case .MBps:
            return "MB/s"
        }
    }
}

extension MeasurementProgress {

    /// data in Mbps
    var defaultValueInMegaBits: Double {
        self.convertTo(unit: .Mbps)
    }

    /// data in MB/s
    var defaultValueInMegaBytes: Double {
        self.convertTo(unit: .MBps)
    }

    /**
     Convert the measurement data to the given unit

     - Parameters:
        unit: the target unit to convert to
     - Returns: the value in `Double` under the specified unit measurement
     */
    func convertTo(unit: MeasurementUnit) -> Double {
        let elapsedTime = appInfo.elapsedTime
        let numBytes = appInfo.numBytes
        let time = Float64(elapsedTime) / 1_000_000
        var speed = Float64(numBytes) / time
        switch unit {
        case .Mbps:
            speed *= 8
        case .MBps:
            speed *= 1
        }

        speed /= 1_000_000
        return speed
    }
}
