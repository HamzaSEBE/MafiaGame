import 'dart:async';
import 'package:mafia_nightfall/presentation/interactive/web/player_components.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_session_ended_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class WebPlayerScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String seatId;

  const WebPlayerScreen({
    super.key,
    required this.sessionId,
    required this.seatId,
  });

  @override
  ConsumerState<WebPlayerScreen> createState() => _WebPlayerScreenState();
}

class _WebPlayerScreenState extends ConsumerState<WebPlayerScreen>
    with WidgetsBindingObserver {
  final Map<String, String> _selectedTargets = {};
  final Set<String> _submittingActions = {};
  bool _isShowingRole = false;
  bool _sessionEnded = false;
  Phase? _lastPhase;
  int? _lastActionRevision;
  String? _lastSeenAnnouncement;
  StreamSubscription<InteractiveSession?>? _sessionSubscription;
  bool _privateResultVisible = false;
  String? _lastPrivateResult;
  Timer? _privateResultTimer;

  late final Stream<InteractiveSession?> _sessionStream;
  late final Stream<InteractiveSeat?> _seatStream;
  late final Stream<InteractiveSecret?> _secretStream;
  late final Stream<List<InteractiveSeat>> _seatsStream;
  late final Stream<List<ActionRequest>> _myActionsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final service = ref.read(interactiveServiceProvider);
    _sessionStream = service.streamSession(widget.sessionId);
    _seatStream = service.streamMySeat(widget.sessionId, widget.seatId);
    _secretStream = service.streamMySecret(widget.sessionId, widget.seatId);
    _seatsStream = service.streamSeats(widget.sessionId);
    _myActionsStream = service.uid == null
        ? Stream.value(const [])
        : service.streamMyActionRequests(widget.sessionId, service.uid!);
    _sessionSubscription = _sessionStream.listen((session) {
      if (!mounted) return;
      if (session?.status == SessionStatus.finished) {
        setState(() => _sessionEnded = true);
      }

      if (session?.globalAnnouncement != null &&
          session?.globalAnnouncement != _lastSeenAnnouncement) {
        _lastSeenAnnouncement = session?.globalAnnouncement;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            scrollable: true,
            backgroundColor: context.visual.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: context.visual.accent, width: 2),
            ),
            icon: Icon(
              Icons.campaign_outlined,
              color: context.visual.iconColor2,
            ),
            title: const Text(
              'إفصاح شيخ المواطنين',
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppTheme.roleImage(Role.citizensSheikh),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session!.globalAnnouncement!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.visual.textPrimary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.visual.accent,
                  ),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }, onError: (Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() {
        _isShowingRole = false;
        _privateResultVisible = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription?.cancel();
    _privateResultTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitAction(
    String actionType,
    String targetId,
    int expectedRevision, {
    int expectedActionVersion = 0,
  }) async {
    if (_submittingActions.contains(actionType)) return;
    setState(() => _submittingActions.add(actionType));

    try {
      await ref
          .read(interactiveServiceProvider)
          .submitAction(
            widget.sessionId,
            widget.seatId,
            actionType,
            targetId,
            expectedRevision: expectedRevision,
            expectedActionVersion: expectedActionVersion,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر إرسال الحركة: $error',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingActions.remove(actionType));
      }
    }
  }

  void _resetForRevision(InteractiveSession session) {
    if (_lastPhase == session.phase &&
        _lastActionRevision == session.actionRevision) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _lastPhase = session.phase;
        _lastActionRevision = session.actionRevision;
        _selectedTargets.clear();
        _submittingActions.clear();
        _isShowingRole = false;
      });
    });
  }

  String _phaseTitle(InteractiveSession s) => s.status == SessionStatus.waiting
      ? 'قبل بداية الحكاية'
      : switch (s.phase) {
          Phase.roleReveal => 'اكتشف دورك في المدينة',
          Phase.night || Phase.nightResolution => 'المدينة تُغمض عينيها',
          Phase.day => 'الشمس كشفت شيئاً',
          Phase.voting => 'صوتك يغيّر الحكاية',
          _ => 'القرار بيد الحكم',
        };
  Widget _page(Widget child, {InteractiveSession? session}) => PlayerPage(
    title: session == null ? 'بطاقتك في المدينة' : _phaseTitle(session),
    subtitle: session?.phase == Phase.voting
        ? 'اختر بعناية. يمكنك تغيير صوتك ما دام التصويت مفتوحاً.'
        : 'احتفظ بأسرارك، وتابع إشارة الحكم. ستظهر حركتك هنا عندما يحين دورك.',
    status: session == null
        ? 'جارٍ الاتصال'
        : 'الجولة ${session.round} · ${session.phase == Phase.voting
              ? 'التصويت'
              : session.phase == Phase.day
              ? 'النهار'
              : session.phase == Phase.night
              ? 'الليل'
              : 'طاولة اللعب'}',
    child: child,
  );
  @override
  Widget build(BuildContext context) {
    if (_sessionEnded) return const WebSessionEndedScreen();
    final service = ref.read(interactiveServiceProvider);
    return StreamBuilder<InteractiveSession?>(
      stream: _sessionStream,
      builder: (context, roomSnap) {
        if (roomSnap.hasError) {
          return _page(
            _buildError(
              'تعذر الاتصال بالجلسة. تحقق من الإنترنت ثم أعد فتح الرابط.',
            ),
          );
        }
        final session = roomSnap.data;
        if (session?.status == SessionStatus.finished ||
            (roomSnap.connectionState == ConnectionState.active &&
                session == null)) {
          return const WebSessionEndedScreen();
        }
        if (session == null) {
          return _page(
            const PlayerNotice(
              title: 'نوصلك بالمدينة…',
              message: 'أبقِ الصفحة مفتوحة حتى يكتمل الاتصال.',
            ),
          );
        }
        _resetForRevision(session);
        return StreamBuilder<InteractiveSeat?>(
          stream: _seatStream,
          builder: (context, seatSnap) {
            if (seatSnap.hasError) {
              return _page(
                _buildError('تعذر تحميل مقعدك. أعد فتح رابط الجلسة.'),
                session: session,
              );
            }
            return StreamBuilder<InteractiveSecret?>(
              stream: _secretStream,
              builder: (context, secretSnap) {
                if (secretSnap.hasError) {
                  return _page(
                    _buildError(
                      'تعذر تحميل بطاقتك. تحقق من اتصالك ثم أعد فتح الرابط.',
                    ),
                    session: session,
                  );
                }
                final seat = seatSnap.data, secret = secretSnap.data;
                if (seat == null || secret == null) {
                  return _page(
                    const PlayerNotice(
                      title: 'نجهّز بطاقتك…',
                      message: 'ستظهر هنا بعد اكتمال ربط مقعدك.',
                    ),
                    session: session,
                  );
                }
                if (!seat.isAlive &&
                    !secret.requiredActions.any(
                      (a) => a.type == 'retaliation',
                    )) {
                  return _page(_buildDeadScreen(), session: session);
                }
                return _page(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPrivateRoleCard(seat, secret),
                      if (seat.isAlive &&
                          secret.role == Role.citizensSheikh &&
                          !seat.isCitizenSheikhRevealed &&
                          (session.phase == Phase.day ||
                              session.phase == Phase.voting)) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed:
                              !session.actionsOpen ||
                                  secret.promptRevision !=
                                      session.actionRevision ||
                                  _submittingActions.contains(
                                    'citizenSheikhReveal',
                                  )
                              ? null
                              : () => _submitAction(
                                  'citizenSheikhReveal',
                                  widget.seatId,
                                  session.actionRevision,
                                ),
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text(
                            'إفصاح هويتك علناً · مرة واحدة',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildActionArea(session, seat, secret, service),
                    ],
                  ),
                  session: session,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPrivateRoleCard(InteractiveSeat seat, InteractiveSecret secret) {
    final role = secret.role;
    final visible = _isShowingRole && role != null;
    void conceal() {
      if (mounted && _isShowingRole) setState(() => _isShowingRole = false);
    }

    return Focus(
      onFocusChange: (focused) {
        if (!focused) conceal();
      },
      onKeyEvent: (node, event) {
        if (event.logicalKey != LogicalKeyboardKey.space &&
            event.logicalKey != LogicalKeyboardKey.enter) {
          return KeyEventResult.ignored;
        }
        setState(() => _isShowingRole = event is! KeyUpEvent && role != null);
        return KeyEventResult.handled;
      },
      child: MouseRegion(
        onExit: (_) => conceal(),
        child: Listener(
          onPointerDown: role == null
              ? null
              : (_) => setState(() => _isShowingRole = true),
          onPointerUp: (_) => conceal(),
          onPointerCancel: (_) => conceal(),
          child: Semantics(
            label: visible
                ? 'بطاقتك مكشوفة. ارفع إصبعك لإخفائها.'
                : 'بطاقتك السرية. اضغط باستمرار لكشفها.',
            child: PlayerPanel(
              highlight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        visible
                            ? Icons.visibility_outlined
                            : Icons.lock_outline_rounded,
                        size: 18,
                        color: context.visual.iconColor2,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          visible ? 'لعيونك فقط' : 'هوية محمية',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.visual.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.fingerprint_rounded,
                        size: 26,
                        color: context.visual.iconColor2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    seat.playerName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: context.visual.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visible) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        AppTheme.roleImage(role),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.roleName(role),
                      style: TextStyle(
                        color: AppTheme.roleColor(role),
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      AppTheme.roleAbilityDescription(role),
                      style: TextStyle(
                        color: context.visual.textSecondary,
                        height: 1.7,
                      ),
                    ),
                    if (secret.isSniper) ...[
                      const SizedBox(height: 12),
                      const PlayerTag(
                        label: 'رصاصة قنّاص واحدة',
                        icon: Icons.gps_fixed_rounded,
                        color: AppTheme.warning,
                      ),
                    ],
                    if (secret.mafiaTeammates.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'زملاؤك في المافيا: ${secret.mafiaTeammates.join('، ')}',
                        style: TextStyle(
                          color: context.visual.textPrimary,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ] else ...[
                    Divider(color: context.visual.surfaceHigh),
                    const SizedBox(height: 12),
                    Text(
                      role == null
                          ? 'دورك لم يُوزّع بعد'
                          : 'اضغط باستمرار لكشف دورك',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.visual.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role == null
                          ? 'انتظر الحكم حتى يجهّز الأدوار.'
                          : 'ارفع إصبعك لإخفائه فوراً. تأكد أن الشاشة لك وحدك.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                        color: context.visual.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(
    InteractiveSession session,
    InteractiveSeat seat,
    InteractiveSecret secret,
    InteractiveService service,
  ) {
    if (service.uid == null) {
      return _buildError('انتهى اتصالك. أعد فتح رابط الجلسة.');
    }
    return StreamBuilder<List<ActionRequest>>(
      stream: _myActionsStream,
      builder: (context, actionSnap) {
        if (actionSnap.hasError) {
          return _buildError(
            'تعذر تأكيد حركاتك. تحقق من الاتصال ثم أعد فتح الرابط.',
          );
        }
        final actions = (actionSnap.data ?? <ActionRequest>[])
            .where((a) => a.revision == session.actionRevision)
            .toList();
        final submitted = actions.map((a) => a.actionType).toSet();
        if (secret.requiredActions.isEmpty) {
          return Column(
            children: [
              if (secret.privateResult != null) ...[
                _buildPrivateResult(secret.privateResult!),
                const SizedBox(height: 16),
              ],
              PlayerNotice(
                title: session.phase == Phase.day
                    ? 'استمع. ناقش. راقب.'
                    : 'كل دور يأتي في وقته',
                message: session.phase == Phase.roleReveal
                    ? 'اكشف بطاقتك بالضغط المستمر ثم انتظر إشارة الحكم.'
                    : session.phase == Phase.day
                    ? 'ناقش اللاعبين وحافظ على سرّك. ستظهر خيارات التصويت عندما يفتحها الحكم.'
                    : 'لا يوجد إجراء مطلوب منك الآن. أبقِ الصفحة مفتوحة وتابع إشارة الحكم.',
                icon: session.phase == Phase.day
                    ? Icons.wb_sunny_outlined
                    : Icons.nights_stay_outlined,
              ),
            ],
          );
        }
        return StreamBuilder<List<InteractiveSeat>>(
          stream: _seatsStream,
          builder: (context, seatsSnap) {
            if (seatsSnap.hasError) {
              return _buildError('تعذر تحميل أسماء اللاعبين. تحقق من الاتصال.');
            }
            if (!seatsSnap.hasData) {
              return const PlayerNotice(
                title: 'نجهّز خياراتك…',
                message: 'جارٍ تحميل اللاعبين المتاحين.',
              );
            }
            final seats = seatsSnap.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (secret.privateResult != null) ...[
                  _buildPrivateResult(secret.privateResult!),
                  const SizedBox(height: 16),
                ],
                for (final prompt in secret.requiredActions) ...[
                  Builder(
                    builder: (context) {
                      final isVote = prompt.type == 'vote';
                      final previous = actions
                          .where((a) => a.actionType == prompt.type)
                          .firstOrNull;
                      final completed =
                          submitted.contains(prompt.type) && !isVote;
                      final candidate =
                          _selectedTargets[prompt.type] ??
                          (isVote ? previous?.targetId : null);
                      final selected =
                          prompt.availableTargets.contains(candidate)
                          ? candidate
                          : null;
                      final busy = _submittingActions.contains(prompt.type);
                      final enabled =
                          session.actionsOpen &&
                          secret.promptRevision == session.actionRevision &&
                          !busy &&
                          actionSnap.hasData;
                      final targets = seats
                          .where(
                            (s) =>
                                prompt.availableTargets.contains(s.id) &&
                                !(prompt.type == 'sniperKill' &&
                                    s.id == widget.seatId),
                          )
                          .toList();
                      return PlayerPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _actionTitle(prompt.type),
                                    style: TextStyle(
                                      color: context.visual.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isVote
                                      ? Icons.how_to_vote_outlined
                                      : Icons.touch_app_outlined,
                                  color: context.visual.iconColor2,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (completed)
                              const PlayerNotice(
                                title: 'وصل قرارك',
                                message:
                                    'تم إرسال هذه الحركة. بانتظار بقية الأدوار…',
                                icon: Icons.check_circle_outline_rounded,
                              )
                            else ...[
                              Text(
                                !session.actionsOpen
                                    ? 'أغلق الحكم استقبال الحركات. انتظر النتيجة.'
                                    : isVote && previous != null
                                    ? 'تصويتك الحالي: ${seats.where((s) => s.id == previous.targetId).firstOrNull?.playerName ?? 'لاعب'}. يمكنك تغييره قبل الفرز.'
                                    : 'اختر لاعباً ثم أكّد قرارك. لا يُرسل اختيارك حتى التأكيد.',
                                style: TextStyle(
                                  color: context.visual.textSecondary,
                                  height: 1.8,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 18),
                              for (final target in targets)
                                PlayerChoice(
                                  name: target.playerName,
                                  selected: selected == target.id,
                                  badge: target.isCitizenSheikhRevealed
                                      ? 'صوته ×3'
                                      : null,
                                  onTap: enabled
                                      ? () => setState(
                                          () => _selectedTargets[prompt.type] =
                                              target.id,
                                        )
                                      : null,
                                ),
                              if (targets.isEmpty &&
                                  prompt.type != 'sniperKill')
                                const Text('لا توجد أهداف متاحة لهذه الحركة.'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: enabled && selected != null
                                    ? () => _submitAction(
                                        prompt.type,
                                        selected,
                                        session.actionRevision,
                                        expectedActionVersion:
                                            previous?.submissionVersion ?? 0,
                                      )
                                    : null,
                                icon: Icon(
                                  busy
                                      ? Icons.hourglass_top_rounded
                                      : Icons.check_rounded,
                                ),
                                label: Text(
                                  busy
                                      ? 'جارٍ إرسال قرارك…'
                                      : isVote && previous != null
                                      ? 'تأكيد تغيير التصويت'
                                      : 'تأكيد وإرسال',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (prompt.type == 'sniperKill' &&
                                  prompt.availableTargets.contains(
                                    widget.seatId,
                                  )) ...[
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: enabled
                                      ? () => _submitAction(
                                          prompt.type,
                                          widget.seatId,
                                          session.actionRevision,
                                          expectedActionVersion:
                                              previous?.submissionVersion ?? 0,
                                        )
                                      : null,
                                  child: const Text(
                                    'تخطي القنص · احتفظ بالرصاصة',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        );
      },
    );
  }

  String _actionTitle(String type) => switch (type) {
    'vote' => 'صوّت ضد لاعب للإقصاء',
    'assassination' => 'اختر هدف الاغتيال',
    'protection' => 'اختر من تريد حمايته',
    'investigation' => 'اختر لاعبًا للتحقيق معه',
    'silence' => 'اختر من تريد إسكات صوته',
    'retaliation' => 'اختر هدف الانتقام',
    'sniperKill' => 'رصاصة واحدة. قرارك.',
    'sleep' => 'لا يوجد لديك قدرة (اختر اسمك للتأكيد)',
    _ => 'اختر هدف الحركة',
  };

  Widget _buildPrivateResult(String result) {
    if (result != _lastPrivateResult) {
      _lastPrivateResult = result;
      _privateResultVisible = true;
      _privateResultTimer?.cancel();
      _privateResultTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _privateResultVisible = false);
      });
    }
    return PlayerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, color: context.visual.iconColor2),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'نتيجة خاصة بك',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_privateResultVisible)
            Text(
              result,
              style: TextStyle(
                color: context.visual.textPrimary,
                fontSize: 16,
                height: 1.8,
              ),
            )
          else
            const Text('أُخفيت النتيجة لحماية خصوصيتك.'),
          TextButton(
            onPressed: () =>
                setState(() => _privateResultVisible = !_privateResultVisible),
            child: Text(
              _privateResultVisible ? 'إخفاء النتيجة' : 'عرض النتيجة',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadScreen() => const PlayerNotice(
    title: 'انتهى دورك… وبقيت الحكاية',
    message:
        'أصبحت خارج اللعب. تابع مجريات المدينة بصمت، ولا تشارك في النقاش أو التصويت.',
    icon: Icons.nightlight_outlined,
  );
  Widget _buildError(String message) => PlayerNotice(
    title: 'نحتاج اتصالك من جديد',
    message: message,
    error: true,
    icon: Icons.wifi_off_rounded,
  );
}
