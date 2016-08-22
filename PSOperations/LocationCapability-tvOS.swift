//
//  LocationCapability-tvOS.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(tvOS)

import Foundation
import CoreLocation

public struct Location: CapabilityType {
    public static let name = "Location"

    public init() { }

    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.notAvailable)
            return
        }
        
        let actual = CLLocationManager.authorizationStatus()
        
        switch actual {
            case .notDetermined: completion(.notDetermined)
            case .restricted: completion(.notAvailable)
            case .denied: completion(.denied)
            case .authorizedWhenInUse: completion(.authorized)
            case .authorizedAlways:
                fatalError(".Always should be unavailable on tvOS")
        }
    }
    
    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        Authorizer.authorize(completion: completion)
    }
}

private let Authorizer = LocationAuthorizer()

private class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private var completion: ((CapabilityStatus) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func authorize(completion: @escaping (CapabilityStatus) -> Void) {
        guard self.completion == nil else {
            fatalError("Attempting to authorize location when a request is already in-flight")
        }
        self.completion = completion
        
        let key = "NSLocationWhenInUseUsageDescription"
        manager.requestWhenInUseAuthorization()
        
        // This is helpful when developing an app.
        assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }
    
    @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let completion = self.completion, manager == self.manager && status != .notDetermined {
            self.completion = nil
            
            switch status {
                case .authorizedWhenInUse:
                    completion(.authorized)
                case .denied:
                    completion(.denied)
                case .restricted:
                    completion(.notAvailable)
                case .authorizedAlways:
                    fatalError(".Always should be unavailable on tvOS")
                case .notDetermined:
                    fatalError("Unreachable due to the if statement, but included to keep clang happy")
            }
        }
    }
    
}

#endif
