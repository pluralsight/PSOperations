#if os(iOS)

import Foundation
import Photos

public struct Photos: CapabilityType {
    public static let name = "Photos"

    public init() { }

    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized: completion(.authorized)
        case .denied: completion(.denied)
        case .restricted: completion(.notAvailable)
        case .notDetermined: completion(.notDetermined)
        @unknown default: completion(.notDetermined)
        }
    }

    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized: completion(.authorized)
            case .denied: completion(.denied)
            case .restricted: completion(.notAvailable)
            case .notDetermined: completion(.notDetermined)
            @unknown default: completion(.notDetermined)
            }
        }
    }
}

#endif
