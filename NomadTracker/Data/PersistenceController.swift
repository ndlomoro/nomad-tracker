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
        container = NSPersistentContainer(name: "NomadTracker")
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
                stay.daysSpent = 0
                stay.daysRemaining = 90
                stay.maxAllowedDays = 90
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

// MARK: - Preview
extension PersistenceController {
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        result.isReady = true
        return result
    }()
}
