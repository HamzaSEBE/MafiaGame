import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class LobbyPanel extends StatelessWidget {
  const LobbyPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [context.visual.surface, context.visual.background],
      ),
      border: Border.all(color: context.visual.surfaceHigh),
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class LobbyInvite extends StatefulWidget {
  const LobbyInvite({super.key, required this.url});
  final String url;
  @override
  State<LobbyInvite> createState() => _LobbyInviteState();
}

class _LobbyInviteState extends State<LobbyInvite> {
  bool _copying = false;
  Widget? _cachedQr;
  String? _cachedUrl;
  double? _cachedSize;
  Future<void> _copy() async {
    if (_copying) return;
    setState(() => _copying = true);
    try {
      await Clipboard.setData(ClipboardData(text: widget.url));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم نسخ رابط الانضمام')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر النسخ. يمكنك تحديد الرابط ونسخه يدوياً.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  void _enlarge() {
    final size = MediaQuery.sizeOf(context);
    final side = math
        .min(size.width - 96, size.height - 180)
        .clamp(120.0, 440.0);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'مكانك في المدينة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _qr(side),
                const SizedBox(height: 12),
                const Text(
                  'افتح كاميرا هاتفك وامسح الرمز',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qr(double size) {
    if (_cachedUrl == widget.url && _cachedSize == size) return _cachedQr!;
    _cachedUrl = widget.url;
    _cachedSize = size;
    return _cachedQr = RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: QrImageView(
          data: widget.url,
          version: QrVersions.auto,
          size: size,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          semanticsLabel: 'رمز الانضمام للجلسة',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LobbyPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: context.visual.iconColor2),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'دعوة إلى الطاولة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final qr = Semantics(
              button: true,
              label: 'تكبير رمز الانضمام',
              child: InkWell(
                onTap: _enlarge,
                borderRadius: BorderRadius.circular(16),
                child: _qr(c.maxWidth < 310 ? 170 : 180),
              ),
            );
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'امسح الرمز.\nخذ مكانك.',
                  style: TextStyle(
                    color: context.visual.textPrimary,
                    fontSize: 21,
                    height: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يختار كل لاعب اسمه، ثم توافق على طلبه هنا.',
                  style: TextStyle(
                    color: context.visual.textSecondary,
                    fontSize: 12,
                    height: 1.8,
                  ),
                ),
                TextButton(
                  onPressed: _enlarge,
                  child: const Text('تكبير الرمز'),
                ),
              ],
            );
            if (c.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) > 21) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: qr),
                  const SizedBox(height: 16),
                  info,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                qr,
                const SizedBox(width: 18),
                Expanded(child: info),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          key: const ValueKey('copy-join-link'),
          onPressed: _copying ? null : _copy,
          icon: const Icon(Icons.link_rounded),
          label: const Text('نسخ رابط الانضمام'),
        ),
        const SizedBox(height: 10),
        SelectableText(
          widget.url,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.visual.textSecondary,
            fontSize: 10,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

class LobbyCounts extends StatelessWidget {
  const LobbyCounts({
    super.key,
    required this.total,
    required this.linked,
    required this.pending,
    this.onPendingTap,
  });
  final int total, linked, pending;
  final VoidCallback? onPendingTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _count(
              context,
              'مقاعد مرتبطة',
              linked,
              Icons.verified_user_outlined,
              AppTheme.success,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onPendingTap,
              child: _count(
                context,
                'طلبات بانتظارك',
                pending,
                Icons.mark_email_unread_outlined,
                context.visual.iconColor2,
              ),
            ),
          ),
          Expanded(
            child: _count(
              context,
              'مقاعد الطاولة',
              total,
              Icons.groups_outlined,
              context.visual.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : linked / total,
          minHeight: 5,
          color: context.visual.iconColor2,
          backgroundColor: context.visual.surfaceHigh,
        ),
      ),
    ],
  );
  Widget _count(
    BuildContext context,
    String label,
    int number,
    IconData icon,
    Color color,
  ) => Column(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(
        '$number',
        style: TextStyle(
          color: context.visual.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 25,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.visual.textSecondary, fontSize: 11),
      ),
    ],
  );
}
