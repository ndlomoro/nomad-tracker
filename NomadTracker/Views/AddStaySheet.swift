/*
 AddStaySheet - Modal sheet for adding or editing a stay.
 Provides country search picker, date pickers, visa type selector, and notes.
 */

import SwiftUI

struct AddStaySheet: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var stayStore: StayStore
    
    // MARK: - Input
    
    let editStay: Stay?
    
    // MARK: - State
    
    @State private var selectedCountry: Country?
    @State private var searchText: String = ""
    @State private var entryDate: Date
    @State private var visaType: VisaType
    @State private var notes: String = ""
    @State private var showConfirmation: Bool = false
    @State private var formError: String?
    
    // MARK: - Init
    
    init(editStay: Stay? = nil) {
        self.editStay = editStay
        
        if let editStay {
            _entryDate = State(initialValue: editStay.entryDate)
            _visaType = State(initialValue: editStay.visaType)
            _notes = State(initialValue: editStay.notes ?? "")
        } else {
            _entryDate = State(initialValue: Date())
            _visaType = State(initialValue: .tourist)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                countrySection
                dateSection
                visaTypeSection
                notesSection
            }
            .navigationTitle(editStay != nil ? "Edit Stay" : "New Stay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editStay != nil ? "Update" : "Save") {
                        saveStay()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .alert("Error", isPresented: .constant(formError != nil)) {
                Button("OK", role: .cancel) {
                    formError = nil
                }
            } message: {
                if let error = formError {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Country Picker Section
    
    private var countrySection: some View {
        Section("Country") {
            if let selectedCountry {
                HStack {
                    Text(countryFlagEmoji(for: selectedCountry.id))
                        .font(.title3)
                    Text(selectedCountry.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search countries...", text: $searchText)
                        .textFieldStyle(.plain)
                    Spacer()
                }
            }
            
            if !searchText.isEmpty || selectedCountry != nil {
                countryPickerList
            }
        }
    }
    
    private var filteredCountries: [Country] {
        guard !searchText.isEmpty else {
            return stayStore.availableCountries
        }
        return stayStore.availableCountries.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText) ||
            country.id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var countryPickerList: some View {
        List(filteredCountries, id: \.self) { country in
            Button {
                selectedCountry = country
                searchText = ""
            } label: {
                HStack {
                    Text(countryFlagEmoji(for: country.id))
                        .font(.title3)
                    Text(country.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(country.defaultStayDays)d max")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .frame(height: 200)
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        Section("Entry Date") {
            DatePicker(
                "Arrived on",
                selection: $entryDate,
                in: ...Date(),
                displayedComponents: .date
            )
        }
    }
    
    // MARK: - Visa Type Section
    
    private var visaTypeSection: some View {
        Section("Visa Type") {
            Picker("Visa Type", selection: $visaType) {
                ForEach(VisaType.allCases, id: \.self) { type in
                    Text(type.displayName)
                        .tag(type)
                }
            }
            .pickerStyle(.wheel)
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        Section("Notes") {
            TextField(
                "Optional: add notes about this stay",
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }
    
    // MARK: - Save Logic
    
    private var isSaveDisabled: Bool {
        selectedCountry == nil && editStay == nil
    }
    
    private func saveStay() {
        if let editStay {
            // Edit existing stay
            stayStore.editStay(
                stayId: editStay.id,
                entryDate: entryDate,
                visaType: visaType,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            // Add new stay
            guard let country = selectedCountry else { return }
            
            // Check for duplicate active stay in same country
            let duplicateActive = stayStore.activeStays.first {
                $0.countryId == country.id
            }
            
            if let duplicate = duplicateActive {
                formError = "You already have an active stay in \(duplicate.countryName). End it first or edit it."
                return
            }
            
            stayStore.addStay(
                countryId: country.id,
                countryName: country.name,
                entryDate: entryDate,
                visaType: visaType,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        dismiss()
    }
    
    // MARK: - Helpers
    
    private func countryFlagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 0x1F1E6
        return String(
            countryCode.uppercased().utf16.map {
                Character(UnicodeScalar(base + UInt32($0 - 0x41))!)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    AddStaySheet()
        .environmentObject(StayStore())
}
