//
//  CloudCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if !os(watchOS)

import Foundation
import CloudKit

public struct iCloudContainer: CapabilityType {
    
    public static let name = "iCloudContainer"
    
    private let container: CKContainer
    private let permissions: CKApplicationPermissions
    
    public init(container: CKContainer, permissions: CKApplicationPermissions = []) {
        self.container = container
        self.permissions = permissions
    }
    
    public func requestStatus(_ completion: (CapabilityStatus) -> Void) {
        verifyAccountStatus(container, permission: permissions, shouldRequest: false, completion: completion)
    }
    
    public func authorize(_ completion: (CapabilityStatus) -> Void) {
        verifyAccountStatus(container, permission: permissions, shouldRequest: true, completion: completion)
    }
    
}

private func verifyAccountStatus(_ container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: (CapabilityStatus) -> Void) {
    container.accountStatus { accountStatus, accountError in
        switch accountStatus {
            case .noAccount: completion(.notAvailable)
            case .restricted: completion(.notAvailable)
            case .couldNotDetermine:
                let error = accountError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.notAuthenticated.rawValue, userInfo: nil)
                completion(.Error(error))
            case .available:
                if permission != [] {
                    verifyPermission(container, permission: permission, shouldRequest: shouldRequest, completion: completion)
                } else {
                    completion(.authorized)
                }
        }
    }
}

private func verifyPermission(_ container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: (CapabilityStatus) -> Void) {
    container.status(forApplicationPermission: permission) { permissionStatus, permissionError in
        switch permissionStatus {
            case .initialState:
                if shouldRequest {
                    requestPermission(container, permission: permission, completion: completion)
                } else {
                    completion(.notDetermined)
                }
            case .denied: completion(.denied)
            case .granted: completion(.authorized)
            case .couldNotComplete:
                let error = permissionError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.permissionFailure.rawValue, userInfo: nil)
                completion(.Error(error))
        }
    }
}

private func requestPermission(_ container: CKContainer, permission: CKApplicationPermissions, completion: (CapabilityStatus) -> Void) {
    DispatchQueue.main.async {
        container.requestApplicationPermission(permission) { requestStatus, requestError in
            switch requestStatus {
                case .initialState: completion(.notDetermined)
                case .denied: completion(.denied)
                case .granted: completion(.authorized)
                case .couldNotComplete:
                    let error = requestError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.permissionFailure.rawValue, userInfo: nil)
                    completion(.Error(error))
            }
        }
    }
}

#endif
