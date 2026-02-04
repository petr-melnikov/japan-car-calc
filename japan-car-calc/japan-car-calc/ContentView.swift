import SwiftUI

struct ContentView: View {
    @ObservedObject var model: CalculatorModel

    var body: some View {
        VStack(spacing: 12) {
            Text("🚗 Калькулятор авто")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Стоимость в тысячах йен:")
                    .font(.caption)
                TextField("", text: $model.priceYen)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: model.priceYen) { _ in
                        model.calculate()
                    }
                
                Text("Доставка (тыс. йен):")
                    .font(.caption)
                TextField("", text: $model.deliveryCost)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: model.deliveryCost) { _ in
                        model.calculate()
                    }
                
                Text("Наценка (%):")
                    .font(.caption)
                TextField("", text: $model.markupPercent)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: model.markupPercent) { _ in
                        model.calculate()
                    }
            }
            
            if model.isLoading {
                ProgressView("Загрузка курса...")
                    .font(.caption)
            } else if !model.error.isEmpty {
                Text(model.error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let rate = model.exchangeRate {
                Text("Курс: 1¥ = €\(String(format: "%.6f", rate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !model.finalPrice.isEmpty {
                Divider()
                
                HStack(alignment: .top, spacing: 16) {
                    // Оригинальная стоимость
                    VStack(spacing: 4) {
                        Text("Оригинал")
                            .font(.caption)
                            .fontWeight(.semibold)
                        if !model.basePrice.isEmpty {
                            Text("€\(model.basePrice)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("€\(model.finalPrice)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // С наценкой
                    VStack(spacing: 4) {
                        Text("+\(model.markupPercent)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                        if !model.basePriceWithMarkup.isEmpty {
                            Text("€\(model.basePriceWithMarkup)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("€\(model.finalPriceWithMarkup)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Button(action: {
                    model.copyToClipboard()
                }) {
                    HStack {
                        Image(systemName: model.copied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(model.copied ? "Скопировано!" : "Копировать")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 200)
        .onAppear {
            model.fetchExchangeRate()
        }
    }
}
