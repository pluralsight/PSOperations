import Foundation

public enum CapabilityErrorCode: Int {
    public static var domain = "CapabilityErrors"

    case notDetermined
    case notAvailable
    case denied
}

public enum CapabilityStatus {
    /// The capability has not been requested yet
    case notDetermined

    /// The capability has been requested and approved
    case authorized

    /// The capability has been requested but was denied by the user
    case denied

    /// The capability is not available (perhaps due to restrictions, or lack of support)
    case notAvailable

    /// There was an error requesting the status of the capability
    case error(NSError)
}

public protocol CapabilityType {
    static var name: String { get }

    /// Retrieve the status of the capability.
    /// This method is called from the main queue.
    func requestStatus(_ completion: @escaping (CapabilityStatus) -> Void)

    /// Request authorization for the capability.
    /// This method is called from the main queue, and only if the
    /// capability's status is "NotDetermined"
    func authorize(_ completion: @escaping (CapabilityStatus) -> Void)
}

/// A condition for verifying and/or requesting a certain capability
public struct Capability<C: CapabilityType>: OperationCondition {

    public static var name: String { return "Capability<\(C.name)>" }
    public static var isMutuallyExclusive: Bool { return true }

    fileprivate let capability: C
    fileprivate let shouldRequest: Bool

    public init(_ capability: C, requestIfNecessary: Bool = true) {
        self.capability = capability
        self.shouldRequest = requestIfNecessary
    }

    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        guard shouldRequest == true else { return nil }
        return AuthorizeCapability(capability: capability)
    }

    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        DispatchQueue.main.async {
            self.capability.requestStatus { status in
                if let error = status.error {
                    let conditionError = NSError(code: .conditionFailed, userInfo: [
                        OperationConditionKey: type(of: self).name,
                        NSUnderlyingErrorKey: error
                    ])
                    completion(.failed(conditionError))
                } else {
                    completion(.satisfied)
                }
            }
        }
    }
}

private class AuthorizeCapability<C: CapabilityType>: Operation {
    fileprivate let capability: C

    init(capability: C) {
        self.capability = capability
        super.init()
        addCondition(AlertPresentation())
        addCondition(MutuallyExclusive<C>())
    }

    override fileprivate func execute() {
        DispatchQueue.main.async {
            self.capability.requestStatus { status in
                switch status {
                case .notDetermined: self.requestAuthorization()
                default: self.finishWithError(status.error)
                }
            }
        }
    }

    fileprivate func requestAuthorization() {
        DispatchQueue.main.async {
            self.capability.authorize { status in
                self.finishWithError(status.error)
            }
        }
    }
}

private extension NSError {
    convenience init(capabilityErrorCode: CapabilityErrorCode) {
        self.init(domain: CapabilityErrorCode.domain, code: capabilityErrorCode.rawValue, userInfo: [:])
    }
}

private extension CapabilityStatus {
    var error: NSError? {
        switch self {
        case .notDetermined: return NSError(capabilityErrorCode: .notDetermined)
        case .authorized: return nil
        case .denied: return NSError(capabilityErrorCode: .denied)
        case .notAvailable: return NSError(capabilityErrorCode: .notAvailable)
        case .error(let e): return e
        }
    }
}
