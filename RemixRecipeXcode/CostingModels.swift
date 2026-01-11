import Foundation
import SwiftData

// MARK: - Phase 3: Costing & Accounting Models

/// Tracks historical recipe costs over time
@Model
final class RecipeCostHistory {
    @Attribute(.unique) var id: String
    var recipeId: String
    var recipeName: String
    var date: Date
    var totalCost: Decimal
    var portionCost: Decimal // Cost per serving
    var sellingPrice: Decimal?
    var targetFoodCostPercentage: Double?
    var actualFoodCostPercentage: Double?
    var ingredientCostsJSON: String? // JSON breakdown of individual ingredient costs
    var portionSize: String
    var notes: String?
    
    // Computed
    var grossProfit: Decimal? {
        guard let price = sellingPrice else { return nil }
        return price - portionCost
    }
    
    var profitMargin: Double? {
        guard let price = sellingPrice, price > 0 else { return nil }
        let profit = Double(truncating: grossProfit! as NSNumber)
        let priceDouble = Double(truncating: price as NSNumber)
        return (profit / priceDouble) * 100
    }
    
    var isWithinTarget: Bool {
        guard let target = targetFoodCostPercentage,
              let actual = actualFoodCostPercentage else { return false }
        return actual <= target
    }
    
    init(
        id: String = UUID().uuidString,
        recipeId: String,
        recipeName: String,
        date: Date = Date(),
        totalCost: Decimal,
        portionCost: Decimal,
        sellingPrice: Decimal? = nil,
        targetFoodCostPercentage: Double? = nil,
        portionSize: String,
        ingredientCostsJSON: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.date = date
        self.totalCost = totalCost
        self.portionCost = portionCost
        self.sellingPrice = sellingPrice
        self.targetFoodCostPercentage = targetFoodCostPercentage
        self.portionSize = portionSize
        self.ingredientCostsJSON = ingredientCostsJSON
        self.notes = notes
        
        // Calculate actual food cost percentage
        if let price = sellingPrice, price > 0 {
            let costDouble = Double(truncating: portionCost as NSNumber)
            let priceDouble = Double(truncating: price as NSNumber)
            self.actualFoodCostPercentage = (costDouble / priceDouble) * 100
        }
    }
}

/// Financial period tracking (weekly, monthly, quarterly)
@Model
final class FinancialPeriod {
    @Attribute(.unique) var id: String
    var periodType: PeriodType // daily, weekly, monthly, quarterly, yearly
    var startDate: Date
    var endDate: Date
    var totalRevenue: Decimal
    var totalCOGS: Decimal // Cost of Goods Sold
    var totalWasteCost: Decimal
    var totalPurchases: Decimal
    var openingInventoryValue: Decimal
    var closingInventoryValue: Decimal
    var foodCostPercentage: Double
    var targetFoodCostPercentage: Double
    var notes: String?
    
    // Computed
    var grossProfit: Decimal {
        totalRevenue - totalCOGS
    }
    
    var grossProfitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        let profit = Double(truncating: grossProfit as NSNumber)
        let revenue = Double(truncating: totalRevenue as NSNumber)
        return (profit / revenue) * 100
    }
    
    var isOnTarget: Bool {
        foodCostPercentage <= targetFoodCostPercentage
    }
    
    var variance: Double {
        foodCostPercentage - targetFoodCostPercentage
    }
    
    /// Actual COGS calculation: Opening + Purchases - Closing
    var calculatedCOGS: Decimal {
        openingInventoryValue + totalPurchases - closingInventoryValue
    }
    
    init(
        id: String = UUID().uuidString,
        periodType: PeriodType,
        startDate: Date,
        endDate: Date,
        totalRevenue: Decimal = 0,
        openingInventoryValue: Decimal = 0,
        closingInventoryValue: Decimal = 0,
        totalPurchases: Decimal = 0,
        totalWasteCost: Decimal = 0,
        targetFoodCostPercentage: Double = 30.0
    ) {
        self.id = id
        self.periodType = periodType
        self.startDate = startDate
        self.endDate = endDate
        self.totalRevenue = totalRevenue
        self.openingInventoryValue = openingInventoryValue
        self.closingInventoryValue = closingInventoryValue
        self.totalPurchases = totalPurchases
        self.totalWasteCost = totalWasteCost
        self.targetFoodCostPercentage = targetFoodCostPercentage
        
        // Calculate COGS
        self.totalCOGS = openingInventoryValue + totalPurchases - closingInventoryValue
        
        // Calculate food cost %
        if totalRevenue > 0 {
            let cogs = Double(truncating: totalCOGS as NSNumber)
            let revenue = Double(truncating: totalRevenue as NSNumber)
            self.foodCostPercentage = (cogs / revenue) * 100
        } else {
            self.foodCostPercentage = 0
        }
    }
}

