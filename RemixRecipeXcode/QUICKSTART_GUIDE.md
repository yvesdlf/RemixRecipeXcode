# Quick Start Guide: Building Your First Inventory View

## Goal
Create a functional inventory management view in 30 minutes or less.

---

## Step 1: Create InventoryListView

Create a new SwiftUI file: `InventoryListView.swift`

```swift
import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Query(sort: \InventoryItem.ingredientName) private var inventoryItems: [InventoryItem]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingLowStockOnly = false
    @State private var showingAddItem = false
    
    var filteredItems: [InventoryItem] {
        var items = inventoryItems
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { $0.ingredientName.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter low stock only
        if showingLowStockOnly {
            items = items.filter { $0.isLowStock }
        }
        
        return items
    }
    
    var body: some View {
        List {
            // Low stock alert section
            if !lowStockItems.isEmpty {
                Section {
                    ForEach(lowStockItems) { item in
                        LowStockRow(item: item)
                    }
                } header: {
                    Label("Low Stock Alerts", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            
            // All items section
            Section("All Items") {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tray",
                        description: Text("Add your first inventory item to get started")
                    )
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: item) {
                            InventoryItemRow(item: item)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search ingredients")
        .navigationTitle("Inventory")
        .navigationDestination(for: InventoryItem.self) { item in
            InventoryDetailView(item: item)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Toggle(isOn: $showingLowStockOnly) {
                    Label("Low Stock", systemImage: "exclamationmark.triangle")
                }
                .toggleStyle(.button)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView()
        }
    }
    
    private var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
    }
}

// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ingredientName)
                    .font(.headline)
                
                HStack {
                    Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(item.stockStatus)
                        .font(.caption)
                        .foregroundStyle(stockStatusColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(item.totalValue.formatted(.number.precision(.fractionLength(2))))")
                    .font(.headline)
                
                if item.isLowStock {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
        }
    }
    
    private var stockStatusColor: Color {
        switch item.stockStatus {
        case "Out of Stock": .red
        case "Low Stock": .orange
        case "Below Par": .yellow
        default: .green
        }
    }
}

// MARK: - Low Stock Row

struct LowStockRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading) {
                Text(item.ingredientName)
                    .font(.headline)
                Text("Only \(item.quantityOnHand.formatted()) \(item.unit) left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Order") {
                // TODO: Create PO or add to cart
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InventoryListView()
    }
    .modelContainer(for: InventoryItem.self, inMemory: true)
}
```

---

## Step 2: Create InventoryDetailView

```swift
import SwiftUI
import SwiftData

struct InventoryDetailView: View {
    @Bindable var item: InventoryItem
    @Environment(\.modelContext) private var modelContext
    @State private var showingAdjustment = false
    
    var body: some View {
        List {
            // Current Stock Section
            Section("Current Stock") {
                HStack {
                    Text("Quantity on Hand")
                    Spacer()
                    Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                        .bold()
                }
                
                HStack {
                    Text("Unit Cost")
                    Spacer()
                    Text("$\(item.unitCost.formatted(.number.precision(.fractionLength(2))))")
                }
                
                HStack {
                    Text("Total Value")
                    Spacer()
                    Text("$\(item.totalValue.formatted(.number.precision(.fractionLength(2))))")
                        .bold()
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(item.stockStatus)
                        .foregroundStyle(statusColor)
                        .bold()
                }
            }
            
            // Stock Levels Section
            Section("Stock Levels") {
                HStack {
                    Text("Par Level")
                    Spacer()
                    Text("\(item.parLevel.formatted()) \(item.unit)")
                }
                
                HStack {
                    Text("Reorder Point")
                    Spacer()
                    Text("\(item.reorderPoint.formatted()) \(item.unit)")
                }
                
                if let storage = item.storageLocation {
                    HStack {
                        Text("Storage Location")
                        Spacer()
                        Text(storage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Recent Transactions
            Section("Recent Transactions") {
                if item.transactions.isEmpty {
                    Text("No transactions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(item.transactions.sorted(by: { $0.timestamp > $1.timestamp }).prefix(10)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .navigationTitle(item.ingredientName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button {
                showingAdjustment = true
            } label: {
                Label("Adjust Stock", systemImage: "arrow.up.arrow.down")
            }
        }
        .sheet(isPresented: $showingAdjustment) {
            StockAdjustmentView(item: item)
        }
    }
    
    private var statusColor: Color {
        switch item.stockStatus {
        case "Out of Stock": .red
        case "Low Stock": .orange
        case "Below Par": .yellow
        default: .green
        }
    }
}

struct TransactionRow: View {
    let transaction: InventoryTransaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.transactionType.icon)
                .foregroundStyle(transaction.quantity >= 0 ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(transaction.transactionType.displayName)
                    .font(.headline)
                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(transaction.quantity > 0 ? "+" : "")\(transaction.quantity.formatted())")
                    .font(.headline)
                    .foregroundStyle(transaction.quantity >= 0 ? .green : .red)
                Text("$\(transaction.totalCost.formatted(.number.precision(.fractionLength(2))))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryItem.self, configurations: config)
    
    let item = InventoryItem(
        ingredientName: "Beef Chuck",
        quantityOnHand: 3.5,
        unit: "kg",
        parLevel: 10,
        reorderPoint: 5,
        unitCost: 15.50,
        storageLocation: "Freezer A1"
    )
    container.mainContext.insert(item)
    
    NavigationStack {
        InventoryDetailView(item: item)
    }
    .modelContainer(container)
}
```

