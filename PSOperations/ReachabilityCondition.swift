/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if !os(watchOS)

import Foundation
import SystemConfiguration

/**
    This is a condition that performs a very high-level reachability check.
    It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
    Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
*/
public struct ReachabilityCondition: OperationCondition {
    public static let hostKey = "Host"
    public static let name = "Reachability"
    public static let isMutuallyExclusive = false
    
    let host: URL
    
    
    public init(host: URL) {
        self.host = host
    }
    
    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        ReachabilityController.requestReachability(host) { reachable in
            if reachable {
                completion(.satisfied)
            }
            else {
                let error = NSError(code: .conditionFailed, userInfo: [
                    OperationConditionKey: type(of: self).name,
                    type(of: self).hostKey: self.host
                ])
                
                completion(.failed(error))
            }
        }
    }
    
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController {
    static var reachabilityRefs = [String: SCNetworkReachability]()

    static let reachabilityQueue = DispatchQueue(label: "Operations.Reachability", attributes: [])
    
    static func requestReachability(_ url: URL, completionHandler: @escaping (Bool) -> Void) {
        if let host = url.host {
            reachabilityQueue.async {
                var ref = self.reachabilityRefs[host]
                
                if ref == nil {
                    let hostString = host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.utf8String!)
                }
                
                if let ref = ref {
                    self.reachabilityRefs[host] = ref
                    
                    var reachable = false
                    var flags: SCNetworkReachabilityFlags = []
                    if SCNetworkReachabilityGetFlags(ref, &flags) {
                        /*
                        Note that this is a very basic "is reachable" check.
                        Your app may choose to allow for other considerations,
                        such as whether or not the connection would require
                        VPN, a cellular connection, etc.
                        */
                        reachable = flags.contains(.reachable)
                    }
                    completionHandler(reachable)
                }
                else {
                    completionHandler(false)
                }
            }
        }
        else {
            completionHandler(false)
        }
    }
}

#endif
