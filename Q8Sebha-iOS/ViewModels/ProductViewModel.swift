import Foundation

@MainActor
final class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [Category] = []
    @Published var selectedProduct: Product?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var orderSuccess = false

    private let api = APIService.shared

    func fetchProducts(category: String? = nil, search: String? = nil) async {
        isLoading = true
        do {
            let r = try await api.products(category: category, search: search)
            products = r.data
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func fetchProduct(_ id: Int) async {
        isLoading = true
        do {
            let r = try await api.product(id)
            selectedProduct = r.data
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func buyProduct(_ id: Int, notes: String? = nil) async {
        isLoading = true; errorMessage = nil; orderSuccess = false
        do {
            let r = try await api.createOrder(productId: id, notes: notes)
            orderSuccess = r.success
            if !r.success { errorMessage = r.message ?? "فشل الطلب" }
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
