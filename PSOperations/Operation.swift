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
    class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state" as NSObject, "cancelledState" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsCancelled() -> Set<NSObject> {
        return ["cancelledState" as NSObject]
    }
    
    // MARK: State Management
    
    fileprivate enum State: Int, Comparable {
        /// The initial state of an `Operation`.
        case initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case pending
        
        /// The `Operation` is evaluating conditions.
        case evaluatingConditions
        
        /**
            The `Operation`'s conditions have all been satisfied, and it is ready 
            to execute.
        */
        case ready
        
        /// The `Operation` is executing.
        case executing
        
        /**
            Execution of the `Operation` has finished, but it has not yet notified 
            the queue of this.
        */
        case finishing
        
        /// The `Operation` has finished executing.
        case finished
        
        func canTransitionToState(_ target: State, operationIsCancelled cancelled: Bool) -> Bool {
            switch (self, target) {
            case (.initialized, .pending):
                return true
            case (.pending, .evaluatingConditions):
                return true
            case (.pending, .finishing) where cancelled:
                return true
            case (.pending, .ready) where cancelled:
                return true
            case (.evaluatingConditions, .ready):
                return true
            case (.ready, .executing):
                return true
            case (.ready, .finishing):
                return true
            case (.executing, .finishing):
                return true
            case (.finishing, .finished):
                return true
            default:
                return false
            }
        }
    }
    
    /**
        Indicates that the Operation can now begin to evaluate readiness conditions,
        if appropriate.
    */
    func didEnqueue() {
        state = .pending
    }
    
    /// Private storage for the `state` property that will be KVO observed.
    fileprivate var _state = State.initialized
    
    /// A lock to guard reads and writes to the `_state` property
    fileprivate let stateLock = NSRecursiveLock()

    fileprivate var state: State {
        get {
            return stateLock.withCriticalScope {
                _state
            }
        }
        
        set(newState) {
            /*
            It's important to note that the KVO notifications are NOT called from inside
            the lock. If they were, the app would deadlock, because in the middle of
            calling the `didChangeValueForKey()` method, the observers try to access
            properties like "isReady" or "isFinished". Since those methods also
            acquire the lock, then we'd be stuck waiting on our own lock. It's the
            classic definition of deadlock.
            */
            willChangeValue(forKey: "state")
            
            stateLock.withCriticalScope { Void -> Void in
                guard _state != .finished else {
                    return
                }
                
                assert(_state.canTransitionToState(newState, operationIsCancelled: isCancelled), "Performing invalid state transition.")
                _state = newState
            }
            
            didChangeValue(forKey: "state")
        }
    }
    
    // Here is where we extend our definition of "readiness".
    override open var isReady: Bool {
        
        var _ready = false
        
        stateLock.withCriticalScope {
            switch state {
                
            case .initialized:
                // If the operation has been cancelled, "isReady" should return true
                _ready = isCancelled
                
            case .pending:
                // If the operation has been cancelled, "isReady" should return true
                guard !isCancelled else {
                    state = .ready
                    _ready = true
                    return
                }
                
                // If super isReady, conditions can be evaluated
                if super.isReady {
                    evaluateConditions()
                    _ready = state == .ready
                }
                
            case .ready:
                _ready = super.isReady || isCancelled
                
            default:
                _ready = false
            }
            
        }
        
        return _ready
    }
    
    open var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }

        set {
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
    
    var _cancelled = false {
        willSet {
            willChangeValue(forKey: "cancelledState")
        }
        
        didSet {
            didChangeValue(forKey: "cancelledState")
            if _cancelled != oldValue && _cancelled == true {
                
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
        assert(state == .pending && !isCancelled, "evaluateConditions() was called out-of-order")
        
        state = .evaluatingConditions
        
        guard conditions.count > 0 else {
            state = .ready
            return
        }
        
        OperationConditionEvaluator.evaluate(conditions, operation: self) { failures in
            if !failures.isEmpty {
                self.cancelWithErrors(failures)
            }
            
            //We must preceed to have the operation exit the queue
            self.state = .ready
        }
    }
     
    // MARK: Observers and Conditions
    
    fileprivate(set) var conditions = [OperationCondition]()

    open func addCondition(_ condition: OperationCondition) {
        assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun.")

        conditions.append(condition)
    }
    
    fileprivate(set) var observers = [OperationObserver]()
    
    open func addObserver(_ observer: OperationObserver) {
        assert(state < .executing, "Cannot modify observers after execution has begun.")
        
        observers.append(observer)
    }
    
    override open func addDependency(_ operation: Foundation.Operation) {
        assert(state <= .executing, "Dependencies cannot be modified after execution has begun.")

        super.addDependency(operation)
    }
    
    // MARK: Execution and Cancellation
    
    override final public func start() {
        // NSOperation.start() contains important logic that shouldn't be bypassed.
        super.start()
        
        // If the operation has been cancelled, we still need to enter the "Finished" state.
        stateLock.withCriticalScope {
            if isCancelled {
                finish()
            }
        }
    }
    
    override final public func main() {
        stateLock.withCriticalScope {
            assert(state == .ready, "This operation must be performed on an operation queue.")
            
            if _internalErrors.isEmpty && !isCancelled {
                state = .executing
                
                for observer in observers {
                    observer.operationDidStart(self)
                }
                
                execute()
            }
            else {
                finish()
            }
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
    
    fileprivate var _internalErrors = [NSError]()
  
  
    open var errors : [NSError] {
        return _internalErrors
    }
  
    override open func cancel() {
        stateLock.withCriticalScope {
            if isFinished {
                return
            }
            
            _cancelled = true
            
            if state > .ready {
                finish()
            }
        }
    }
    
    open func cancelWithErrors(_ errors: [NSError]) {
        _internalErrors += errors
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
        }
        else {
            finish()
        }
    }
    
    /**
        A private property to ensure we only notify the observers once that the 
        operation has finished.
    */
    fileprivate var hasFinishedAlready = false
    public final func finish(_ errors: [NSError] = []) {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .finishing
            
            _internalErrors += errors
          
            finished(_internalErrors)
            
            for observer in observers {
                observer.operationDidFinish(self, errors: _internalErrors)
            }
            
            state = .finished
        }
    }
    
    /**
        Subclasses may override `finished(_:)` if they wish to react to the operation
        finishing with errors. For example, the `LoadModelOperation` implements 
        this method to potentially inform the user about an error when trying to
        bring up the Core Data stack.
    */
    open func finished(_ errors: [NSError]) {
        // No op.
    }
    
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
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
    }
    
}

// Simple operator functions to simplify the assertions used above.
private func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
