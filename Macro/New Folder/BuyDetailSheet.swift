//
//  BuyDetailSheet.swift
//  Macro
//
//  Created by Ghala Alsalem on 02/06/2026.
//


import SwiftUI
import SwiftData

struct BuyDetailSheet: View {
    let symbol: String

    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Int = 1
    @State private var priceText: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var priceFetchDone = false   // true once fetch finishes (success or fail)
    @State private var didAdd = false

    // Live price from the cache (fetched on appear).
    private var livePrice: Double? {
        store.livePrice(for: symbol)
    }

    // The price actually used: whatever the user typed, else live.
    private var effectivePrice: Double {
        Double(priceText) ?? livePrice ?? 0
    }

    private var totalCost: Double {
        effectivePrice * Double(quantity)
    }

    private var canConfirm: Bool {
        effectivePrice > 0 && quantity > 0
    }

    var body: some View {
        ZStack {
            Color("baige").ignoresSafeArea()
            if didAdd {
                confirmationView
            } else {
                buyView
            }
        }
        .task {
            // Fetch the live price; prefill the field if it arrives.
            await store.refreshLivePrices(for: [symbol])
            if let p = store.livePrice(for: symbol), priceText.isEmpty {
                priceText = String(format: "%.2f", p)
            }
            priceFetchDone = true
        }
    }

    // MARK: - Buy screen
    private var buyView: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack {
                Text(store.getReadableName(for: symbol))
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

            // Live price reference
            HStack {
                Text(lang.t("buy.livePrice"))
                    .font(.system(size: 14))
                    .foregroundColor(Color("brown").opacity(0.6))
                Spacer()
                Text(livePrice != nil
                     ? String(format: "%.2f %@", livePrice!, lang.t("unit.sar"))
                     : (priceFetchDone ? lang.t("buy.priceUnavailable") : lang.t("buy.loadingPrice")))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))
            }
            .padding(20)
            .background(Color("white").opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Quantity
            VStack(alignment: .leading, spacing: 12) {
                Text(lang.t("buy.quantity"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))

                HStack(spacing: 20) {
                    Button { if quantity > 1 { quantity -= 1 } } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(quantity > 1 ? Color("light brown") : Color("brown").opacity(0.2))
                    }
                    Text("\(quantity)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                        .frame(minWidth: 50)
                    Button { quantity += 1 } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color("light brown"))
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Price per share (editable)
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t("buy.pricePerShare"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))
                HStack {
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("brown"))
                    Text(lang.t("unit.sar"))
                        .font(.system(size: 14))
                        .foregroundColor(Color("brown").opacity(0.5))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color("white").opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Purchase date
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t("buy.date"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))
                DatePicker("", selection: $purchaseDate,
                           in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.locale, lang.current.locale)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Total cost preview
            HStack {
                Text(lang.t("buy.totalCost"))
                    .font(.system(size: 14))
                    .foregroundColor(Color("brown").opacity(0.7))
                Spacer()
                Text(String(format: "%.0f %@", totalCost, lang.t("unit.sar")))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("brown"))
            }
            .padding(16)
            .background(Color("white").opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Confirm button
            Button {
                performBuy()
            } label: {
                Text(canConfirm
                     ? String(format: quantity > 1 ? lang.t("buy.confirm") : lang.t("buy.confirmOne"), quantity)
                     : lang.t("buy.enterPrice"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canConfirm ? Color("light brown") : Color("brown").opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canConfirm)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Confirmation
    private var confirmationView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Color("dark green"))
            Text(lang.t("buy.added"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("brown"))
            Text(String(format: lang.t("buy.addedBody"),
                        quantity, store.getReadableName(for: symbol),
                        effectivePrice, lang.t("unit.sar")))
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("brown").opacity(0.6))
                .padding(.horizontal, 40)
            Spacer()
            Button { dismiss() } label: {
                Text(lang.t("common.done"))
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

    // MARK: - Buy action
    private func performBuy() {
        guard canConfirm else { return }
        // Make sure the symbol is in the live cache for future valuation.
        Task { _ = await store.addStock(symbol: symbol) }

        let buy = Transaction(
            symbol: symbol,
            type: .buy,
            quantity: quantity,
            pricePerShare: effectivePrice,
            date: purchaseDate
        )
        modelContext.insert(buy)
        try? modelContext.save()

        withAnimation(.spring(response: 0.4)) { didAdd = true }
    }
}
