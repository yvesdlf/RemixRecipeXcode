import Foundation
import SwiftData

/// Helper to populate the app with realistic sample data for testing
struct SampleDataHelper {
    
    /// Load all sample data (locations, inventory items, transactions)
    static func loadAllSampleData(context: ModelContext) {
        // Check if data already exists
        let descriptor = FetchDescriptor<InventoryItem>()
        if let existingItems = try? context.fetch(descriptor), !existingItems.isEmpty {
            print("⚠️ Sample data already exists. Skipping.")
            return
        }
        
        print("📦 Loading sample data...")
        
        // Create locations first
        let locations = createSampleLocations(context: context)
        
        // Create inventory items
        createSampleInventoryItems(context: context, locations: locations)
        
        // Save everything
        do {
            try context.save()
            print("✅ Sample data loaded successfully!")
        } catch {
            print("❌ Error saving sample data: \(error)")
        }
    }
    
    /// Create sample locations
    static func createSampleLocations(context: ModelContext) -> [Location] {
        let locations = [
            Location(
                name: "Main Kitchen",
                locationType: "kitchen",
                address: "Ground Floor"
            ),
            Location(
                name: "Walk-in Freezer",
                locationType: "freezer",
                address: "Basement"
            ),
            Location(
                name: "Dry Storage",
                locationType: "storage",
                address: "Ground Floor"
            ),
            Location(
                name: "Wine Cellar",
                locationType: "storage",
                address: "Basement"
            )
        ]
        
        locations.forEach { context.insert($0) }
        print("✅ Created \(locations.count) locations")
        return locations
    }
    
    /// Create sample inventory items with realistic data
    static func createSampleInventoryItems(context: ModelContext, locations: [Location]) {
        let kitchen = locations.first { $0.name == "Main Kitchen" }
        let freezer = locations.first { $0.name == "Walk-in Freezer" }
        let dryStorage = locations.first { $0.name == "Dry Storage" }
        let wineCellar = locations.first { $0.name == "Wine Cellar" }
        
        let items: [(name: String, qty: Decimal, unit: String, par: Decimal, reorder: Decimal, cost: Decimal, storage: String?, location: Location?, category: String)] = [
            // Meats (Freezer)
            ("Beef Chuck", 12.5, "kg", 25, 10, 15.50, "Shelf A1", freezer, "BEEF"),
            ("Chicken Breast", 8.0, "kg", 20, 8, 12.00, "Shelf A2", freezer, "CHICKEN"),
            ("Salmon Fillet", 4.5, "kg", 10, 5, 28.00, "Shelf B1", freezer, "FISH"),
            ("Pork Tenderloin", 6.0, "kg", 15, 6, 18.50, "Shelf A3", freezer, "PORK"),
            ("Duck Breast", 3.0, "kg", 8, 3, 32.00, "Shelf B2", freezer, "DUCK"),
            
            // Dairy (Kitchen)
            ("Butter (Unsalted)", 2.5, "kg", 10, 4, 8.50, "Fridge 1", kitchen, "DAIRY & EGGS"),
            ("Heavy Cream", 3.0, "L", 8, 3, 6.50, "Fridge 1", kitchen, "DAIRY & EGGS"),
            ("Parmesan Cheese", 1.2, "kg", 5, 2, 45.00, "Fridge 2", kitchen, "DAIRY & EGGS"),
            ("Eggs", 120.0, "pcs", 240, 100, 0.35, "Fridge 1", kitchen, "DAIRY & EGGS"),
            
            // Vegetables (Kitchen)
            ("Onions (Yellow)", 5.5, "kg", 15, 6, 2.50, "Produce Rack", kitchen, "VEGETABLE"),
            ("Garlic", 0.8, "kg", 3, 1, 12.00, "Produce Rack", kitchen, "VEGETABLE"),
            ("Carrots", 4.0, "kg", 10, 4, 3.20, "Produce Rack", kitchen, "VEGETABLE"),
            ("Tomatoes (Roma)", 6.0, "kg", 12, 5, 4.80, "Produce Rack", kitchen, "VEGETABLE"),
            
            // Dry Goods (Dry Storage)
            ("Olive Oil (Extra Virgin)", 4.5, "L", 12, 5, 18.00, "Shelf C1", dryStorage, "OIL / VINEGAR"),
            ("All-Purpose Flour", 15.0, "kg", 30, 12, 1.80, "Shelf D1", dryStorage, "BREAD & OTHER"),
            ("Arborio Rice", 8.0, "kg", 20, 8, 4.50, "Shelf D2", dryStorage, "BREAD & OTHER"),
            ("Pasta (Various)", 12.0, "kg", 25, 10, 3.20, "Shelf D3", dryStorage, "BREAD & OTHER"),
            
            // Herbs & Spices (Kitchen)
            ("Basil (Fresh)", 0.3, "kg", 1, 0.4, 24.00, "Herb Cooler", kitchen, "HERBS"),
            ("Thyme (Fresh)", 0.2, "kg", 0.8, 0.3, 28.00, "Herb Cooler", kitchen, "HERBS"),
            ("Black Pepper (Ground)", 0.5, "kg", 2, 0.8, 15.00, "Spice Rack", kitchen, "SPICES"),
            ("Sea Salt (Maldon)", 1.0, "kg", 3, 1, 12.00, "Spice Rack", kitchen, "SPICES"),
            
            // Wine & Alcohol (Wine Cellar)
            ("Red Wine (Cooking)", 9.0, "bottles", 24, 10, 25.00, "Rack A", wineCellar, "DRY"),
            ("White Wine (Cooking)", 6.0, "bottles", 18, 8, 22.00, "Rack A", wineCellar, "DRY"),
            
            // Stocks & Sauces (Kitchen)
            ("Chicken Stock", 8.0, "L", 20, 8, 4.50, "Stock Shelf", kitchen, "DRY"),
            ("Beef Stock", 6.0, "L", 15, 6, 5.50, "Stock Shelf", kitchen, "DRY"),
        ]
        
        for (name, qty, unit, par, reorder, cost, storage, location, _) in items {
            let item = InventoryItem(
                ingredientName: name,
                quantityOnHand: qty,
                unit: unit,
                parLevel: par,
                reorderPoint: reorder,
                unitCost: cost,
                storageLocation: storage,
                location: location
            )
            context.insert(item)
            
            // Add initial purchase transaction
            let transaction = InventoryTransaction(
                inventoryItem: item,
                transactionType: .purchase,
                quantity: qty,
                unitCost: cost,
                notes: "Initial stock"
            )
            context.insert(transaction)
            
            // Add some usage transactions for variety
            if qty > reorder {
                let usageQty = Decimal(Int.random(in: 1...3))
                let usage = InventoryTransaction(
                    inventoryItem: item,
                    transactionType: .usage,
                    quantity: -usageQty,
                    unitCost: cost,
                    notes: "Recipe production"
                )
                context.insert(usage)
            }
        }
        
        print("✅ Created \(items.count) inventory items with transactions")
    }
    
