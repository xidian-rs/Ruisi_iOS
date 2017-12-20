//
//  Reachability.swift
//  Ruisi
//
//  Created by yang on 2017/11/29.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import SystemConfiguration

// 网络检测 检测网络改变来切换校园网和校外网的rs
class Reachability {
    var hostname: String?
    var isRunning = false
    var isReachableOnWWAN: Bool
    var reachability: SCNetworkReachability?
    var reachabilityFlags = SCNetworkReachabilityFlags()
    let reachabilitySerialQueue = DispatchQueue(label: "ReachabilityQueue")

    static func startCheckHost(host: String) {
        do {
            Network.reachability = try Reachability(hostname: host)
            do {
                try Network.reachability?.start()
            } catch let error as Network.Error {
                print(error)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }

    var status: Network.Status {
        return !isConnectedToNetwork ? .unreachable :
                isReachableViaWiFi ? .wifi :
                        isReachable ? .wwan : .unreachable
    }

    init? (hostname: String) throws {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            throw Network.Error.failedToCreateWith(hostname)
        }

        self.reachability = reachability
        self.hostname = hostname
        isReachableOnWWAN = true
    }

    deinit {
        stop()
    }

    func start() throws {
        guard let reachability = reachability, !isRunning else {
            return
        }
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged<Reachability>.passUnretained(self).toOpaque()
        guard SCNetworkReachabilitySetCallback(reachability, callout, &context) else {
            stop()
            throw Network.Error.failedToSetCallout
        }
        guard SCNetworkReachabilitySetDispatchQueue(reachability, reachabilitySerialQueue) else {
            stop()
            throw Network.Error.failedToSetDispatchQueue
        }
        reachabilitySerialQueue.async {
            self.flagsChanged()
        }
        isRunning = true
        print("network reachability started...")
    }

    func stop() {
        defer {
            isRunning = false
        }
        guard let reachability = reachability else {
            return
        }
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        self.reachability = nil
    }

    var isConnectedToNetwork: Bool {
        return isReachable &&
                !isConnectionRequiredAndTransientConnection &&
                !(isWWAN && !isReachableOnWWAN)
    }

    var isReachableViaWiFi: Bool {
        return isReachable && !isWWAN
    }

    /// Flags that indicate the reachability of a network node name or address, including whether a connection is required, and whether some user intervention might be required when establishing a connection.
    var flags: SCNetworkReachabilityFlags? {
        guard let reachability = reachability else {
            return nil
        }
        var flags = SCNetworkReachabilityFlags()
        return withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0))
        } ? flags : nil
    }

    /// compares the current flags with the previous flags and if changed posts a flagsChanged notification
    func flagsChanged() {
        guard let flags = flags, flags != reachabilityFlags else {
            return
        }
        reachabilityFlags = flags
        NotificationCenter.default.post(name: .flagsChanged, object: self)
    }

    /// The specified node name or address can be reached via a transient connection, such as PPP.
    var transientConnection: Bool {
        return flags?.contains(.transientConnection) == true
    }

    /// The specified node name or address can be reached using the current network configuration.
    var isReachable: Bool {
        return flags?.contains(.reachable) == true
    }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. If this flag is set, the kSCNetworkReachabilityFlagsConnectionOnTraffic flag, kSCNetworkReachabilityFlagsConnectionOnDemand flag, or kSCNetworkReachabilityFlagsIsWWAN flag is also typically set to indicate the type of connection required. If the user must manually make the connection, the kSCNetworkReachabilityFlagsInterventionRequired flag is also set.
    var connectionRequired: Bool {
        return flags?.contains(.connectionRequired) == true
    }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. Any traffic directed to the specified name or address will initiate the connection.
    var connectionOnTraffic: Bool {
        return flags?.contains(.connectionOnTraffic) == true
    }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established.
    var interventionRequired: Bool {
        return flags?.contains(.interventionRequired) == true
    }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. The connection will be established "On Demand" by the CFSocketStream programming interface (see CFStream Socket Additions for information on this). Other functions will not establish the connection.
    var connectionOnDemand: Bool {
        return flags?.contains(.connectionOnDemand) == true
    }

    /// The specified node name or address is one that is associated with a network interface on the current system.
    var isLocalAddress: Bool {
        return flags?.contains(.isLocalAddress) == true
    }

    /// Network traffic to the specified node name or address will not go through a gateway, but is routed directly to one of the interfaces in the system.
    var isDirect: Bool {
        return flags?.contains(.isDirect) == true
    }

    /// The specified node name or address can be reached via a cellular connection, such as EDGE or GPRS.
    var isWWAN: Bool {
        return flags?.contains(.isWWAN) == true
    }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. If this flag is set
    /// The specified node name or address can be reached via a transient connection, such as PPP.
    var isConnectionRequiredAndTransientConnection: Bool {
        return (flags?.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]) == true
    }
}

func callout(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else {
        return
    }
    DispatchQueue.main.async {
        Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue().flagsChanged()
    }
}

extension Notification.Name {
    static let flagsChanged = Notification.Name("FlagsChanged")
}

struct Network {
    static var reachability: Reachability?

    enum Status: String, CustomStringConvertible {
        case unreachable, wifi, wwan
        var description: String {
            return rawValue
        }
    }

    enum Error: Swift.Error {
        case failedToSetCallout
        case failedToSetDispatchQueue
        case failedToCreateWith(String)
        case failedToInitializeWith(sockaddr_in)
    }
}
