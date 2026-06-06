import SwiftUI

struct AuctionListView: View {
    @StateObject private var vm = AuctionViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading { ProgressView().frame(maxWidth:.infinity, maxHeight:.infinity) }
                else if vm.auctions.isEmpty {
                    VStack(spacing:16) {
                        Text("🔨").font(.system(size:60))
                        Text("لا توجد مزادات نشطة").font(.custom("Tajawal-Medium",size:18)).foregroundColor(.secondary)
                        if !authVM.isGuest {
                            Button("أضف مزاد") { showCreateSheet = true }
                                .buttonStyle(.borderedProminent).tint(Color("Primary"))
                        }
                    }.frame(maxWidth:.infinity, maxHeight:.infinity)
                } else {
                    List {
                        ForEach(vm.auctions) { auction in
                            NavigationLink(destination: AuctionDetailView(auctionId: auction.id)) {
                                AuctionRow(auction: auction, vm: vm)
                            }
                            .listRowInsets(EdgeInsets(top:8,leading:16,bottom:8,trailing:16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchAuctions() }
                }
            }
            .navigationTitle("المزاد 🔨")
            .toolbar {
                if !authVM.isGuest {
                    ToolbarItem(placement:.navigationBarLeading) {
                        Button(action:{ showCreateSheet = true }) {
                            Image(systemName:"plus.circle.fill").foregroundColor(Color("Primary"))
                        }
                    }
                }
            }
            .sheet(isPresented:$showCreateSheet) {
                CreateAuctionView()
            }
        }
        .task { await vm.fetchAuctions() }
    }
}

// ─── صف المزاد ────────────────────────────────────────────────────────────
struct AuctionRow: View {
    let auction: Auction
    @ObservedObject var vm: AuctionViewModel
    @State private var timeStr = ""
    let timer = Timer.publish(every:1, on:.main, in:.common).autoconnect()

    var body: some View {
        VStack(alignment:.trailing, spacing:10) {
            HStack(alignment:.top) {
                VStack(alignment:.leading, spacing:4) {
                    // العداد
                    HStack(spacing:4) {
                        Image(systemName:"clock.fill").font(.caption2).foregroundColor(timerColor)
                        Text(timeStr).font(.custom("Tajawal-Bold",size:13)).foregroundColor(timerColor)
                    }
                    Text("\(auction.bidsCount) مزايدة").font(.custom("Tajawal-Regular",size:12)).foregroundColor(.secondary)
                }
                Spacer()
                // صورة أو إيموجي
                ZStack {
                    if auction.imageUrls.isEmpty {
                        Text("📿").font(.system(size:40)).frame(width:70,height:70).background(Color(.systemGray6)).cornerRadius(12)
                    } else {
                        AsyncImage(url: URL(string: APIService.shared.baseURL.replacing("/api","") + "/uploads/" + auction.primaryImage)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { Text("📿") }
                        .frame(width:70,height:70).clipped().cornerRadius(12)
                    }
                }
            }

            Text(auction.title).font(.custom("Tajawal-Bold",size:16)).multilineTextAlignment(.trailing)

            // شريط السعر
            VStack(alignment:.trailing, spacing:4) {
                HStack {
                    Text(auction.maxPriceFormatted).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(auction.currentPriceFormatted).font(.custom("Tajawal-Bold",size:15)).foregroundColor(Color("Primary"))
                }
                ProgressView(value: auction.progressFraction)
                    .tint(progressColor(auction.progressFraction))
            }

            if let terms = auction.sellerTerms, !terms.isEmpty {
                Text("📋 \(terms)").font(.caption).foregroundColor(.secondary).lineLimit(2).multilineTextAlignment(.trailing)
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(16)
        .shadow(color:.black.opacity(0.06), radius:6, y:3)
        .onReceive(timer) { _ in timeStr = vm.countdownString(for:auction) }
        .onAppear { timeStr = vm.countdownString(for:auction) }
    }

    private var timerColor: Color {
        let t = auction.timeRemaining
        if t < 60 { return .red } else if t < 300 { return .orange } else { return Color("Primary") }
    }
    private func progressColor(_ f: Double) -> Color {
        if f > 0.75 { return .red } else if f > 0.5 { return .orange } else { return Color("Primary") }
    }
}
