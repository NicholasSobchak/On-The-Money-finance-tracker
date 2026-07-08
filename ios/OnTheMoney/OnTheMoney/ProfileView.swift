import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Coming Soon")
                    .font(.custom("Palatino", size: 20))
                    .foregroundColor(.themeMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground)
        }
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
