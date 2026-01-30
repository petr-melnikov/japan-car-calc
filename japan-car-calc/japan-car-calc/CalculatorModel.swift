import Foundation
import Combine
import AppKit

class CalculatorModel: ObservableObject {
    @Published var priceYen: String = ""
    @Published var deliveryCost: String = "500"
    @Published var exchangeRate: Double?
    @Published var isLoading: Bool = true
    @Published var error: String = ""
    @Published var basePrice: String = ""
    @Published var finalPrice: String = ""
    @Published var copied: Bool = false
    
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
            return
        }
        
        // Формула: (стоимость в тысячах йен + доставка) * 1000 * курс * 1.3 + 550
        let yenTotal = (yenPrice + delivery) * 1000
        let euroFromYen = yenTotal * rate
        basePrice = String(format: "%.2f", euroFromYen)
        
        let total = euroFromYen * 1.3 + 550
        finalPrice = String(format: "%.2f", total)
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
}

struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
}

struct FrankfurterResponse: Codable {
    let rates: [String: Double]
}
