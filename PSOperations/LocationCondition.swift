/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if !os(OSX)

import CoreLocation

/// A condition for verifying access to the user's location.
@available(*, deprecated, message: "use Capability(Location...) instead")

public struct LocationCondition: OperationCondition {
    /**
     Declare a new enum instead of using `CLAuthorizationStatus`, because that
     enum has more case values than are necessary for our purposes.
     */
    public enum Usage {
        case whenInUse
        #if !os(tvOS)
        case always
        #endif
    }
    
    public static let name = "Location"
    static let locationServicesEnabledKey: NSString = "CLLocationServicesEnabled"
    static let authorizationStatusKey: NSString = "CLAuthorizationStatus"
    public static let isMutuallyExclusive = false
    
    let usage: Usage
    
    public init(usage: Usage) {
        self.usage = usage
    }
    
    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return LocationPermissionOperation(usage: usage)
    }
    
    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        let enabled = CLLocationManager.locationServicesEnabled()
        let actual = CLLocationManager.authorizationStatus()
        
        var error: NSError?
        
        // There are several factors to consider when evaluating this condition
        switch (enabled, usage, actual) {
        case (true, _, .authorizedAlways):
            // The service is enabled, and we have "Always" permission -> condition satisfied.
            break
            
        case (true, .whenInUse, .authorizedWhenInUse):
            /*
            The service is enabled, and we have and need "WhenInUse"
            permission -> condition satisfied.
            */
            break
            
        default:
            /*
            Anything else is an error. Maybe location services are disabled,
            or maybe we need "Always" permission but only have "WhenInUse",
            or maybe access has been restricted or denied,
            or maybe access hasn't been request yet.
            
            The last case would happen if this condition were wrapped in a `SilentCondition`.
            */
            
            error = NSError(
                code: .conditionFailed,
                userInfo: [
                    OperationConditionKey: type(of: self).name,
                    type(of: self).locationServicesEnabledKey: enabled,
                    type(of: self).authorizationStatusKey: Int(actual.rawValue)
                ]
            )
        }
        
        if let error = error {
            completion(.failed(error))
        }
        else {
            completion(.satisfied)
        }
    }
}

/**
 A private `Operation` that will request permission to access the user's location,
 if permission has not already been granted.
 */
class LocationPermissionOperation: Operation {
    let usage: LocationCondition.Usage
    var manager: CLLocationManager?
    
    init(usage: LocationCondition.Usage) {
        self.usage = usage
        super.init()
        /*
        This is an operation that potentially presents an alert so it should
        be mutually exclusive with anything else that presents an alert.
        */
        addCondition(AlertPresentation())
    }
    
    override func execute() {
        /*
        Not only do we need to handle the "Not Determined" case, but we also
        need to handle the "upgrade" (.WhenInUse -> .Always) case.
        */
        
        #if os(tvOS)
            switch (CLLocationManager.authorizationStatus(), usage) {
            case (.notDetermined, _):
                DispatchQueue.main.async {
                    self.requestPermission()
                }
                
            default:
                finish()
            }
        #else
            switch (CLLocationManager.authorizationStatus(), usage) {
            case (.notDetermined, _), (.authorizedWhenInUse, .always):
                DispatchQueue.main.async {
                    self.requestPermission()
                }
                
            default:
                finish()
            }
        #endif
    }
    
    fileprivate func requestPermission() {
        manager = CLLocationManager()
        manager?.delegate = self
        
        let key: String
        
        #if os(tvOS)
            switch usage {
            case .whenInUse:
                key = "NSLocationWhenInUseUsageDescription"
                manager?.requestWhenInUseAuthorization()
            }
        #else
            switch usage {
            case .whenInUse:
                key = "NSLocationWhenInUseUsageDescription"
                manager?.requestWhenInUseAuthorization()
                
            case .always:
                key = "NSLocationAlwaysUsageDescription"
                manager?.requestAlwaysAuthorization()
            }
        #endif
        
        // This is helpful when developing the app.
        assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }
    
}

extension LocationPermissionOperation: CLLocationManagerDelegate {
    @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if manager == self.manager && isExecuting && status != .notDetermined {
            finish()
        }
    }
}

#endif