    /// Clear all sample data (for testing)
    static func clearAllData(context: ModelContext) {
        // Delete all inventory items (will cascade to transactions)
        let itemDescriptor = FetchDescriptor<InventoryItem>()
        if let items = try? context.fetch(itemDescriptor) {
            items.forEach { context.delete($0) }
        }
        
        // Delete all locations
        let locationDescriptor = FetchDescriptor<Location>()
        if let locations = try? context.fetch(locationDescriptor) {
            locations.forEach { context.delete($0) }
        }
        
        try? context.save()
        print("🗑️ All sample data cleared")
    }
    
    /// Get summary statistics
    static func getSummary(context: ModelContext) -> String {
        let itemDescriptor = FetchDescriptor<InventoryItem>()
        let locationDescriptor = FetchDescriptor<Location>()
        let transactionDescriptor = FetchDescriptor<InventoryTransaction>()
        
        let itemCount = (try? context.fetch(itemDescriptor))?.count ?? 0
        let locationCount = (try? context.fetch(locationDescriptor))?.count ?? 0
        let transactionCount = (try? context.fetch(transactionDescriptor))?.count ?? 0
        
        let totalValue = InventoryItem.totalInventoryValue(in: context)
        let lowStockCount = InventoryItem.lowStockItems(in: context).count
        
        return """
        📊 Database Summary:
        • Inventory Items: \(itemCount)
        • Locations: \(locationCount)
        • Transactions: \(transactionCount)
        • Total Value: $\(totalValue.formatted(.number.precision(.fractionLength(2))))
        • Low Stock Items: \(lowStockCount)
        """
    }
}

// MARK: - Preview Helper

extension SampleDataHelper {
    /// Quick setup for previews
    static func setupPreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: InventoryItem.self, Location.self, InventoryTransaction.self,
            configurations: config
        )
        
        loadAllSampleData(context: container.mainContext)
        return container
    }
}
