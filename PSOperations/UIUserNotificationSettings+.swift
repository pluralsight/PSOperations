#if os(iOS)

import UIKit

@available(*, deprecated)
extension UIUserNotificationSettings {
    /// Check to see if one Settings object is a superset of another Settings object.
    func contains(_ settings: UIUserNotificationSettings) -> Bool {
        // our types must contain all of the other types
        if !types.contains(settings.types) {
            return false
        }

        let otherCategories = settings.categories ?? []
        let myCategories = categories ?? []

        return myCategories.isSuperset(of: otherCategories)
    }

    /**
        Merge two Settings objects together. `UIUserNotificationCategories` with 
        the same identifier are considered equal.
    */
    func settingsByMerging(_ settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
        let mergedTypes = types.union(settings.types)

        let myCategories = categories ?? []
        var existingCategoriesByIdentifier = Dictionary(sequence: myCategories) { $0.identifier }

        let newCategories = settings.categories ?? []
        let newCategoriesByIdentifier = Dictionary(sequence: newCategories) { $0.identifier }

        for (newIdentifier, newCategory) in newCategoriesByIdentifier {
            existingCategoriesByIdentifier[newIdentifier] = newCategory
        }

        let mergedCategories = Set(existingCategoriesByIdentifier.values)
        return UIUserNotificationSettings(types: mergedTypes, categories: mergedCategories)
    }
}

#endif
