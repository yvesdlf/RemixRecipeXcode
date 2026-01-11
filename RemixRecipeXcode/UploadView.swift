import SwiftUI

struct UploadView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()
                    Text("Upload Recipes")
                        .font(.headline)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                VStack {
                    Image(systemName: "doc.plaintext")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()
                    Text("Upload Price List")
                        .font(.headline)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Upload Data")
    }
}

#Preview {
    NavigationStack {
        UploadView()
    }
}
