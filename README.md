# PSOperations

[![codebeat badge](https://codebeat.co/badges/5a8fa0e4-178b-499b-9947-98bf69013b7f)](https://codebeat.co/projects/github-com-pluralsight-psoperations) ![](https://travis-ci.org/pluralsight/PSOperations.svg)

This is an adaptation of the sample code provided in the Advanced NSOperations session of WWDC 2015. This code has been updated to work with the latest Swift changes as of Xcode 7. For usage examples, see [WWDC 2015 Advanced NSOperations](https://developer.apple.com/videos/wwdc/2015/?id=226) and/or look at the included unit tests.

Feel free to fork and submit pull requests, as we are always looking for improvements from the community.

Differences from the first version of the WWDC sample code:
* Canceling operations would not work.
* Canceling functions are slightly more friendly.
* Negated Condition would not negate.
* Unit tests!

Differences from the second version of the WWDC sample code:
* Sometimes canceling wouldn't work correctly in iOS 8.4. The finished override wasn't being called during cancel. We have fixed this to work in both iOS 8.4 and iOS 9.0.
* Canceling functions are slightly more friendly.
* Unit tests!

A difference from the WWDC Sample code worth mentioning:
* When conditions are evaluated and they fail the associated operation is cancelled. The operation still goes through the same flow otherwise, only now it will be marked as cancelled.
