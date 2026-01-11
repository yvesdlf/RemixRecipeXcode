import Foundation
import Foundation
import SwiftData

// MARK: - Enhanced Ingredient Model with Costing

@Model
final class Ingredient {
    var name: String
    var quantity: String // Kept as String for recipe context (e.g., "1.5")
    var unit: String
    var category: String?
    
    // NEW: Cost tracking (added for Phase 3)
    var currentCostPerUnit: Decimal? // Current cost per unit
    var lastCostUpdate: Date?
    
    // NEW: Notes and allergens
    var allergens: [String]? // e.g., ["dairy", "nuts", "gluten"]
    var notes: String?

    init(
        name: String, 
        quantity: String, 
        unit: String, 
        category: String? = nil,
        currentCostPerUnit: Decimal? = nil,
        allergens: [String]? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.currentCostPerUnit = currentCostPerUnit
        self.lastCostUpdate = currentCostPerUnit != nil ? Date() : nil
        self.allergens = allergens
        self.notes = notes
    }
    
    // Computed: Calculate line cost for this ingredient in recipe
    var lineCost: Decimal {
        guard let cost = currentCostPerUnit,
              let qty = Decimal(string: quantity) else { return 0 }
        return qty * cost
    }
}

// MARK: - Enhanced Recipe Model with Costing

@Model
final class Recipe {
    @Attribute(.unique) var id: String
    var name: String
    var descriptionText: String
    var course: String
    var cuisine: String
    var portionSize: String
    var prepTime: String
    var cookTime: String
    var ingredients: [Ingredient]
    var method: [String]
    var plating: [String]
    var chefNotes: String?
    var category: String
    
    // NEW: Costing & Financial tracking
    var sellingPrice: Decimal? // Menu price
    var targetFoodCostPercentage: Double? // e.g., 30.0 = 30%
    var lastCostCalculation: Date?
    
    // NEW: Production tracking
    var totalProductionCount: Int // How many times this recipe was made
    var lastProducedDate: Date?
    
    // NEW: Menu & Display
    var isActive: Bool // Is this on the menu?
    var menuCategory: String? // e.g., "Appetizers", "Mains", "Desserts"
    var imageURL: String? // Photo of the dish
    var allergens: [String]? // Computed or manually entered

    init(
        id: String,
        name: String,
        descriptionText: String,
        course: String,
        cuisine: String,
        portionSize: String,
        prepTime: String,
        cookTime: String,
        ingredients: [Ingredient],
        method: [String],
        plating: [String],
        chefNotes: String? = nil,
        category: String,
        sellingPrice: Decimal? = nil,
        targetFoodCostPercentage: Double? = 30.0,
        isActive: Bool = true,
        menuCategory: String? = nil
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.course = course
        self.cuisine = cuisine
        self.portionSize = portionSize
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.ingredients = ingredients
        self.method = method
        self.plating = plating
        self.chefNotes = chefNotes
        self.category = category
        self.sellingPrice = sellingPrice
        self.targetFoodCostPercentage = targetFoodCostPercentage
        self.totalProductionCount = 0
        self.isActive = isActive
        self.menuCategory = menuCategory
    }
    
    // MARK: - Computed Properties
    
    /// Calculate total recipe cost from ingredient costs
    var totalCost: Decimal {
        ingredients.reduce(0) { $0 + $1.lineCost }
    }
    
    /// Calculate cost per portion (if portionSize is a number)
    var costPerPortion: Decimal {
        // Try to extract portion count from portionSize string
        // e.g., "6 servings" -> 6, "1 plate" -> 1
        let portions = parsePortionCount(from: portionSize) ?? 1
        return portions > 0 ? totalCost / Decimal(portions) : totalCost
    }
    
    /// Actual food cost percentage based on current costs
    var actualFoodCostPercentage: Double? {
        guard let price = sellingPrice, price > 0 else { return nil }
        let cost = Double(truncating: costPerPortion as NSNumber)
        let priceDouble = Double(truncating: price as NSNumber)
        return (cost / priceDouble) * 100
    }
    
    /// Profit margin per portion
    var profitMargin: Decimal? {
        guard let price = sellingPrice else { return nil }
        return price - costPerPortion
    }
    
    /// Profit margin percentage
    var profitMarginPercentage: Double? {
        guard let price = sellingPrice, price > 0, let margin = profitMargin else { return nil }
        let marginDouble = Double(truncating: margin as NSNumber)
        let priceDouble = Double(truncating: price as NSNumber)
        return (marginDouble / priceDouble) * 100
    }
    
    /// Check if within target food cost
    var isWithinTargetCost: Bool {
        guard let target = targetFoodCostPercentage,
              let actual = actualFoodCostPercentage else { return false }
        return actual <= target
    }
    
    /// Get all allergens from ingredients
    var allAllergens: [String] {
        var allergenSet = Set<String>()
        for ingredient in ingredients {
            if let ingredientAllergens = ingredient.allergens {
                allergenSet.formUnion(ingredientAllergens)
            }
        }
        // Add manually entered allergens if any
        if let recipeAllergens = allergens {
            allergenSet.formUnion(recipeAllergens)
        }
        return Array(allergenSet).sorted()
    }
    
    // MARK: - Helper Functions
    
