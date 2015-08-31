# PSOperations

![](https://travis-ci.org/pluralsight/PSOperations.svg)

This is an adaptation of the sample code provided in the Advanced NSOperations session of WWDC 2015. This code has been updated to work with the latest Swift changes as of Xcode 7 beta 6. For usage examples, see [WWDC 2015 Advanced NSOperations](https://developer.apple.com/videos/wwdc/2015/?id=226) and/or look at the included unit tests.

Feel free to fork and submit pull requests, as we are always looking for improvements from the community.

This also provides fixes to issues found in the original sample code, mostly: 
* Canceling operations would not work (In the first version of the WWDC sample code).
* Canceling functions are slightly more friendly.
* Negated Condition would not negate (In the first version of the WWDC sample code). 
* Unit tests!

3 differences from the WWDC Sample code worth mentioning:
* When conditions are evaluated and they fail the associated operation is cancelled. The operation still goes through the same flow otherwise, only now it will be marked as cancelled.
* DelayOperation has a semaphore that waits in the execute function. This allows cancelling to work in all cases.
* BlockOperations that have a mainQueue block to execute have a semaphore that waits in the execution function. This allows canceling of the operation while executing the mainQueue closure.
