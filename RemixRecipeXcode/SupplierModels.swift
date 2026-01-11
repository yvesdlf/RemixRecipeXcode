import Foundation
import SwiftData

// MARK: - Phase 2: Supplier & Procurement Management Models

/// Supplier/Vendor information
@Model
final class Supplier {
    @Attribute(.unique) var id: String
    var name: String
    var contactName: String?
    var email: String?
    var phone: String?
    var address: String?
    var paymentTerms: String? // e.g., "Net 30", "COD", "Net 15"
    var deliverySchedule: String? // e.g., "Mon/Wed/Fri", "Daily"
    var rating: Double // 0.0 to 5.0
    var isActive: Bool
    var notes: String?
    var createdAt: Date
    var lastOrderDate: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \SupplierIngredient.supplier) 
    var suppliedIngredients: [SupplierIngredient]
    
    @Relationship(deleteRule: .nullify, inverse: \PurchaseOrder.supplier) 
    var purchaseOrders: [PurchaseOrder]
    
    // Computed properties
    var totalOrders: Int {
        purchaseOrders.count
    }
    
    var activeOrders: Int {
        purchaseOrders.filter { $0.status != .delivered && $0.status != .cancelled }.count
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        contactName: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        paymentTerms: String? = nil,
        deliverySchedule: String? = nil,
        rating: Double = 0.0,
        isActive: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.contactName = contactName
        self.email = email
        self.phone = phone
        self.address = address
        self.paymentTerms = paymentTerms
        self.deliverySchedule = deliverySchedule
        self.rating = rating
        self.isActive = isActive
        self.notes = notes
        self.createdAt = Date()
        self.suppliedIngredients = []
        self.purchaseOrders = []
    }
}

/// Links suppliers to ingredients with pricing information
@Model
final class SupplierIngredient {
    @Attribute(.unique) var id: String
    var ingredientName: String
    var supplierSKU: String? // Supplier's product code
    var unitPrice: Decimal
    var unit: String
    var leadTimeDays: Int // How many days to deliver
    var minimumOrderQuantity: Decimal
    var packSize: String? // e.g., "Case of 12", "5kg bag"
    var lastPriceUpdate: Date
    var isPreferred: Bool // Preferred supplier for this ingredient
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var supplier: Supplier?
    @Relationship(deleteRule: .cascade, inverse: \PriceHistory.supplierIngredient) 
    var priceHistory: [PriceHistory]
    
    // Computed
    var pricePerBaseUnit: Decimal {
        // If pack size specified, calculate base unit price
        // This is simplified - in real app would parse pack size
        unitPrice
    }
    
    init(
        id: String = UUID().uuidString,
        ingredientName: String,
        supplier: Supplier? = nil,
        supplierSKU: String? = nil,
        unitPrice: Decimal,
        unit: String,
        leadTimeDays: Int = 1,
        minimumOrderQuantity: Decimal = 1,
        packSize: String? = nil,
        isPreferred: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.supplier = supplier
        self.supplierSKU = supplierSKU
        self.unitPrice = unitPrice
        self.unit = unit
        self.leadTimeDays = leadTimeDays
        self.minimumOrderQuantity = minimumOrderQuantity
        self.packSize = packSize
        self.lastPriceUpdate = Date()
        self.isPreferred = isPreferred
        self.notes = notes
        self.priceHistory = []
    }
    
    /// Update price and log history
    func updatePrice(to newPrice: Decimal, context: ModelContext) {
        let history = PriceHistory(
            supplierIngredient: self,
            oldPrice: unitPrice,
            newPrice: newPrice
        )
        context.insert(history)
        
        unitPrice = newPrice
        lastPriceUpdate = Date()
    }
}

/// Tracks price changes over time
@Model
final class PriceHistory {
    @Attribute(.unique) var id: String
    var oldPrice: Decimal
    var newPrice: Decimal
    var changeDate: Date
    var changePercentage: Double
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var supplierIngredient: SupplierIngredient?
    
