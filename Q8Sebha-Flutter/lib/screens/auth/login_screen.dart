import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone    = TextEditingController();
  final _password = TextEditingController();
  bool _showPass  = false;
  bool _isSignup  = false;
  final _name     = TextEditingController();
  final _email    = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors:[AppTheme.primary, Color(0xFF0D5C35)],
            begin:Alignment.topCenter, end:Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children:[
              const SizedBox(height:20),
              // شعار
              const Text('📿', style:TextStyle(fontSize:80)),
              const Text('Q8Sebha',
                style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700,
                                fontSize:36, color:Colors.white)),
              const Text('مسابيح وأحجار كريمة',
                style:TextStyle(fontFamily:'Tajawal', fontSize:15, color:Colors.white70)),
              const SizedBox(height:32),

              // البطاقة
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(24),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.1),blurRadius:20,offset:const Offset(0,8))]),
                child: Column(children:[
                  // تبويب تسجيل دخول / إنشاء حساب
                  Row(children:[
                    Expanded(child: GestureDetector(
                      onTap:()=>setState(()=>_isSignup=true),
                      child: Container(
                        padding:const EdgeInsets.symmetric(vertical:10),
                        decoration:BoxDecoration(
                          color:_isSignup?AppTheme.primary:Colors.transparent,
                          borderRadius:BorderRadius.circular(10)),
                        child:Text('إنشاء حساب', textAlign:TextAlign.center,
                          style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700,
                            color:_isSignup?Colors.white:Colors.grey)),
                      ),
                    )),
                    Expanded(child: GestureDetector(
                      onTap:()=>setState(()=>_isSignup=false),
                      child: Container(
                        padding:const EdgeInsets.symmetric(vertical:10),
                        decoration:BoxDecoration(
                          color:!_isSignup?AppTheme.primary:Colors.transparent,
                          borderRadius:BorderRadius.circular(10)),
                        child:Text('تسجيل الدخول', textAlign:TextAlign.center,
                          style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700,
                            color:!_isSignup?Colors.white:Colors.grey)),
                      ),
                    )),
                  ]),
                  const SizedBox(height:20),

                  if (_isSignup) ...[
                    Q8Field(hint:'الاسم الكامل', controller:_name, icon:Icons.person),
                    const SizedBox(height:12),
                    Q8Field(hint:'البريد الإلكتروني (اختياري)', controller:_email, icon:Icons.email, keyboard:TextInputType.emailAddress),
                    const SizedBox(height:12),
                  ],
                  Q8Field(hint:'رقم الهاتف', controller:_phone, icon:Icons.phone, keyboard:TextInputType.phone),
                  const SizedBox(height:12),
                  Q8Field(hint:'كلمة المرور', controller:_password, icon:Icons.lock, obscure:!_showPass,
                    suffix: IconButton(
                      icon:Icon(_showPass?Icons.visibility_off:Icons.visibility, color:Colors.grey),
                      onPressed:()=>setState(()=>_showPass=!_showPass),
                    )),
                  const SizedBox(height:8),

                  if (auth.errorMessage != null) ErrorBanner(auth.errorMessage!),
                  const SizedBox(height:8),

                  Q8Button(
                    label: _isSignup ? 'إنشاء الحساب' : 'تسجيل الدخول',
                    isLoading: auth.isLoading,
                    onTap: () {
                      if (_isSignup) {
                        auth.register(_name.text, _phone.text, _password.text, email:_email.text);
                      } else {
                        auth.login(_phone.text, _password.text);
                      }
                    },
                  ),
                  const SizedBox(height:16),
                  const Divider(),
                  const SizedBox(height:8),
                  TextButton.icon(
                    onPressed: auth.continueAsGuest,
                    icon: const Icon(Icons.person_outline, color:Colors.grey),
                    label: const Text('الدخول كضيف',
                      style:TextStyle(fontFamily:'Tajawal', color:Colors.grey, fontSize:14)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
