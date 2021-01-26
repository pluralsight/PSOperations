#if os(iOS)

import Foundation
import Photos

public struct Photos: CapabilityType {
    public static let name = "Photos"

    public init() { }

    private func capabilityStatus(for authStatus: PHAuthorizationStatus) -> CapabilityStatus {
        switch authStatus {
        case .authorized: return .authorized
        case .limited: return .authorized
        case .denied: return .denied
        case .restricted: return .notAvailable
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        completion(capabilityStatus(for: status))
    }

    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(capabilityStatus(for: status))
        }
    }
}

#endif
