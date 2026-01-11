//
//  RemixRecipeXcodeApp.swift
//  RemixRecipeXcode
//
//  Created by Yves de Lafontaine on 07/01/2026.
//

import SwiftUI
import SwiftData

@main
struct RemixRecipeXcodeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Core Models
            Item.self,
            Ingredient.self,
            Recipe.self,
            
            // Phase 1: Inventory Management
            Location.self,
            InventoryItem.self,
            InventoryTransaction.self,
            StockTransfer.self,
            
            // Phase 2: Supplier & Procurement
            Supplier.self,
            SupplierIngredient.self,
            PriceHistory.self,
            PurchaseOrder.self,
            PurchaseOrderItem.self,
            GoodsReceivedNote.self,
            GoodsReceivedItem.self,
            
            // Phase 3 & 4: Costing, Waste, Financial
            RecipeCostHistory.self,
            FinancialPeriod.self,
            WasteLog.self,
            VarianceRecord.self,
            MenuItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppHubView()
        }
        .modelContainer(sharedModelContainer)
    }
}

