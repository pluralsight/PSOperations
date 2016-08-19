//
//  PhotosCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

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
        }
    }
    
    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
                case .authorized: completion(.authorized)
                case .denied: completion(.denied)
                case .restricted: completion(.notAvailable)
                case .notDetermined: completion(.notDetermined)
            }
        }
    }
}

#endif
