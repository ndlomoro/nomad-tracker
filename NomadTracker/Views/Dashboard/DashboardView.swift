/*
 DashboardView - Main dashboard showing active stays and year summary
 */

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var stayStore: StayStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showAddStay = false
    @State private var showCountryDetail: Country? = nil
    @State private var isRefreshing = false
    
    private var year: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    var activeStays: [Stay] {
        stayStore.activeStays
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Stays")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(activeStays.count) countries")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Year Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                        let summary = stayStore.yearSummary(year: year)
                        Text("\(summary.totalDays) days total")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Country Cards
                if activeStays.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("No active stays")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("Tap + to add your first stay")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(spacing: 10) {
                        ForEach(activeStays) { stay in
                            CountryCardView(stay: stay)
                                .onTapGesture {
                                    if let country = stayStore.availableCountries.first(where: { $0.id == stay.countryId }) {
                                        showCountryDetail = country
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await refreshData()
        }
        .navigationTitle("NomadTracker")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showAddStay = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAddStay) {
            AddStaySheet()
        }
        .sheet(item: $showCountryDetail) { country in
            CountryDetailView(country: country, stayStore: stayStore)
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        stayStore.syncToAppGroup()
        isRefreshing = false
    }
}

#Preview {
    DashboardView()
        .environmentObject(StayStore())
}
