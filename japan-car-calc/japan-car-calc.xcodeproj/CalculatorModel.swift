import Foundation

class CalculatorModel: ObservableObject {
    @Published var priceYen: String = ""
    @Published var deliveryCost: String = "500"
    @Published var exchangeRate: Double?
    @Published var isLoading: Bool = true
    @Published var error: String = ""
    @Published var basePrice: String = ""
    @Published var finalPrice: String = ""
    @Published var copied: Bool = false
}
