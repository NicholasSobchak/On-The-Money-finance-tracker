import SwiftUI

struct PortfolioView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.custom("Palatino", size: 16))
                        .foregroundColor(.themeMuted)
                    Text("$27,200")
                        .font(.custom("Palatino", size: 36))
                        .foregroundColor(.themeText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.top, 24)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground)
        }
    }
}

#Preview {
    PortfolioView()
        .preferredColorScheme(.dark)
}
