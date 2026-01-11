import SwiftUI
import SwiftData

struct AppHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Operations") {
                    NavigationLink {
                        RecipesView()
                    } label: {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    
                    NavigationLink {
                        CreateRecipeView()
                    } label: {
                        Label("Create Recipe", systemImage: "plus.circle.fill")
                    }
                }
                
                Section("Management") {
                    NavigationLink {
                        IngredientsView()
                    } label: {
                        Label("Ingredients", systemImage: "carrot.fill")
                    }
                    
                    NavigationLink {
                        SuppliersView()
                    } label: {
                        Label("Suppliers", systemImage: "person.3.fill")
                    }
                    
                    NavigationLink {
                        PriceListsView()
                    } label: {
                        Label("Price Lists", systemImage: "list.bullet.rectangle")
                    }
                }
                
                Section("Data") {
                    NavigationLink {
                        UploadView()
                    } label: {
                        Label("Upload", systemImage: "arrow.up.doc.fill")
                    }
                }
                
                Section("New Features") {
                    NavigationLink {
                        InventoryListView()
                    } label: {
                        Label("Inventory", systemImage: "tray.fill")
                    }
                    NavigationLink {
                        LocationsView()
                    } label: {
                        Label("Locations", systemImage: "mappin.circle.fill")
                    }
                }
            }
            .navigationTitle("Glass Kitchen Master")
        }
    }
}

#Preview {
    AppHubView()
        .modelContainer(for: Recipe.self)
}


