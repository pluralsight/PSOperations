//
//  PushCapability-OSX.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(OSX)

import Cocoa

public struct Push: CapabilityType {

    public static func didReceiveToken(token: NSData) {
        authorizer.completeAuthorization(token: token, error: nil)
    }

    public static func didFailRegistration(error: NSError) {
        authorizer.completeAuthorization(token: nil, error: error)
    }

    public static let name = "Push"

    private let types: NSApplication.RemoteNotificationType

    public init(types: NSApplication.RemoteNotificationType) {
        self.types = types
    }

    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        if authorizer.token != nil {
            completion(.authorized)
        } else {
            completion(.notDetermined)
        }
    }

    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        authorizer.authorize(types: types, completion: completion)
    }
}

private let authorizer = PushAuthorizer()

private class PushAuthorizer {

    var token: NSData?
    var completion: ((CapabilityStatus) -> Void)?

    func authorize(types: NSApplication.RemoteNotificationType, completion: @escaping (CapabilityStatus) -> Void) {
        guard self.completion == nil else {
            fatalError("Cannot request push authorization while a request is already in progress")
        }

        self.completion = completion
        NSApplication.shared.registerForRemoteNotifications(matching: types)
    }

    fileprivate func completeAuthorization(token: NSData?, error: NSError?) {
        self.token = token

        guard let completion = self.completion else { return }
        self.completion = nil

        if token != nil {
            completion(.authorized)
        } else if let error = error {
            completion(.error(error))
        } else {
            completion(.notDetermined)
        }
    }
}

#endif
