/*
 CountryDetailView - Detailed view for a country's visa rules and stay history
 */

import SwiftUI

struct CountryDetailView: View {
    let country: Country
    @ObservedObject var stayStore: StayStore
    @Environment(\.dismiss) var dismiss
    
    var staysForCountry: [Stay] {
        stayStore.stays.filter { $0.countryId == country.id }
    }
    
    var activeStay: Stay? {
        staysForCountry.first { $0.isActive }
    }
    
    var totalDaysThisYear: Int {
        let year = Calendar.current.component(.year, from: Date())
        return stayStore.yearSummary(year: year).countryDays[country.name, default: 0]
    }
    
    var body: some View {
        NavigationView {
            List {
                // Country Info Section
                Section("Country Information") {
                    HStack {
                        Text(country.flagEmoji)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text(country.name)
                                .font(.headline)
                            Text(country.id)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Label(country.region, systemImage: "globe")
                        Spacer()
                    }
                    
                    HStack {
                        Label(country.ruleType.description, systemImage: "calendar")
                        Spacer()
                    }
                }
                
                // Visa Rules Section
                Section("Visa Rules") {
                    HStack {
                        Text("Default Stay")
                        Spacer()
                        Text("\(country.defaultStayDays) days")
                            .fontWeight(.medium)
                    }
                    
                    if country.maxExtensionDays > 0 {
                        HStack {
                            Text("Max Extension")
                            Spacer()
                            Text("\(country.maxExtensionDays) days")
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("Total Maximum")
                        Spacer()
                        Text("\(country.totalMaxDays) days")
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    
                    HStack {
                        Text("Multiple Entry")
                        Spacer()
                        Text(country.multipleEntry ? "Yes" : "No")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Visa Required")
                        Spacer()
                        Text(country.visaRequired ? "Yes" : "No")
                            .fontWeight(.medium)
                    }
                    
                    if let visaType = country.visaType {
                        HStack {
                            Text("Visa Type")
                            Spacer()
                            Text(visaType)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if country.isSchengen {
                        HStack {
                            Text("Schengen Area")
                            Spacer()
                            Text("Yes")
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                // Digital Nomad Visa Section
                if let dnv = country.digitalNomadVisa, dnv.available {
                    Section("Digital Nomad Visa") {
                        if let name = dnv.name {
                            HStack {
                                Text("Program")
                                Spacer()
                                Text(name)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let duration = dnv.durationDays {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(duration) days")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Text("Renewable")
                            Spacer()
                            Text(dnv.renewable ?? false ? "Yes" : "No")
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Stay History Section
                Section("Your Stay History") {
                    if staysForCountry.isEmpty {
                        Text("No stays recorded")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(staysForCountry) { stay in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stay.entryDate.formatted(date: .abbreviated, time: .omitted))
                                    if let exit = stay.exitDate {
                                        Text("→ \(exit.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Still here")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                                Spacer()
                                Text("\(stay.daysSpent) days")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                // Year Summary Section
                Section("Year Summary") {
                    HStack {
                        Text("Days in \(country.name) this year")
                        Spacer()
                        Text("\(totalDaysThisYear)")
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    
                    if totalDaysThisYear > 0 {
                        ProgressView(value: Double(totalDaysThisYear), total: Double(country.totalMaxDays))
                            .tint(totalDaysThisYear > country.totalMaxDays ? .red : .blue)
                        
                        Text("\(totalDaysThisYear) of \(country.totalMaxDays) days used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Notes Section
                if let notes = country.notes {
                    Section("Notes") {
                        Text(notes)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("Country Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CountryDetailView(
        country: Country(
            id: "MX",
            name: "Mexico",
            region: "North America",
            defaultStayDays: 180,
            maxExtensionDays: 0,
            ruleType: .calendarYear,
            multipleEntry: true,
            visaRequired: false,
            visaType: nil,
            isSchengen: false,
            digitalNomadVisa: nil,
            notes: "180 days maximum stay per entry."
        ),
        stayStore: StayStore()
    )
}