    private func parsePortionCount(from portionSize: String) -> Int? {
        // Extract first number from portion size string
        let numbers = portionSize.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        return Int(numbers)
    }
    
    /// Mark recipe as produced (for inventory depletion)
    func recordProduction(quantity: Int = 1) {
        totalProductionCount += quantity
        lastProducedDate = Date()
    }
}

// MARK: - Category Helper Functions
let INGREDIENT_CATEGORIES: [String] = [
    "BEEF","BREAD & OTHER","CAVIAR","CHICKEN","CRESS","DAIRY & EGGS","DRY","DUCK","FISH","FRUIT","HERBS","JAPANESE","PERUVIAN","KOREAN","BALINESE","LAMB","MOLLUSC","PORK","SHELLFISH","SPICES","TRUFFLE","VEGETABLE","OIL / VINEGAR"
]

// Basic category guesser adapted from TS (simplified for now)
func mapIngredientCategory(_ name: String) -> String {
    let lower = name.lowercased()
    func m(_ pattern: String) -> Bool { lower.range(of: pattern, options: .regularExpression) != nil }
    if m("beef|wagyu|ribeye|tenderloin|sirloin|brisket|short rib|ox|oxtail") { return "BEEF" }
    if m("chicken|poultry") { return "CHICKEN" }
    if m("duck") { return "DUCK" }
    if m("lamb|mutton") { return "LAMB" }
    if m("pork|bacon|pancetta|prosciutto|ham|chorizo|iberico|sausage|guanciale") { return "PORK" }
    if m("salmon|tuna|hamachi|yellowtail|sea bass|sea bream|snapper|halibut|cod|mahi|barramundi|kingfish|mackerel|anchov|sardine|trout|fish") { return "FISH" }
    if m("lobster|crab|shrimp|prawn|langoustine|crayfish|crawfish") { return "SHELLFISH" }
    if m("mussel|clam|oyster|scallop|squid|octopus|calamari|cuttlefish") { return "MOLLUSC" }
    if m("caviar|roe|tobiko|ikura") { return "CAVIAR" }
    if m("truffle") { return "TRUFFLE" }
    if m("milk|cream|butter|cheese|parmesan|pecorino|mascarpone|ricotta|mozzarella|burrata|yogurt|creme fraiche|sour cream|egg|yolk|crème") { return "DAIRY & EGGS" }
    if m("basil|thyme|rosemary|oregano|parsley|cilantro|coriander|mint|dill|chive|tarragon|sage|bay leaf|lemongrass|kaffir|curry leaf|shiso|chervil") { return "HERBS" }
    if m("cress|micro|microgreen") { return "CRESS" }
    if m("pepper|cumin|coriander seed|turmeric|paprika|saffron|cinnamon|cardamom|clove|nutmeg|star anise|fennel seed|mustard seed|chili|cayenne|togarashi|szechuan|yukari|furikake|five spice|garam masala|curry powder|sumac|za'atar|fleur de sel|sea salt|salt") { return "SPICES" }
    if m("miso|dashi|nori|wakame|kombu|bonito|sake|mirin|wasabi|soy sauce|tamari|ponzu|yuzu|matcha|panko|tempura|tofu|edamame|umeboshi|shiitake|enoki|shimeji|ramen|udon|soba") { return "JAPANESE" }
    if m("gochujang|gochugaru|kimchi|doenjang|ssamjang|korean") { return "KOREAN" }
    if m("aji|amarillo|leche de tigre|huancaina|rocoto|quinoa|chicha|cancha|choclo") { return "PERUVIAN" }
    if m("sambal|kecap|bumbu|galangal|candlenut|terasi|belacan|tamarind|pandan|kemangi|kaffir|rendang|satay|gado|tempeh") { return "BALINESE" }
    if m("oil|olive oil|sesame oil|vegetable oil|neutral oil|vinegar|rice vinegar|balsamic|sherry vinegar") { return "OIL / VINEGAR" }
    if m("apple|pear|lemon|lime|orange|grapefruit|yuzu|passion fruit|mango|papaya|pineapple|banana|berry|strawberry|raspberry|blueberry|blackberry|fig|grape|melon|watermelon|coconut|pomegranate|cherry|peach|apricot|plum|kiwi|avocado|tomato") { return "FRUIT" }
    if m("onion|garlic|shallot|leek|celery|carrot|potato|sweet potato|radish|turnip|beet|cabbage|lettuce|spinach|kale|chard|arugula|rocket|asparagus|broccoli|cauliflower|zucchini|courgette|eggplant|aubergine|pepper|capsicum|cucumber|squash|pumpkin|corn|pea|bean|edamame|sprout|artichoke|fennel|bok choy|pak choi|daikon|ginger|galangal|green bean|snow pea|snap pea|shiitake|mushroom|portobello|cremini|button mushroom|oyster mushroom|chanterelle|porcini|morel") { return "VEGETABLE" }
    if m("bread|brioche|baguette|ciabatta|focaccia|toast|crouton|panko|flour|rice|pasta|noodle|wonton|gyoza|dumpling|tortilla|wrap|cracker|chip|crisp") { return "BREAD & OTHER" }
    if m("sugar|honey|maple|syrup|stock|broth|sauce|paste|jam|jelly|preserve|dried|powder|starch|cornstarch|gelatin|agar|yeast|baking") { return "DRY" }
    return "DRY"
}
