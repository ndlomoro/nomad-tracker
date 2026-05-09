/*
 SettingsView - App settings including passport nationality selector,
 data export/import (JSON), reset data, and about section with version.
 */

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var stayStore: StayStore
    
    // MARK: - State
    
    @State private var passportCountryCode: String = ""
    @State private var showExportAlert: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var exportSuccess: Bool = false
    @State private var importSuccess: Bool = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                profileSection
                dataManagementSection
                privacySection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Export Successful", isPresented: $exportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your stay history has been exported successfully.")
            }
            .alert("Import Result", isPresented: $importSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your stay history has been imported successfully.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("Reset All Data", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    stayStore.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your stay data. This action cannot be undone.")
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .onAppear {
                loadPassportCountry()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(Color.nomadBlue)
                
                VStack(alignment: .leading) {
                    Text("Passport Nationality")
                        .font(.headline)
                    
                    Text("Used for visa rule calculations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(passportCountryCode.isEmpty ? "Not set" : passportCountryCode)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // In production, navigate to a country picker
                // For now, use a simple text field
            }
            
            TextField("Country code (e.g. US, CA, GB)", text: $passportCountryCode)
                
                .onSubmit {
                    savePassportCountry()
                }
                .onChange(of: passportCountryCode) { _, newValue in
                    savePassportCountry()
                }
        }
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        Section("Data Management") {
            Button {
                exportData()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading) {
                        Text("Export Data")
                            .font(.subheadline.bold())
                        
                        Text("Download your stay history as JSON")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            Button {
                showImportPicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Import Data")
                            .font(.subheadline.bold())
                        
                        Text("Restore from a JSON backup file")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            Button {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading) {
                        Text("Reset All Data")
                            .font(.subheadline.bold())
                        
                        Text("Permanently delete all stay records")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section("Privacy") {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.secondary)
                
                Text("All data is stored locally on your device")
                    .font(.subheadline)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "cloud.slash")
                    .foregroundStyle(.secondary)
                
                Text("No cloud sync or data collection")
                    .font(.subheadline)
                
                Spacer()
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.title3)
                    .foregroundStyle(Color.nomadBlue)
                
                VStack(alignment: .leading) {
                    Text("Nomad Tracker")
                        .font(.headline)
                    
                    Text("Version \(appVersion) (\(appBuild))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                
                Text("Made for digital nomads")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Track your visa days across countries and never overstay again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Supports calendar year, 90/180 rolling window, and custom visa rules.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Data Export
    
    private func exportData() {
        guard let jsonData = stayStore.exportStaysAsJSON() else {
            errorMessage = "Failed to export data."
            return
        }
        
        // Save to a temporary file and share
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("nomad_tracker_export_\(dateStamp()).json")
        
        do {
            try jsonData.write(to: fileURL)
            
            // Use UIActivityViewController via coordinator
            // For SwiftUI, we'll use a simpler approach with a success alert
            exportSuccess = true
            
            // Also try to share via share sheet if possible
            presentShareSheet(for: fileURL)
            
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
    
    private func presentShareSheet(for url: URL) {
#if os(iOS)
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
#else
        NSWorkspace.shared.open(url)
#endif
    }
    
    // MARK: - Data Import
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let success = stayStore.importStaysFromJSON(data)
                if success {
                    importSuccess = true
                }
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Passport Country
    
    private func savePassportCountry() {
        let code = passportCountryCode.uppercased().trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(code, forKey: "passport_country_code")
    }
    
    private func loadPassportCountry() {
        passportCountryCode = UserDefaults.standard.string(forKey: "passport_country_code") ?? ""
    }
    
    // MARK: - Helpers
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(StayStore())
}
