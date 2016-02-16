Pod::Spec.new do |s|

	s.name         	= "PSOperations"
	s.version      	= "2.1.0"
	s.summary      	= "This is an adaptation of the sample code provided in the Advanced NSOperations session of WWDC 2015"
	s.description  	= <<-DESC
	This is an adaptation of the sample code provided in the [Advanced NSOperations session of WWDC 2015](https://developer.apple.com/videos/wwdc/2015/?id=226).  This code has been updated to work with the latest Swift changes as of Xcode 7.  For usage examples, see WWDC 2015 Advanced NSOperations and/or look at the included unit tests.

	Feel free to fork and submit pull requests, as we are always looking for improvements from the community.

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

	DESC

	s.homepage	= "https://github.com/pluralsight/PSOperations"
	s.license	= { :type => 'MIT' }
	s.author	= "Matt McMurry", "Mark Schultz"

	s.ios.deployment_target = '8.0'
	s.watchos.deployment_target = "2.0"
	s.osx.deployment_target = "10.11"

	s.requires_arc = true
	s.pod_target_xcconfig = { "EMBEDDED_CONTENT_CONTAINS_SWIFT" => "YES" }

	s.source 	= {  git: "https://github.com/pluralsight/PSOperations.git",  tag: s.version.to_s  }
	
	subspec_sources = { 
		"CloudKit" => [
			"PSOperations/iCloudContainerCapability.swift", 
			"PSOperations/CloudCondition.swift",
			"PSOperations/CKContainer+Operations.swift",
			"CloudCondition.swift"
		],
		"HealthKit" => ["PSOperations/Health*.swift"],
		"CoreLocation" => ["PSOperations/Location*.swift"],
		"PassKit" => ["PSOperations/Passbook*.swift"],
		"Photos" => ["PSOperations/Photos*.swift"],
		"SystemConfiguration" => ["PSOperations/ReachabilityCondition.swift"],
		"EventKit" => ["PSOperations/Calendar*.swift"]
		}
	
	s.source_files = "PSOperations/**/*.swift"
	s.exclude_files = subspec_sources.values.flatten()

	s.subspec "Core" do |sb|
		sb.source_files = "PSOperations/**/*.swift"
		sb.exclude_files = subspec_sources.values.flatten()
	end

	s.subspec "CloudKit" do |sb|
		sb.source_files = subspec_sources["CloudKit"]
	end

	s.subspec "HealthKit" do |sb|
		sb.source_files = subspec_sources["HealthKit"]
	end

	s.subspec "CoreLocation" do |sb|
		sb.source_files = subspec_sources["CoreLocation"]
	end

	s.subspec "PassKit" do |sb|
		sb.source_files = subspec_sources["PassKit"]
	end

	s.subspec "Photos" do |sb|
		sb.source_files = subspec_sources["Photos"]
	end

	s.subspec "SystemConfiguration" do |sb|
		sb.source_files = subspec_sources["SystemConfiguration"]
	end

	s.subspec "EventKit" do |sb|
		sb.source_files = subspec_sources["EventKit"]
	end
end
