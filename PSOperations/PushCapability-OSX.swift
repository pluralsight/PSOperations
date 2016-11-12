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
    
    public static func didReceiveToken(_ token: Data) {
        authorizer.completeAuthorization(token, error: nil)
    }
    
    public static func didFailRegistration(_ error: NSError) {
        authorizer.completeAuthorization(nil, error: error)
    }
    
    public static let name = "Push"
    
    private let types: NSRemoteNotificationType
    
    public init(application: NSApplication, types: NSRemoteNotificationType) {
        self.types = types
        if authorizer.application == nil {
            authorizer.application = application
        }
    }
    
    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        if let _ = authorizer.token {
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

fileprivate class PushAuthorizer {
    
    var application: NSApplication?
    var token: Data?
    var completion: ((CapabilityStatus) -> Void)?
    
    func authorize(types: NSRemoteNotificationType, completion: @escaping (CapabilityStatus) -> Void) {
        guard self.completion == nil else {
            fatalError("Cannot request push authorization while a request is already in progress")
        }
        
        self.completion = completion
        
        guard let application = application else {
            fatalError("An application has not yet been configured, so this won't work")
        }
        
        application.registerForRemoteNotifications(matching: types)
    }
    
    fileprivate func completeAuthorization(_ token: Data?, error: NSError?) {
        self.token = token
        
        guard let completion = self.completion else { return }
        self.completion = nil
        
        if let _ = self.token {
            completion(.authorized)
        } else if let error = error {
            completion(.error(error))
        } else {
            completion(.notDetermined)
        }
    }
    
}

#endif
