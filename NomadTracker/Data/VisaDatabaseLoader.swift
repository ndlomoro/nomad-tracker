/*
 VisaDatabaseLoader - Loads visa database from JSON into Core Data
 */

import Foundation
import CoreData

class VisaDatabaseLoader {
    static let shared = VisaDatabaseLoader()
    
    private init() {}
    
    // MARK: - Load Database
    func loadIfNeeded(into context: NSManagedObjectContext) {
        // Check if already loaded
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Country")
        request.includesPendingChanges = false
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            if count > 0 {
                print("✅ Visa database already loaded (\(count) countries)")
                return
            }
        } catch {
            print("❌ Error checking database: \(error)")
            return
        }
        
        // Load from JSON
        guard let url = Bundle.main.url(forResource: "visa_database", withExtension: "json") else {
            print("❌ visa_database.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let countries = json?["countries"] as? [[String: Any]] ?? []
            
            print("📦 Loading \(countries.count) countries into database...")
            
            for countryDict in countries {
                guard let code = countryDict["code"] as? String,
                      let name = countryDict["name"] as? String else { continue }
                
                let country = CountryManagedObject(context: context)
                country.id = code
                country.name = name
                country.region = countryDict["region"] as? String ?? "Unknown"
                country.defaultStayDays = Int16(countryDict["default_stay_days"] as? Int ?? 90)
                country.maxExtensionDays = Int16(countryDict["max_extension_days"] as? Int ?? 0)
                country.ruleType = countryDict["rule_type"] as? String ?? "calendar_year"
                country.multipleEntry = countryDict["multiple_entry"] as? Bool ?? true
                country.visaRequired = countryDict["visa_required"] as? Bool ?? false
                country.schengen = countryDict["schengen"] as? Bool ?? false
                country.notes = countryDict["notes"] as? String
            }
            
            try context.save()
            print("✅ Visa database loaded successfully")
            
        } catch {
            print("❌ Error loading visa database: \(error)")
        }
    }
    
    // MARK: - Load Countries as Model Objects
    func loadCountries() -> [Country] {
        guard let url = Bundle.main.url(forResource: "visa_database", withExtension: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let countries = json?["countries"] as? [[String: Any]] ?? []
            
            return countries.compactMap { dict -> Country? in
                guard let code = dict["code"] as? String,
                      let name = dict["name"] as? String else { return nil }
                
                // Create model object
                // This would use the Country model, not Core Data entity
                return nil  // Placeholder
            }
        } catch {
            print("❌ Error loading countries: \(error)")
            return []
        }
    }
}
