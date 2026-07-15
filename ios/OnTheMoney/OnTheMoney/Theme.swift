import SwiftUI

extension Color {
    static let themeBackground = Color(light: Color(red: 0.96, green: 0.96, blue: 0.96),
                                        dark: Color(red: 0.04, green: 0.04, blue: 0.04))
    static let themeSurface = Color(light: Color.white,
                                    dark: Color(red: 0.1, green: 0.1, blue: 0.1))
    static let themeSurface2 = Color(light: Color(red: 0.92, green: 0.92, blue: 0.92),
                                     dark: Color(red: 0.15, green: 0.13, blue: 0.16))
    static let themeText = Color(light: Color(red: 0.12, green: 0.12, blue: 0.12),
                                 dark: Color(red: 0.88, green: 0.85, blue: 0.80))
    static let themeAccent = Color(light: .black,
                                   dark: .white)
    static let themeSecondaryAccent = Color(light: Color(red: 0.60, green: 0.15, blue: 0.65),
                                            dark: Color(red: 0.29, green: 0.06, blue: 0.31))
    static let themeMuted = Color(light: Color(red: 0.45, green: 0.45, blue: 0.45),
                                  dark: Color(red: 0.55, green: 0.53, blue: 0.51))
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}
