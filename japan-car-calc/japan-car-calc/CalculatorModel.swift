import Foundation
import Combine
import AppKit

class CalculatorModel: ObservableObject {
    @Published var priceYen: String = ""
    @Published var deliveryCost: String = "500"
    @Published var markupPercent: String = "5"
    @Published var exchangeRate: Double?
    @Published var isLoading: Bool = true
    @Published var error: String = ""
    @Published var basePrice: String = ""
    @Published var finalPrice: String = ""
    @Published var basePriceWithMarkup: String = ""
    @Published var finalPriceWithMarkup: String = ""
    @Published var priceYenWithMarkup: String = ""
    @Published var copied: Bool = false
    @Published var copiedWithMarkup: Bool = false
    @Published var copiedYenWithMarkup: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchExchangeRate() {
        isLoading = true
        error = ""
        
        // Пробуем первый API
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=JPY&to=EUR") else {
            trySecondAPI()
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: FrankfurterResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.trySecondAPI()
                }
            } receiveValue: { [weak self] response in
                self?.exchangeRate = response.rates["EUR"]
                self?.isLoading = false
                self?.calculate()
            }
            .store(in: &cancellables)
    }
    
    private func trySecondAPI() {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/JPY") else {
            useFallbackRate()
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.useFallbackRate()
                }
            } receiveValue: { [weak self] response in
                self?.exchangeRate = response.rates["EUR"]
                self?.isLoading = false
                self?.calculate()
            }
            .store(in: &cancellables)
    }
    
    private func useFallbackRate() {
        exchangeRate = 0.0062
        error = "Используется примерный курс валют"
        isLoading = false
        calculate()
    }
    
    func calculate() {
        guard let rate = exchangeRate,
              let yenPrice = Double(priceYen.replacingOccurrences(of: ",", with: "")),
              let delivery = Double(deliveryCost.replacingOccurrences(of: ",", with: "")) else {
            finalPrice = ""
            basePrice = ""
            finalPriceWithMarkup = ""
            basePriceWithMarkup = ""
            priceYenWithMarkup = ""
            return
        }
        
        let markup = Double(markupPercent.replacingOccurrences(of: ",", with: "")) ?? 0
        
        // Формула: (стоимость в тысячах йен + доставка) * 1000 * курс * 1.3 + 550
        let yenTotal = (yenPrice + delivery) * 1000
        let euroFromYen = yenTotal * rate
        basePrice = String(format: "%.2f", euroFromYen)
        
        let total = euroFromYen * 1.3 + 550
        finalPrice = String(format: "%.2f", total)
        
        // Расчёт с наценкой
        let yenPriceWithMarkup = yenPrice * (1 + markup / 100)
        priceYenWithMarkup = String(format: "%.0f", yenPriceWithMarkup)
        let yenTotalWithMarkup = (yenPriceWithMarkup + delivery) * 1000
        let euroFromYenWithMarkup = yenTotalWithMarkup * rate
        basePriceWithMarkup = String(format: "%.2f", euroFromYenWithMarkup)
        
        let totalWithMarkup = euroFromYenWithMarkup * 1.3 + 550
        finalPriceWithMarkup = String(format: "%.2f", totalWithMarkup)
    }
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(finalPrice, forType: .string)
        
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.copied = false
        }
    }
    
    func copyWithMarkupToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(finalPriceWithMarkup, forType: .string)
        
        copiedWithMarkup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.copiedWithMarkup = false
        }
    }
    
    func copyYenWithMarkupToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(priceYenWithMarkup, forType: .string)
        
        copiedYenWithMarkup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.copiedYenWithMarkup = false
        }
    }
}

struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
}

struct FrankfurterResponse: Codable {
    let rates: [String: Double]
}
