/*
 CountryManagedObject - Core Data entity for country/visa data
 Auto-generated from NomadTracker.xcdatamodeld / Country entity
 */

import Foundation
import CoreData

@objc(Country)
public class CountryManagedObject: NSManagedObject, Identifiable {

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var region: String?
    @NSManaged public var defaultStayDays: Int16
    @NSManaged public var maxExtensionDays: Int16
    @NSManaged public var ruleType: String
    @NSManaged public var multipleEntry: Bool
    @NSManaged public var visaRequired: Bool
    @NSManaged public var schengen: Bool
    @NSManaged public var notes: String?
}

// MARK: - FetchRequest
extension CountryManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CountryManagedObject> {
        return NSFetchRequest<CountryManagedObject>(entityName: "Country")
    }
}
