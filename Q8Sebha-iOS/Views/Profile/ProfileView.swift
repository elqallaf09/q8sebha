import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var ordersVM = OrdersViewModel()
    @State private var showEditSheet  = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            if authVM.isGuest {
                guestView
            } else if let u = authVM.currentUser {
                userView(u)
            }
        }
    }

    @ViewBuilder
    private var guestView: some View {
        VStack(spacing:20) {
            Text("👤").font(.system(size:80))
            Text("أنت تتصفح كضيف").font(.custom("Tajawal-Bold",size:20))
            Text("سجّل دخولك للاستمتاع بجميع الميزات").font(.custom("Tajawal-Regular",size:15)).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button(action:{ authVM.appState = .auth }) {
                Text("تسجيل الدخول / إنشاء حساب")
                    .font(.custom("Tajawal-Bold",size:16)).foregroundColor(.white)
                    .frame(maxWidth:.infinity).frame(height:50)
                    .background(Color("Primary")).cornerRadius(14)
            }.padding(.horizontal, 40)
        }
        .navigationTitle("الملف الشخصي")
    }

    @ViewBuilder
    private func userView(_ u: User) -> some View {
        List {
            // رأس البروفايل
            Section {
                HStack(spacing:16) {
                    ZStack {
                        Circle().fill(Color("Primary").opacity(0.15)).frame(width:70,height:70)
                        Text("📿").font(.system(size:36))
                    }
                    VStack(alignment:.trailing, spacing:4) {
                        Text(u.name).font(.custom("Tajawal-Bold",size:20))
                        Text(u.phone).font(.custom("Tajawal-Regular",size:14)).foregroundColor(.secondary)
                        if u.role != "user" {
                            Text(u.role == "admin" ? "⚙️ أدمن" : "🏪 بائع")
                                .font(.caption.bold()).foregroundColor(.white)
                                .padding(.horizontal,8).padding(.vertical,3)
                                .background(u.role=="admin" ? Color.purple : Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
            }

            // معلومات التواصل
            Section("معلومات الحساب") {
                InfoRow(icon:"phone.fill",      label:"رقم الهاتف",       value:u.phone)
                InfoRow(icon:"envelope.fill",   label:"البريد",           value:u.email ?? "—")
                InfoRow(icon:"message.fill",    label:"طريقة التواصل",   value:u.contactMethod ?? "—")
                InfoRow(icon:"shippingbox.fill",label:"التوصيل",         value:u.deliveryMethod ?? "—")
                if let area = u.deliveryArea { InfoRow(icon:"mappin.fill", label:"المنطقة", value:area) }
            }

            // طلباتي
            Section("طلباتي (\(ordersVM.orders.count))") {
                if ordersVM.orders.isEmpty {
                    Text("لا توجد طلبات بعد").foregroundColor(.secondary)
                        .font(.custom("Tajawal-Regular",size:14))
                } else {
                    ForEach(ordersVM.orders.prefix(5)) { order in
                        OrderRow(order: order)
                    }
                    if ordersVM.orders.count > 5 {
                        NavigationLink("عرض كل الطلبات") { AllOrdersView(orders: ordersVM.orders) }
                    }
                }
            }

            // الإعدادات
            Section {
                Button(action:{ showEditSheet = true }) {
                    Label("تعديل الملف الشخصي", systemImage:"pencil").foregroundColor(Color("Primary"))
                }
                Button(role:.destructive, action:{ showLogoutAlert = true }) {
                    Label("تسجيل الخروج", systemImage:"rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("حسابي")
        .sheet(isPresented:$showEditSheet) { EditProfileView() }
        .alert("تأكيد الخروج", isPresented:$showLogoutAlert) {
            Button("تسجيل الخروج", role:.destructive) { authVM.logout() }
            Button("إلغاء", role:.cancel) {}
        }
        .task { await ordersVM.fetchOrders() }
    }
}

// ─── الإشعارات ────────────────────────────────────────────────────────────
struct NotificationsView: View {
    @StateObject private var vm = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.notifications.isEmpty && !vm.isLoading {
                    VStack(spacing:12) {
                        Text("🔔").font(.system(size:60))
                        Text("لا توجد إشعارات").font(.custom("Tajawal-Medium",size:16)).foregroundColor(.secondary)
                    }.frame(maxWidth:.infinity, maxHeight:.infinity)
                } else {
                    List {
                        ForEach(vm.notifications) { n in
                            NotifRow(notif: n).onTapGesture { Task { await vm.markRead(n.id) } }
                                .listRowBackground(n.isRead ? Color.clear : Color("Primary").opacity(0.05))
                        }
                    }.refreshable { await vm.fetchAll() }
                }
            }
            .navigationTitle("الإشعارات 🔔")
            .toolbar {
                ToolbarItem(placement:.navigationBarLeading) {
                    if vm.notifications.contains(where:{!$0.isRead}) {
                        Button("قراءة الكل") { Task { await vm.markAllRead() } }.font(.caption)
                    }
                }
            }
        }
        .task { await vm.fetchAll() }
    }
}

// ─── Helpers ──────────────────────────────────────────────────────────────
struct InfoRow: View {
    let icon,label,value: String
    var body: some View {
        HStack {
            Text(value).font(.custom("Tajawal-Regular",size:15))
            Spacer()
            Label(label, systemImage:icon).labelStyle(.titleAndIcon).font(.custom("Tajawal-Medium",size:14)).foregroundColor(.secondary)
        }
    }
}

struct OrderRow: View {
    let order: Order
    var body: some View {
        HStack {
            VStack(alignment:.leading, spacing:4) {
                Text(order.totalFormatted).font(.custom("Tajawal-Bold",size:14)).foregroundColor(Color("Primary"))
                Text(order.status.displayName).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment:.trailing, spacing:4) {
                Text(order.productName ?? "منتج").font(.custom("Tajawal-Medium",size:14))
                Text(order.orderNumber).font(.caption2.monospaced()).foregroundColor(.secondary)
            }
            Text(order.productEmoji ?? "📿").font(.title2)
        }.padding(.vertical, 4)
    }
}

struct NotifRow: View {
    let notif: AppNotification
    var body: some View {
        HStack(alignment:.top, spacing:12) {
            if !notif.isRead { Circle().fill(Color("Primary")).frame(width:8,height:8).padding(.top,6) }
            else             { Circle().fill(Color.clear).frame(width:8,height:8) }
            VStack(alignment:.trailing, spacing:4) {
                Text(notif.title).font(.custom("Tajawal-Bold",size:14))
                Text(notif.body).font(.custom("Tajawal-Regular",size:13)).foregroundColor(.secondary)
            }
            Spacer()
            Text(notif.icon).font(.title2)
        }
        .padding(.vertical, 4)
        .opacity(notif.isRead ? 0.7 : 1)
    }
}

struct AllOrdersView: View {
    let orders: [Order]
    var body: some View {
        List(orders) { OrderRow(order:$0) }
            .navigationTitle("جميع الطلبات")
    }
}

// ─── تعديل الملف الشخصي ───────────────────────────────────────────────────
struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var contact  = ""
    @State private var delivery = ""
    @State private var area     = ""
    @State private var address  = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("طريقة التواصل") {
                    Picker("التواصل", selection:$contact) {
                        Text("واتساب").tag("whatsapp")
                        Text("اتصال").tag("phone")
                        Text("الاثنان").tag("both")
                    }.pickerStyle(.segmented)
                }
                Section("التوصيل") {
                    Picker("طريقة التوصيل", selection:$delivery) {
                        Text("توصيل").tag("delivery")
                        Text("استلام").tag("pickup")
                    }.pickerStyle(.segmented)
                    TextField("المنطقة", text:$area)
                    TextField("العنوان", text:$address)
                }
            }
            .navigationTitle("تعديل الملف")
            .toolbar {
                ToolbarItem(placement:.navigationBarLeading) {
                    Button("إغلاق") { dismiss() }
                }
                ToolbarItem(placement:.navigationBarTrailing) {
                    Button("حفظ") {
                        isLoading = true
                        Task {
                            _ = try? await APIService.shared.updateProfile([
                                "contact_method": contact, "delivery_method": delivery,
                                "delivery_area": area, "delivery_address": address
                            ])
                            isLoading = false
                            dismiss()
                        }
                    }.disabled(isLoading)
                }
            }
            .onAppear {
                let u = authVM.currentUser
                contact  = u?.contactMethod  ?? "whatsapp"
                delivery = u?.deliveryMethod ?? "delivery"
                area     = u?.deliveryArea   ?? ""
                address  = u?.deliveryAddress ?? ""
            }
        }
    }
}

// ─── ViewModels مساعدة ────────────────────────────────────────────────────
@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    func fetchOrders() async {
        orders = (try? await APIService.shared.myOrders())?.data ?? []
    }
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false

    func fetchAll() async {
        isLoading = true
        notifications = (try? await APIService.shared.notifications())?.data ?? []
        isLoading = false
    }

    func markRead(_ id: Int) async {
        try? await APIService.shared.markRead(id)
        if let i = notifications.firstIndex(where:{$0.id==id}) {
            notifications[i].isRead = true
        }
    }

    func markAllRead() async {
        try? await APIService.shared.markAllRead()
        for i in notifications.indices { notifications[i].isRead = true }
    }
}
