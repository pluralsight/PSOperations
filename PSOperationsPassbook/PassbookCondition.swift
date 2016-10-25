/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)
    
import PassKit
import PSOperations

/// A condition for verifying that Passbook exists and is accessible.
@available(*, deprecated, message: "use Capability(Passbook....) instead")
    
public struct PassbookCondition: OperationCondition {
    
    public static let name = "Passbook"
    public static let isMutuallyExclusive = false
    
    public init() { }
    
    public func dependencyForOperation(_ operation: PSOperations.Operation) -> Foundation.Operation? {
        /*
            There's nothing you can do to make Passbook available if it's not 
            on your device.
        */
        return nil
    }
    
    public func evaluateForOperation(_ operation: PSOperations.Operation, completion: @escaping (OperationConditionResult) -> Void) {
        if PKPassLibrary.isPassLibraryAvailable() {
            completion(.satisfied)
        }
        else {
            let error = NSError(code: .conditionFailed, userInfo: [
                OperationConditionKey: type(of: self).name
            ])

            completion(.failed(error))
        }
    }
}
    
#endif
