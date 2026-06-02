import SwiftUI
import SwiftData

struct HoldingDetailSheet: View {
    let position: PortfolioMath.Position

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // How many shares the user is choosing to sell.
    @State private var sellQuantity: Int = 1
    // Set after a successful sell to show the brick-reward confirmation.
    @State private var lastBricksEarned: Int? = nil
    @State private var didSell = false

    // Live price (nil while loading — we disable selling until it arrives so
    // the realized gain and brick reward are always computed correctly).
    private var livePrice: Double? {
        store.livePrice(for: position.symbol)
    }

    private var currentValue: Double {
        (livePrice ?? position.averageBuyPrice) * Double(position.quantity)
    }

    private var unrealizedGain: Double {
        currentValue - position.costBasis
    }

    // Preview of what THIS sell would realize, at the live price.
    private var previewRealizedGain: Double {
        guard let price = livePrice else { return 0 }
        return (price - position.averageBuyPrice) * Double(sellQuantity)
    }

    private var previewBricks: Int {
        guard previewRealizedGain > 0 else { return 0 }
        return Int(previewRealizedGain / 3.4)
    }

    var body: some View {
        ZStack {
            Color("baige").ignoresSafeArea()

            if didSell {
                confirmationView
            } else {
                sellView
            }
        }
    }

    // MARK: - Sell screen
    private var sellView: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack {
                Text(store.getReadableName(for: position.symbol))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("brown"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color("brown").opacity(0.3))
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // Stat rows
            VStack(spacing: 14) {
                statRow("Shares held", "\(position.quantity)")
                statRow("Average buy price", String(format: "%.2f SAR", position.averageBuyPrice))
                statRow("Current price",
                        livePrice != nil ? String(format: "%.2f SAR", livePrice!) : "Loading…")
                Divider()
                statRow("Current value", String(format: "%.0f SAR", currentValue))
                statRow("Unrealized gain",
                        String(format: "%@%.0f SAR", unrealizedGain >= 0 ? "+" : "", unrealizedGain),
                        color: unrealizedGain >= 0 ? Color("dark green") : Color("burgindy"))
            }
            .padding(20)
            .background(Color("white").opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Quantity selector
            VStack(alignment: .leading, spacing: 12) {
                Text("How many shares to sell?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))

                HStack(spacing: 20) {
                    Button { if sellQuantity > 1 { sellQuantity -= 1 } } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(sellQuantity > 1 ? Color("light brown") : Color("brown").opacity(0.2))
                    }
                    Text("\(sellQuantity)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                        .frame(minWidth: 50)
                    Button { if sellQuantity < position.quantity { sellQuantity += 1 } } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(sellQuantity < position.quantity ? Color("light brown") : Color("brown").opacity(0.2))
                    }
                    Spacer()
                    Button("All") { sellQuantity = position.quantity }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("brown"))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color("white")).clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Live preview of the sale outcome
            VStack(spacing: 6) {
                HStack {
                    Text("Realized gain")
                        .font(.system(size: 14))
                        .foregroundColor(Color("brown").opacity(0.7))
                    Spacer()
                    Text(String(format: "%@%.0f SAR", previewRealizedGain >= 0 ? "+" : "", previewRealizedGain))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(previewRealizedGain >= 0 ? Color("dark green") : Color("burgindy"))
                }
                HStack {
                    Text("Bricks earned")
                        .font(.system(size: 14))
                        .foregroundColor(Color("brown").opacity(0.7))
                    Spacer()
                    HStack(spacing: 4) {
                        Image("brick").resizable().scaledToFit().frame(width: 16, height: 16)
                        Text("+\(previewBricks)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("light brown"))
                    }
                }
            }
            .padding(16)
            .background(Color("white").opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Sell button (disabled until live price is available)
            Button {
                performSell()
            } label: {
                Text(livePrice == nil ? "Loading price…" : "Sell \(sellQuantity) \(sellQuantity > 1 ? "Shares" : "Share")")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(livePrice == nil ? Color("brown").opacity(0.3) : Color("light brown"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(livePrice == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Confirmation screen (after selling)
    private var confirmationView: some View {
        VStack(spacing: 20) {
            Spacer()

            if let earned = lastBricksEarned, earned > 0 {
                Image("brick")
                    .resizable().scaledToFit()
                    .frame(width: 90, height: 90)
                Text("+\(earned)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color("light brown"))
                Text(earned == 1 ? "brick earned!" : "bricks earned!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("brown"))
                Text("Locked in from your profit.\nThey're yours to keep.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("brown").opacity(0.6))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(Color("dark green"))
                Text("Sale complete")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("No bricks this time — they're only earned on a profit.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("brown").opacity(0.6))
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("light brown"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Sell action
    private func performSell() {
        guard let price = livePrice else { return }
        let qty = min(sellQuantity, position.quantity)
        guard qty > 0 else { return }

        let realized = (price - position.averageBuyPrice) * Double(qty)

        // Record the sell as an event-log row, freezing the realized gain.
        let sell = Transaction(
            symbol: position.symbol,
            type: .sell,
            quantity: qty,
            pricePerShare: price,
            realizedGain: realized
        )
        modelContext.insert(sell)
        try? modelContext.save()

        // Award bricks — only adds, only on profit.
        let before = store.brickCount
        store.awardBricks(fromRealizedGain: realized)
        lastBricksEarned = store.brickCount - before

        withAnimation(.spring(response: 0.4)) { didSell = true }
    }

    // MARK: - Helper
    private func statRow(_ label: String, _ value: String, color: Color = Color("brown")) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color("brown").opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
    }
}