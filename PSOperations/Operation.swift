/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file contains the foundational subclass of NSOperation.
*/

import Foundation

/**
    The subclass of `NSOperation` from which all other operations should be derived.
    This class adds both Conditions and Observers, which allow the operation to define
    extended readiness requirements, as well as notify many interested parties 
    about interesting operation state changes
*/
open class Operation: Foundation.Operation {

    private static var psoperationContext = 0

    /* The completionBlock property has unexpected behaviors such as executing twice and executing on unexpected threads. BlockObserver
     * executes in an expected manner.
     */
    @available(*, deprecated, message: "use BlockObserver completions instead")
    override open var completionBlock: (() -> Void)? {
        set {
            fatalError("The completionBlock property on NSOperation has unexpected behavior and is not supported in PSOperations.Operation 😈")
        }
        get {
            return nil
        }
    }

    // use the KVO mechanism to indicate that changes to "state" affect other properties as well
    @objc class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state" as NSObject]
    }

    @objc class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state" as NSObject]
    }

    @objc class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state" as NSObject]
    }

    @objc class func keyPathsForValuesAffectingIsCancelled() -> Set<NSObject> {
        return ["cancelledState" as NSObject]
    }

    override public init() {
        super.init()
        self.addObserver(self, forKeyPath: "isReady", options: [], context: &Operation.psoperationContext)
    }

    deinit {
        self.removeObserver(self, forKeyPath: "isReady", context: &Operation.psoperationContext)
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &Operation.psoperationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        stateAccess.lock()
        defer { stateAccess.unlock() }
        guard super.isReady && !isCancelled && state == .pending else { return }
        evaluateConditions()
    }

    /**
        Indicates that the Operation can now begin to evaluate readiness conditions,
        if appropriate.
    */
    func didEnqueue() {
        stateAccess.lock()
        defer { stateAccess.unlock() }
        state = .pending
    }

    private let stateAccess = NSRecursiveLock()
    /// Private storage for the `state` property that will be KVO observed.
    private var _state = State.initialized
    private let stateQueue = DispatchQueue(label: "Operations.Operation.state")
    fileprivate var state: State {
        get {
            return stateQueue.sync {
                return _state
            }
        }
        set {
            /*
             It's important to note that the KVO notifications are NOT called from inside
             the lock. If they were, the app would deadlock, because in the middle of
             calling the `didChangeValueForKey()` method, the observers try to access
             properties like "isReady" or "isFinished". Since those methods also
             acquire the lock, then we'd be stuck waiting on our own lock. It's the
             classic definition of deadlock.
             */
            willChangeValue(forKey: "state")
            stateQueue.sync {
                guard _state != .finished else { return }
                assert(_state.canTransitionToState(newValue, operationIsCancelled: isCancelled), "Performing invalid state transition. from: \(_state) to: \(newValue)")
                _state = newValue
            }
            didChangeValue(forKey: "state")
        }
    }

    // Here is where we extend our definition of "readiness".
    override open var isReady: Bool {
        stateAccess.lock()
        defer { stateAccess.unlock() }

        guard super.isReady else { return false }

        guard !isCancelled  else { return true }

        switch state {
        case .initialized, .evaluatingConditions, .pending:
            return false
        case .ready, .executing, .finishing, .finished:
            return true
        }
    }

    open var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }
        set {
            stateAccess.lock()
            defer { stateAccess.unlock() }

            assert(state < .executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? .userInitiated : .default
        }
    }

    override open var isExecuting: Bool {
        return state == .executing
    }

    override open var isFinished: Bool {
        return state == .finished
    }

    private var __cancelled = false
    private let cancelledQueue = DispatchQueue(label: "Operations.Operation.cancelled")
    private var _cancelled: Bool {
        get {
            var currentState = false
            cancelledQueue.sync {
                currentState = __cancelled
            }
            return currentState
        }
        set {
            stateAccess.lock()
            defer { stateAccess.unlock() }

            guard _cancelled != newValue else { return }

            willChangeValue(forKey: "cancelledState")
            cancelledQueue.sync {
                __cancelled = newValue
            }

            if state == .initialized || state == .pending {
                state = .ready
            }

            didChangeValue(forKey: "cancelledState")

            if newValue {
                for observer in observers {
                    observer.operationDidCancel(self)
                }
            }
        }
    }

    override open var isCancelled: Bool {
        return _cancelled
    }

    fileprivate func evaluateConditions() {
        stateAccess.lock()
        defer { stateAccess.unlock() }

        assert(state == .pending && !isCancelled, "evaluateConditions() was called out-of-order")

        guard !conditions.isEmpty else {
            state = .ready
            return
        }

        state = .evaluatingConditions

        OperationConditionEvaluator.evaluate(conditions, operation: self) { failures in
            self.stateAccess.lock()
            defer { self.stateAccess.unlock() }

            if !failures.isEmpty {
                self.cancelWithErrors(failures)
            }

            self.state = .ready
        }
    }

    // MARK: Observers and Conditions

    fileprivate(set) var conditions: [OperationCondition] = []

    open func addCondition(_ condition: OperationCondition) {
        assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }

    fileprivate(set) var observers: [OperationObserver] = []

    open func addObserver(_ observer: OperationObserver) {
        assert(state < .executing, "Cannot modify observers after execution has begun.")
        observers.append(observer)
    }

    override open func addDependency(_ operation: Foundation.Operation) {
        assert(state <= .executing, "Dependencies cannot be modified after execution has begun.")
        super.addDependency(operation)
    }

    // MARK: Execution and Cancellation
    override public final func main() {
        stateAccess.lock()

        assert(state == .ready, "This operation must be performed on an operation queue.")

        if internalErrors.isEmpty && !isCancelled {
            state = .executing
            stateAccess.unlock()

            for observer in observers {
                observer.operationDidStart(self)
            }

            execute()
        } else {
            finish()
            stateAccess.unlock()
        }
    }

    /**
    `execute()` is the entry point of execution for all `Operation` subclasses.
    If you subclass `Operation` and wish to customize its execution, you would
    do so by overriding the `execute()` method.
    
    At some point, your `Operation` subclass must call one of the "finish"
    methods defined below; this is how you indicate that your operation has
    finished its execution, and that operations dependent on yours can re-evaluate
    their readiness state.
    */
    open func execute() {
        print("\(type(of: self)) must override `execute()`.")

        finish()
    }

    private let errorQueue = DispatchQueue(label: "Operations.Operation.internalErrors")
    private var _internalErrors: [NSError] = []
    fileprivate var internalErrors: [NSError] {
        get {
            return errorQueue.sync {
                return _internalErrors
            }
        }
        set {
            errorQueue.sync {
                _internalErrors = newValue
            }
        }
    }

    open var errors: [NSError] {
        return internalErrors
    }

    override open func cancel() {
        stateAccess.lock()
        defer { stateAccess.unlock() }
        guard !isFinished else { return }

        _cancelled = true

        if state > .ready {
            finish()
        }
    }

    open func cancelWithErrors(_ errors: [NSError]) {
        internalErrors += errors
        cancel()
    }

    open func cancelWithError(_ error: NSError) {
        cancelWithErrors([error])
    }

    public final func produceOperation(_ operation: Foundation.Operation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }

    // MARK: Finishing

    /**
        Most operations may finish with a single error, if they have one at all.
        This is a convenience method to simplify calling the actual `finish()` 
        method. This is also useful if you wish to finish with an error provided 
        by the system frameworks. As an example, see `DownloadEarthquakesOperation` 
        for how an error from an `NSURLSession` is passed along via the 
        `finishWithError()` method.
    */
    public final func finishWithError(_ error: NSError?) {
        if let error = error {
            finish([error])
        } else {
            finish()
        }
    }

    /**
        A private property to ensure we only notify the observers once that the 
        operation has finished.
    */
    fileprivate var hasFinishedAlready = false
    public final func finish(_ errors: [NSError] = []) {
        stateAccess.lock()
        defer { stateAccess.unlock() }
        guard !hasFinishedAlready else { return }

        hasFinishedAlready = true
        state = .finishing

        internalErrors += errors

        finished(internalErrors)

        for observer in observers {
            observer.operationDidFinish(self, errors: internalErrors)
        }

        state = .finished
    }

    /**
        Subclasses may override `finished(_:)` if they wish to react to the operation
        finishing with errors. For example, the `LoadModelOperation` implements 
        this method to potentially inform the user about an error when trying to
        bring up the Core Data stack.
    */
    open func finished(_ errors: [NSError]) { }

    override open func waitUntilFinished() {
        /*
            Waiting on operations is almost NEVER the right thing to do. It is 
            usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
            or `dispatch_group_notify`, or even `NSLocking` objects. Many developers 
            use waiting when they should instead be chaining discrete operations 
            together using dependencies.
            
            To reinforce this idea, invoking `waitUntilFinished()` will crash your
            app, as incentive for you to find a more appropriate way to express
            the behavior you're wishing to create.
        */
        fatalError("Waiting on operations is an anti-pattern.")
    }
}
