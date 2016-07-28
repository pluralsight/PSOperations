//
//  UserNotificationCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS)

import UIKit
    
public struct UserNotification: CapabilityType {
    
    public static let name = "UserNotificaton"
    
    public static func didRegisterUserSettings() {
        authorizer.completeAuthorization()
    }
    
    public enum Behavior {
        case replace
        case merge
    }
    
    private let settings: UIUserNotificationSettings
    private let behavior: Behavior
    
    public init(settings: UIUserNotificationSettings, behavior: Behavior = .merge, application: UIApplication) {
        self.settings = settings
        self.behavior = behavior
        
        if authorizer._application == nil {
            authorizer.application = application
        }
    }
    
    public func requestStatus(_ completion: (CapabilityStatus) -> Void) {
        let registered = authorizer.areSettingsRegistered(settings)
        completion(registered ? .authorized : .notDetermined)
    }
    
    public func authorize(_ completion: (CapabilityStatus) -> Void) {
        let settings: UIUserNotificationSettings
        
        switch behavior {
            case .replace:
                settings = self.settings
            case .merge:
                let current = authorizer.application.currentUserNotificationSettings()
                settings = current?.settingsByMerging(self.settings) ?? self.settings
        }
        
        authorizer.authorize(settings, completion: completion)
    }
    
}
    
private let authorizer = UserNotificationAuthorizer()
    
private class UserNotificationAuthorizer {
    
    var _application: UIApplication?
    var application: UIApplication {
        set {
            _application = newValue
        }
        get {
            guard let application = _application else {
                fatalError("Application not yet configured. Results would be undefined.")
            }
            
            return application
        }
    }
    var completion: ((CapabilityStatus) -> Void)?
    var settings: UIUserNotificationSettings?
    
    func areSettingsRegistered(_ settings: UIUserNotificationSettings) -> Bool {
        let current = application.currentUserNotificationSettings()
        
        return current?.contains(settings) ?? false
    }
    
    func authorize(_ settings: UIUserNotificationSettings, completion: (CapabilityStatus) -> Void) {
        guard self.completion == nil else {
            fatalError("Cannot request push authorization while a request is already in progress")
        }
        guard self.settings == nil else {
            fatalError("Cannot request push authorization while a request is already in progress")
        }
        
        self.completion = completion
        self.settings = settings
        
        application.registerUserNotificationSettings(settings)
    }
    
    private func completeAuthorization() {
        
        guard let completion = self.completion else { return }
        guard let settings = self.settings else { return }
        
        self.completion = nil
        self.settings = nil
        
        let registered = areSettingsRegistered(settings)
        completion(registered ? .authorized : .denied)
    }
    
}

#endif
