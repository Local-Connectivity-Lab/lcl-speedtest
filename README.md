# LCL Speedtest

LCL Speedtest is a cross-platform Speedtest client-side library written in Swift. The library is a community implementation of [NDT7 protocol from M-Lab](https://www.measurementlab.net/tests/ndt/ndt7/).

Please follow the policy and rules from M-Lab when using the measurement resources. 

## Requirements
- Swift 5.7+
- macOS 10.15+, iOS 14+, Linux

## Getting Started
Add the following to your `Package.swift` file:
```code
.package(url: "https://github.com/Local-Connectivity-Lab/lcl-speedtest.git", from: "1.0.0")
```

Then import the module to your project
```code
.target(
    name: "YourAppName",
    .dependencies: [
        .product(name: "LCLSpeedtest", package: "lcl-speedtest")
    ]
)
```

### Basic Usage
```swift
var testClient = SpeedTestClient()
testClient.onDownloadProgress = { measurement in
    print(measurement)
}
testClient.onUploadProgress = { measurement in
    print(measurement)
}
try await testClient.start(with: .downloadAndUpload)
```

### Features
- Measure download and upload throughputs through Websocket protocol.
- Fine tune upload throughput following the system capacity.
- Measurement supports cancellation.


## Contributing
Any contribution and pull requests are welcome! However, before you plan to implement some features or try to fix an uncertain issue, it is recommended to open a discussion first. You can also join our [Discord channel](https://discord.com/invite/gn4DKF83bP), or visit our [website](https://seattlecommunitynetwork.org/).

## License
LCL Speedtest is released under Apache License. See [LICENSE](/LICENSE) for more details.
