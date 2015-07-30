/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to UIKit.UIUserNotificationSettings.
*/

#if os(iOS)

import UIKit

extension UIUserNotificationSettings {
    /// Check to see if one Settings object is a superset of another Settings object.
    func contains(settings: UIUserNotificationSettings) -> Bool {
        // our types must contain all of the other types
        
        if types & settings.types == settings.types {
            return false
        }
        
        let otherCategories = settings.categories ?? []
        let myCategories = categories ?? []
        
        return myCategories.isSupersetOf(otherCategories)
    }
    
    /**
        Merge two Settings objects together. `UIUserNotificationCategories` with 
        the same identifier are considered equal.
    */
    func settingsByMerging(settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
        let mergedTypes = types | settings.types
        
        let myCategories = categories as? Set<UIUserNotificationCategory> ?? Set<UIUserNotificationCategory>()
        var existingCategoriesByIdentifier = [String: UIUserNotificationCategory]()
        for category in myCategories {
            existingCategoriesByIdentifier[category.identifier] = category
        }
        
        let newCategories = settings.categories as? Set<UIUserNotificationCategory> ?? Set<UIUserNotificationCategory>()
        var newCategoriesByIdentifier = [String: UIUserNotificationCategory]()
        for category in newCategories {
            let t = category
            newCategoriesByIdentifier[category.identifier] = category
        }
        
        for (newIdentifier, newCategory) in newCategoriesByIdentifier {
            existingCategoriesByIdentifier[newIdentifier] = newCategory
        }
        
        let mergedCategories = Set(existingCategoriesByIdentifier.values)
        return UIUserNotificationSettings(forTypes: mergedTypes, categories: mergedCategories)
    }
}

#endif
