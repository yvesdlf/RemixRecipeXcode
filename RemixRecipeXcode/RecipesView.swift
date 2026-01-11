import SwiftUI
import SwiftData

// Legacy mock recipe struct (deprecated - use SwiftData Recipe model instead)
struct MockRecipe: Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var cuisine: String
    var course: String
}

let mockRecipes: [MockRecipe] = [
    MockRecipe(id: UUID(), name: "Beef Bourguignon", description: "Classic French stew", cuisine: "French", course: "Mains"),
    MockRecipe(id: UUID(), name: "Tuna Tartare", description: "Fresh and zesty", cuisine: "Japanese", course: "Appetizers"),
    MockRecipe(id: UUID(), name: "Chocolate Fondant", description: "Lava cake dessert", cuisine: "Global", course: "Desserts")
]

struct RecipesView: View {
    @Query private var recipes: [Recipe]
    @State private var search: String = ""
    @State private var selectedRecipe: Recipe?

    var filtered: [Recipe] {
        guard !search.isEmpty else { return recipes }
        return recipes.filter { 
            $0.name.localizedCaseInsensitiveContains(search) || 
            $0.descriptionText.localizedCaseInsensitiveContains(search) || 
            $0.cuisine.localizedCaseInsensitiveContains(search) 
        }
    }

    var body: some View {
        List(filtered) { recipe in
            NavigationLink(value: recipe) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                    Text(recipe.descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Label(recipe.cuisine, systemImage: "globe")
                        Label(recipe.course, systemImage: "fork.knife")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic))
        .navigationTitle("Recipes")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailViewSwiftData(recipe: recipe)
        }
        .overlay {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "No Recipes",
                    systemImage: "book.closed",
                    description: Text("Add your first recipe to get started")
                )
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    
    NavigationStack {
        RecipesView()
    }
    .modelContainer(container)
}
