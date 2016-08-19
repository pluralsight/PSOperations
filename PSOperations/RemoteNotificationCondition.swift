/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import UIKit
    
private let RemoteNotificationQueue = OperationQueue()
private let RemoteNotificationName = "RemoteNotificationPermissionNotification"

private enum RemoteRegistrationResult {
    case token(Data)
    case error(NSError)
}

/// A condition for verifying that the app has the ability to receive push notifications.
@available(*, deprecated, message: "use Capability(Push(...)) instead")
    
public struct RemoteNotificationCondition: OperationCondition {
    public static let name = "RemoteNotification"
    public static let isMutuallyExclusive = false
    
    static func didReceiveNotificationToken(_ token: Data) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: RemoteNotificationName), object: nil, userInfo: [
            "token": token
        ])
    }
    
    static func didFailToRegister(_ error: NSError) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: RemoteNotificationName), object: nil, userInfo: [
            "error": error
        ])
    }
    
    let application: UIApplication
    
    public init(application: UIApplication) {
        self.application = application
    }
    
    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return RemoteNotificationPermissionOperation(application: application, handler: { _ in })
    }
    
    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        /*
            Since evaluation requires executing an operation, use a private operation
            queue.
        */
        RemoteNotificationQueue.addOperation(RemoteNotificationPermissionOperation(application: application) { result in
            switch result {
                case .token(_):
                    completion(.satisfied)

                case .error(let underlyingError):
                    let error = NSError(code: .conditionFailed, userInfo: [
                        OperationConditionKey: type(of: self).name,
                        NSUnderlyingErrorKey: underlyingError
                    ])

                    completion(.failed(error))
            }
        })
    }
}

/**
    A private `Operation` to request a push notification token from the `UIApplication`.
    
    - note: This operation is used for *both* the generated dependency **and** 
        condition evaluation, since there is no "easy" way to retrieve the push
        notification token other than to ask for it.

    - note: This operation requires you to call either `RemoteNotificationCondition.didReceiveNotificationToken(_:)` or
        `RemoteNotificationCondition.didFailToRegister(_:)` in the appropriate 
        `UIApplicationDelegate` method, as shown in the `AppDelegate.swift` file.
*/
class RemoteNotificationPermissionOperation: Operation {
    let application: UIApplication
    fileprivate let handler: (RemoteRegistrationResult) -> Void
    
    fileprivate init(application: UIApplication, handler: @escaping (RemoteRegistrationResult) -> Void) {
        self.application = application
        self.handler = handler

        super.init()
        
        /*
            This operation cannot run at the same time as any other remote notification
            permission operation.
        */
        addCondition(MutuallyExclusive<RemoteNotificationPermissionOperation>())
    }
    
    override func execute() {
        DispatchQueue.main.async {
            let notificationCenter = NotificationCenter.default
            
            notificationCenter.addObserver(self, selector: #selector(RemoteNotificationPermissionOperation.didReceiveResponse(_:)), name: NSNotification.Name(rawValue: RemoteNotificationName), object: nil)
            
            self.application.registerForRemoteNotifications()
        }
    }
    
    @objc func didReceiveResponse(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        
        let userInfo = (notification as NSNotification).userInfo

        if let token = userInfo?["token"] as? Data {
            handler(.token(token))
        }
        else if let error = userInfo?["error"] as? NSError {
            handler(.error(error))
        }
        else {
            fatalError("Received a notification without a token and without an error.")
        }

        finish()
    }
}
    
#endif