---

## Step 3: Create StockAdjustmentView

```swift
import SwiftUI
import SwiftData

struct StockAdjustmentView: View {
    let item: InventoryItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var adjustmentType: TransactionType = .purchase
    @State private var quantityChange: String = ""
    @State private var cost: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    Text(item.ingredientName)
                        .font(.headline)
                    HStack {
                        Text("Current Stock")
                        Spacer()
                        Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                    }
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
                        TextField("0", text: $quantityChange)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(item.unit)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        TextField(item.unitCost.formatted(), text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let newQuantity = calculateNewQuantity() {
                    Section("Preview") {
                        HStack {
                            Text("New Stock Level")
                            Spacer()
                            Text("\(newQuantity.formatted()) \(item.unit)")
                                .bold()
                                .foregroundStyle(newQuantity > 0 ? .primary : .red)
                        }
                    }
                }
            }
            .navigationTitle("Adjust Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAdjustment()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Decimal(string: quantityChange) else { return false }
        return true
    }
    
    private func calculateNewQuantity() -> Decimal? {
        guard let change = Decimal(string: quantityChange) else { return nil }
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
        guard let change = Decimal(string: quantityChange) else { return }
        
        let signedChange = shouldSubtract ? -change : change
        let adjustmentCost = Decimal(string: cost) ?? item.unitCost
        
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryItem.self, configurations: config)
    
    let item = InventoryItem(
        ingredientName: "Beef Chuck",
        quantityOnHand: 3.5,
        unit: "kg",
        unitCost: 15.50
    )
    
    StockAdjustmentView(item: item)
        .modelContainer(container)
}
```

---

## Step 4: Create AddInventoryItemView

```swift
import SwiftUI
import SwiftData

struct AddInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var locations: [Location]
    
    @State private var ingredientName = ""
    @State private var quantity = ""
    @State private var unit = "kg"
    @State private var parLevel = ""
    @State private var reorderPoint = ""
    @State private var unitCost = ""
    @State private var storageLocation = ""
    @State private var selectedLocation: Location?
    @State private var notes = ""
    
    let commonUnits = ["kg", "g", "L", "mL", "pcs", "oz", "lb", "gal", "qt"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Ingredient Name", text: $ingredientName)
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(commonUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        TextField("0.00", text: $unitCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Stock Levels") {
                    HStack {
                        Text("Par Level")
                        Spacer()
                        TextField("0", text: $parLevel)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Reorder Point")
                        Spacer()
                        TextField("0", text: $reorderPoint)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Location") {
                    if !locations.isEmpty {
                        Picker("Location", selection: $selectedLocation) {
                            Text("None").tag(nil as Location?)
                            ForEach(locations) { location in
                                Text(location.name).tag(location as Location?)
                            }
                        }
                    }
                    
                    TextField("Storage Location (e.g., Shelf A3)", text: $storageLocation)
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !ingredientName.isEmpty && 
        Decimal(string: quantity) != nil &&
        Decimal(string: unitCost) != nil
    }
    
    private func addItem() {
        let item = InventoryItem(
            ingredientName: ingredientName,
            quantityOnHand: Decimal(string: quantity) ?? 0,
            unit: unit,
            parLevel: Decimal(string: parLevel) ?? 10,
            reorderPoint: Decimal(string: reorderPoint) ?? 5,
            unitCost: Decimal(string: unitCost) ?? 0,
            storageLocation: storageLocation.isEmpty ? nil : storageLocation,
            location: selectedLocation,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(item)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddInventoryItemView()
        .modelContainer(for: [InventoryItem.self, Location.self], inMemory: true)
}
```

