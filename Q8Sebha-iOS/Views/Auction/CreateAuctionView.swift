import SwiftUI

struct CreateAuctionView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AuctionViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var title          = ""
    @State private var description    = ""
    @State private var startingPrice  = ""
    @State private var maxPrice       = ""
    @State private var durationMin    = 60.0   // دقيقة
    @State private var terms          = ""
    @State private var errorMsg: String?
    @State private var success = false

    let durations: [(label:String, value:Double)] = [
        ("10 دقائق",10),("30 دقيقة",30),("ساعة",60),
        ("3 ساعات",180),("6 ساعات",360),("12 ساعة",720),("24 ساعة",1440)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.trailing, spacing:18) {
                    Group {
                        Q8TextField(placeholder:"عنوان المسباح", text:$title, icon:"text.alignright")
                        Q8TextField(placeholder:"الوصف والمواصفات", text:$description, icon:"doc.text")
                        Q8TextField(placeholder:"السعر الابتدائي (د.ك)", text:$startingPrice, keyboardType:.decimalPad, icon:"tag.fill")
                        Q8TextField(placeholder:"الحد الأعلى — أقصاه 4000 د.ك", text:$maxPrice, keyboardType:.decimalPad, icon:"arrow.up.circle.fill")
                    }

                    // مدة المزاد
                    VStack(alignment:.trailing, spacing:8) {
                        Text("مدة المزاد").font(.custom("Tajawal-Bold",size:15))
                        Slider(value:$durationMin, in:1...1440, step:1)
                            .tint(Color("Primary"))
                        HStack {
                            Text(formatDur(durationMin)).font(.custom("Tajawal-Bold",size:14)).foregroundColor(Color("Primary"))
                            Spacer()
                        }
                        // اختصارات
                        ScrollView(.horizontal, showsIndicators:false) {
                            HStack {
                                ForEach(durations, id:\.value) { d in
                                    Button(d.label) { durationMin = d.value }
                                        .font(.caption).padding(.horizontal,10).padding(.vertical,6)
                                        .background(abs(durationMin-d.value) < 0.1 ? Color("Primary") : Color(.systemGray5))
                                        .foregroundColor(abs(durationMin-d.value) < 0.1 ? .white : .primary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(14).background(Color(.systemGray6)).cornerRadius(12)

                    Q8TextField(placeholder:"شروط البيع (اختياري)", text:$terms, icon:"scroll.fill")

                    // شريط السعر
                    if let sp = Double(startingPrice), let mp = Double(maxPrice), mp > sp {
                        PriceRangeBar(current:sp, min:sp, max:mp)
                    }

                    if let err = errorMsg {
                        Text(err).foregroundColor(.red).font(.caption).multilineTextAlignment(.trailing)
                    }

                    Q8Button(title:"نشر المزاد 🔨", isLoading:vm.isLoading, action:submit)
                }
                .padding()
            }
            .navigationTitle("إضافة مزاد جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.navigationBarTrailing) {
                    Button("إغلاق") { dismiss() }.foregroundColor(.secondary)
                }
            }
            .onChange(of: vm.selectedAuction) { newVal in
                if newVal != nil { success = true }
            }
            .alert("تم نشر المزاد ✅", isPresented:$success) {
                Button("حسناً") { dismiss() }
            }
        }
    }

    private func submit() {
        guard !title.isEmpty, let sp = Double(startingPrice), let mp = Double(maxPrice) else {
            errorMsg = "يرجى تعبئة جميع الحقول المطلوبة"; return
        }
        guard mp <= 4000 else { errorMsg = "الحد الأعلى لا يتجاوز 4000 د.ك"; return }
        guard mp > sp    else { errorMsg = "الحد الأعلى يجب أن يكون أكبر من السعر الابتدائي"; return }
        errorMsg = nil
        Task {
            let body: [String:Any] = [
                "title": title, "description": description,
                "starting_price": sp, "max_price": mp,
                "duration_minutes": Int(durationMin),
                "seller_terms": terms,
                "bid_increment": 1.0
            ]
            let r = try? await APIService.shared.createAuction(body)
            if r?.success == true { vm.selectedAuction = r?.data }
            else { errorMsg = r?.message ?? "فشل نشر المزاد" }
        }
    }

    private func formatDur(_ m: Double) -> String {
        let mins = Int(m)
        if mins < 60 { return "\(mins) دقيقة" }
        let h = mins/60, rem = mins%60
        return rem == 0 ? "\(h) ساعة" : "\(h) ساعة و\(rem) دقيقة"
    }
}

struct PriceRangeBar: View {
    let current, min, max: Double
    var fraction: Double { (current-min) / Swift.max(1, max-min) }
    var body: some View {
        VStack(alignment:.trailing, spacing:6) {
            Text("نطاق السعر").font(.custom("Tajawal-Bold",size:14))
            GeometryReader { geo in
                ZStack(alignment:.leading) {
                    Capsule().fill(Color(.systemGray4)).frame(height:8)
                    Capsule().fill(LinearGradient(colors:[.green,.orange,.red], startPoint:.leading, endPoint:.trailing))
                        .frame(width: geo.size.width * fraction, height:8)
                }
            }.frame(height:8)
            HStack {
                Text(String(format:"%.0f د.ك",max)).font(.caption).foregroundColor(.secondary)
                Spacer()
                Text(String(format:"%.0f د.ك",min)).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(12).background(Color(.systemGray6)).cornerRadius(12)
    }
}
