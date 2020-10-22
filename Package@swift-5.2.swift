// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PSOperations",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_11),
        .tvOS(.v9),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PSOperations",
            targets: ["PSOperations"]),
        .library(
            name: "PSOperationsCalendar",
            targets: ["PSOperationsCalendar"]),
        .library(
            name: "PSOperationsLocation",
            targets: ["PSOperationsLocation"]),
        .library(
            name: "PSOperationsHealth",
            targets: ["PSOperationsHealth"]),
        .library(
            name: "PSOperationsPassbook",
            targets: ["PSOperationsPassbook"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "PSOperations",
                path: "PSOperations",
                exclude: ["Info.plist", "PSOperations.h"]),
        .target(name: "PSOperationsCalendar",
                dependencies: ["PSOperations"],
                path: "PSOperationsCalendar"),
        .target(name: "PSOperationsLocation",
                dependencies: ["PSOperations"],
                path: "PSOperationsLocation"),
        .target(name: "PSOperationsHealth",
                dependencies: ["PSOperations"],
                path: "PSOperationsHealth"),
        .target(name: "PSOperationsPassbook",
                dependencies: ["PSOperations"],
                path: "PSOperationsPassbook"),
        .testTarget(name: "PSOperationsTests",
                    dependencies: ["PSOperations"],
                    path: "PSOperationsTests",
                    exclude: ["Info.plist"]),
    ]
)
