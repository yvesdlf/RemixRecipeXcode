import SwiftUI
import SwiftData

/// Main inventory list view showing all inventory items with search and filters
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
    
    var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }
    
    var body: some View {
        List {
            // Low stock alert section
            if !lowStockItems.isEmpty && !showingLowStockOnly {
                Section {
                    ForEach(lowStockItems) { item in
                        LowStockAlertRow(item: item)
                    }
                } header: {
                    Label("Low Stock Alerts (\(lowStockItems.count))", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            
            // All items section
            Section {
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
            } header: {
                if showingLowStockOnly {
                    Text("Low Stock Items (\(filteredItems.count))")
                } else {
                    Text("All Items (\(filteredItems.count))")
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
                .tint(showingLowStockOnly ? .orange : .gray)
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
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
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
                
                HStack(spacing: 8) {
                    Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(item.stockStatus)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(stockStatusColor.opacity(0.2))
                        .foregroundStyle(stockStatusColor)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(currencyString(from: item.totalValue))
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if item.isLowStock {
                    Label("Reorder", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func currencyString(from value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
    
    private var stockStatusColor: Color {
        switch item.stockStatus {
        case "Out of Stock": return .red
        case "Low Stock": return .orange
        case "Below Par": return .yellow
        default: return .green
        }
    }
}

// MARK: - Low Stock Alert Row

struct LowStockAlertRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.ingredientName)
                    .font(.headline)
                Text("Only \(item.quantityOnHand.formatted()) \(item.unit) left (needs \(item.reorderPoint.formatted()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            NavigationLink(value: item) {
                Text("View")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("With Items") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryItem.self, configurations: config)
    let context = container.mainContext
    
    // Add sample items
    let item1 = InventoryItem(
        ingredientName: "Beef Chuck",
        quantityOnHand: 12.5,
        unit: "kg",
        parLevel: 20,
        reorderPoint: 10,
        unitCost: 15.50
    )
    context.insert(item1)
    
    let item2 = InventoryItem(
        ingredientName: "Red Wine",
        quantityOnHand: 3,
        unit: "bottles",
        parLevel: 12,
        reorderPoint: 6,
        unitCost: 25.00
    )
    context.insert(item2)
    
    let item3 = InventoryItem(
        ingredientName: "Butter",
        quantityOnHand: 0.5,
        unit: "kg",
        parLevel: 5,
        reorderPoint: 2,
        unitCost: 8.50
    )
    context.insert(item3)
    
    NavigationStack {
        InventoryListView()
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryItem.self, configurations: config)
    
    NavigationStack {
        InventoryListView()
    }
    .modelContainer(container)
}
