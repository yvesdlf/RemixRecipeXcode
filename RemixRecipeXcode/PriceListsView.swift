import SwiftUI

struct PriceIngredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var category: String
    var usedIn: Int
}

let mockPriceIngredients: [PriceIngredient] = [
    .init(name: "Beef Tenderloin", category: "BEEF", usedIn: 1),
    .init(name: "Olive Oil", category: "OIL / VINEGAR", usedIn: 2),
    .init(name: "Chocolate", category: "DESSERTS", usedIn: 1)
]

struct PriceListsView: View {
    var grouped: [String: [PriceIngredient]] {
        Dictionary(grouping: mockPriceIngredients, by: { $0.category })
    }

    var body: some View {
        List {
            ForEach(grouped.keys.sorted(), id: \.self) { key in
                Section(key) {
                    ForEach(grouped[key] ?? []) { ing in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(ing.name)
                                Text("Used in \(ing.usedIn) recipes").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ing.category).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Price Lists")
    }
}

#Preview {
    NavigationStack { PriceListsView() }
}
