import SwiftUI

struct SupplierItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var contactName: String
    var phone: String
    var email: String
}

struct SuppliersView: View {
    @State private var suppliers: [SupplierItem] = []
    @State private var name = ""
    @State private var contact = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var editingSupplier: SupplierItem?

    var body: some View {
        Form {
            Section(editingSupplier == nil ? "Add New Supplier" : "Edit Supplier") {
                TextField("Supplier Name", text: $name)
                TextField("Contact Name", text: $contact)
                TextField("Phone", text: $phone)
                TextField("Email", text: $email)
                HStack {
                    Button(editingSupplier == nil ? "Add Supplier" : "Save Changes") {
                        guard !name.isEmpty else { return }
                        if let edit = editingSupplier,
                           let index = suppliers.firstIndex(where: { $0.id == edit.id }) {
                            suppliers[index].name = name
                            suppliers[index].contactName = contact
                            suppliers[index].phone = phone
                            suppliers[index].email = email
                        } else {
                            suppliers.append(.init(id: UUID(), name: name, contactName: contact, phone: phone, email: email))
                        }
                        clearForm()
                    }
                    .buttonStyle(.borderedProminent)

                    if editingSupplier != nil {
                        Button("Cancel") {
                            clearForm()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section("Suppliers") {
                if suppliers.isEmpty {
                    Text("No suppliers added yet.").foregroundStyle(.secondary)
                }
                ForEach(suppliers) { s in
                    VStack(alignment: .leading) {
                        Text(s.name).bold()
                        Text("Contact: \(s.contactName)")
                            .foregroundStyle(.secondary)
                        Text("Phone: \(s.phone)")
                            .foregroundStyle(.secondary)
                        Text("Email: \(s.email)")
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Edit") {
                                editingSupplier = s
                                name = s.name
                                contact = s.contactName
                                phone = s.phone
                                email = s.email
                            }
                            .buttonStyle(.bordered)

                            Button("Delete") {
                                suppliers.removeAll { $0.id == s.id }
                                if editingSupplier?.id == s.id {
                                    clearForm()
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { idx in suppliers.remove(atOffsets: idx) }
            }
        }
        .navigationTitle("Suppliers")
    }

    private func clearForm() {
        name = ""
        contact = ""
        phone = ""
        email = ""
        editingSupplier = nil
    }
}

#Preview {
    NavigationStack { SuppliersView() }
}
