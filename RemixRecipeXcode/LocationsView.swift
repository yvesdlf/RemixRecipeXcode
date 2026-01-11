import SwiftUI
import SwiftData

/// View for managing storage locations (kitchens, freezers, dry storage, etc.)
struct LocationsView: View {
    @Query(sort: \Location.name) private var locations: [Location]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingAddLocation = false
    @State private var selectedLocation: Location?
    
    var filteredLocations: [Location] {
        guard !searchText.isEmpty else { return locations }
        return locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            if filteredLocations.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "mappin.slash",
                    description: Text("Add your first location to organize inventory")
                )
            } else {
                ForEach(filteredLocations) { location in
                    NavigationLink(value: location) {
                        LocationRow(location: location)
                    }
                }
                .onDelete(perform: deleteLocations)
            }
        }
        .searchable(text: $searchText, prompt: "Search locations")
        .navigationTitle("Locations")
        .navigationDestination(for: Location.self) { location in
            LocationDetailView(location: location)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddLocation = true
                } label: {
                    Label("Add Location", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView()
        }
    }
    
    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            let location = filteredLocations[index]
            modelContext.delete(location)
        }
        try? modelContext.save()
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let location: Location
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on type
            Image(systemName: locationIcon)
                .font(.title2)
                .foregroundStyle(locationColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(location.locationType.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(locationColor.opacity(0.2))
                        .foregroundStyle(locationColor)
                        .clipShape(Capsule())
                    
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Item count and value
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(location.inventoryItems.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var locationIcon: String {
        switch location.locationType.lowercased() {
        case "kitchen": return "fork.knife"
        case "freezer": return "snowflake"
        case "storage": return "shippingbox.fill"
        case "restaurant": return "building.2.fill"
        case "dry-storage": return "archivebox.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private var locationColor: Color {
        switch location.locationType.lowercased() {
        case "kitchen": return .orange
        case "freezer": return .blue
        case "storage": return .brown
        case "restaurant": return .purple
        case "dry-storage": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Location Detail View

struct LocationDetailView: View {
    @Bindable var location: Location
    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    
    var sortedItems: [InventoryItem] {
        location.inventoryItems.sorted { $0.ingredientName < $1.ingredientName }
    }
    
    var totalValue: Decimal {
        location.inventoryValue()
    }
    
    var lowStockCount: Int {
        location.inventoryItems.filter { $0.isLowStock }.count
    }
    
    var body: some View {
        List {
            // Summary Section
            Section {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(location.inventoryItems.count)")
                                .font(.title)
                                .bold()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Value")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(totalValue.formatted(.number.precision(.fractionLength(2))))")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    if lowStockCount > 0 {
                        Divider()
                        
                        HStack {
                            Label("Low Stock Items", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("\(lowStockCount)")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Location Info
            Section("Location Details") {
                LabeledContent("Type", value: location.locationType.capitalized)
                
                if let address = location.address {
                    LabeledContent("Address", value: address)
                }
                
                LabeledContent("Status", value: location.isActive ? "Active" : "Inactive")
                
                LabeledContent("Created", value: location.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            
            // Inventory Items
            Section {
                if sortedItems.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tray",
                        description: Text("No inventory items stored at this location")
                    )
                } else {
                    ForEach(sortedItems) { item in
                        NavigationLink(value: item) {
                            InventoryItemRow(item: item)
                        }
                    }
                }
            } header: {
                Text("Inventory (\(sortedItems.count))")
            }
            
            // Actions
            Section {
                Button {
                    showingEdit = true
                } label: {
                    Label("Edit Location", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Location", systemImage: "trash")
                }
                .disabled(!location.inventoryItems.isEmpty)
            } footer: {
                if !location.inventoryItems.isEmpty {
                    Text("Remove all items from this location before deleting.")
                        .font(.caption)
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: InventoryItem.self) { item in
            InventoryDetailView(item: item)
        }
        .sheet(isPresented: $showingEdit) {
            EditLocationView(location: location)
        }
        .alert("Delete Location?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLocation()
            }
        } message: {
            Text("This will permanently delete \(location.name). This action cannot be undone.")
        }
    }
    
    private func deleteLocation() {
        modelContext.delete(location)
        try? modelContext.save()
    }
}

// MARK: - Add Location View

struct AddLocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var locationType = "kitchen"
    @State private var address = ""
    @State private var isActive = true
    @FocusState private var isNameFocused: Bool
    
    let locationTypes = ["kitchen", "freezer", "storage", "dry-storage", "restaurant", "warehouse", "bar"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Location Name", text: $name)
                        .focused($isNameFocused)
                    
                    Picker("Type", selection: $locationType) {
                        ForEach(locationTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    TextField("Address (optional)", text: $address)
                }
                
                Section {
                    Toggle("Active", isOn: $isActive)
                } footer: {
                    Text("Inactive locations won't appear in inventory assignment.")
                }
                
                if !name.isEmpty {
                    Section("Preview") {
                        HStack {
                            Image(systemName: iconForType(locationType))
                                .foregroundStyle(colorForType(locationType))
                            Text(name)
                                .fontWeight(.medium)
                            Spacer()
                            Text(locationType.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addLocation()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
    
    private func addLocation() {
        let location = Location(
            name: name,
            locationType: locationType,
            address: address.isEmpty ? nil : address,
            isActive: isActive
        )
        
        modelContext.insert(location)
        try? modelContext.save()
        dismiss()
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "kitchen": return "fork.knife"
        case "freezer": return "snowflake"
        case "storage": return "shippingbox.fill"
        case "restaurant": return "building.2.fill"
        case "dry-storage": return "archivebox.fill"
        case "warehouse": return "building.fill"
        case "bar": return "wineglass.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "kitchen": return .orange
        case "freezer": return .blue
        case "storage": return .brown
        case "restaurant": return .purple
        case "dry-storage": return .yellow
        case "warehouse": return .gray
        case "bar": return .red
        default: return .gray
        }
    }
}

// MARK: - Edit Location View

struct EditLocationView: View {
    @Bindable var location: Location
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var locationType: String
    @State private var address: String
    @State private var isActive: Bool
    
    let locationTypes = ["kitchen", "freezer", "storage", "dry-storage", "restaurant", "warehouse", "bar"]
    
    init(location: Location) {
        self.location = location
        _name = State(initialValue: location.name)
        _locationType = State(initialValue: location.locationType)
        _address = State(initialValue: location.address ?? "")
        _isActive = State(initialValue: location.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Location Name", text: $name)
                    
                    Picker("Type", selection: $locationType) {
                        ForEach(locationTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    TextField("Address (optional)", text: $address)
                }
                
                Section {
                    Toggle("Active", isOn: $isActive)
                } footer: {
                    Text("Inactive locations won't appear in inventory assignment.")
                }
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        location.name = name
        location.locationType = locationType
        location.address = address.isEmpty ? nil : address
        location.isActive = isActive
        dismiss()
    }
}

// MARK: - Preview

#Preview("Locations List") {
    NavigationStack {
        LocationsView()
    }
    .modelContainer(SampleDataHelper.setupPreviewContainer())
}

#Preview("Location Detail") {
    let container = SampleDataHelper.setupPreviewContainer()
    let location = try! container.mainContext.fetch(FetchDescriptor<Location>()).first!
    
    NavigationStack {
        LocationDetailView(location: location)
    }
    .modelContainer(container)
}

#Preview("Add Location") {
    AddLocationView()
        .modelContainer(for: Location.self, inMemory: true)
}
