import SwiftUI

struct AuthFlowView: View {
    @State private var showSignup = false
    var body: some View {
        NavigationStack {
            if showSignup { SignupView(showSignup: $showSignup) }
            else          { LoginView(showSignup: $showSignup) }
        }
    }
}

// ─── شاشة تسجيل الدخول ───────────────────────────────────────────────────
struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showSignup: Bool

    @State private var phone    = ""
    @State private var password = ""
    @State private var showPass = false

    var body: some View {
        ZStack {
            LinearGradient(colors:[Color("Primary"), Color("Primary").opacity(0.7)],
                           startPoint:.top, endPoint:.bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // شعار
                VStack(spacing:8) {
                    Text("📿").font(.system(size:70))
                    Text("Q8Sebha").font(.system(size:34, weight:.bold)).foregroundColor(.white)
                    Text("مسابيح وأحجار كريمة").font(.custom("Tajawal-Regular",size:16)).foregroundColor(.white.opacity(0.85))
                }
                .padding(.top, 20)

                // البطاقة
                VStack(spacing:16) {
                    Q8TextField(placeholder:"رقم الهاتف", text:$phone, keyboardType:.phonePad, icon:"phone.fill")
                    Q8SecureField(placeholder:"كلمة المرور", text:$password, show:$showPass)

                    if let err = authVM.errorMessage {
                        Text(err).foregroundColor(.red).font(.caption).multilineTextAlignment(.center)
                    }

                    Q8Button(title: "تسجيل الدخول", isLoading: authVM.isLoading) {
                        Task { await authVM.login(phone: phone, password: password) }
                    }

                    Button("ليس لديك حساب؟ إنشاء حساب جديد") {
                        showSignup = true
                    }
                    .font(.custom("Tajawal-Medium",size:14)).foregroundColor(Color("Primary"))

                    Divider()

                    Button(action: { authVM.continueAsGuest() }) {
                        HStack { Image(systemName:"person.fill"); Text("الدخول كضيف") }
                            .font(.custom("Tajawal-Medium",size:14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .background(.white)
                .cornerRadius(20)
                .shadow(color:.black.opacity(0.1), radius:10)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
    }
}

// ─── شاشة إنشاء الحساب ───────────────────────────────────────────────────
struct SignupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showSignup: Bool

    @State private var name     = ""
    @State private var phone    = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var showPass = false

    var body: some View {
        ZStack {
            Color("Primary").ignoresSafeArea()
            ScrollView {
                VStack(spacing:28) {
                    VStack(spacing:6) {
                        Text("📿").font(.system(size:50))
                        Text("حساب جديد").font(.custom("Tajawal-Bold",size:28)).foregroundColor(.white)
                    }.padding(.top,20)

                    VStack(spacing:14) {
                        Q8TextField(placeholder:"الاسم الكامل", text:$name, icon:"person.fill")
                        Q8TextField(placeholder:"رقم الهاتف", text:$phone, keyboardType:.phonePad, icon:"phone.fill")
                        Q8TextField(placeholder:"البريد الإلكتروني (اختياري)", text:$email, keyboardType:.emailAddress, icon:"envelope.fill")
                        Q8SecureField(placeholder:"كلمة المرور", text:$password, show:$showPass)

                        if let err = authVM.errorMessage {
                            Text(err).foregroundColor(.red).font(.caption).multilineTextAlignment(.center)
                        }

                        Q8Button(title:"إنشاء الحساب", isLoading:authVM.isLoading) {
                            Task { await authVM.register(name:name, phone:phone, password:password, email:email.isEmpty ? nil : email) }
                        }

                        Button("لديك حساب؟ تسجيل الدخول") { showSignup = false }
                            .font(.custom("Tajawal-Medium",size:14)).foregroundColor(Color("Primary"))
                    }
                    .padding(24).background(.white).cornerRadius(20)
                    .shadow(color:.black.opacity(0.1),radius:10)
                    .padding(.horizontal,24)
                }
                .padding(.bottom,30)
            }
        }
        .navigationBarHidden(true)
    }
}

// ─── Splash ───────────────────────────────────────────────────────────────
struct SplashView: View {
    var body: some View {
        ZStack {
            Color("Primary").ignoresSafeArea()
            VStack(spacing:16) {
                Text("📿").font(.system(size:100))
                Text("Q8Sebha").font(.system(size:40,weight:.bold)).foregroundColor(.white)
                Text("مسابيح وأحجار كريمة").font(.custom("Tajawal-Regular",size:18)).foregroundColor(.white.opacity(0.8))
                ProgressView().tint(.white).padding(.top,20)
            }
        }
    }
}

// ─── Reusable Components ──────────────────────────────────────────────────
struct Q8TextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var icon: String = ""

    var body: some View {
        HStack {
            if !icon.isEmpty { Image(systemName:icon).foregroundColor(Color("Primary")).frame(width:20) }
            TextField(placeholder, text:$text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .font(.custom("Tajawal-Regular",size:16))
                .multilineTextAlignment(.right)
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct Q8SecureField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack {
            Image(systemName:"lock.fill").foregroundColor(Color("Primary")).frame(width:20)
            Group {
                if show { TextField(placeholder, text:$text) }
                else    { SecureField(placeholder, text:$text) }
            }
            .font(.custom("Tajawal-Regular",size:16)).multilineTextAlignment(.right)
            Button(action:{ show.toggle() }) {
                Image(systemName: show ? "eye.slash.fill" : "eye.fill").foregroundColor(.secondary)
            }
        }
        .padding(14).background(Color(.systemGray6)).cornerRadius(12)
    }
}

struct Q8Button: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading { ProgressView().tint(.white) }
                else { Text(title).font(.custom("Tajawal-Bold",size:16)).foregroundColor(.white) }
            }
            .frame(maxWidth:.infinity).frame(height:50)
            .background(isLoading ? Color("Primary").opacity(0.6) : Color("Primary"))
            .cornerRadius(14)
        }
        .disabled(isLoading)
    }
}
