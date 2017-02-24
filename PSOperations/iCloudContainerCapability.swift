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

    fileprivate let container: CKContainer
    fileprivate let permissions: CKContainer.Application.Permissions

    public init(container: CKContainer, permissions: CKContainer.Application.Permissions = []) {
        self.container = container
        self.permissions = permissions
    }

    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        verifyAccountStatus(container, permission: permissions, shouldRequest: false, completion: completion)
    }

    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        verifyAccountStatus(container, permission: permissions, shouldRequest: true, completion: completion)
    }
}

private func verifyAccountStatus(_ container: CKContainer, permission: CKContainer.Application.Permissions, shouldRequest: Bool, completion: @escaping (CapabilityStatus) -> Void) {

    container.accountStatus { accountStatus, accountError in

        func completeWithError() {
            completion(.error(accountError ?? CKError(.notAuthenticated)))
        }

        switch accountStatus {
        case .noAccount: completion(.notAvailable)
        case .restricted: completion(.notAvailable)
        case .available:
            if permission != [] {
                verifyPermission(container, permission: permission, shouldRequest: shouldRequest, completion: completion)
            } else {
                completion(.authorized)
            }
        case .couldNotDetermine:
            completeWithError()
        @unknown default:
            completeWithError()
        }
    }
}

private func verifyPermission(_ container: CKContainer, permission: CKContainer.Application.Permissions, shouldRequest: Bool, completion: @escaping (CapabilityStatus) -> Void) {
    container.status(forApplicationPermission: permission) { permissionStatus, permissionError in

        func completeWithError() {
            completion(.error(permissionError ?? CKError(.permissionFailure)))
        }

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
            completeWithError()
        @unknown default:
            completeWithError()
        }
    }
}

private func requestPermission(_ container: CKContainer, permission: CKContainer.Application.Permissions, completion: @escaping (CapabilityStatus) -> Void) {
    DispatchQueue.main.async {
        container.requestApplicationPermission(permission) { requestStatus, requestError in
            switch requestStatus {
            case .initialState: completion(.notDetermined)
            case .denied: completion(.denied)
            case .granted: completion(.authorized)
            case .couldNotComplete:
                completion(.error(requestError ?? CKError(.permissionFailure)))
            @unknown default:
                completion(.notDetermined)
            }
        }
    }
}

#endif
