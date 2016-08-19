//
//  HealthCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS) || os(watchOS)

import Foundation
import HealthKit
import PSOperations

public struct Health: CapabilityType {
    public static let name = "Health"
    
    fileprivate let readTypes: Set<HKSampleType>
    fileprivate let writeTypes: Set<HKSampleType>
    
    public init(typesToRead: Set<HKSampleType>, typesToWrite: Set<HKSampleType>) {
        self.readTypes = typesToRead
        self.writeTypes = typesToWrite
    }
    
    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.notAvailable)
            return
        }
        
        let notDeterminedTypes = writeTypes.filter { SharedHealthStore.authorizationStatus(for: $0) == .notDetermined }
        if notDeterminedTypes.isEmpty == false {
            completion(.notDetermined)
            return
        }
        
        let deniedTypes = writeTypes.filter { SharedHealthStore.authorizationStatus(for: $0) == .sharingDenied }
        if deniedTypes.isEmpty == false {
            completion(.denied)
            return
        }
        
        // if we get here, then every write type has been authorized
        // there's no way to know if we have read permissions,
        // so the best we can do is see if we've ever asked for authorization
        
        let unrequestedReadTypes = readTypes.subtracting(requestedReadTypes)
        
        if unrequestedReadTypes.isEmpty == false {
            completion(.notDetermined)
            return
        }
        
        // if we get here, then there was nothing to request for reading or writing
        // thus, everything is authorized
        completion(.authorized)
    }
    
    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.notAvailable)
            return
        }
        
        // make a note that we've requested these types before
        requestedReadTypes.formUnion(readTypes)
        
        // This method is smart enough to not re-prompt for access if it has already been granted.
        SharedHealthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { _, error in
            if let error = error {
                completion(.error(error as NSError))
            } else {
                self.requestStatus(completion)
            }
        }
    }
    
}

/**
    HealthKit does not report on whether or not you're allowed to read certain data types.
    Instead, we'll keep track of which types we've already request to read. If a new request
    comes along for a type that's not in here, we know that we'll need to re-prompt for
    permission to read that particular type.
*/
private var requestedReadTypes = Set<HKSampleType>()
private let SharedHealthStore = HKHealthStore()

#endif
