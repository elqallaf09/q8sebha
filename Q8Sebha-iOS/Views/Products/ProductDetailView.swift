import SwiftUI

struct ProductDetailView: View {
    let productId: Int
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProductViewModel()
    @State private var notes    = ""
    @State private var showBuySheet = false
    @State private var showSuccess  = false
    @State private var showGuestAlert = false

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth:.infinity, maxHeight:.infinity)
            } else if let p = vm.selectedProduct {
                productBody(p)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchProduct(productId) }
        .alert("تم الطلب ✅", isPresented: $showSuccess) {
            Button("حسناً") {}
        } message: {
            Text("سيصلك رابط الدفع عبر الواتساب خلال دقائق")
        }
        .alert("مستخدم ضيف", isPresented: $showGuestAlert) {
            Button("إنشاء حساب") { authVM.appState = .auth }
            Button("إلغاء", role:.cancel) {}
        } message: {
            Text("يجب تسجيل الدخول للشراء")
        }
    }

    @ViewBuilder
    private func productBody(_ p: Product) -> some View {
        ScrollView {
            VStack(alignment:.trailing, spacing:20) {
                // صورة
                ZStack {
                    if p.imageUrls.isEmpty {
                        Text(p.emoji).font(.system(size:100))
                            .frame(maxWidth:.infinity).frame(height:260)
                            .background(Color(.systemGray6))
                    } else {
                        AsyncImage(url: URL(string: APIService.shared.baseURL.replacing("/api","") + "/uploads/" + p.primaryImage)) { img in
                            img.resizable().scaledToFit()
                        } placeholder: {
                            Text(p.emoji).font(.system(size:80))
                        }
                        .frame(maxWidth:.infinity).frame(height:260)
                    }
                    if let badge = p.badge {
                        VStack { HStack { Spacer(); Text(badge).font(.callout.bold()).foregroundColor(.white)
                            .padding(.horizontal,12).padding(.vertical,6).background(Color.red).cornerRadius(8).padding(12) }; Spacer() }
                    }
                }

                VStack(alignment:.trailing, spacing:14) {
                    // الاسم والسعر
                    HStack {
                        Text(p.priceFormatted).font(.custom("Tajawal-Bold",size:24)).foregroundColor(Color("Primary"))
                        Spacer()
                        Text(p.name).font(.custom("Tajawal-Bold",size:20))
                    }

                    // المواصفات
                    if p.beadCount != nil || p.material != nil || p.weightGrams != nil {
                        VStack(alignment:.trailing, spacing:8) {
                            Text("المواصفات").font(.custom("Tajawal-Bold",size:16))
                            Divider()
                            if let v = p.beadCount   { SpecRow(label:"عدد الحبات",     value:"\(v) حبة") }
                            if let v = p.beadSizeMm  { SpecRow(label:"حجم الحبة",      value:"\(v) مم") }
                            if let v = p.weightGrams { SpecRow(label:"الوزن",          value:"\(v) غ") }
                            if let v = p.material    { SpecRow(label:"الخامة",         value:v) }
                            if let v = p.originCountry { SpecRow(label:"بلد المنشأ",   value:v) }
                        }
                        .padding(14).background(Color(.systemGray6)).cornerRadius(12)
                    }

                    if let desc = p.description {
                        Text(desc).font(.custom("Tajawal-Regular",size:15)).foregroundColor(.secondary).multilineTextAlignment(.trailing)
                    }

                    // ملاحظات الطلب
                    VStack(alignment:.trailing, spacing:6) {
                        Text("ملاحظات الطلب (اختياري)").font(.custom("Tajawal-Medium",size:14))
                        TextEditor(text:$notes)
                            .frame(height:80).padding(8).background(Color(.systemGray6)).cornerRadius(10)
                    }

                    // زر الشراء
                    Button(action: {
                        if authVM.isGuest { showGuestAlert = true; return }
                        showBuySheet = true
                    }) {
                        HStack {
                            Text("شراء الآن").font(.custom("Tajawal-Bold",size:18)).foregroundColor(.white)
                            Image(systemName:"cart.fill").foregroundColor(.white)
                        }
                        .frame(maxWidth:.infinity).frame(height:54)
                        .background(Color("Primary")).cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
        .confirmationDialog("تأكيد الشراء", isPresented:$showBuySheet) {
            Button("تأكيد الشراء — \(p.priceFormatted)") {
                Task {
                    await vm.buyProduct(p.id, notes: notes.isEmpty ? nil : notes)
                    if vm.orderSuccess { showSuccess = true }
                }
            }
            Button("إلغاء", role:.cancel) {}
        } message: {
            Text("سيصلك رابط الدفع عبر الواتساب")
        }
    }
}

struct SpecRow: View {
    let label: String; let value: String
    var body: some View {
        HStack { Text(value).font(.custom("Tajawal-Regular",size:14)); Spacer(); Text(label).font(.custom("Tajawal-Medium",size:14)) }
    }
}
