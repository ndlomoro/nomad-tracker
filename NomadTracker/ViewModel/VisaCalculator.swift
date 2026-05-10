/*
 VisaCalculator - Core logic for counting days and detecting visa violations
 Handles calendar year rules, rolling 90/180 windows, and extensions
 */

import Foundation

class VisaCalculator {
    
    // MARK: - Calculate remaining days for an active stay
    func calculateRemainingDays(
        stay: Stay,
        country: Country,
        allStays: [Stay]
    ) -> StayStatus {
        
        let maxDays = country.totalMaxDays
        let daysSpent = stay.daysSpent
        
        switch country.ruleType {
        case .calendarYear:
            return calculateCalendarYearStatus(
                daysSpent: daysSpent,
                maxDays: maxDays,
                isActive: stay.isActive
            )
            
        case .rolling90_180:
            return calculateRolling90_180Status(
                stay: stay,
                allStays: allStays,
                isActive: stay.isActive
            )
            
        case .rollingWindow:
            return calculateCalendarYearStatus(
                daysSpent: daysSpent,
                maxDays: maxDays,
                isActive: stay.isActive
            )
        }
    }
    
    // MARK: - Calendar Year Rule
    // Days counted within Jan 1 - Dec 31, resets each year
    private func calculateCalendarYearStatus(
        daysSpent: Int,
        maxDays: Int,
        isActive: Bool
    ) -> StayStatus {
        
        let remaining = maxDays - daysSpent
        
        if remaining < 0 {
            return .expired(daysOver: abs(remaining))
        }
        
        if isActive {
            return .active(daysSpent: daysSpent, daysRemaining: remaining)
        }
        
        if remaining <= 3 {
            return .critical(daysRemaining: remaining)
        }
        
        if remaining <= 7 {
            return .critical(daysRemaining: remaining)
        }
        
        if remaining <= 15 {
            return .warning(daysRemaining: remaining)
        }
        
        if remaining <= 30 {
            return .warning(daysRemaining: remaining)
        }
        
        return .safe(daysRemaining: remaining)
    }
    
    // MARK: - Schengen 90/180 Rolling Window Rule
    // Maximum 90 days in any rolling 180-day period
    private func calculateRolling90_180Status(
        stay: Stay,
        allStays: [Stay],
        isActive: Bool
    ) -> StayStatus {
        
        let today = Date()
        let calendar = Calendar.current
        
        // Get all Schengen stays in the past 180 days
        let schengenStays = allStays.filter { stay in
            let entryDate = stay.entryDate
            let _ = stay.exitDate ?? today
            let daysAgo = calendar.dateComponents([.day], from: entryDate, to: today).day ?? 0
            return daysAgo <= 180
        }
        
        // Calculate total days spent in Schengen in rolling 180-day window
        var totalDaysInWindow = 0
        for s in schengenStays {
            let windowStart = calendar.date(byAdding: .day, value: -180, to: today) ?? today
            let effectiveEntry = max(s.entryDate, windowStart)
            let effectiveExit = s.exitDate ?? today
            let days = calendar.dateComponents([.day], from: effectiveEntry, to: effectiveExit).day ?? 0
            totalDaysInWindow += max(0, days)
        }
        
        let remaining = 90 - totalDaysInWindow
        
        if remaining < 0 {
            return .expired(daysOver: abs(remaining))
        }
        
        if isActive {
            return .active(daysSpent: totalDaysInWindow, daysRemaining: remaining)
        }
        
        if remaining <= 3 {
            return .critical(daysRemaining: remaining)
        }
        
        if remaining <= 7 {
            return .critical(daysRemaining: remaining)
        }
        
        if remaining <= 15 {
            return .warning(daysRemaining: remaining)
        }
        
        return .safe(daysRemaining: remaining)
    }
    
    // MARK: - Year Summary
    func calculateYearSummary(
        year: Int,
        stays: [Stay],
        countries: [Country]
    ) -> [String: Int] {
        
        var summary: [String: Int] = [:]
        let calendar = Calendar.current
        
        for stay in stays {
            let entryYear = calendar.component(.year, from: stay.entryDate)
            let exitYear = calendar.component(.year, from: stay.exitDate ?? Date())
            
            if entryYear == year || exitYear == year || (entryYear < year && exitYear > year) {
                // Calculate days within this specific year
                var yearStartComponents = DateComponents()
                yearStartComponents.year = year
                yearStartComponents.month = 1
                yearStartComponents.day = 1
                guard let yearStart = calendar.date(from: yearStartComponents) else { continue }
                
                var yearEndComponents = DateComponents()
                yearEndComponents.year = year + 1
                yearEndComponents.month = 1
                yearEndComponents.day = 1
                guard let yearEndBase = calendar.date(from: yearEndComponents) else { continue }
                let yearEnd = calendar.date(byAdding: .day, value: -1, to: yearEndBase)!
                
                let effectiveEntry = max(stay.entryDate, yearStart)
                let effectiveExit = min(stay.exitDate ?? Date(), yearEnd)
                
                let days = calendar.dateComponents([.day], from: effectiveEntry, to: effectiveExit).day ?? 0
                summary[stay.countryName] = (summary[stay.countryName] ?? 0) + max(0, days)
            }
        }
        
        return summary
    }
    
    // MARK: - Check if user can enter a country
    func canEnterCountry(
        country: Country,
        pastStays: [Stay]
    ) -> (canEnter: Bool, reason: String) {
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check stays in the relevant period
        let relevantStays = pastStays.filter { stay in
            stay.countryId == country.id
        }
        
        switch country.ruleType {
        case .calendarYear:
            let yearStays = relevantStays.filter { stay in
                calendar.component(.year, from: stay.entryDate) == calendar.component(.year, from: today)
            }
            let daysUsed = yearStays.reduce(0) { $0 + $1.daysSpent }
            let remaining = country.totalMaxDays - daysUsed
            
            if remaining > 0 {
                return (true, "\(remaining) days available this year")
            } else {
                return (false, "No days remaining this calendar year. Resets Jan 1.")
            }
            
        case .rolling90_180:
            // Check Schengen-wide stays
            let schengenStays = pastStays.filter { stay in
                let countryDaysAgo = calendar.dateComponents([.day], from: stay.entryDate, to: today).day ?? 0
                return countryDaysAgo <= 180
            }
            var totalSchengenDays = 0
            for s in schengenStays {
                let windowStart = calendar.date(byAdding: .day, value: -180, to: today) ?? today
                let effectiveEntry = max(s.entryDate, windowStart)
                let effectiveExit = s.exitDate ?? today
                let days = calendar.dateComponents([.day], from: effectiveEntry, to: effectiveExit).day ?? 0
                totalSchengenDays += max(0, days)
            }
            let remaining = 90 - totalSchengenDays
            
            if remaining > 0 {
                return (true, "\(remaining) Schengen days available in rolling 180-day window")
            } else {
                return (false, "Schengen 90/180 limit reached. Wait for window to open.")
            }
            
        case .rollingWindow:
            return (true, "Check country-specific rolling window rules")
        }
    }
}
