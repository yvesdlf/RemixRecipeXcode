import SwiftUI
import SwiftData

/// Detailed view of a single inventory item showing stock, transactions, and actions
struct InventoryDetailView: View {
    @Bindable var item: InventoryItem
    @Environment(\.modelContext) private var modelContext
    @State private var showingAdjustment = false
    @State private var showingDeleteConfirmation = false
    
    var sortedTransactions: [InventoryTransaction] {
        item.transactions.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        List {
            // Status Card
    // ...existing code...
                VStack(spacing: 16) {
                    // Stock Level
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Stock on Hand")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                                .font(.title)
                                .bold()
                        }
                        
                        Spacer()
                        
                        // Status Badge
                        Text(item.stockStatus)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.2))
                            .foregroundStyle(statusColor)
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    // Total Value
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Value")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currencyString(from: item.totalValue))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Unit Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currencyString(from: item.unitCost))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Stock Levels Section
            Section("Stock Levels") {
                LabeledContent("Par Level", value: "\(item.parLevel.formatted()) \(item.unit)")
                LabeledContent("Reorder Point", value: "\(item.reorderPoint.formatted()) \(item.unit)")
                
                if item.isLowStock {
                    HStack {
                        Label("Below reorder point", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }
                
                if let storage = item.storageLocation {
                    LabeledContent("Storage", value: storage)
                }
                
                if let location = item.location {
                    LabeledContent("Location", value: location.name)
                }
            }
            
            // Notes
            if let notes = item.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.subheadline)
                }
            }
            
            // Recent Transactions
            Section {
                if sortedTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Transactions will appear here when you adjust stock")
                    )
                } else {
                    ForEach(sortedTransactions.prefix(20)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            } header: {
                HStack {
                    Text("Recent Transactions")
                    Spacer()
                    if sortedTransactions.count > 20 {
                        Text("Showing 20 of \(sortedTransactions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Item", systemImage: "trash")
                }
            }
        }
        .navigationTitle(item.ingredientName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdjustment = true
                } label: {
                    Label("Adjust Stock", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showingAdjustment) {
            StockAdjustmentView(item: item)
        }
        .alert("Delete Item?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                // no-op
            }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This will permanently delete \(item.ingredientName) and all its transaction history. This action cannot be undone.")
        }
    }
    
    private func currencyString(from value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
    
    private var statusColor: Color {
        switch item.stockStatus {
        case "Out of Stock":
            return Color.red
        case "Low Stock":
            return Color.orange
        case "Below Par":
            return Color.yellow
        case "In Stock":
            return Color.green
        default:
            return Color.green
        }
    }
    
    private func deleteItem() {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: InventoryTransaction
    
    private func currencyString(from value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
    
    var body: some View {
    // ...existing code...
            // Icon
            Image(systemName: transaction.transactionType.icon)
                .font(.title3)
                .foregroundStyle(transaction.quantity >= 0 ? .green : .red)
                .frame(width: 30)
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Quantity & Cost
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.quantity > 0 ? "+" : "")\(transaction.quantity.formatted())")
                    .font(.headline)
                    .foregroundStyle(transaction.quantity >= 0 ? .green : .red)
                
                Text(currencyString(from: transaction.totalCost))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
        unitCost: 15.50,
        storageLocation: "Freezer A1",
        notes: "Premium grade beef from supplier ABC"
    )
    context.insert(item)
    
    // Add some transactions
    let purchase = InventoryTransaction(
        inventoryItem: item,
        transactionType: .purchase,
        quantity: 10,
        unitCost: 15.50,
        notes: "PO-2026-001"
    )
    context.insert(purchase)
    
    let usage = InventoryTransaction(
        inventoryItem: item,
        transactionType: .usage,
        quantity: -2,
        unitCost: 15.50,
        notes: "Used in Beef Bourguignon production"
    )
    context.insert(usage)
    
    let waste = InventoryTransaction(
        inventoryItem: item,
        transactionType: .wastage,
        quantity: -0.5,
        unitCost: 15.50,
        notes: "Spoilage"
    )
    context.insert(waste)
    
    NavigationStack {
        InventoryDetailView(item: item)
    }
    .modelContainer(container)
}
import SwiftUI
import SwiftData

/// Detailed view of a single inventory item showing stock, transactions, and actions
// ...existing code...
    @Bindable var item: InventoryItem
    @Environment(\.modelContext) private var modelContext
    @State private var showingAdjustment = false
    @State private var showingDeleteConfirmation = false
    
    var sortedTransactions: [InventoryTransaction] {
        item.transactions.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        List {
                VStack(spacing: 16) {
                    // Stock Level
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Stock on Hand")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(item.quantityOnHand.formatted()) \(item.unit)")
                                .font(.title)
                                .bold()
                        }
                        
                        Spacer()
                        
                        // Status Badge
                        Text(item.stockStatus)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.2))
                            .foregroundStyle(statusColor)
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    // Total Value
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Value")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currencyString(from: item.totalValue))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Unit Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currencyString(from: item.unitCost))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Stock Levels Section
            Section("Stock Levels") {
                LabeledContent("Par Level", value: "\(item.parLevel.formatted()) \(item.unit)")
                LabeledContent("Reorder Point", value: "\(item.reorderPoint.formatted()) \(item.unit)")
                
                if item.isLowStock {
                    HStack {
                        Label("Below reorder point", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }
                
                if let storage = item.storageLocation {
                    LabeledContent("Storage", value: storage)
                }
                
                if let location = item.location {
                    LabeledContent("Location", value: location.name)
                }
            }
            
            // Notes
            if let notes = item.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.subheadline)
                }
            }
            
            // Recent Transactions
            Section {
                if sortedTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Transactions will appear here when you adjust stock")
                    )
                } else {
                    ForEach(sortedTransactions.prefix(20)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            } header: {
                HStack {
                    Text("Recent Transactions")
                    Spacer()
                    if sortedTransactions.count > 20 {
                        Text("Showing 20 of \(sortedTransactions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Item", systemImage: "trash")
                }
            }
        }
        .navigationTitle(item.ingredientName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdjustment = true
                } label: {
                    Label("Adjust Stock", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showingAdjustment) {
            StockAdjustmentView(item: item)
        }
        .alert("Delete Item?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                // no-op
            }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This will permanently delete \(item.ingredientName) and all its transaction history. This action cannot be undone.")
        }
    }
    
    private func currencyString(from value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
    
    private var statusColor: Color {
        switch item.stockStatus {
        case "Out of Stock":
            return Color.red
        case "Low Stock":
            return Color.orange
        case "Below Par":
            return Color.yellow
        case "In Stock":
            return Color.green
        default:
            return Color.green
        }
    }
    
    private func deleteItem() {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

// MARK: - Transaction Row

// ...existing code...
    let transaction: InventoryTransaction
    
    private func currencyString(from value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: transaction.transactionType.icon)
                .font(.title3)
                .foregroundStyle(transaction.quantity >= 0 ? .green : .red)
                .frame(width: 30)
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Quantity & Cost
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.quantity > 0 ? "+" : "")\(transaction.quantity.formatted())")
                    .font(.headline)
                    .foregroundStyle(transaction.quantity >= 0 ? .green : .red)
                
                Text(currencyString(from: transaction.totalCost))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
        unitCost: 15.50,
        storageLocation: "Freezer A1",
        notes: "Premium grade beef from supplier ABC"
    )
    context.insert(item)
    
    // Add some transactions
    let purchase = InventoryTransaction(
        inventoryItem: item,
        transactionType: .purchase,
        quantity: 10,
        unitCost: 15.50,
        notes: "PO-2026-001"
    )
    context.insert(purchase)
    
    let usage = InventoryTransaction(
        inventoryItem: item,
        transactionType: .usage,
        quantity: -2,
        unitCost: 15.50,
        notes: "Used in Beef Bourguignon production"
    )
    context.insert(usage)
    
    let waste = InventoryTransaction(
        inventoryItem: item,
        transactionType: .wastage,
        quantity: -0.5,
        unitCost: 15.50,
        notes: "Spoilage"
    )
    context.insert(waste)
    
    NavigationStack {
        InventoryDetailView(item: item)
    }
    .modelContainer(container)
}
