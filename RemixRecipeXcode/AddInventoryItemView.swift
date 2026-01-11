import SwiftUI
import SwiftData

/// Sheet view for adding new inventory items
struct AddInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var locations: [Location]
    
    @State private var ingredientName = ""
    @State private var quantity: Decimal = 0
    @State private var unit = "kg"
    @State private var parLevel: Decimal = 10
    @State private var reorderPoint: Decimal = 5
    @State private var unitCost: Decimal = 0
    @State private var storageLocation = ""
    @State private var selectedLocation: Location?
    @State private var notes = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, quantity, cost
    }
    
    let commonUnits = ["kg", "g", "L", "mL", "pcs", "units", "oz", "lb", "gal", "qt", "bottles", "cans", "boxes"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Ingredient Name", text: $ingredientName)
                        .focused($focusedField, equals: .name)
                    
                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .quantity)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(commonUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", value: $unitCost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .cost)
                    }
                }
                
                Section {
                    HStack {
                        Text("Par Level")
                            .help("The ideal stock quantity to maintain")
                        Spacer()
                        TextField("0", value: $parLevel, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Reorder Point")
                            .help("Reorder when stock falls below this level")
                        Spacer()
                        TextField("0", value: $reorderPoint, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Stock Levels")
                } footer: {
                    Text("Set par level to your ideal stock quantity. Set reorder point to trigger low stock alerts.")
                }
                
                Section("Location") {
                    if !locations.isEmpty {
                        Picker("Location", selection: $selectedLocation) {
                            Text("None").tag(nil as Location?)
                            ForEach(locations) { location in
                                Text(location.name).tag(location as Location?)
                            }
                        }
                    } else {
                        HStack {
                            Text("No locations available")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Create Location") {
                                // TODO: Navigate to location creation
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    TextField("Storage Location (e.g., Shelf A3, Freezer 2)", text: $storageLocation)
                }
                
                Section("Notes (Optional)") {
                    TextField("Additional notes about this item", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Preview section
                if isValid {
                    Section("Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Initial Stock:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(quantity.formatted()) \(unit)")
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Initial Value:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                let totalValue = quantity * unitCost
                                Text("$\(NSDecimalNumber(decimal: totalValue).doubleValue, specifier: "%.2f")")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
                
                // Keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                focusedField = .name
                
                // Create a default location if none exists
                if locations.isEmpty {
                    let defaultLocation = Location(
                        name: "Main Kitchen",
                        locationType: "kitchen"
                    )
                    modelContext.insert(defaultLocation)
                    try? modelContext.save()
                }
            }
        }
    }
    
    private var isValid: Bool {
        !ingredientName.isEmpty &&
        quantity >= 0 &&
        unitCost >= 0 &&
        parLevel >= 0 &&
        reorderPoint >= 0
    }
    
    private func addItem() {
        let item = InventoryItem(
            ingredientName: ingredientName,
            quantityOnHand: quantity,
            unit: unit,
            parLevel: parLevel,
            reorderPoint: reorderPoint,
            unitCost: unitCost,
            storageLocation: storageLocation.isEmpty ? nil : storageLocation,
            location: selectedLocation,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(item)
        
        // Create initial purchase transaction
        if quantity > 0 {
            let transaction = InventoryTransaction(
                inventoryItem: item,
                transactionType: .purchase,
                quantity: quantity,
                unitCost: unitCost,
                notes: "Initial stock"
            )
            modelContext.insert(transaction)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryItem.self, Location.self, configurations: config)
    let context = container.mainContext
    
    let location = Location(name: "Main Kitchen", locationType: "kitchen")
    context.insert(location)
    
    return AddInventoryItemView()
        .modelContainer(container)
}
