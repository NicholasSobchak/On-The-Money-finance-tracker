import SwiftUI

enum PadKey: Identifiable, Hashable {
    case number(Int)
    case delete
    case empty
    case blank
    
    var id: String {
        switch self {
        case .number(let n):
            return String(n)
        case .delete:
            return "delete"
        case .empty:
            return "empty"
        case .blank:
            return "blank"
        }
    }
}

struct PinpadView: View {
    @Binding var pin: String
    let maxDigits: Int
    let instructions: String?
    var onConfirm: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            if let instructions = instructions {
                Text(instructions)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.themeMuted)
                    .multilineTextAlignment(.center)
            }

            // PIN display dots
            HStack(spacing: 12) {
                ForEach(0..<maxDigits, id: \.self) { i in
                    Circle()
                        .fill(pin.count > i ? Color.themeAccent : Color.themeSurface2)
                        .frame(width: 16, height: 16)
                        .animation(.easeInOut(duration: 0.2), value: pin.count)
                }
            }
            .padding(.vertical, 12)

            // Numpad
            VStack(spacing: 12) {
                numpadRow([.number(1), .number(2), .number(3)])
                numpadRow([.number(4), .number(5), .number(6)])
                numpadRow([.number(7), .number(8), .number(9)])
                numpadRow([.blank, .number(0), .delete])
            }
            .padding(.top, 12)
        }
    }

    private func numpadRow(_ row: [PadKey]) -> some View {
        HStack(spacing: 12) {
            ForEach(row, id: \.self) { key in
                switch key {
                case .number(let num):
                    numpadButton("\(num)") {
                        if pin.count < maxDigits {
                            pin += "\(num)"
                        }
                    }
                case .delete:
                    numpadButton("⌫") {
                        if !pin.isEmpty {
                            pin.removeLast()
                        }
                    }
                case .blank:
                    // Blank disabled button for alignment
                    Text("")
                        .font(.custom("Palatino", size: 24))
                        .frame(width: 64, height: 64)
                        .background(Color.black)
                        .cornerRadius(12)
                case .empty:
                    Spacer()
                }
            }
        }
    }

    private func numpadButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.custom("Palatino", size: 24))
                .foregroundColor(.themeText)
                .frame(width: 64, height: 64)
                .background(Color.themeSurface2)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
