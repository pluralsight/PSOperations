#if os(OSX)

import CoreLocation
import Foundation
import PSOperations

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
        case .notDetermined:
            completion(.notDetermined)
        case .restricted:
            completion(.notAvailable)
        case .denied:
            completion(.denied)
        case .authorized:
            completion(.authorized)
        default:
            completion(.authorized)

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

        let key = "NSLocationUsageDescription"
        manager.startUpdatingLocation()

        // This is helpful when developing an app.
        assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }

    @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let completion = self.completion, manager == self.manager {
            self.completion = nil

            switch status {
            case .authorized:
                completion(.authorized)
            case .denied:
                completion(.denied)
            case .restricted:
                completion(.notAvailable)
            case .notDetermined:
                self.completion = completion
                manager.startUpdatingLocation()
                manager.stopUpdatingLocation()
            default:
                completion(.authorized)
            }
        }
    }
}

#endif
