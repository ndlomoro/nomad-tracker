/*
 PersistenceController - Core Data Stack
 Manages the persistent container, context, and background saves.
*/

import CoreData
import SwiftUI

@MainActor
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    let viewContext: NSManagedObjectContext
    
    @Published var isReady = false
    
    init(inMemory: Bool = false) {
        // Create model programmatically to avoid Xcode 26 model format issues
        let model = Self.createModel()
        container = NSPersistentContainer(name: "NomadTracker", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        
        if inMemory {
            description.type = NSInMemoryStoreType
        } else {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        container.persistentStoreDescriptions = [description]
        // Use the container's own viewContext (main queue) — NOT a background context
        viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        
        // Load persistent stores
        Task {
            await load()
            await loadVisaDatabase()
            await importBundledPhotosData()
            isReady = true
        }
    }
    
    func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("❌ Core Data save error: \(error)")
            }
        }
    }
    
    @objc func saveContext() {
        let context = container.newBackgroundContext()
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Background save error: \(error)")
            }
        }
    }
    
    func load() async {
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                container.loadPersistentStores { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        } catch {
            print("❌ Failed to load Core Data: \(error)")
        }
    }
    
    // MARK: - Load Visa Database
    func loadVisaDatabase() async {
        guard let url = Bundle.main.url(forResource: "visa_database", withExtension: "json") else {
            print("⚠️ visa_database.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let countries = json?["countries"] as? [[String: Any]] ?? []
            
            // Check if already loaded
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Country")
            request.fetchLimit = 1
            let count = try viewContext.count(for: request)
            
            if count > 0 {
                print("✅ Visa database already loaded (\(count) countries)")
                return
            }
            
            print("📦 Loading \(countries.count) countries...")
            
            for countryDict in countries {
                guard let code = countryDict["code"] as? String,
                      let name = countryDict["name"] as? String else { continue }
                
                let country = CountryManagedObject(context: viewContext)
                country.id = code
                country.name = name
                country.region = countryDict["region"] as? String ?? "Unknown"
                country.defaultStayDays = countryDict["default_stay_days"] as? Int16 ?? 90
                country.maxExtensionDays = countryDict["max_extension_days"] as? Int16 ?? 0
                country.ruleType = countryDict["rule_type"] as? String ?? "calendar_year"
                country.multipleEntry = countryDict["multiple_entry"] as? Bool ?? true
                country.visaRequired = countryDict["visa_required"] as? Bool ?? false
                country.schengen = countryDict["schengen"] as? Bool ?? false
                country.notes = countryDict["notes"] as? String
            }
            
            try viewContext.save()
            print("✅ Visa database loaded")
            
        } catch {
            print("❌ Error loading visa database: \(error)")
        }
    }
    
    // MARK: - Auto-import bundled Photos data on first launch
    func importBundledPhotosData() async {
        guard let url = Bundle.main.url(forResource: "photos_import", withExtension: "json") else {
            print("⚠️ photos_import.json not found in bundle")
            return
        }
        
        // Check if stays already exist
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Stay")
        request.fetchLimit = 1
        do {
            let count = try viewContext.count(for: request)
            if count > 0 {
                print("✅ Stays already exist (\(count) records) — skipping auto-import")
                return
            }
        } catch {
            print("❌ Error checking stays: \(error)")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let imported = await importStaysFromJSON(data: data)
            print("✅ Auto-imported \(imported) stays from bundled Photos data")
        } catch {
            print("❌ Error auto-importing Photos data: \(error)")
        }
    }
    
    // MARK: - Import from JSON (Photos data)
    func importStaysFromJSON(data: Data) async -> Int {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let stays = json?["stays"] as? [[String: Any]] ?? []
            
            var imported = 0
            for stayDict in stays {
                guard let code = stayDict["country_code"] as? String,
                      let name = stayDict["country_name"] as? String,
                      let entryStr = stayDict["entry_date"] as? String else { continue }
                
                let entryDate = ISO8601DateFormatter().date(from: entryStr) ?? Date()
                let exitDict = stayDict["exit_date"] as? String
                let exitDate: Date? = exitDict != nil ? (ISO8601DateFormatter().date(from: exitDict!) ?? nil) : nil
                
                let stay = StayManagedObject(context: viewContext)
                stay.id = UUID()
                stay.countryId = code
                stay.countryName = name
                stay.entryDate = entryDate
                stay.exitDate = exitDate
                stay.visaType = "tourist"
                stay.createdAt = Date()
                stay.maxAllowedDays = 90
                
                // Calculate days from actual dates
                let calendar = Calendar.current
                let end = exitDate ?? Date()
                let days = calendar.dateComponents([.day], from: entryDate, to: end).day ?? 0
                stay.daysSpent = Int16(days)
                stay.daysRemaining = Int16(max(0, 90 - days))
                imported += 1
            }
            
            try viewContext.save()
            print("✅ Imported \(imported) stays from Photos data")
            return imported
            
        } catch {
            print("❌ Import error: \(error)")
            return 0
        }
    }
}

// MARK: - Programmatic Model Creation
extension PersistenceController {
    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Stay Entity
        let stayEntity = NSEntityDescription()
        stayEntity.name = "Stay"
        stayEntity.managedObjectClassName = "NomadTracker.StayManagedObject"
        
        let stayAttrs: [(String, NSAttributeType, Any?)] = [
            ("id", .UUIDAttributeType, nil),
            ("countryId", .stringAttributeType, nil),
            ("countryName", .stringAttributeType, nil),
            ("entryDate", .dateAttributeType, nil),
            ("exitDate", .dateAttributeType, nil),
            ("visaType", .stringAttributeType, "tourist"),
            ("notes", .stringAttributeType, nil),
            ("createdAt", .dateAttributeType, nil),
            ("daysSpent", .integer16AttributeType, 0),
            ("daysRemaining", .integer16AttributeType, 0),
            ("maxAllowedDays", .integer16AttributeType, 90),
        ]
        
        for (name, type, defaultVal) in stayAttrs {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.defaultValue = defaultVal
            stayEntity.properties.append(attr)
        }
        
        // Country Entity
        let countryEntity = NSEntityDescription()
        countryEntity.name = "Country"
        countryEntity.managedObjectClassName = "NomadTracker.CountryManagedObject"
        
        let countryAttrs: [(String, NSAttributeType, Any?)] = [
            ("id", .stringAttributeType, nil),
            ("name", .stringAttributeType, nil),
            ("region", .stringAttributeType, "Unknown"),
            ("defaultStayDays", .integer16AttributeType, 90),
            ("maxExtensionDays", .integer16AttributeType, 0),
            ("ruleType", .stringAttributeType, "calendar_year"),
            ("multipleEntry", .booleanAttributeType, true),
            ("visaRequired", .booleanAttributeType, false),
            ("schengen", .booleanAttributeType, false),
            ("notes", .stringAttributeType, nil),
        ]
        
        for (name, type, defaultVal) in countryAttrs {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.defaultValue = defaultVal
            countryEntity.properties.append(attr)
        }
        
        model.entities = [stayEntity, countryEntity]
        return model
    }
}

// MARK: - Preview
extension PersistenceController {
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        result.isReady = true
        return result
    }()
}
