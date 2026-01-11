import SwiftUI

struct CreateIngredient: Identifiable, Hashable {
    let id: UUID
    var name: String
    var quantity: String
    var unit: String
    var cost: String
}

struct CreateRecipeView: View {
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var yield: String = ""
    @State private var items: [CreateIngredient] = [.init(id: UUID(), name: "", quantity: "", unit: "", cost: "")]

    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Recipe Name", text: $title)
                TextField("Yield (servings)", text: $yield)
                TextField("Description", text: $description, axis: .vertical)
            }
            Section("Ingredients") {
                ForEach($items) { $item in
                    HStack {
                        TextField("Name", text: $item.name)
                        TextField("Qty", text: $item.quantity)
                        TextField("Unit", text: $item.unit)
                        TextField("Cost", text: $item.cost)
                    }
                }
                Button("Add Ingredient") {
                    items.append(.init(id: UUID(), name: "", quantity: "", unit: "", cost: ""))
                }
                .disabled(items.count > 50)
            }
            Section {
                Button("Save Recipe") {}
            }
        }
        .navigationTitle("Create Recipe")
    }
}

#Preview {
    NavigationStack { CreateRecipeView() }
}
