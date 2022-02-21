// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swiftlint:disable:next file_header

import PackageDescription

let package = Package(
    name: "PSOperations",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v6),
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
