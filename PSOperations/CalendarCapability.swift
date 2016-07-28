//
//  CalendarCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if !os(tvOS)

import Foundation
import EventKit

private let SharedEventStore = EKEventStore()

extension EKEntityType: CapabilityType {
    public static var name: String { return "EKEntityType" }
    
    public func requestStatus(_ completion: (CapabilityStatus) -> Void) {
        let status = EKEventStore.authorizationStatus(for: self)
        switch status {
            case .authorized: completion(.authorized)
            case .denied: completion(.denied)
            case .restricted: completion(.notAvailable)
            case .notDetermined: completion(.notDetermined)
        }
    }
    
    public func authorize(_ completion: (CapabilityStatus) -> Void) {
        SharedEventStore.requestAccess(to: self) { granted, error in
            if granted {
                completion(.authorized)
            } else if let error = error {
                completion(.Error(error))
            } else {
                completion(.notAvailable)
            }
        }
    }
}

#endif
