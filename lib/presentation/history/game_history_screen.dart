import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/widgets/newspaper_widget.dart';

class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});
  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  HistoryRepository get _repo => ref.read(historyRepositoryProvider);
  List<GameSummary>? _history;
  HistoryPage? _page;
  bool _loading = false;
  bool _hasError = false;
  bool _mutating = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool more = false}) async {
    if (_loading || _mutating || (more && !(_page?.hasMore ?? false))) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final page = await _repo.getHistoryPage(
        after: more ? _page?.cursor : null,
      );
      if (!mounted) return;
      final merged = more ? [...?_history, ...page.records] : page.records;
      final seen = <String>{};
      setState(() {
        _history = merged.where((e) => seen.add(e.id)).toList();
        _page = page;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String title, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: const Text(
            'سيتم حذف بيانات السجل والتقارير نهائياً. تبقى الإحصائيات الإجمالية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<bool> _delete(GameSummary record) async {
    if (_mutating || _loading || !await _confirm('حذف هذه المباراة؟', 'حذف')) {
      return false;
    }
    if (!mounted || _mutating || _loading) return false;
    setState(() => _mutating = true);
    try {
      await _repo.deleteGame(record.id);
      return mounted;
    } catch (_) {
      if (mounted) {
        _error('تعذر حذف المباراة. بقي السجل متاحاً لإعادة المحاولة.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _clearHistory() async {
    if (_mutating || _loading || !await _confirm('مسح السجل كله؟', 'مسح')) {
      return;
    }
    if (!mounted || _mutating || _loading) return;
    setState(() => _mutating = true);
    try {
      await _repo.clearHistory();
      if (mounted) {
        setState(() {
          _history = [];
          _page = const HistoryPage(records: [], hasMore: false);
        });
      }
    } catch (_) {
      if (mounted) {
        _error(
          'تعذر إكمال المسح. حدّث السجل ثم أعد المحاولة للمباريات المتبقية.',
        );
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  void _error(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _openReport(GameSummary summary) {
    var future = _repo.getGame(summary.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => FutureBuilder<GameRecord?>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Dialog(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جارٍ تحميل تقرير المباراة…'),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('تعذر تحميل التقرير'),
                actions: [
                  TextButton(
                    onPressed: () =>
                        refresh(() => future = _repo.getGame(summary.id)),
                    child: const Text('إعادة المحاولة'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق'),
                  ),
                ],
              );
            }
            final record = snapshot.data;
            if (record == null) {
              return AlertDialog(
                title: const Text('المباراة لم تعد متاحة'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق'),
                  ),
                ],
              );
            }
            return _reportDialog(ctx, record);
          },
        ),
      ),
    );
  }

  Widget _reportDialog(BuildContext dialogContext, GameRecord record) {
    GameState? state;
    if (record.gameStateJson != null) {
      try {
        state = GameState.fromJson(record.gameStateJson!);
      } catch (_) {
        // Older or incomplete snapshots can still show the saved text report.
      }
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state != null)
              NewspaperWidget(gameState: state)
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4ECD8),
                  border: Border.all(color: const Color(0xFFD4C4A8), width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '📰 جريدة المدينة',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Divider(color: Colors.black54, thickness: 2),
                    const SizedBox(height: 16),
                    Text(
                      record.newspaperText,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.visual.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 32,
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'إغلاق الجريدة',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('سجل المباريات'),
      actions: [
        IconButton(
          tooltip: 'مسح السجل',
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: _loading || _mutating ? null : _clearHistory,
        ),
      ],
    ),
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: context.visual.backgroundGradient),
      child: Column(
        children: [
          if (_mutating) const LinearProgressIndicator(),
          if (_hasError)
            TextButton(
              onPressed: _loading || _mutating ? null : _loadHistory,
              child: const Text('تعذر تحميل السجل · إعادة المحاولة'),
            ),
          Expanded(
            child: _history == null
                ? Center(
                    child: _hasError
                        ? const Text('تحقق من الاتصال ثم أعد المحاولة.')
                        : const CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollCacheExtent: const ScrollCacheExtent.pixels(200),
                      padding: const EdgeInsets.all(16),
                      itemCount: _history!.isEmpty
                          ? 1
                          : _history!.length +
                                ((_page?.hasMore ?? false) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_history!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: Text('لا يوجد سجل بعد')),
                          );
                        }
                        if (index == _history!.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _mutating
                                          ? null
                                          : () => _loadHistory(more: true),
                                      child: const Text('تحميل مباريات أقدم'),
                                    ),
                            ),
                          );
                        }
                        final record = _history![index];
                        final mafia = [
                          'المافيا',
                          'mafia',
                        ].contains(record.winningTeam);
                        final joker = [
                          'المهرج (الجوكر)',
                          'joker',
                          'المهرج',
                          'independent',
                        ].contains(record.winningTeam);
                        final color = mafia
                            ? AppTheme.mafiaPrimary
                            : joker
                            ? Colors.purpleAccent
                            : AppTheme.citizensPrimary;
                        final winner = mafia
                            ? 'المافيا'
                            : joker
                            ? 'الجوكر'
                            : 'المواطنون';
                        return Dismissible(
                          key: ValueKey(record.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _delete(record),
                          onDismissed: (_) => setState(
                            () =>
                                _history!.removeWhere((r) => r.id == record.id),
                          ),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            alignment: AlignmentDirectional.centerEnd,
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.error,
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: Icon(
                                joker
                                    ? Icons.theater_comedy_outlined
                                    : Icons.emoji_events_outlined,
                                color: color,
                                size: 32,
                              ),
                              title: Text(
                                'فوز $winner',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatDate(record.date)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${record.playerCount} لاعباً · تقرير المباراة',
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_left_rounded),
                              onTap: _mutating
                                  ? null
                                  : () => _openReport(record),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
