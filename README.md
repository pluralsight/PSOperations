# PSOperations

[![codebeat badge](https://codebeat.co/badges/5a8fa0e4-178b-499b-9947-98bf69013b7f)](https://codebeat.co/projects/github-com-pluralsight-psoperations) [![Build Status](https://app.bitrise.io/app/e1a3e3a8d5e6ef42/status.svg?token=4Mixz35ECEfGcWB8vCPpig)](https://app.bitrise.io/app/e1a3e3a8d5e6ef42)

PSOperations is a framework that leverages the power of NSOperation and NSOperationQueue. It enables you to use operations more easily in all parts of your project.

This is an adaptation of the sample code provided in the [Advanced NSOperations](https://developer.apple.com/videos/wwdc/2015/?id=226) session of WWDC 2015.



## Support

 - Swift 5.x
 - iOS 8.0
 - tvOS 9.0
 - watchOS (undefined deployment target)
 - macOS (undefined deployment target)
 - Extension friendly
 - Tests only run against iOS 9 (latest) and tvOS 9 (latest)

### Swift 3+
Because Swift 3 removes the `NS` prefix on several Foundation types we've added a few typealiases for convenience. We investigated renaming the few classes that conflict but ran into radar://28917706 where frameworks will fallback to Foundation types if the framework doesn't contain the given type i.e. `UIKit.Data` is valid and really is `Foundation.Data`. If we were to rename `Operation` to `PSOperation` usuages of `PSOperations.Operation` would end up using `Foundation.Operation` and potentially break your code. 

Here are the typealiases:
```
public typealias PSOperation = Operation
public typealias PSOperationQueue = OperationQueue
public typealias PSOperationQueueDelegate = OperationQueueDelegate
public typealias PSBlockOperation = BlockOperation
```

## Installation
PSOperations supports multiple methods for installing the library in a project.

### CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like PSOperations in your projects.

 You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate PSOperations into your Xcode project using CocoaPods, specify it in your `Podfile`.  
If you want all the child subspecs (Health and Passbook capabilities):

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'TargetName' do
pod 'PSOperations', '~> 4.0'
end
```

Then, run the following command:

```bash
$ pod install
```

**Alternative configurations:**  
Core functionality, _excluding_ capabilities:
```ruby
pod 'PSOperations/Core', '~> 4.0'
```

Core functionality, including only the Passbook capability:
```ruby
pod 'PSOperations/Passbook', '~> 4.0'
```

Core functionality, including only the Health capability:
```ruby
pod 'PSOperations/Health', '~> 4.0'
```

Core functionality, including only the Calendar capability:
```ruby
pod 'PSOperations/Calendar', '~> 4.0'
```

Core functionality, including only the Location capability and operation:
```ruby
pod 'PSOperations/Location', '~> 4.0'
```

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PSOperations into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "pluralsight/PSOperations"
```

Run `carthage` to build the framework and drag the built `PSOperations.framework` into your Xcode project. Optionally you can add `PSOperationsHealth.framework`, `PSOperationsPassbook.framework`, `PSOperationsCalendar.framework`  and `PSOperationsLocation.framework`

## Getting started

Don't forget to import!
```
import PSOperations
```

If you are using the HealthCapability, PassbookCapability, CalendarCapability, LocationCapability or LocationOperation you'll need to import them separately:

```
import PSOperationsHealth
import PSOperationsPassbook
import PSOperationsCalendar
import PSOperationsLocation
```

These features need to be in a separate framework otherwise they may cause App Store review rejection for importing `HealthKit`, `PassKit`, `EventKit` or `CoreLocation` but not actually using them.

#### Create a Queue
The OperationQueue is the heartbeat and is a subclass of NSOperationQueue:
```
let operationQueue = OperationQueue()
```

#### Create an Operation
`Operation` is a subclass of `NSOperation`. Like `NSOperation` it doesn't do much. But PSOperations provides a few helpful subclasses such as:
```
BlockOperation
GroupOperation
URLSessionTaskOperation
LocationOperation
DelayOperation
```

Here is a quick example:
```
let blockOperation = BlockOperation {
	print("perform operation")
}

operationQueue.addOperation(blockOperation)
```

#### Observe an Operation
`Operation` instances can be observed for starting, cancelling, finishing and producing new operations with the `OperationObserver` protocol.

PSOperations provide a couple of types that implement the protocol:
```
BlockObserver
TimeoutObserver
```

Here is a quick example:
```
let blockOperation = BlockOperation {
	print("perform operation")
}

let finishObserver = BlockObserver { operation, error in        
	print("operation finished! \(error)")
}

blockOperation.addObserver(finishObserver)

operationQueue.addOperation(blockOperation)
```

#### Set Conditions on an Operation
`Operation` instances can have conditions required to be met in order to execute using the `OperationCondition` protocol.

PSOperations provide a several types that implement the protocol:
```
SilentCondition
NegatedCondition
NoCancelledDependencies
MutuallyExclusive
ReachabilityCondition
Capability
```

Here is a quick example:
```
let blockOperation = BlockOperation {
	print("perform operation")
}

let dependentOperation = BlockOperation {
	print("working away")
}
                dependentOperation.addCondition(NoCancelledDependencies())
dependentOperation.addDependency(blockOperation)

operationQueue.addOperation(blockOperation)
operationQueue.addOperation(dependentOperation)
```

if `blockOperation` is cancelled, `dependentOperation` will not execute.

#### Set Capabilities on an Operation
A `CapabilityType` is used by the `Capability` condition and allows you to easily view the authorization state and request the authorization of certain capabilities within Apple's ecosystem. i.e. Calendar, Photos, iCloud, Location, and Push Notification.

Here is a quick example:
```
let blockOperation = BlockOperation {
	print("perform operation")
}


let calendarCapability = Capability(Photos())
        
blockOperation.addCondition(calendarCapability)

operationQueue.addOperation(blockOperation)
```

This operation requires access to Photos and will request access to them if needed.

#### Going custom
The examples above provide simple jobs but PSOperations can be involved in many parts of your application. Here is a custom `UIStoryboardSegue` that leverages the power of PSOperations. The segue is retained until an operation is completed. This is a generic `OperationSegue` that will run any given operation. One use case for this might be an authentication operation that ensures a user is authenticated before preceding with the segue. The authentication operation could even present authentication UI if needed.

```
class OperationSegue: UIStoryboardSegue {
    
    var operation: Operation?
    var segueCompletion: ((success: Bool) -> Void)?
    
    override func perform() {        
        if let operation = operation {
            let opQ = OperationQueue()
            var retainedSelf: OperationSegue? = self
            
            let completionObserver = BlockObserver {
                op, errors in
                
                dispatch_async_on_main {
                    defer {
                        retainedSelf = nil
                    }
                    
                    let success = errors.count == 0 && !op.cancelled
                    
                    if let completion = retainedSelf?.segueCompletion {
                        completion(success: success)
                    }
                    
                    if success {
                        retainedSelf?.finish()
                    }
                }
            }
            
            operation.addObserver(completionObserver)
            opQ.addOperation(operation)
        } else {
            finish()
        }
    }
    
    func finish() {
        super.perform()
    }
}

```

## Contribute


Feel free to submit pull requests, as we are always looking for improvements from the community.

## WWDC Differences

Differences from the first version of the WWDC sample code:

 - Canceling operations would not work.
 - Canceling functions are slightly more friendly.
 - Negated Condition would not negate.
 - Unit tests!

Differences from the second version of the WWDC sample code:

 - Sometimes canceling wouldn't work correctly in iOS 8.4. The finished override wasn't being called during cancel. We have fixed this to work in both iOS 8.4 and iOS 9.0.
 - Canceling functions are slightly more friendly.
 - Unit tests!

A difference from the WWDC Sample code worth mentioning:
 
 - When conditions are evaluated and they fail the associated operation is cancelled. The operation still goes through the same flow otherwise, only now it will be marked as cancelled.
