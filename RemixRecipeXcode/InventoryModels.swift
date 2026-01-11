import Foundation
import SwiftData

// MARK: - Phase 1: Core Inventory Management Models

/// Represents a physical storage location (kitchen, pantry, freezer, etc.)
@Model
final class Location {
    @Attribute(.unique) var id: String
    var name: String
    var locationType: String // "kitchen", "storage", "restaurant", "freezer", "dry-storage"
    var address: String?
    var isActive: Bool
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \InventoryItem.location) 
    var inventoryItems: [InventoryItem]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        locationType: String,
        address: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.locationType = locationType
        self.address = address
        self.isActive = isActive
        self.createdAt = Date()
        self.inventoryItems = []
    }
}

/// Tracks real-time inventory for an ingredient at a specific location
@Model
final class InventoryItem {
    @Attribute(.unique) var id: String
    var ingredientName: String // Reference to ingredient name
    var quantityOnHand: Decimal
    var unit: String
    var parLevel: Decimal // Minimum stock level (triggers reorder)
    var reorderPoint: Decimal // Point at which to reorder
    var unitCost: Decimal
    var storageLocation: String? // e.g., "Shelf A3", "Freezer 2"
    var lastUpdated: Date
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var location: Location?
    @Relationship(deleteRule: .cascade, inverse: \InventoryTransaction.inventoryItem) 
    var transactions: [InventoryTransaction]
    
    // Computed properties
    var isLowStock: Bool {
        quantityOnHand <= reorderPoint
    }
    
    var isBelowPar: Bool {
        quantityOnHand < parLevel
    }
    
    var stockStatus: String {
        if quantityOnHand <= 0 {
            return "Out of Stock"
        } else if isLowStock {
            return "Low Stock"
        } else if isBelowPar {
            return "Below Par"
        } else {
            return "In Stock"
        }
    }
    
    var totalValue: Decimal {
        quantityOnHand * unitCost
    }
    
    init(
        id: String = UUID().uuidString,
        ingredientName: String,
        quantityOnHand: Decimal = 0,
        unit: String,
        parLevel: Decimal = 10,
        reorderPoint: Decimal = 5,
        unitCost: Decimal = 0,
        storageLocation: String? = nil,
        location: Location? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.quantityOnHand = quantityOnHand
        self.unit = unit
        self.parLevel = parLevel
        self.reorderPoint = reorderPoint
        self.unitCost = unitCost
        self.storageLocation = storageLocation
        self.lastUpdated = Date()
        self.notes = notes
        self.location = location
        self.transactions = []
    }
    
    /// Update quantity and create transaction record
    func adjustQuantity(
        by amount: Decimal,
        type: TransactionType,
        cost: Decimal? = nil,
        notes: String? = nil,
        context: ModelContext
    ) {
        quantityOnHand += amount
        lastUpdated = Date()
        
        let transaction = InventoryTransaction(
            inventoryItem: self,
            transactionType: type,
            quantity: amount,
            unitCost: cost ?? unitCost,
            notes: notes
        )
        context.insert(transaction)
    }
}

/// Transaction types for inventory movements
enum TransactionType: String, Codable, CaseIterable {
    case purchase = "purchase"
    case usage = "usage"
    case transfer = "transfer"
    case wastage = "wastage"
    case adjustment = "adjustment"
    case production = "production" // Used in recipe production
    case returned = "returned"
    
    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .usage: return "Usage"
        case .transfer: return "Transfer"
        case .wastage: return "Wastage"
        case .adjustment: return "Adjustment"
        case .production: return "Production"
        case .returned: return "Return"
        }
    }
    
    var icon: String {
        switch self {
        case .purchase: return "cart.fill.badge.plus"
        case .usage: return "minus.circle"
        case .transfer: return "arrow.left.arrow.right"
        case .wastage: return "trash"
        case .adjustment: return "slider.horizontal.3"
        case .production: return "fork.knife"
        case .returned: return "arrow.uturn.backward"
        }
    }
}

/// Records all inventory movements for audit trail
@Model
final class InventoryTransaction {
    @Attribute(.unique) var id: String
    var transactionType: TransactionType
    var quantity: Decimal // Positive for additions, negative for subtractions
    var unitCost: Decimal
    var timestamp: Date
    var userId: String? // Future: link to User model
    var notes: String?
    var referenceId: String? // Link to PO, Recipe, Waste log, etc.
    
    // Relationships
    @Relationship(deleteRule: .nullify) var inventoryItem: InventoryItem?
    
    // Computed
    var totalCost: Decimal {
        abs(quantity) * unitCost
    }
    
    init(
        id: String = UUID().uuidString,
        inventoryItem: InventoryItem? = nil,
        transactionType: TransactionType,
        quantity: Decimal,
        unitCost: Decimal,
        userId: String? = nil,
        notes: String? = nil,
        referenceId: String? = nil
    ) {
        self.id = id
        self.inventoryItem = inventoryItem
        self.transactionType = transactionType
        self.quantity = quantity
        self.unitCost = unitCost
        self.timestamp = Date()
        self.userId = userId
        self.notes = notes
        self.referenceId = referenceId
    }
}

/// Transfer request between locations
@Model
final class StockTransfer {
    @Attribute(.unique) var id: String
    var fromLocationId: String
    var toLocationId: String
    var ingredientName: String
    var quantity: Decimal
    var unit: String
    var status: TransferStatus
    var requestedBy: String?
    var approvedBy: String?
    var requestedAt: Date
    var approvedAt: Date?
    var completedAt: Date?
    var notes: String?
    
    init(
        id: String = UUID().uuidString,
        fromLocationId: String,
        toLocationId: String,
        ingredientName: String,
        quantity: Decimal,
        unit: String,
        requestedBy: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.fromLocationId = fromLocationId
        self.toLocationId = toLocationId
        self.ingredientName = ingredientName
        self.quantity = quantity
        self.unit = unit
        self.status = .pending
        self.requestedBy = requestedBy
        self.requestedAt = Date()
        self.notes = notes
    }
    
    func approve(by userId: String) {
        status = .approved
        approvedBy = userId
        approvedAt = Date()
    }
    
    func complete() {
        status = .completed
        completedAt = Date()
    }
    
    func reject() {
        status = .rejected
    }
}

enum TransferStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "blue"
        case .rejected: return "red"
        case .completed: return "green"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Low Stock Alert Helper

struct LowStockAlert: Identifiable {
    let id: String
    let ingredientName: String
    let currentQuantity: Decimal
    let reorderPoint: Decimal
    let parLevel: Decimal
    let unit: String
    let location: String
    let severity: AlertSeverity
    
    enum AlertSeverity: String {
        case critical = "Out of Stock"
        case high = "Low Stock"
        case medium = "Below Par"
        
        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            }
        }
    }
}

// MARK: - Extensions for Querying

extension InventoryItem {
    /// Get all low stock items across all locations
    static func lowStockItems(in context: ModelContext) -> [InventoryItem] {
        let descriptor = FetchDescriptor<InventoryItem>(
            predicate: #Predicate { $0.quantityOnHand <= $0.reorderPoint },
            sortBy: [SortDescriptor(\.quantityOnHand, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Get total inventory value for all items
    static func totalInventoryValue(in context: ModelContext) -> Decimal {
        let descriptor = FetchDescriptor<InventoryItem>()
        guard let items = try? context.fetch(descriptor) else { return 0 }
        return items.reduce(0) { $0 + $1.totalValue }
    }
}

extension Location {
    /// Get inventory value for this location
    func inventoryValue() -> Decimal {
        inventoryItems.reduce(0) { $0 + $1.totalValue }
    }
}
