import SwiftUI
import SwiftData

/// Sheet view for adjusting inventory stock levels
struct StockAdjustmentView: View {
    let item: InventoryItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var adjustmentType: TransactionType = .purchase
    @State private var quantityChange: Decimal = 0
    @State private var cost: Decimal = 0
    @State private var notes: String = ""
    @FocusState private var isQuantityFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.ingredientName)
                            .font(.headline)
                        HStack {
                            Text("Current Stock:")
                                .foregroundStyle(.secondary)
                            Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Adjustment") {
                    Picker("Type", selection: $adjustmentType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0", value: $quantityChange, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isQuantityFocused)
                        Text(item.unit)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField(item.unitCost.formatted(), value: $cost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes about this transaction", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let newQuantity = calculateNewQuantity() {
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Current")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                            }
                            
                            HStack {
                                Text(shouldSubtract ? "Removing" : "Adding")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(shouldSubtract ? "-" : "+")\(quantityChange.formatted()) \(item.unit)")
                                    .foregroundStyle(shouldSubtract ? Color.red : Color.green)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("New Stock")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(newQuantity.formatted()) \(item.unit)")
                                    .fontWeight(.bold)
                                    .foregroundStyle(newQuantity > 0 ? Color.primary : Color.red)
                            }
                            
                            if newQuantity <= item.reorderPoint && newQuantity > 0 {
                                Label("Will be below reorder point", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.orange)
                            } else if newQuantity <= 0 {
                                Label("Stock will be depleted", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            }
                        }
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle("Adjust Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAdjustment()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
                
                // Keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isQuantityFocused = false
                    }
                }
            }
            .onAppear {
                cost = item.unitCost
                isQuantityFocused = true
            }
        }
    }
    
    private var isValid: Bool {
        let hasQuantity = quantityChange != 0
        let costValue = cost
        return hasQuantity && costValue >= 0
    }
    
    private func calculateNewQuantity() -> Decimal? {
        let change = quantityChange
        let signedChange = shouldSubtract ? -change : change
        return item.quantityOnHand + signedChange
    }
    
    private var shouldSubtract: Bool {
        switch adjustmentType {
        case .usage, .wastage, .transfer:
            return true
        default:
            return false
        }
    }
    
    private func saveAdjustment() {
        let change = quantityChange
        let signedChange = shouldSubtract ? -change : change
        let adjustmentCost = cost == 0 ? item.unitCost : cost
        
        if adjustmentType == .purchase && adjustmentCost != item.unitCost {
            item.unitCost = adjustmentCost
        }
        
        item.adjustQuantity(
            by: signedChange,
            type: adjustmentType,
            cost: adjustmentCost,
            notes: notes.isEmpty ? nil : notes,
            context: modelContext
        )
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryItem.self, configurations: config)
    let context = container.mainContext
    
    let item = InventoryItem(
        ingredientName: "Beef Chuck",
        quantityOnHand: 3.5,
        unit: "kg",
        parLevel: 10,
        reorderPoint: 5,
        unitCost: 15.50
    )
    context.insert(item)
    
    StockAdjustmentView(item: item)
        .modelContainer(container)
}
