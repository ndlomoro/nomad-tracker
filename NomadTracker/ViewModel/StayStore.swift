/*
 StayStore - Central data store for stays, visa calculations, and alerts.
 Observes Core Data via notifications, syncs to App Group for widgets.
 */

import Foundation
import Combine
import SwiftUI
import CoreData
import WidgetKit
import Photos
import CoreLocation

@MainActor
class StayStore: ObservableObject {

    // MARK: - Published State

    @Published var stays: [Stay] = []
    @Published var availableCountries: [Country] = []
    @Published var alertConfig: AlertConfig = AlertConfig()

    // MARK: - Private

    private let persistenceController = PersistenceController.shared
    private let visaCalculator = VisaCalculator()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        loadCountries()
        loadAlertConfig()
        fetchStays()
        setupCoreDataObserver()
    }

    // MARK: - Core Data Observer

    private func setupCoreDataObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: persistenceController.container.viewContext)
            .sink { [weak self] _ in
                Task { [weak self] in
                    guard let self else { return }
                    self.fetchStays()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Fetch Stays from Core Data

    private func fetchStays() {
        let request: NSFetchRequest<StayManagedObject> = StayManagedObject.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(StayManagedObject.entryDate), ascending: false)]

        do {
            let managedStays = try persistenceController.container.viewContext.fetch(request)
            self.stays = managedStays.compactMap { $0.toStay() }
            syncToAppGroup()
        } catch {
            print("❌ Error fetching stays: \(error)")
        }
    }

    // MARK: - Load Countries from JSON

    private func loadCountries() {
        guard let url = Bundle.main.url(forResource: "visa_database", withExtension: "json") else {
            print("⚠️ visa_database.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let countriesArray = json?["countries"] as? [[String: Any]] ?? []

            self.availableCountries = countriesArray.compactMap { Country(from: $0) }
        } catch {
            print("❌ Error loading countries: \(error)")
        }
    }

    // MARK: - Add Stay

    func addStay(countryId: String, countryName: String, entryDate: Date, visaType: VisaType, notes: String? = nil) {
        let context = persistenceController.container.viewContext
        let managed = StayManagedObject(context: context)
        managed.id = UUID()
        managed.countryId = countryId
        managed.countryName = countryName
        managed.entryDate = entryDate
        managed.exitDate = nil
        managed.visaType = visaType.rawValue
        managed.notes = notes
        managed.createdAt = Date()
        managed.daysSpent = 0
        let maxD = maxAllowedDays(for: countryId)
        managed.daysRemaining = Int16(maxD)
        managed.maxAllowedDays = Int16(maxD)

        do {
            try context.save()
            syncToAppGroup()
        } catch {
            print("❌ Error saving stay: \(error)")
        }
    }

    // MARK: - End Stay

    func endStay(stayId: UUID, exitDate: Date) {
        let request: NSFetchRequest<StayManagedObject> = StayManagedObject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", stayId as CVarArg)

        do {
            if let managed = try persistenceController.container.viewContext.fetch(request).first {
                managed.exitDate = exitDate
                // Recalculate daysSpent with correct elapsed-day logic
                let days = Stay.elapsedDays(from: managed.entryDate, to: exitDate)
                managed.daysSpent = Int16(max(0, days))
                managed.daysRemaining = Int16(max(0, Int(managed.maxAllowedDays) - days))
                try persistenceController.container.viewContext.save()
                syncToAppGroup()
            }
        } catch {
            print("❌ Error ending stay: \(error)")
        }
    }

    // MARK: - Edit Stay

    func editStay(stayId: UUID, entryDate: Date, visaType: VisaType, notes: String?) {
        let request: NSFetchRequest<StayManagedObject> = StayManagedObject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", stayId as CVarArg)

        do {
            if let managed = try persistenceController.container.viewContext.fetch(request).first {
                managed.entryDate = entryDate
                managed.visaType = visaType.rawValue
                managed.notes = notes
                try persistenceController.container.viewContext.save()
                syncToAppGroup()
            }
        } catch {
            print("❌ Error editing stay: \(error)")
        }
    }

    // MARK: - Delete Stay

    func deleteStay(stayId: UUID) {
        let request: NSFetchRequest<StayManagedObject> = StayManagedObject.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", stayId as CVarArg)

        do {
            if let managed = try persistenceController.container.viewContext.fetch(request).first {
                persistenceController.container.viewContext.delete(managed)
                try persistenceController.container.viewContext.save()
                syncToAppGroup()
            }
        } catch {
            print("❌ Error deleting stay: \(error)")
        }
    }

    // MARK: - Computed Properties

    var activeStays: [Stay] {
        stays.filter { $0.isActive }
    }

    var allStays: [Stay] {
        stays
    }

    // MARK: - Visa Calculations

    func stayStatus(for stay: Stay) -> StayStatus {
        let country = availableCountries.first { $0.id == stay.countryId }

        if let country {
            return visaCalculator.calculateRemainingDays(
                stay: stay,
                country: country,
                allStays: stays.filter { $0.countryId == stay.countryId }
            )
        }

        // Default fallback
        let remaining = stay.maxAllowedDays - stay.daysSpent
        if remaining < 0 {
            return .expired(daysOver: abs(remaining))
        }
        if stay.isActive {
            return .active(daysSpent: stay.daysSpent, daysRemaining: remaining)
        }
        if remaining <= 3 {
            return .critical(daysRemaining: remaining)
        }
        if remaining <= 15 {
            return .warning(daysRemaining: remaining)
        }
        return .safe(daysRemaining: remaining)
    }

    func maxAllowedDays(for countryId: String) -> Int {
        availableCountries.first(where: { $0.id == countryId })?.totalMaxDays ?? 90
    }

    // MARK: - Year Summary

    struct YearSummary: Identifiable {
        let id = UUID()
        let year: Int
        let totalDays: Int
        let countryDays: [String: Int]
    }

    func yearSummary(year: Int) -> YearSummary {
        let countryDays = visaCalculator.calculateYearSummary(
            year: year,
            stays: stays,
            countries: availableCountries
        )
        let totalDays = countryDays.values.reduce(0, +)
        return YearSummary(year: year, totalDays: totalDays, countryDays: countryDays)
    }

    func allYearSummaries() -> [YearSummary] {
        let years = Set(stays.map { Calendar.current.component(.year, from: $0.entryDate) })
        return years.map { yearSummary(year: $0) }.sorted { $0.year > $1.year }
    }

    // MARK: - Alert Configuration

    struct AlertConfig: Codable {
        var thresholds: [Int] = [30, 15, 7, 3, 1]
    }

    let availableThresholds: [Int] = [30, 15, 7, 3, 1]
    static let defaultAlertThresholds: [Int] = [30, 15, 7, 3, 1]

    private func saveAlertConfig() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(alertConfig) {
            UserDefaults.standard.set(data, forKey: "nomad_alert_config")
        }
    }

    private func loadAlertConfig() {
        if let data = UserDefaults.standard.data(forKey: "nomad_alert_config"),
           let config = try? JSONDecoder().decode(AlertConfig.self, from: data) {
            alertConfig = config
        }
    }

    func toggleThreshold(_ threshold: Int) {
        if let index = alertConfig.thresholds.firstIndex(of: threshold) {
            alertConfig.thresholds.remove(at: index)
        } else {
            alertConfig.thresholds.append(threshold)
        }
        saveAlertConfig()
    }

    // MARK: - Data Export / Import

    func exportStaysAsJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(stays)
    }

    func importStaysFromJSON(_ data: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let importedStays = try? decoder.decode([Stay].self, from: data) else {
            return false
        }

        let context = persistenceController.container.viewContext
        for stay in importedStays {
            let managed = StayManagedObject(context: context)
            managed.id = stay.id
            managed.countryId = stay.countryId
            managed.countryName = stay.countryName
            managed.entryDate = stay.entryDate
            managed.exitDate = stay.exitDate
            managed.visaType = stay.visaType.rawValue
            managed.notes = stay.notes
            managed.createdAt = stay.createdAt
            // Use country-specific max days from visa database
            let maxD = maxAllowedDays(for: stay.countryId)
            managed.daysSpent = Int16(Stay.elapsedDays(from: stay.entryDate, to: stay.exitDate ?? Date()))
            managed.daysRemaining = Int16(max(0, maxD - Int(managed.daysSpent)))
            managed.maxAllowedDays = Int16(maxD)
        }

        do {
            try context.save()
            syncToAppGroup()
            return true
        } catch {
            print("❌ Error importing stays: \(error)")
            return false
        }
    }

    // MARK: - Photo Import
    
    static func importStaysFromPhotoLibrary() async throws -> [Stay] {
        // Request photo library access
        let authorized = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
        
        guard authorized else {
            throw NSError(domain: "PhotoLibrary", code: -1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
        }
        
        // Query photos with location data
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "location != nil")
        let assets = PHAsset.fetchAssets(with: options)
        
        var staysByCountry: [String: (entryDate: Date, exitDate: Date)] = [:]
        
        // enumerateObjects' closure is synchronous, so collect the assets first,
        // then do the async reverse-geocoding in a normal async loop.
        var collectedAssets: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            collectedAssets.append(asset)
        }

        for asset in collectedAssets {
            guard let location = asset.location else { continue }
            guard let creationDate = asset.creationDate else { continue }

            // Reverse geocode to get country
            let country = await reverseGeocodeToCountry(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            guard let country = country, !country.isEmpty else { continue }

            if var existing = staysByCountry[country] {
                existing.entryDate = min(existing.entryDate, creationDate)
                existing.exitDate = max(existing.exitDate, creationDate)
                staysByCountry[country] = existing
            } else {
                staysByCountry[country] = (creationDate, creationDate)
            }
        }
        
        // Convert to Stay objects
        var stays: [Stay] = []
        for (countryName, dates) in staysByCountry {
            let stay = Stay(
                id: UUID(),
                countryId: "",
                countryName: countryName,
                entryDate: dates.entryDate,
                exitDate: dates.exitDate,
                visaType: .tourist,
                notes: "Imported from Photos",
                createdAt: Date()
            )
            stays.append(stay)
        }
        
        return stays
    }
    
    private static func reverseGeocodeToCountry(latitude: Double, longitude: Double) async -> String? {
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(
                CLLocation(latitude: latitude, longitude: longitude)
            ) { placemarks, _ in
                if let placemark = placemarks?.first {
                    continuation.resume(with: .success(placemark.country ?? ""))
                } else {
                    continuation.resume(with: .success(nil))
                }
            }
        }
    }
    
    // MARK: - Reset Data
    
    func resetAllData() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Stay")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            try context.save()
            syncToAppGroup()
        } catch {
            print("❌ Error resetting data: \(error)")
        }
    }

    // MARK: - File-based sync (for widgets, no App Group entitlement required)

    func syncToAppGroup() {
        // Write active stays to shared file
        let sharedStays = activeStays.map { stay -> SharedStayData in
            let country = availableCountries.first { $0.id == stay.countryId }
            let maxD = country?.totalMaxDays ?? 90
            return SharedStayData(
                id: stay.id,
                countryName: stay.countryName,
                countryCode: stay.countryId,
                daysSpent: stay.daysSpent,
                daysRemaining: stay.daysRemaining,
                maxDays: maxD,
                entryDate: stay.entryDate,
                exitDate: stay.exitDate,
                visaType: stay.visaType.rawValue,
                notes: stay.notes
            )
        }
        SharedStayData.saveToFile(sharedStays)

        // Write year summary to shared file
        let currentYear = Calendar.current.component(.year, from: Date())
        let summary = yearSummary(year: currentYear)
        let sharedCountries = summary.countryDays.map { name, days in
            let code = availableCountries.first { $0.name == name }?.id ?? ""
            let maxD = availableCountries.first { $0.name == name }?.totalMaxDays ?? 90
            return SharedCountryYearData(id: UUID(), countryName: name, countryCode: code, daysSpent: days, maxDays: maxD)
        }.sorted { $0.daysSpent > $1.daysSpent }
        SharedYearSummaryData.saveToFile(SharedYearSummaryData(year: currentYear, countries: sharedCountries))

        WidgetCenter.shared.reloadAllTimelines()
    }
}
