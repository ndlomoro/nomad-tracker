/*
 DashboardView - Overview of current stays and visa status
 Uses StayStore (same as other views) for consistency.
 */

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var stayStore: StayStore
    
    private var year: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    var activeStays: [Stay] {
        stayStore.activeStays
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Stays").font(.headline)
                        Text("\(activeStays.count) countries").foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Year Summary").font(.headline)
                        let summary = stayStore.yearSummary(year: year)
                        Text("\(summary.totalDays) days total").foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
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
                    VStack(spacing: 12) {
                        ForEach(activeStays) { stay in
                            CountryCardView(stay: stay)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(StayStore())
}
