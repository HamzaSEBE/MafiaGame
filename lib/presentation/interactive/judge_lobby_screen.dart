import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mafia_nightfall/core/config/app_environment.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:mafia_nightfall/presentation/interactive/lobby_components.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_dashboard_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/session_exit_confirmation.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'package:mafia_nightfall/presentation/setup/role_review_screen.dart';

class JudgeLobbyScreen extends ConsumerStatefulWidget {
  const JudgeLobbyScreen({super.key});

  @override
  ConsumerState<JudgeLobbyScreen> createState() => _JudgeLobbyScreenState();
}

class _JudgeLobbyScreenState extends ConsumerState<JudgeLobbyScreen> {
  String? _sessionId;
  String? _creationError;
  bool _isCreating = true;
  bool _isStarting = false;
  bool _isExiting = false;
  bool _leaveRequested = false;
  final Map<String, bool> _requestTasks = {};
  final Set<String> _busySeats = {};
  final Set<String> _handledRequests = {};
  final _requestsKey = GlobalKey();
  String _requestKey(JoinRequest r) =>
      '${r.uid}/${r.timestamp.microsecondsSinceEpoch}';

  Stream<List<InteractiveSeat>>? _seatsStream;
  Stream<List<JoinRequest>>? _requestsStream;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    final state = ref.read(gameOrchestratorProvider);
    final service = ref.read(interactiveServiceProvider);