    init(
        id: String = UUID().uuidString,
        supplierIngredient: SupplierIngredient? = nil,
        oldPrice: Decimal,
        newPrice: Decimal,
        notes: String? = nil
    ) {
        self.id = id
        self.supplierIngredient = supplierIngredient
        self.oldPrice = oldPrice
        self.newPrice = newPrice
        self.changeDate = Date()
        
        let change = Double(truncating: (newPrice - oldPrice) as NSNumber)
        let original = Double(truncating: oldPrice as NSNumber)
        self.changePercentage = original > 0 ? (change / original) * 100 : 0
        self.notes = notes
    }
}

/// Purchase Order statuses
enum PurchaseOrderStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case pending = "pending"
    case approved = "approved"
    case ordered = "ordered"
    case partiallyReceived = "partially_received"
    case delivered = "delivered"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .pending: return "Pending Approval"
        case .approved: return "Approved"
        case .ordered: return "Ordered"
        case .partiallyReceived: return "Partially Received"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .pending: return "orange"
        case .approved: return "blue"
        case .ordered: return "purple"
        case .partiallyReceived: return "yellow"
        case .delivered: return "green"
        case .cancelled: return "red"
        }
    }
}

/// Purchase Order (PO)
@Model
final class PurchaseOrder {
    @Attribute(.unique) var id: String
    var poNumber: String // e.g., "PO-2026-0001"
    var status: PurchaseOrderStatus
    var orderDate: Date
    var expectedDeliveryDate: Date?
    var actualDeliveryDate: Date?
    var totalCost: Decimal
    var shippingCost: Decimal
    var taxAmount: Decimal
    var notes: String?
    var createdBy: String?
    var approvedBy: String?
    var approvedAt: Date?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var supplier: Supplier?
    @Relationship(deleteRule: .cascade, inverse: \PurchaseOrderItem.purchaseOrder) 
    var items: [PurchaseOrderItem]
    @Relationship(deleteRule: .cascade, inverse: \GoodsReceivedNote.purchaseOrder) 
    var goodsReceivedNotes: [GoodsReceivedNote]
    
    // Computed
    var grandTotal: Decimal {
        totalCost + shippingCost + taxAmount
    }
    
    var isOverdue: Bool {
        guard let expected = expectedDeliveryDate else { return false }
        return status != .delivered && status != .cancelled && Date() > expected
    }
    
    var itemsCount: Int {
        items.count
    }
    
    var receivedItemsCount: Int {
        items.filter { $0.quantityReceived >= $0.quantityOrdered }.count
    }
    
    init(
        id: String = UUID().uuidString,
        poNumber: String,
        supplier: Supplier? = nil,
        orderDate: Date = Date(),
        expectedDeliveryDate: Date? = nil,
        totalCost: Decimal = 0,
        shippingCost: Decimal = 0,
        taxAmount: Decimal = 0,
        notes: String? = nil,
        createdBy: String? = nil
    ) {
        self.id = id
        self.poNumber = poNumber
        self.supplier = supplier
        self.status = .draft
        self.orderDate = orderDate
        self.expectedDeliveryDate = expectedDeliveryDate
        self.totalCost = totalCost
        self.shippingCost = shippingCost
        self.taxAmount = taxAmount
        self.notes = notes
        self.createdBy = createdBy
        self.items = []
        self.goodsReceivedNotes = []
    }
    
    func approve(by userId: String) {
        status = .approved
        approvedBy = userId
        approvedAt = Date()
    }
    
    func markAsOrdered() {
        status = .ordered
    }
    
    func cancel() {
        status = .cancelled
    }
    
    /// Generate next PO number (simplified)
    static func generatePONumber() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let random = Int.random(in: 1000...9999)
        return "PO-\(year)-\(random)"
    }
}

/// Individual items in a purchase order
@Model
final class PurchaseOrderItem {
    @Attribute(.unique) var id: String
    var ingredientName: String
    var supplierSKU: String?
    var quantityOrdered: Decimal
    var quantityReceived: Decimal
    var unit: String
    var unitPrice: Decimal
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var purchaseOrder: PurchaseOrder?
    
    // Computed
    var lineTotal: Decimal {
        quantityOrdered * unitPrice
    }
    
    var isFullyReceived: Bool {
        quantityReceived >= quantityOrdered
    }
    
    var remainingQuantity: Decimal {
        max(0, quantityOrdered - quantityReceived)
    }
    
