import SwiftUI
import UIKit

struct PinpadView: View {
    @Binding var pin: String
    let maxDigits: Int
    let instructions: String?
    var onConfirm: (() -> Void)?

    @State private var rotation: Double = 0
    @State private var lastSelectedNumber: Int = -1
    @State private var lastDragLocation: CGPoint = .zero
    @State private var digitCount: Int = 0

    private let dialSize: CGFloat = 340
    private let numberCount = 100
    private let anglePerNumber: Double = 360.0 / 100.0
    private let numberRadius: CGFloat = 340 * 0.35

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
                        .fill(digitCount > i ? Color.themeAccent : Color.themeSurface2)
                        .frame(width: 14, height: 14)
                        .animation(.easeInOut(duration: 0.2), value: digitCount)
                }
            }
            .padding(.vertical, 8)

            // Safe dial
            ZStack {
                // Outer ring (metallic look)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.35, blue: 0.38),
                                Color(red: 0.22, green: 0.22, blue: 0.25),
                                Color(red: 0.15, green: 0.15, blue: 0.18)
                            ]),
                            center: .center,
                            startRadius: dialSize * 0.35,
                            endRadius: dialSize * 0.5
                        )
                    )
                    .frame(width: dialSize, height: dialSize)
                    .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)

                // Inner ring groove
                Circle()
                    .stroke(Color.black.opacity(0.4), lineWidth: 2)
                    .frame(width: dialSize * 0.85, height: dialSize * 0.85)

                // Rotating number ring
                ZStack {
                    // Tick marks for every number (1-100)
                    ForEach(0..<numberCount, id: \.self) { i in
                        let angle = Double(i) * anglePerNumber - 90 + rotation
                        let isMajor = i % 10 == 0
                        let isMid = i % 5 == 0
                        Rectangle()
                            .fill(isMajor ? Color.white.opacity(0.6) : (isMid ? Color.white.opacity(0.35) : Color.white.opacity(0.15)))
                            .frame(
                                width: isMajor ? 2 : 1,
                                height: isMajor ? 14 : (isMid ? 10 : 6)
                            )
                            .offset(y: -dialSize * 0.44)
                            .rotationEffect(.degrees(angle + 90))
                    }

                    // Number labels — every 10th
                    ForEach(0..<numberCount, id: \.self) { i in
                        let angle = Double(i) * anglePerNumber - 90 + rotation

                        if i % 10 == 0 {
                            let displayNum = i == 0 ? 100 : i
                            Text("\(displayNum)")
                                .font(.custom("Palatino", size: 13))
                                .foregroundColor(Color.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.4), radius: 1)
                                .offset(
                                    x: numberRadius * cos(angle * .pi / 180),
                                    y: numberRadius * sin(angle * .pi / 180)
                                )
                        }
                    }
                }
                .frame(width: dialSize, height: dialSize)
                .clipShape(Circle())

                // Pointer triangle — fixed, points DOWN at the number ring
                Path { path in
                    let cx = dialSize / 2
                    let tipY = dialSize / 2 - numberRadius + 14
                    path.move(to: CGPoint(x: cx, y: tipY))
                    path.addLine(to: CGPoint(x: cx - 6, y: tipY - 22))
                    path.addLine(to: CGPoint(x: cx + 6, y: tipY - 22))
                    path.closeSubpath()
                }
                .fill(Color.themeAccent)
                .shadow(color: .themeAccent.opacity(0.5), radius: 4)

                // Center hub
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.3, green: 0.3, blue: 0.33),
                                Color(red: 0.18, green: 0.18, blue: 0.21)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                // Selected number in center
                Text(currentNumber > 0 ? "\(currentNumber)" : "100")
                    .font(.custom("Palatino", size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let center = CGPoint(x: dialSize / 2, y: dialSize / 2)

                        if lastDragLocation == .zero {
                            lastDragLocation = value.location
                            return
                        }

                        let angle = atan2(
                            value.location.y - center.y,
                            value.location.x - center.x
                        ) * 180 / .pi

                        let prevAngle = atan2(
                            lastDragLocation.y - center.y,
                            lastDragLocation.x - center.x
                        ) * 180 / .pi

                        var delta = angle - prevAngle
                        if delta > 180 { delta -= 360 }
                        if delta < -180 { delta += 360 }

                        rotation += delta
                        lastDragLocation = value.location

                        let newNum = currentNumber
                        if newNum != lastSelectedNumber {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            lastSelectedNumber = newNum
                        }
                    }
                    .onEnded { _ in
                        lastDragLocation = .zero
                        if digitCount < maxDigits && currentNumber >= 0 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            let num = currentNumber == 0 ? 100 : currentNumber
                            pin += "\(num)"
                            digitCount += 1
                            lastSelectedNumber = -1
                            if digitCount == maxDigits {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onConfirm?()
                                }
                            }
                        }
                        snapToNearest()
                    }
            )

            // Backspace button
            HStack {
                Spacer()
                Button {
                    if digitCount > 0 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let num = currentNumber == 0 ? 100 : currentNumber
                        let numStr = "\(num)"
                        if pin.hasSuffix(numStr) {
                            pin = String(pin.dropLast(numStr.count))
                        } else {
                            pin = String(pin.dropLast())
                        }
                        digitCount = max(0, digitCount - 1)
                    }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20))
                        .foregroundColor(digitCount == 0 ? .clear : .themeMuted)
                        .frame(width: 44, height: 44)
                }
                .disabled(digitCount == 0)
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private var currentNumber: Int {
        var normalized = rotation.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        let index = Int(normalized / anglePerNumber + 0.5) % numberCount
        return index
    }

    private func snapToNearest() {
        let num = currentNumber
        let targetRotation = Double(num) * anglePerNumber
        var diff = targetRotation - rotation
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {
            rotation += diff
        }
        lastSelectedNumber = -1
    }
}
