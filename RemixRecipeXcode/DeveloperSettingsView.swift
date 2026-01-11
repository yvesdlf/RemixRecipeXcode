import SwiftUI
import SwiftData

/// Developer/Settings view for testing and data management
struct DeveloperSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingLoadConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var summaryText = ""
    @State private var isLoading = false
    
    var body: some View {
        List {
            Section {
                Button {
                    showingLoadConfirmation = true
                } label: {
                    Label("Load Sample Data", systemImage: "tray.and.arrow.down.fill")
                }
                .disabled(isLoading)
                
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear All Data", systemImage: "trash.fill")
                }
                .disabled(isLoading)
            } header: {
                Text("Sample Data")
            } footer: {
                Text("Load realistic sample data for testing. Includes 25 inventory items, 4 locations, and transaction history.")
            }
            
            Section {
                if !summaryText.isEmpty {
                    Text(summaryText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Button("Show Statistics") {
                        updateSummary()
                    }
                }
            } header: {
                Text("Database Info")
            }
            
            Section {
                Button {
                    createDefaultLocation()
                } label: {
                    Label("Create Default Location", systemImage: "mappin.circle")
                }
                
                Button {
                    createTestItem()
                } label: {
                    Label("Create Test Item", systemImage: "plus.circle")
                }
            } header: {
                Text("Quick Actions")
            }
        }
        .navigationTitle("Developer Settings")
        .onAppear {
            updateSummary()
        }
        .alert("Load Sample Data?", isPresented: $showingLoadConfirmation) {
            Button("Cancel", role: .cancel) {
                // no-op
            }
            Button("Load") {
                loadSampleData()
            }
        } message: {
            Text("This will add sample inventory items, locations, and transactions. Existing data will not be deleted.")
        }
        .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {
                // no-op
            }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("⚠️ This will permanently delete ALL inventory items, locations, and transactions. This action cannot be undone!")
        }
    }
    
    private func loadSampleData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SampleDataHelper.loadAllSampleData(context: modelContext)
            updateSummary()
            isLoading = false
        }
    }
    
    private func clearAllData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SampleDataHelper.clearAllData(context: modelContext)
            updateSummary()
            isLoading = false
        }
    }
    
    private func updateSummary() {
        summaryText = SampleDataHelper.getSummary(context: modelContext)
    }
    
    private func createDefaultLocation() {
        let location = Location(
            name: "Main Kitchen",
            locationType: "kitchen",
            address: "Ground Floor"
        )
        modelContext.insert(location)
        try? modelContext.save()
        updateSummary()
    }
    
    private func createTestItem() {
        let item = InventoryItem(
            ingredientName: "Test Item \(Int.random(in: 1000...9999))",
            quantityOnHand: Decimal(Int.random(in: 1...50)),
            unit: "kg",
            parLevel: 20,
            reorderPoint: 10,
            unitCost: Decimal(Double.random(in: 5...50))
        )
        modelContext.insert(item)
        try? modelContext.save()
        updateSummary()
    }
}

#Preview {
    NavigationStack {
        DeveloperSettingsView()
    }
    .modelContainer(for: [InventoryItem.self, Location.self])
}
