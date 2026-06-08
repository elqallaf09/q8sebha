import 'package:flutter/material.dart';
import '../main.dart';

// ─── زر رئيسي ──────────────────────────────────────────────────────────
class Q8Button extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color? color;

  const Q8Button({super.key, required this.label, this.isLoading=false, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: isLoading ? null : onTap,
    style: ElevatedButton.styleFrom(backgroundColor: color ?? AppTheme.primary),
    child: isLoading
        ? const SizedBox(width:22, height:22, child:CircularProgressIndicator(color:Colors.white, strokeWidth:2.5))
        : Text(label),
  );
}

// ─── حقل نص ────────────────────────────────────────────────────────────
class Q8Field extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboard;
  final IconData? icon;
  final bool obscure;
  final Widget? suffix;

  const Q8Field({super.key, required this.hint, required this.controller,
                 this.keyboard=TextInputType.text, this.icon, this.obscure=false, this.suffix});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboard,
    obscureText: obscure,
    textAlign: TextAlign.right,
    decoration: InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      prefixIcon: icon != null ? Icon(icon, color:AppTheme.primary, size:20) : null,
      suffixIcon: suffix,
    ),
  );
}

// ─── بطاقة ─────────────────────────────────────────────────────────────
class Q8Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const Q8Card({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: child,
      ),
    ),
  );
}

// ─── شريط تحميل ─────────────────────────────────────────────────────────
class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppTheme.primary));
}

// ─── رسالة فارغة ─────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji, message;
  const EmptyState({super.key, required this.emoji, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
      Text(emoji, style:const TextStyle(fontSize:64)),
      const SizedBox(height:12),
      Text(message, style:const TextStyle(fontFamily:'Tajawal', fontSize:16, color:Colors.grey)),
    ]),
  );
}

// ─── رسالة خطأ ───────────────────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical:8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color:Colors.red.shade50, borderRadius:BorderRadius.circular(10)),
    child: Text(message, style:const TextStyle(color:Colors.red, fontFamily:'Tajawal', fontSize:13), textAlign:TextAlign.right),
  );
}

// ─── شريط السعر ───────────────────────────────────────────────────────────
class PriceRangeBar extends StatelessWidget {
  final double fraction;
  const PriceRangeBar({super.key, required this.fraction});
  @override
  Widget build(BuildContext context) {
    final color = fraction > 0.75 ? Colors.red : fraction > 0.5 ? Colors.orange : AppTheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 6,
      ),
    );
  }
}