enum PeriodType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Phase 4: Waste Management Models

/// Waste log entry
@Model
final class WasteLog {
    @Attribute(.unique) var id: String
    var ingredientName: String
    var quantity: Decimal
    var unit: String
    var wasteCategory: WasteCategory
    var wasteReason: String?
    var costImpact: Decimal // Cost of wasted items
    var timestamp: Date
    var locationId: String?
    var loggedBy: String?
    var recipeId: String? // If waste occurred during recipe production
    var notes: String?
    var imageURL: String? // Photo of waste for accountability
    
    init(
        id: String = UUID().uuidString,
        ingredientName: String,
        quantity: Decimal,
        unit: String,
        wasteCategory: WasteCategory,
        wasteReason: String? = nil,
        costImpact: Decimal,
        locationId: String? = nil,
        loggedBy: String? = nil,
        recipeId: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.quantity = quantity
        self.unit = unit
        self.wasteCategory = wasteCategory
        self.wasteReason = wasteReason
        self.costImpact = costImpact
        self.timestamp = Date()
        self.locationId = locationId
        self.loggedBy = loggedBy
        self.recipeId = recipeId
        self.notes = notes
    }
}

enum WasteCategory: String, Codable, CaseIterable {
    case spoilage = "spoilage"
    case prep = "prep"
    case service = "service"
    case overcooking = "overcooking"
    case portionError = "portion_error"
    case expiredStock = "expired_stock"
    case contamination = "contamination"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spoilage: return "Spoilage"
        case .prep: return "Prep Waste"
        case .service: return "Service Waste"
        case .overcooking: return "Overcooking"
        case .portionError: return "Portion Error"
        case .expiredStock: return "Expired Stock"
        case .contamination: return "Contamination"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .spoilage: return "exclamationmark.triangle"
        case .prep: return "scissors"
        case .service: return "fork.knife"
        case .overcooking: return "flame"
        case .portionError: return "chart.bar"
        case .expiredStock: return "calendar.badge.exclamationmark"
        case .contamination: return "xmark.shield"
        case .other: return "questionmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .spoilage: return "red"
        case .prep: return "orange"
        case .service: return "yellow"
        case .overcooking: return "red"
        case .portionError: return "purple"
        case .expiredStock: return "red"
        case .contamination: return "red"
        case .other: return "gray"
        }
    }
}

/// Variance analysis record
@Model
final class VarianceRecord {
    @Attribute(.unique) var id: String
    var ingredientName: String
    var periodStart: Date
    var periodEnd: Date
    var theoreticalUsage: Decimal // Expected usage based on recipes sold
    var actualUsage: Decimal // From inventory transactions
    var variance: Decimal // Difference between theoretical and actual
    var variancePercentage: Double
    var unit: String
    var costImpact: Decimal // Variance * unit cost
    var isAcceptable: Bool // Within acceptable threshold
    var acceptableThreshold: Double // e.g., 5%
    var investigationNotes: String?
    var rootCause: String?
    
    var varianceType: VarianceType {
        if variance > 0 {
            return .overuse
        } else if variance < 0 {
            return .underuse
        } else {
            return .none
        }
    }
    
    init(
        id: String = UUID().uuidString,
        ingredientName: String,
        periodStart: Date,
        periodEnd: Date,
        theoreticalUsage: Decimal,
        actualUsage: Decimal,
        unit: String,
        unitCost: Decimal,
        acceptableThreshold: Double = 5.0,
        investigationNotes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.theoreticalUsage = theoreticalUsage
        self.actualUsage = actualUsage
        self.variance = actualUsage - theoreticalUsage
        self.unit = unit
        self.acceptableThreshold = acceptableThreshold
        self.investigationNotes = investigationNotes
        
        // Calculate variance percentage
        let theoretical = Double(truncating: theoreticalUsage as NSNumber)
        if theoretical > 0 {
            let varianceDouble = Double(truncating: variance as NSNumber)
            self.variancePercentage = abs((varianceDouble / theoretical) * 100)
        } else {
            self.variancePercentage = 0
        }
        
        // Calculate cost impact
        self.costImpact = abs(variance) * unitCost
        
        // Determine if acceptable
        self.isAcceptable = variancePercentage <= acceptableThreshold
    }
}