    init(
        id: String = UUID().uuidString,
        ingredientName: String,
        supplierSKU: String? = nil,
        quantityOrdered: Decimal,
        quantityReceived: Decimal = 0,
        unit: String,
        unitPrice: Decimal,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.supplierSKU = supplierSKU
        self.quantityOrdered = quantityOrdered
        self.quantityReceived = quantityReceived
        self.unit = unit
        self.unitPrice = unitPrice
        self.notes = notes
    }
}

/// Goods Received Note (GRN) - Records actual deliveries
@Model
final class GoodsReceivedNote {
    @Attribute(.unique) var id: String
    var grnNumber: String
    var receivedDate: Date
    var receivedBy: String?
    var invoiceNumber: String?
    var deliveryNoteNumber: String?
    var notes: String?
    var hasDiscrepancies: Bool
    var discrepancyNotes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var purchaseOrder: PurchaseOrder?
    @Relationship(deleteRule: .cascade, inverse: \GoodsReceivedItem.goodsReceivedNote) 
    var items: [GoodsReceivedItem]
    
    init(
        id: String = UUID().uuidString,
        grnNumber: String,
        purchaseOrder: PurchaseOrder? = nil,
        receivedDate: Date = Date(),
        receivedBy: String? = nil,
        invoiceNumber: String? = nil,
        deliveryNoteNumber: String? = nil,
        hasDiscrepancies: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.grnNumber = grnNumber
        self.purchaseOrder = purchaseOrder
        self.receivedDate = receivedDate
        self.receivedBy = receivedBy
        self.invoiceNumber = invoiceNumber
        self.deliveryNoteNumber = deliveryNoteNumber
        self.hasDiscrepancies = hasDiscrepancies
        self.notes = notes
        self.items = []
    }
    
    static func generateGRNNumber() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let random = Int.random(in: 1000...9999)
        return "GRN-\(year)-\(random)"
    }
}

/// Items in a Goods Received Note
@Model
final class GoodsReceivedItem {
    @Attribute(.unique) var id: String
    var ingredientName: String
    var quantityOrdered: Decimal
    var quantityReceived: Decimal
    var unit: String
    var hasDiscrepancy: Bool
    var discrepancyNotes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify) var goodsReceivedNote: GoodsReceivedNote?
    
    var variance: Decimal {
        quantityReceived - quantityOrdered
    }
    
    var variancePercentage: Double {
        let ordered = Double(truncating: quantityOrdered as NSNumber)
        guard ordered > 0 else { return 0 }
        let variance = Double(truncating: variance as NSNumber)
        return (variance / ordered) * 100
    }
    
    init(
        id: String = UUID().uuidString,
        ingredientName: String,
        quantityOrdered: Decimal,
        quantityReceived: Decimal,
        unit: String,
        hasDiscrepancy: Bool = false,
        discrepancyNotes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.quantityOrdered = quantityOrdered
        self.quantityReceived = quantityReceived
        self.unit = unit
        self.hasDiscrepancy = hasDiscrepancy || (quantityOrdered != quantityReceived)
        self.discrepancyNotes = discrepancyNotes
    }
}

// MARK: - Extensions

extension Supplier {
    /// Calculate average delivery time
    func averageDeliveryTime() -> Int? {
        let completed = purchaseOrders.filter { 
            $0.status == .delivered && $0.actualDeliveryDate != nil 
        }
        guard !completed.isEmpty else { return nil }
        
        let totalDays = completed.compactMap { order -> Int? in
            guard let actual = order.actualDeliveryDate else { return nil }
            return Calendar.current.dateComponents([.day], from: order.orderDate, to: actual).day
        }.reduce(0, +)
        
        return totalDays / completed.count
    }
    
    /// Calculate on-time delivery rate
    func onTimeDeliveryRate() -> Double {
        let completed = purchaseOrders.filter { $0.status == .delivered }
        guard !completed.isEmpty else { return 0.0 }
        
        let onTime = completed.filter { order in
            guard let expected = order.expectedDeliveryDate,
                  let actual = order.actualDeliveryDate else { return false }
            return actual <= expected
        }.count
        
        return Double(onTime) / Double(completed.count) * 100
    }
}
