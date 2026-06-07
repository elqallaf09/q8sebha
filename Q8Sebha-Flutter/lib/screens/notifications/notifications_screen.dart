import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<NotificationProvider>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationProvider>();
    final hasUnread = vm.notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [
        // ─── AppBar ────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.primary,
          title: const Text('الإشعارات',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
              fontSize: 18, color: Colors.white)),
          centerTitle: true,
          actions: [
            if (hasUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton(
                  onPressed: () => vm.markAllRead(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('قراءة الكل',
                    style: TextStyle(fontFamily: 'Tajawal', color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
          ],
        ),

        // ─── المحتوى ───────────────────────────────────────────────────
        if (vm.isLoading)
          const SliverFillRemaining(child: LoadingBody())
        else if (vm.notifications.isEmpty)
          const SliverFillRemaining(
            child: EmptyState(emoji: '🔔', message: 'لا توجد إشعارات'))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final n = vm.notifications[i];
                  return Dismissible(
                    key: Key('n${n.id}'),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.done_all, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => vm.markRead(n.id),
                    child: GestureDetector(
                      onTap: () => vm.markRead(n.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.white : AppTheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: n.isRead
                              ? Border.all(color: Colors.grey.shade100)
                              : Border.all(color: AppTheme.primary.withOpacity(0.15)),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // dot
                            if (!n.isRead)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, right: 4),
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary, shape: BoxShape.circle)),
                              )
                            else
                              const SizedBox(width: 12),
                            // المحتوى
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(n.title,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                      fontSize: 14, color: AppTheme.textDark)),
                                  const SizedBox(height: 4),
                                  Text(n.body,
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // الأيقونة
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? const Color(0xFFF5F5F8)
                                    : AppTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text(n.icon,
                                style: const TextStyle(fontSize: 22))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: vm.notifications.length,
              ),
            ),
          ),
      ]),
    );
  }
}
