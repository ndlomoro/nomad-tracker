/*
 DashboardView - Overview of current stays and visa status
 */

import SwiftUI

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Stay.entryDate, ascending: false)],
        predicate: NSPredicate(format: "exitDate == nil")
    ) private var activeStays: FetchedResults<Stay>
    
    @State private var showAddStay = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Active Stays
                    if activeStays.isEmpty {
                        emptyState
                    } else {
                        ForEach(activeStays) { stay in
                            CountryCardView(stay: stay)
                        }
                    }
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Nomad Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddStay = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.nomadBlue)
                
                VStack(alignment: leading, spacing: 4) {
                    Text("Current Status")
                        .font(.title2.bold())
                    
                    Text(activeStays.isEmpty
                         ? "No active stays"
                         : "\(activeStays.count) country\(activeStays.count > 1 ? "ies" : "")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.pin")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No Active Stays")
                .font(.title3.bold())
            
            Text("Start tracking your time in each country to avoid visa overstays.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showAddStay = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Your First Stay")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.nomadBlue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Year Summary",
                    color: .purple
                )
                
                QuickActionButton(
                    icon: "doc.badge.plus",
                    title: "Export History",
                    color: .green
                )
                
                QuickActionButton(
                    icon: "bell.badge.fill",
                    title: "Alerts",
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
