//
//  OperationDebugData.swift
//  OperationKit
//
//  Created by Justin Newitter on 4/15/16.
//

import Foundation

/**
 * Protocol for expressing that an object can return `OperationDebugData`.
 */
protocol OperationDebuggable {

    func debugData() -> OperationDebugData

}

public class OperationDebugData {

    private static let dumpDepthLimit: Int = 50

    public typealias Logger = (String) -> Void

    public let description: String
    public let properties: [String: String]
    public let conditions: [String]
    public let dependencies: [OperationDebugData]
    public let subOperations: [OperationDebugData]

    public init(
        description: String,
        properties: [String: String],
        conditions: [String],
        dependencies: [OperationDebugData],
        subOperations: [OperationDebugData] = []) {
        self.description = description
        self.properties = properties
        self.conditions = conditions
        self.dependencies = dependencies
        self.subOperations = subOperations
    }

    /**
     Recursively dumps `OperationDebugData` via `print()`.
     */
    public func dump() {
        dump { (str: String) -> Void in
            print(str)
        }
    }

    /**
     Recursively dumps `OperationDebugData` via the passed in `Logger`.
     */
    public func dump(logger: Logger) {
        OperationDebugData.dumpRecursiveHelper(data: self, depth: 0, logger: logger)
    }

    /**
     Recursively traverses the passed in `OperationDebugData` and uses the passed logger for output.

     - parameter data:   The `OperationDebugData` to traverse and log data about.
     - parameter depth:  The `depth` for the traversal. This is used for tabbing the output over to
     visually represent the `Operation` hierarchy.
     - parameter logger: The `Logger` to use for output.
     */
    private static func dumpRecursiveHelper(data data: OperationDebugData, depth: Int, logger: Logger) {
        guard depth <= self.dumpDepthLimit else {
            logger("*** Reached a max recursive dump depth limit of: \(self.dumpDepthLimit ) ***")
            return
        }

        // Generate the tab spacing prefix to use when logging to visually represent the hierarchy
        let tab = OperationDebugData.tabSpacing(depth)
        let subSectionTab = OperationDebugData.tabSpacing(depth + 1)
        let subSectionDataTab = OperationDebugData.tabSpacing(depth + 2)

        let propertiesStr = data.properties.map { (key, value) in
            return "\(key): \(value)"
            }.joinWithSeparator(", ")

        // Main log line for the current `OperationDebugData` object
        logger("\(tab)- \(data.description) {\(propertiesStr)}")

        // Log any conditions
        if !data.conditions.isEmpty {
            logger("\(subSectionTab)[Conditions(\(data.conditions.count))]:")
            for condition in data.conditions {
                logger("\(subSectionDataTab)\(condition)")
            }
        }

        // Log any dependencies
        if !data.dependencies.isEmpty {
            logger("\(subSectionTab)[Dependencies(\(data.dependencies.count))]:")
            for dependency in data.dependencies {
                let dependencyPropertiesStr = dependency.properties.map { (key, value) in
                    return "\(key): \(value)"
                    }.joinWithSeparator(", ")
                logger("\(subSectionDataTab)\(dependency.description) {\(dependencyPropertiesStr)}")
            }
        }

        // Recrusively log any sub operations
        if !data.subOperations.isEmpty {
            logger("\(subSectionTab)[Sub Operations(\(data.subOperations.count))]:")
            for subData in data.subOperations {
                dumpRecursiveHelper(data: subData, depth: depth + 2, logger: logger)
            }
        }
    }

    /**
     Returns a string of space characters based on the passed `depth`.

     - parameter depth: The `depth` of the hierarchy to create the tab space based on.

     - returns: A `String` of spaces representing the tab spacing for the passed `depth`.
     */
    private static func tabSpacing(depth: Int) -> String {
        return String(count: depth * 4, repeatedValue: (" " as Character))
    }
    
}