    try {
      final sessionId = await service.createSession(state);
      if (_leaveRequested || !mounted) {
        await service.endSession(sessionId);
        return;
      }
      setState(() {
        _sessionId = sessionId;
        _seatsStream = service.streamSeats(sessionId);
        _requestsStream = service.streamJoinRequests(sessionId);
        _isCreating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creationError = error.toString();
        _isCreating = false;
      });
    }
  }

  Future<void> _startGame(List<InteractiveSeat> seats) async {
    if (_isStarting ||
        _isExiting ||
        _requestTasks.isNotEmpty ||
        _sessionId == null) {
      return;
    }
    final expected = ref
        .read(gameOrchestratorProvider)
        .players
        .map((p) => p.id)
        .toSet();
    if (seats.isEmpty ||
        seats.length != expected.length ||
        seats.any(
          (s) => s.status != SeatStatus.linked || !expected.contains(s.id),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب ربط جميع المقاعد باللاعبين أولاً!')),
      );
      return;
    }

    setState(() => _isStarting = true);
    final service = ref.read(interactiveServiceProvider);
    final state = ref.read(gameOrchestratorProvider);
    try {
      // Publish roles the first time; when returning from the dashboard, keep
      // the current phase and action choices untouched.
      if (state.phase == Phase.roleReveal) {
        await service.syncGameState(_sessionId!, state, null, null);
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JudgeDashboardScreen(sessionId: _sessionId!),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر فتح لوحة الحكم: $error')));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _reviewRoles() async {
    if (ref.read(gameOrchestratorProvider).phase != Phase.roleReveal) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RoleReviewScreen(returnToLobby: true),
      ),
    );
  }

  Future<void> _exitSession() async {
    if (_isExiting) return;
    final confirmed = await confirmEndInteractiveSession(context);
    if (!confirmed || !mounted) return;

    setState(() => _isExiting = true);
    final sessionId = _sessionId;
    _leaveRequested = true;

    try {
      if (sessionId != null) {
        await ref
            .read(interactiveServiceProvider)
            .endSession(sessionId)
            .timeout(const Duration(seconds: 15));
      }
      if (!mounted) return;
      await ref.read(gameOrchestratorProvider.notifier).endGame();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إنهاء الجلسة. افحص الاتصال ثم أعد المحاولة: $error',
          ),
        ),
      );
    }
  }

  Widget _guardSystemBack(Widget child) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSession();
      },
      child: child,
    );
  }

  void _retryStreams() {
    final id = _sessionId;
    if (id == null) return;
    final service = ref.read(interactiveServiceProvider);
    setState(() {
      _seatsStream = service.streamSeats(id);
      _requestsStream = service.streamJoinRequests(id);
    });
  }

  Future<void> _handleRequest(
    JoinRequest request, {
    required bool approve,
  }) async {
    final id = _sessionId;
    if (id == null ||
        _requestTasks.containsKey(request.uid) ||
        _busySeats.contains(request.seatId) ||
        _isStarting ||
        _isExiting) {
      return;
    }
    setState(() {
      _requestTasks[request.uid] = approve;
      _busySeats.add(request.seatId);
    });
    try {
      final service = ref.read(interactiveServiceProvider);
      await (approve
              ? service.approveJoinRequest(id, request.seatId, request.uid)
              : service.rejectJoinRequest(id, request.uid))
          .timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _handledRequests.add(_requestKey(request)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message
                  : 'لم يتأكد تنفيذ الطلب. تحقق من الاتصال ثم أعد المحاولة.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _requestTasks.remove(request.uid);
          _busySeats.remove(request.seatId);
        });
      }
    }
  }

  Widget _section(String title, {String? detail}) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.visual.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (detail != null)
          Text(
            detail,
            style: TextStyle(color: context.visual.textSecondary, fontSize: 12),
          ),
      ],
    ),
  );
  Widget _requestCard(JoinRequest request, List<InteractiveSeat> seats) {
    final seat = seats.where((s) => s.id == request.seatId).firstOrNull;
    final busy = _requestTasks.containsKey(request.uid);
    final disabled =
        _isStarting || _isExiting || _busySeats.contains(request.seatId);
    final available = seat != null && seat.status != SeatStatus.linked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LobbyPanel(
        key: ValueKey('request-${request.uid}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.visual.palette.cardEnd,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person_add_alt_rounded,
                    color: context.visual.iconColor2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.displayName,
                        style: TextStyle(
                          color: context.visual.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        available
                            ? 'يطلب مقعد ${seat.playerName}'
                            : 'هذا المقعد لم يعد متاحاً',
                        style: TextStyle(
                          color: context.visual.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (busy)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _requestTasks[request.uid] == true
                      ? 'جارٍ تأكيد ربط المقعد…'
                      : 'جارٍ رفض الطلب…',
                  style: TextStyle(
                    color: context.visual.iconColor2,
                    fontSize: 12,
                  ),
                ),
              ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: ValueKey('approve-${request.uid}'),
                  onPressed: disabled || !available
                      ? null
                      : () => _handleRequest(request, approve: true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('قبول اللاعب'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('reject-${request.uid}'),
                  onPressed: disabled
                      ? null
                      : () => _handleRequest(request, approve: false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('رفض'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatCard(InteractiveSeat seat) {
    final linked = seat.status == SeatStatus.linked;
    return Container(
      key: ValueKey('seat-${seat.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.visual.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: linked
              ? AppTheme.success.withValues(alpha: .28)
              : context.visual.surfaceHigh,
        ),
      ),
      child: Row(
        children: [
          Icon(
            linked
                ? Icons.check_circle_outline_rounded
                : Icons.person_outline_rounded,
            color: linked ? AppTheme.success : context.visual.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seat.playerName,
                  style: TextStyle(
                    color: context.visual.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  linked ? 'تم ربط المقعد' : 'بانتظار الانضمام',
                  style: TextStyle(
                    color: linked
                        ? AppTheme.success
                        : context.visual.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _streamError(String text) => LobbyPanel(
    child: Column(
      children: [
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _retryStreams,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المزامنة'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final phase = ref.watch(gameOrchestratorProvider).phase;
    if (_isCreating || _sessionId == null) {
      return _guardSystemBack(
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: _isExiting ? null : _exitSession,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: context.visual.backgroundGradient,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LobbyPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _creationError == null
                            ? Icons.door_sliding_outlined
                            : Icons.wifi_off_rounded,
                        size: 40,
                        color: context.visual.iconColor2,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _creationError == null
                            ? 'نجهّز طاولة المدينة…'
                            : 'تعذر فتح صالة اللاعبين',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _creationError == null
                            ? 'لحظات ويصبح رابط دعوتك جاهزاً.'
                            : 'تحقق من الاتصال ثم أعد المحاولة.',
                        textAlign: TextAlign.center,
                      ),
                      if (_creationError != null)
                        TextButton.icon(
                          onPressed: () {
                            if (_isCreating) return;
                            setState(() {
                              _isCreating = true;
                              _creationError = null;
                            });
                            _createSession();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final url = AppEnvironment.joinLink(
      _sessionId!,
      protocol: ref.read(interactiveServiceProvider).protocolFor(_sessionId!),
    );
    return _guardSystemBack(
      StreamBuilder<List<InteractiveSeat>>(
        stream: _seatsStream,
        builder: (context, seatsSnap) => StreamBuilder<List<JoinRequest>>(
          stream: _requestsStream,
          builder: (context, requestsSnap) {
            final seats = seatsSnap.data ?? const <InteractiveSeat>[];
            final requests =
                (requestsSnap.data ?? const <JoinRequest>[])
                    .where((r) => !_handledRequests.contains(_requestKey(r)))
                    .toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            final linked = seats
                .where((s) => s.status == SeatStatus.linked)
                .length;
            final expected = ref
                .read(gameOrchestratorProvider)
                .players
                .map((p) => p.id)
                .toSet();
            final ready =
                seatsSnap.hasData &&
                requestsSnap.hasData &&
                !seatsSnap.hasError &&
                !requestsSnap.hasError &&
                seats.isNotEmpty &&
                seats.length == expected.length &&
                seats.every(
                  (s) =>
                      s.status == SeatStatus.linked && expected.contains(s.id),
                );
            List<Widget> roster() => [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (seatsSnap.hasError || requestsSnap.hasError)
                      _streamError(
                        'تعذرت مزامنة المقاعد أو الطلبات. لن تبدأ الجلسة حتى تتجدد البيانات.',
                      ),
                    Container(
                      key: _requestsKey,
                      child: _section(
                        'طلبات الانضمام',
                        detail: '${requests.length} طلب',
                      ),
                    ),
                    if (!requestsSnap.hasData && !requestsSnap.hasError)
                      const LinearProgressIndicator(),
                    if (requests.isEmpty && requestsSnap.hasData)
                      LobbyPanel(
                        child: Row(
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: context.visual.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'لا توجد طلبات معلّقة. ستظهر هنا مباشرة عند انضمام اللاعبين.',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SliverList.builder(
                itemCount: requests.length,
                itemBuilder: (context, i) => _requestCard(requests[i], seats),
              ),
              SliverToBoxAdapter(
                child: _section(
                  'مقاعد الطاولة',
                  detail: '$linked / ${seats.length}',
                ),
              ),
              if (!seatsSnap.hasData && !seatsSnap.hasError)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              SliverList.builder(
                itemCount: seats.length,
                itemBuilder: (context, i) => _seatCard(seats[i]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ];
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(
                  tooltip: 'إنهاء الجلسة',
                  onPressed: _isExiting ? null : _exitSession,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: const Text('صالة اللاعبين'),
              ),
              body: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: context.visual.backgroundGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final hero = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'المدينة تجمع أسرارها',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: context.visual.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'دعوتك جاهزة. اجمع اللاعبين، وافتح فصلاً جديداً.',
                                style: TextStyle(
                                  color: context.visual.textSecondary,
                                  height: 1.8,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 22),
                              LobbyCounts(
                                total: seats.length,
                                linked: linked,
                                pending: requests.length,
                                onPendingTap: requests.isEmpty
                                    ? null
                                    : () {
                                        final target =
                                            _requestsKey.currentContext;
                                        if (target != null) {
                                          Scrollable.ensureVisible(
                                            target,
                                            alignment: 0,
                                            duration:
                                                MediaQuery.of(
                                                  context,
                                                ).disableAnimations
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 220,
                                                  ),
                                          );
                                        }
                                      },
                              ),
                              const SizedBox(height: 22),
                              LobbyInvite(url: url),
                            ],
                          );
                          if (c.maxWidth >= 860) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 360,
                                    child: SingleChildScrollView(child: hero),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: CustomScrollView(slivers: roster()),
                                  ),
                                ],
                              ),
                            );
                          }
                          return CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  0,
                                ),
                                sliver: SliverToBoxAdapter(child: hero),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverMainAxisGroup(slivers: roster()),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.visual.background,
                  border: Border(
                    top: BorderSide(color: context.visual.surfaceHigh),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (phase == Phase.roleReveal)
                              TextButton.icon(
                                onPressed: _isStarting || _isExiting
                                    ? null
                                    : _reviewRoles,
                                icon: const Icon(Icons.style_outlined),
                                label: const Text(
                                  'مراجعة الأدوار أو إعادة توزيعها',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ElevatedButton.icon(
                              key: const ValueKey('start-lobby-game'),
                              onPressed:
                                  !ready ||
                                      _isStarting ||
                                      _isExiting ||
                                      _requestTasks.isNotEmpty ||
                                      phase == Phase.winCheck
                                  ? null
                                  : () => _startGame(seats),
                              icon: Icon(
                                _isStarting
                                    ? Icons.hourglass_top_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(
                                _isStarting
                                    ? 'جارٍ فتح اللعبة…'
                                    : phase == Phase.winCheck
                                    ? 'انتهت اللعبة'
                                    : !ready
                                    ? 'بانتظار ربط جميع المقاعد'
                                    : phase == Phase.roleReveal
                                    ? 'بدء الحكاية'
                                    : 'استئناف اللعبة',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
