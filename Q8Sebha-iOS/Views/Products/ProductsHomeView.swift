import SwiftUI

struct ProductsHomeView: View {
    @StateObject private var vm = ProductViewModel()
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""

    let categories: [(emoji: String, name: String, slug: String)] = [
        ("📿","المسابيح","misbaha"),
        ("💍","خواتم","rings"),
        ("💎","أحجار كريمة","gemstones"),
        ("🏺","تحف","antiques"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.trailing, spacing:0) {
                    // شريط البحث
                    HStack {
                        TextField("ابحث...", text:$searchText)
                            .submitLabel(.search)
                            .onSubmit { Task { await vm.fetchProducts(category:selectedCategory, search:searchText) } }
                        Image(systemName:"magnifyingglass").foregroundColor(.secondary)
                    }
                    .padding(12).background(Color(.systemGray6)).cornerRadius(12)
                    .padding(.horizontal).padding(.top,8)

                    // الفئات
                    ScrollView(.horizontal, showsIndicators:false) {
                        HStack(spacing:12) {
                            CategoryChip(emoji:"🔍", name:"الكل", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                                Task { await vm.fetchProducts() }
                            }
                            ForEach(categories, id:\.slug) { cat in
                                CategoryChip(emoji:cat.emoji, name:cat.name, isSelected:selectedCategory==cat.slug) {
                                    selectedCategory = cat.slug
                                    Task { await vm.fetchProducts(category:cat.slug) }
                                }
                            }
                        }
                        .padding(.horizontal).padding(.vertical,10)
                    }

                    // المنتجات
                    if vm.isLoading {
                        ProgressView().frame(maxWidth:.infinity).padding(.top,60)
                    } else if vm.products.isEmpty {
                        VStack(spacing:12) {
                            Text("📦").font(.system(size:50))
                            Text("لا توجد منتجات").font(.custom("Tajawal-Medium",size:16)).foregroundColor(.secondary)
                        }.frame(maxWidth:.infinity).padding(.top,60)
                    } else {
                        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())], spacing:16) {
                            ForEach(vm.products) { product in
                                NavigationLink(destination: ProductDetailView(productId: product.id)) {
                                    ProductCard(product: product)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Q8Sebha 📿")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.fetchProducts() }
    }
}

// ─── بطاقة المنتج ─────────────────────────────────────────────────────────
struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment:.trailing, spacing:8) {
            ZStack(alignment:.topLeading) {
                if product.imageUrls.isEmpty {
                    Text(product.emoji).font(.system(size:70))
                        .frame(maxWidth:.infinity).frame(height:130)
                        .background(Color(.systemGray6)).cornerRadius(12)
                } else {
                    AsyncImage(url: URL(string: APIService.shared.baseURL.replacing("/api","") + "/uploads/" + product.primaryImage)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Text(product.emoji).font(.system(size:50)).frame(maxWidth:.infinity).frame(height:130)
                    }
                    .frame(maxWidth:.infinity).frame(height:130).clipped().cornerRadius(12)
                }
                if let badge = product.badge {
                    Text(badge).font(.caption2.bold()).foregroundColor(.white)
                        .padding(.horizontal,8).padding(.vertical,4)
                        .background(Color.red).cornerRadius(8)
                        .padding(6)
                }
            }

            Text(product.name)
                .font(.custom("Tajawal-Medium",size:14))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)

            Text(product.priceFormatted)
                .font(.custom("Tajawal-Bold",size:14))
                .foregroundColor(Color("Primary"))
        }
        .padding(12)
        .background(.white)
        .cornerRadius(16)
        .shadow(color:.black.opacity(0.07), radius:6, y:3)
    }
}

// ─── CategoryChip ─────────────────────────────────────────────────────────
struct CategoryChip: View {
    let emoji: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action:action) {
            HStack(spacing:6) {
                Text(name).font(.custom("Tajawal-Medium",size:13))
                Text(emoji)
            }
            .padding(.horizontal,14).padding(.vertical,8)
            .background(isSelected ? Color("Primary") : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}
