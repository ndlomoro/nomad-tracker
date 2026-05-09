/*
 StayManagedObject - Core Data entity for stay records
 Auto-generated from NomadTracker.xcdatamodeld / Stay entity
 */

import Foundation
import CoreData

@objc(Stay)
public class StayManagedObject: NSManagedObject, Identifiable {

    @NSManaged public var id: UUID
    @NSManaged public var countryId: String
    @NSManaged public var countryName: String
    @NSManaged public var entryDate: Date
    @NSManaged public var exitDate: Date?
    @NSManaged public var visaType: String
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var daysSpent: Int16
    @NSManaged public var daysRemaining: Int16
    @NSManaged public var maxAllowedDays: Int16

    // MARK: - Convert to Domain Model

    func toStay() -> Stay? {
        guard let visa = VisaType(rawValue: visaType) else { return nil }
        return Stay(
            id: id,
            countryId: countryId,
            countryName: countryName,
            entryDate: entryDate,
            exitDate: exitDate,
            visaType: visa,
            notes: notes,
            createdAt: createdAt
        )
    }

    // MARK: - Create from Domain Model

    static func fromStay(_ stay: Stay, context: NSManagedObjectContext) -> StayManagedObject {
        let managed = StayManagedObject(context: context)
        managed.id = stay.id
        managed.countryId = stay.countryId
        managed.countryName = stay.countryName
        managed.entryDate = stay.entryDate
        managed.exitDate = stay.exitDate
        managed.visaType = stay.visaType.rawValue
        managed.notes = stay.notes
        managed.createdAt = stay.createdAt
        managed.daysSpent = Int16(stay.daysSpent)
        managed.daysRemaining = Int16(stay.daysRemaining)
        managed.maxAllowedDays = Int16(stay.maxAllowedDays)
        return managed
    }
}

// MARK: - FetchRequest
extension StayManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StayManagedObject> {
        return NSFetchRequest<StayManagedObject>(entityName: "Stay")
    }
}
