/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import EventKit

/// A condition for verifying access to the user's calendar.
public struct CalendarCondition: OperationCondition {
    
    public static let name = "Calendar"
    static let entityTypeKey = "EKEntityType"
    public let isMutuallyExclusive = false
    
    let entityType: EKEntityType
    
    init(entityType: EKEntityType) {
        self.entityType = entityType
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return CalendarPermissionOperation(entityType: entityType)
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        switch EKEventStore.authorizationStatusForEntityType(entityType) {
            case .Authorized:
                completion(.Satisfied)

            default:
                // We are not authorized to access entities of this type.
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: self.dynamicType.name,
                    self.dynamicType.entityTypeKey: entityType
                ])
                
                completion(.Failed(error))
        }
    }
}

/**
    A private `Operation` that will request access to the user's Calendar/Reminders, 
    if it has not already been granted.
*/
class CalendarPermissionOperation: Operation {
    let entityType: EKEntityType
    let store = EKEventStore()
    
    init(entityType: EKEntityType) {
        self.entityType = entityType
        super.init()
        addCondition(AlertPresentation())
    }
    
    override func execute() {
        let status = EKEventStore.authorizationStatusForEntityType(entityType)
        
        switch status {
            case .NotDetermined:
                dispatch_async(dispatch_get_main_queue()) {
                    self.store.requestAccessToEntityType(self.entityType) { granted, error in
                        self.finish()
                    }
                }

            default:
                finish()
        }
    }
    
}
