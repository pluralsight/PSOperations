#if os(iOS)

import Foundation
import PassKit
import PSOperations

public enum Passbook: CapabilityType {
    public static let name = "Passbook"

    case viewPasses
    case addPasses

    public func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void) {
        switch self {
        case .viewPasses:
            if PKPassLibrary.isPassLibraryAvailable() {
                completion(.authorized)
            } else {
                completion(.notAvailable)
            }
        case .addPasses:
            if PKAddPassesViewController.canAddPasses() {
                completion(.authorized)
            } else {
                completion(.notAvailable)
            }
        }
    }

    public func authorize(_ completion: @escaping (CapabilityStatus) -> Void) {
        // Since requestStatus() never returns .NotDetermined, this method should never be called
        fatalError("This should never be invoked")
    }
}

#endif