enum VarianceType: String, Codable {
    case overuse = "overuse"
    case underuse = "underuse"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .overuse: return "Over Usage"
        case .underuse: return "Under Usage"
        case .none: return "No Variance"
        }
    }
    
    var color: String {
        switch self {
        case .overuse: return "red"
        case .underuse: return "blue"
        case .none: return "green"
        }
    }
}

// MARK: - Menu Engineering & Profitability

/// Menu item (links to recipe with sales data)
@Model
final class MenuItem {
    @Attribute(.unique) var id: String
    var recipeId: String
    var recipeName: String
    var menuCategory: String
    var sellingPrice: Decimal
    var costPerPortion: Decimal
    var targetFoodCostPercentage: Double
    var isActive: Bool
    var popularity: Int // Sales count
    var lastSoldDate: Date?
    
    // Computed
    var foodCostPercentage: Double {
        guard sellingPrice > 0 else { return 0 }
        let cost = Double(truncating: costPerPortion as NSNumber)
        let price = Double(truncating: sellingPrice as NSNumber)
        return (cost / price) * 100
    }
    
    var contributionMargin: Decimal {
        sellingPrice - costPerPortion
    }
    
    var profitMargin: Double {
        guard sellingPrice > 0 else { return 0 }
        let margin = Double(truncating: contributionMargin as NSNumber)
        let price = Double(truncating: sellingPrice as NSNumber)
        return (margin / price) * 100
    }
    
    /// Menu engineering classification (Star, Horse, Puzzle, Dog)
    func menuEngineeringClass(avgPopularity: Int, avgMargin: Decimal) -> MenuClass {
        let isPopular = popularity >= avgPopularity
        let isProfitable = contributionMargin >= avgMargin
        
        if isPopular && isProfitable {
            return .star
        } else if isPopular && !isProfitable {
            return .horse
        } else if !isPopular && isProfitable {
            return .puzzle
        } else {
            return .dog
        }
    }
    
    init(
        id: String = UUID().uuidString,
        recipeId: String,
        recipeName: String,
        menuCategory: String,
        sellingPrice: Decimal,
        costPerPortion: Decimal,
        targetFoodCostPercentage: Double = 30.0,
        isActive: Bool = true,
        popularity: Int = 0
    ) {
        self.id = id
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.menuCategory = menuCategory
        self.sellingPrice = sellingPrice
        self.costPerPortion = costPerPortion
        self.targetFoodCostPercentage = targetFoodCostPercentage
        self.isActive = isActive
        self.popularity = popularity
    }
}

enum MenuClass: String, CaseIterable {
    case star = "Star" // High popularity, high profit
    case horse = "Horse" // High popularity, low profit
    case puzzle = "Puzzle" // Low popularity, high profit
    case dog = "Dog" // Low popularity, low profit
    
    var description: String {
        switch self {
        case .star: return "Keep and promote"
        case .horse: return "Increase price or reduce cost"
        case .puzzle: return "Promote or reposition"
        case .dog: return "Consider removing"
        }
    }
    
    var color: String {
        switch self {
        case .star: return "green"
        case .horse: return "yellow"
        case .puzzle: return "blue"
        case .dog: return "red"
        }
    }
}

// MARK: - Extensions

extension WasteLog {
    /// Get total waste cost for a period
    static func totalWasteCost(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) -> Decimal {
        let descriptor = FetchDescriptor<WasteLog>(
            predicate: #Predicate { log in
                log.timestamp >= startDate && log.timestamp <= endDate
            }
        )
        
        guard let logs = try? context.fetch(descriptor) else { return 0 }
        return logs.reduce(0) { $0 + $1.costImpact }
    }
    
    /// Get waste by category for reporting
    static func wasteByCategoryReport(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) -> [WasteCategory: Decimal] {
        let descriptor = FetchDescriptor<WasteLog>(
            predicate: #Predicate { log in
                log.timestamp >= startDate && log.timestamp <= endDate
            }
        )
        
        guard let logs = try? context.fetch(descriptor) else { return [:] }
        
        var report: [WasteCategory: Decimal] = [:]
        for log in logs {
            report[log.wasteCategory, default: 0] += log.costImpact
        }
        return report
    }
}

extension RecipeCostHistory {
    /// Get cost trend for a recipe
    static func costTrend(
        for recipeId: String,
        context: ModelContext
    ) -> [RecipeCostHistory] {
        let descriptor = FetchDescriptor<RecipeCostHistory>(
            predicate: #Predicate { $0.recipeId == recipeId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
