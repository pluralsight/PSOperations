#if os(iOS) || os(watchOS)

import CoreLocation
import Foundation
import PSOperations

public enum Location: CapabilityType {
    public static let name = "Location"

    case whenInUse
    case always

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
        case .authorizedAlways: completion(.authorized)
        case .authorizedWhenInUse:
            if self == .whenInUse {
                completion(.authorized)
                } else {
                    // the user wants .Always, but has .WhenInUse
                    // return .NotDetermined so that we can prompt to upgrade the permission
                    completion(.notDetermined)
                }
        @unknown default: completion(.notDetermined)
        }
    }

    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        Authorizer.authorize(self, completion: completion)
    }
}

private let Authorizer = LocationAuthorizer()

private class LocationAuthorizer: NSObject, CLLocationManagerDelegate {

    fileprivate let manager = CLLocationManager()
    fileprivate var completion: ((CapabilityStatus) -> Void)?
    fileprivate var kind = Location.whenInUse

    override init() {
        super.init()
        manager.delegate = self
    }

    func authorize(_ kind: Location, completion: @escaping (CapabilityStatus) -> Void) {
        guard self.completion == nil else {
            fatalError("Attempting to authorize location when a request is already in-flight")
        }
        self.completion = completion
        self.kind = kind

        let key: String
        switch kind {
        case .whenInUse:
            key = "NSLocationWhenInUseUsageDescription"
            manager.requestWhenInUseAuthorization()

        case .always:
            key = "NSLocationAlwaysUsageDescription"
            manager.requestAlwaysAuthorization()
        }

        // This is helpful when developing an app.
        assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }

    @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let completion = self.completion, manager == self.manager && status != .notDetermined {
            self.completion = nil

            switch status {
            case .authorizedAlways:
                completion(.authorized)
            case .authorizedWhenInUse:
                completion(kind == .whenInUse ? .authorized : .denied)
            case .denied:
                completion(.denied)
            case .restricted:
                completion(.notAvailable)
            case .notDetermined:
                fatalError("Unreachable due to the if statement, but included to keep clang happy")
            @unknown default: completion(.notDetermined)
            }
        }
    }
}

#endif
