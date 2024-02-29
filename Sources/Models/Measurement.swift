//
//  File.swift
//  
//
//  Created by Zhennan Zhou on 2/28/24.
//

import Foundation

public enum TestDirection: String, Codable {
    case upload = "upload"
    case download = "download"
}

public enum TestOrigin: String, Codable {
    case client = "client"
    case server = "server"
}

public struct AppInfo: Codable {
    let elapsedTime: Int64
    let numBytes: Int64
    
    enum CodingKeys: String, CodingKey {
        case elapsedTime = "ElapsedTime"
        case numBytes = "NumBytes"
    }
}

public struct BBRInfo: Codable {
    public let elapsedTime: Int64?
    public let bandwith: Int64?
    public let minRtt: Int64?
    public let pacingGain: Int64?
    public let cwndGain: Int64?

    enum CodingKeys: String, CodingKey {
        case elapsedTime = "ElapsedTime"
        case bandwith = "BW"
        case minRtt = "MinRTT"
        case pacingGain = "PacingGain"
        case cwndGain = "CwndGain"
    }
}

public struct ConnectionInfo: Codable {
    public let client: String?
    public let server: String?
    public let uuid: String?

    enum CodingKeys: String, CodingKey {
        case client = "Client"
        case server = "Server"
        case uuid = "UUID"
    }
}

public struct TCPInfo: Codable {
    public let busyTime: Int64?
    public let bytesAcked: Int64?
    public let bytesReceived: Int64?
    public let bytesSent: Int64?
    public let bytesRetrans: Int64?
    public let elapsedTime: Int64?
    public let minRTT: Int64?
    public let rtt: Int64?
    public let rttVar: Int64?
    public let rwndLimited: Int64?
    public let sndBufLimited: Int64?

    enum CodingKeys: String, CodingKey {
        case busyTime = "BusyTime"
        case bytesAcked = "BytesAcked"
        case bytesReceived = "BytesReceived"
        case bytesSent = "BytesSent"
        case bytesRetrans = "BytesRetrans"
        case elapsedTime = "ElapsedTime"
        case minRTT = "MinRTT"
        case rtt = "RTT"
        case rttVar = "RTTVar"
        case rwndLimited = "RWndLimited"
        case sndBufLimited = "SndBufLimited"
    }
}

public struct Measurement: Codable {
    public let appInfo: AppInfo?
    public let bbrInfo: BBRInfo?
    public let connectionInfo: ConnectionInfo?
    public var origin: TestOrigin?
    public var direction: TestDirection?
    public let tcpInfo: TCPInfo?

    /// coding keys for codable purpose.
    enum CodingKeys: String, CodingKey {
        case appInfo = "AppInfo"
        case bbrInfo = "BBRInfo"
        case connectionInfo = "ConnectionInfo"
        case origin = "Origin"
        case direction = "Test"
        case tcpInfo = "TCPInfo"
    }
}
