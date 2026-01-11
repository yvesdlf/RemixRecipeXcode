import SwiftUI

struct IndexView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Glass Kitchen Master V.1")
                    .font(.largeTitle).bold()
                Text("Your Complete Kitchen Management Solution")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack { IndexView() }
}