---

## Step 5: Add to Navigation

Update `AppHubView.swift` to add inventory navigation:

```swift
NavigationLink(destination: InventoryListView()) {
    Label("Inventory", systemImage: "tray.fill")
}
```

---

## Step 6: Add Sample Data (Optional)

Create a helper to add test data:

```swift
// SampleDataHelper.swift
import Foundation
import SwiftData

struct SampleDataHelper {
    static func addSampleInventory(to context: ModelContext) {
        // Create a location
        let kitchen = Location(name: "Main Kitchen", locationType: "kitchen")
        context.insert(kitchen)
        
        // Add sample items
        let beefChuck = InventoryItem(
            ingredientName: "Beef Chuck",
            quantityOnHand: 3.5,
            unit: "kg",
            parLevel: 10,
            reorderPoint: 5,
            unitCost: 15.50,
            storageLocation: "Freezer A1",
            location: kitchen
        )
        context.insert(beefChuck)
        
        let redWine = InventoryItem(
            ingredientName: "Red Wine",
            quantityOnHand: 2,
            unit: "bottles",
            parLevel: 12,
            reorderPoint: 6,
            unitCost: 25.00,
            storageLocation: "Wine Cellar",
            location: kitchen
        )
        context.insert(redWine)
        
        let butter = InventoryItem(
            ingredientName: "Butter",
            quantityOnHand: 0.5,
            unit: "kg",
            parLevel: 5,
            reorderPoint: 2,
            unitCost: 8.50,
            storageLocation: "Fridge A",
            location: kitchen
        )
        context.insert(butter)
        
        try? context.save()
    }
}
```

Then add a button in your app to load sample data (for testing only).

---

## Next Steps

After completing these views, you can:

1. **Add Swift Charts** for inventory trends
2. **Create location management** views
3. **Build purchase order** creation flow
4. **Add supplier** management
5. **Implement waste logging**

---

## Tips

### Performance
- Use `@Query` with predicates for large datasets
- Implement pagination if inventory grows large
- Use `.searchable()` for easy filtering

### User Experience
- Use `.sheet()` for forms
- Add confirmation dialogs for deletions
- Show loading states for long operations
- Add haptic feedback for actions

### Data Validation
- Validate decimal inputs
- Check for duplicate ingredient names
- Prevent negative stock (unless allowed)
- Validate costs are positive

---

## Common Issues & Solutions

**Issue:** "Cannot find type 'InventoryItem' in scope"  
**Solution:** Make sure you've added `InventoryModels.swift` to your target

**Issue:** SwiftData crash on launch  
**Solution:** Check all models are in the Schema in RemixRecipeXcodeApp.swift

**Issue:** Decimal formatting issues  
**Solution:** Use `.formatted(.number.precision(.fractionLength(2)))` for currency

**Issue:** Preview not working  
**Solution:** Make sure to create ModelContainer with `inMemory: true` in previews

---

## Testing Checklist

- [ ] Can add new inventory items
- [ ] Can view item details
- [ ] Can adjust stock levels
- [ ] Transactions are logged correctly
- [ ] Low stock items show in alerts
- [ ] Search works correctly
- [ ] Delete items works
- [ ] Stock status colors display correctly

---

**Ready to build?** Start with Step 1 and you'll have a working inventory system in no time! 🚀
