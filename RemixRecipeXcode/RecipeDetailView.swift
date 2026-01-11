import SwiftUI
import SwiftData

// This view works with the SwiftData Recipe model
@MainActor
struct RecipeDetailViewSwiftData: View {
    let recipe: Recipe // SwiftData @Model Recipe from Models.swift
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic Info
                Text(recipe.name)
                    .font(.largeTitle)
                    .bold()
                
                HStack(spacing: 12) {
                    Label(recipe.cuisine, systemImage: "globe")
                    Label(recipe.course, systemImage: "fork.knife")
                }
                .foregroundStyle(.secondary)
                
                // Description
                Text(recipe.descriptionText)
                    .padding(.top, 8)
                
                // Portion & Times
                GroupBox("Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Portion Size:")
                                .bold()
                            Text(recipe.portionSize)
                        }
                        HStack {
                            Text("Prep Time:")
                                .bold()
                            Text(recipe.prepTime)
                        }
                        HStack {
                            Text("Cook Time:")
                                .bold()
                            Text(recipe.cookTime)
                        }
                    }
                }
                
                // Ingredients
                GroupBox("Ingredients") {
                    ForEach(recipe.ingredients, id: \.name) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text("\(ingredient.quantity) \(ingredient.unit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Method
                if !recipe.method.isEmpty {
                    GroupBox("Method") {
                        ForEach(Array(recipe.method.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .bold()
                                Text(step)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                
                // Plating
                if !recipe.plating.isEmpty {
                    GroupBox("Plating") {
                        ForEach(Array(recipe.plating.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .bold()
                                Text(instruction)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                
                // Chef Notes
                if let notes = recipe.chefNotes, !notes.isEmpty {
                    GroupBox("Chef's Notes") {
                        Text(notes)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    
    // Create sample recipe
    let sampleRecipe = Recipe(
        id: UUID().uuidString,
        name: "Beef Bourguignon",
        descriptionText: "Classic French braised beef dish",
        course: "Main Course",
        cuisine: "French",
        portionSize: "6 servings",
        prepTime: "30 minutes",
        cookTime: "3 hours",
        ingredients: [
            Ingredient(name: "Beef Chuck", quantity: "1.5", unit: "kg", category: "BEEF"),
            Ingredient(name: "Red Wine", quantity: "750", unit: "ml", category: "DRY")
        ],
        method: ["Brown the beef", "Add wine and braise"],
        plating: ["Serve in deep bowls"],
        chefNotes: "Use good quality wine",
        category: "Main"
    )
    
    return NavigationStack {
        RecipeDetailViewSwiftData(recipe: sampleRecipe)
    }
    .modelContainer(container)
}
