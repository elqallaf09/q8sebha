import SwiftUI

struct AuctionDetailView: View {
    let auctionId: Int
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AuctionViewModel()
    @State private var showBidSheet = false
    @State private var showPaySheet = false
    @State private var payLink      = ""
    @State private var showGuestAlert = false
    @State private var timeStr = ""
    let timer = Timer.publish(every:1, on:.main, in:.common).autoconnect()

    var body: some View {
        Group {
            if vm.isLoading && vm.selectedAuction == nil {
                ProgressView()
            } else if let a = vm.selectedAuction {
                detail(a)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchAuction(auctionId) }
        .onReceive(timer) { _ in if let a = vm.selectedAuction { timeStr = vm.countdownString(for:a) } }
        .alert("مستخدم ضيف", isPresented:$showGuestAlert) {
            Button("إنشاء حساب") { authVM.appState = .auth }
            Button("إلغاء", role:.cancel) {}
        } message: { Text("يجب تسجيل الدخول للمزايدة") }
    }

    @ViewBuilder
    private func detail(_ a: Auction) -> some View {
        ScrollView {
            VStack(alignment:.trailing, spacing:20) {
                // صورة
                ZStack(alignment:.bottom) {
                    if a.imageUrls.isEmpty {
                        Text("📿").font(.system(size:100)).frame(maxWidth:.infinity).frame(height:250).background(Color(.systemGray6))
                    } else {
                        AsyncImage(url: URL(string: APIService.shared.baseURL.replacing("/api","") + "/uploads/" + a.primaryImage)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { Text("📿").font(.system(size:80)) }
                        .frame(maxWidth:.infinity).frame(height:250).clipped()
                    }

                    // شريط حالة
                    HStack {
                        HStack(spacing:4) {
                            Image(systemName:"clock.fill").font(.caption2)
                            Text(timeStr).font(.custom("Tajawal-Bold",size:14))
                        }
                        .padding(.horizontal,12).padding(.vertical,6)
                        .background(timerBg(a).opacity(0.9))
                        .foregroundColor(.white).cornerRadius(10)
                        Spacer()
                        Text(a.isActive ? "🟢 نشط" : "🔴 انتهى")
                            .font(.custom("Tajawal-Bold",size:14)).foregroundColor(.white)
                            .padding(.horizontal,12).padding(.vertical,6)
                            .background(a.isActive ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                            .cornerRadius(10)
                    }.padding()
                }

                VStack(alignment:.trailing, spacing:16) {
                    // العنوان والسعر
                    VStack(alignment:.trailing, spacing:6) {
                        Text(a.title).font(.custom("Tajawal-Bold",size:22))
                        HStack {
                            Text(a.maxPriceFormatted).font(.caption).foregroundColor(.secondary)
                            Spacer()
                            VStack(alignment:.trailing, spacing:2) {
                                Text("السعر الحالي").font(.caption).foregroundColor(.secondary)
                                Text(a.currentPriceFormatted).font(.custom("Tajawal-Bold",size:26)).foregroundColor(Color("Primary"))
                            }
                        }
                        ProgressView(value: a.progressFraction)
                            .tint(a.progressFraction > 0.75 ? .red : Color("Primary"))
                        Text("\(a.bidsCount) مزايدة — السعر الابتدائي: \(String(format:"%.3f", a.startingPrice)) د.ك")
                            .font(.caption).foregroundColor(.secondary)
                    }

                    if let terms = a.sellerTerms { infoBox("📋 شروط البائع", terms) }
                    if let name  = a.sellerName  { infoBox("👤 البائع", name) }

                    // أزرار
                    if a.isActive {
                        if !authVM.isGuest {
                            Button(action:{ showBidSheet = true }) {
                                HStack {
                                    Text("زايد الآن +\(String(format:"%.3f",a.bidIncrement)) د.ك")
                                        .font(.custom("Tajawal-Bold",size:18)).foregroundColor(.white)
                                    Image(systemName:"hammer.fill").foregroundColor(.white)
                                }
                                .frame(maxWidth:.infinity).frame(height:54)
                                .background(Color("Primary")).cornerRadius(16)
                            }
                        } else {
                            Button("سجّل الدخول للمزايدة") { showGuestAlert = true }
                                .frame(maxWidth:.infinity).frame(height:54)
                                .background(Color.gray).foregroundColor(.white).cornerRadius(16)
                        }
                    }

                    // إرسال رابط دفع (إذا كان البائع)
                    if !a.isActive, a.sellerId == authVM.currentUser?.id, let wid = a.winnerId {
                        VStack(alignment:.trailing, spacing:10) {
                            Text("الفائز: \(a.winnerName ?? "#\(wid)")").font(.custom("Tajawal-Medium",size:14))
                            TextField("رابط الدفع", text:$payLink).textFieldStyle(.roundedBorder)
                            Button("إرسال رابط الدفع للفائز") {
                                Task {
                                    _ = await vm.sendPaymentLink(auctionId: a.id, link: payLink)
                                }
                            }
                            .frame(maxWidth:.infinity).frame(height:46)
                            .background(Color.green).foregroundColor(.white).cornerRadius(12)

                            Button("إبلاغ عن عدم الدفع ⚠️") {
                                Task { _ = await vm.reportNonPayment(auctionId: a.id) }
                            }
                            .frame(maxWidth:.infinity).frame(height:46)
                            .background(Color.red).foregroundColor(.white).cornerRadius(12)
                        }
                        .padding(14).background(Color(.systemGray6)).cornerRadius(12)
                    }

                    // المزايدات الأخيرة
                    if !vm.bids.isEmpty {
                        VStack(alignment:.trailing, spacing:8) {
                            Text("آخر المزايدات").font(.custom("Tajawal-Bold",size:16))
                            ForEach(vm.bids.prefix(10)) { bid in
                                HStack {
                                    Text(bid.amountFormatted).font(.custom("Tajawal-Bold",size:14)).foregroundColor(Color("Primary"))
                                    Spacer()
                                    Text(bid.bidderName ?? "مجهول").font(.custom("Tajawal-Regular",size:14))
                                    Image(systemName:"person.circle.fill").foregroundColor(.secondary)
                                }
                                .padding(10).background(Color(.systemGray6)).cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(a.title)
        .confirmationDialog("تأكيد المزايدة", isPresented:$showBidSheet) {
            Button("زايد بـ \(String(format:"%.3f", a.currentPrice + a.bidIncrement)) د.ك") {
                Task { await vm.placeBid(auctionId:a.id, amount:a.currentPrice + a.bidIncrement) }
            }
            Button("إلغاء", role:.cancel) {}
        } message: {
            Text("سيتم رفع السعر بـ \(String(format:"%.3f",a.bidIncrement)) د.ك")
        }
    }

    @ViewBuilder
    private func infoBox(_ title: String, _ content: String) -> some View {
        VStack(alignment:.trailing, spacing:4) {
            Text(title).font(.custom("Tajawal-Bold",size:14))
            Text(content).font(.custom("Tajawal-Regular",size:14)).foregroundColor(.secondary).multilineTextAlignment(.trailing)
        }
        .frame(maxWidth:.infinity, alignment:.trailing)
        .padding(12).background(Color(.systemGray6)).cornerRadius(10)
    }

    private func timerBg(_ a: Auction) -> Color {
        let t = a.timeRemaining
        return t < 60 ? .red : t < 300 ? .orange : Color("Primary")
    }
}
