import SwiftUI

struct IngredientItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var usedInCount: Int
}

let mockIngredients: [IngredientItem] = [
    .init(name: "Beef", usedInCount: 1),
    .init(name: "Tuna", usedInCount: 1),
    .init(name: "Chocolate", usedInCount: 1)
]

struct IngredientsView: View {
    @State private var search: String = ""

    var filtered: [IngredientItem] {
        guard !search.isEmpty else { return mockIngredients }
        return mockIngredients.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List(filtered) { ing in
            HStack {
                Text(ing.name)
                Spacer()
                Text("\(ing.usedInCount) recipes")
                    .foregroundStyle(.secondary)
            }
        }
        .searchable(text: $search)
        .navigationTitle("Ingredients")
    }
}

#Preview {
    NavigationStack { IngredientsView() }
}
