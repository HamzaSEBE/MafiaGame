import 'dart:async';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'dart:math' as math;

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

class _WebPlayerScreenState extends ConsumerState<WebPlayerScreen> {
  final Map<String, String> _selectedTargets = {};
  final Set<String> _submittingActions = {};
  bool _isShowingRole = false;
  bool _sessionEnded = false;
  Phase? _lastPhase;
  int? _lastActionRevision;
  StreamSubscription<InteractiveSession?>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    final service = ref.read(interactiveServiceProvider);
    _sessionSubscription = service.streamSession(widget.sessionId).listen(
      (session) {
        if (!mounted || session?.status != SessionStatus.finished) return;
        setState(() => _sessionEnded = true);
      },
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _submitAction(
    String actionType,
    String targetId,
  ) async {
    if (_submittingActions.contains(actionType)) return;
    setState(() => _submittingActions.add(actionType));

    try {
      await ref.read(interactiveServiceProvider).submitAction(
            widget.sessionId,
            widget.seatId,
            actionType,
            targetId,
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

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    if (_sessionEnded) return const WebSessionEndedScreen();

    final service = ref.read(interactiveServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('بطاقتك السرية', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<InteractiveSession?>(
        stream: service.streamSession(widget.sessionId),
        builder: (context, sessionSnap) {
          if (sessionSnap.hasError) {
            return _buildError('تعذر الاتصال بالجلسة: ${sessionSnap.error}');
          }
          final session = sessionSnap.data;
          if (session?.status == SessionStatus.finished) {
            return const WebSessionEndedScreen();
          }
          if (session == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }
          _resetForRevision(session);

          return StreamBuilder<InteractiveSeat?>(
            stream: service.streamMySeat(widget.sessionId, widget.seatId),
            builder: (context, seatSnap) {
              if (seatSnap.hasError) {
                return _buildError('تعذر تحميل مقعدك: ${seatSnap.error}');
              }
              final seat = seatSnap.data;

              return StreamBuilder<InteractiveSecret?>(
                stream: service.streamMySecret(widget.sessionId, widget.seatId),
                builder: (context, secretSnap) {
                  if (secretSnap.hasError) {
                    return _buildError(
                        'تعذر تحميل بطاقتك: ${secretSnap.error}');
                  }
                  final secret = secretSnap.data;
                  if (seat == null || secret == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                    );
                  }

                  final canUseDeadAbility = secret.requiredActions
                      .any((action) => action.type == 'retaliation');
                  if (!seat.isAlive && !canUseDeadAbility) {
                    return _buildDeadScreen();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPrivateRoleCard(seat, secret),
                        if (seat.isAlive &&
                            secret.role == Role.citizensSheikh &&
                            !seat.isCitizenSheikhRevealed) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              service.submitAction(
                                  widget.sessionId,
                                  widget.seatId,
                                  'citizenSheikhReveal',
                                  widget.seatId);
                            },
                            icon:
                                const Icon(Icons.campaign, color: Colors.black),
                            label: const Text('إفصاح هويتك علناً (مرة واحدة)',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildActionArea(
                            session,
                            seat,
                            secret,
                            service,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrivateRoleCard(InteractiveSeat seat, InteractiveSecret secret) {
    final role = secret.role;
    final roleColor =
        role == null ? Colors.orangeAccent : AppTheme.roleColor(role);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown:
          role == null ? null : (_) => setState(() => _isShowingRole = true),
      onPointerUp: (_) => setState(() => _isShowingRole = false),
      onPointerCancel: (_) => setState(() => _isShowingRole = false),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        transitionBuilder: (child, animation) => AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY((1 - animation.value) * math.pi / 2),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(_isShowingRole && role != null),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 156),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isShowingRole && role != null
                  ? (role.team.name == 'mafia'
                      ? const [Color(0xFF3A1515), Color(0xFF1A0A0A)]
                      : const [Color(0xFF15223A), Color(0xFF0A101A)])
                  : const [Color(0xFF211B15), Color(0xFF100D0A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isShowingRole
                  ? roleColor
                  : Colors.orangeAccent.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: roleColor.withValues(alpha: 0.16),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            children: [
              if (_isShowingRole && role != null)
                ClipOval(
                  child: Image.asset(
                    AppTheme.roleImage(role),
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                  ),
                )
              else
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orangeAccent.withValues(alpha: 0.12),
                  child: Icon(
                    role == null ? Icons.hourglass_top : Icons.fingerprint,
                    color: Colors.orangeAccent,
                    size: 42,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seat.playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == null
                          ? 'بانتظار توزيع الأدوار'
                          : _isShowingRole
                              ? AppTheme.roleArabicName(role)
                              : 'اضغط مطولًا لكشف بطاقتك السرية',
                      style: TextStyle(
                        color: _isShowingRole ? roleColor : Colors.white70,
                        fontSize: _isShowingRole ? 21 : 14,
                        fontWeight: _isShowingRole
                            ? FontWeight.w900
                            : FontWeight.normal,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (_isShowingRole && role != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppTheme.roleAbilityDescription(role),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
    final playerUid = service.uid;
    if (playerUid == null) {
      return _buildError('انتهى اتصال اللاعب. أعد فتح رابط الجلسة.');
    }

    return StreamBuilder<List<ActionRequest>>(
      stream: service.streamMyActionRequests(session.id, playerUid),
      builder: (context, actionSnap) {
        if (actionSnap.hasError) {
          return _buildError('تعذر تحميل حركاتك: ${actionSnap.error}');
        }
        final myActions = actionSnap.data ?? const <ActionRequest>[];
        final submittedTypes = myActions
            .where((action) => action.revision == session.actionRevision)
            .map((action) => action.actionType)
            .toSet();
        final previousVote =
            myActions.where((action) => action.actionType == 'vote').toList()
              ..sort((left, right) {
                final revisionOrder = left.revision.compareTo(right.revision);
                return revisionOrder != 0
                    ? revisionOrder
                    : left.timestamp.compareTo(right.timestamp);
              });

        if (secret.requiredActions.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (secret.privateResult != null)
                _buildPrivateResult(secret.privateResult!),
              const SizedBox(height: 12),
              Text(
                session.phase == Phase.roleReveal
                    ? 'اكشف بطاقتك بالضغط المطوّل، ثم انتظر إشارة الحكم.'
                    : session.phase == Phase.day
                        ? 'نهار هادئ... تحدث مع الجميع.'
                        : 'انتظر دورك...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          );
        }

        return StreamBuilder<List<InteractiveSeat>>(
          stream: service.streamSeats(session.id),
          builder: (context, seatsSnap) {
            if (seatsSnap.hasError) {
              return _buildError('تعذر تحميل اللاعبين: ${seatsSnap.error}');
            }
            final seats = seatsSnap.data ?? const <InteractiveSeat>[];
            return ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (secret.privateResult != null) ...[
                  _buildPrivateResult(secret.privateResult!),
                  const SizedBox(height: 12),
                ],
                ...secret.requiredActions.map((prompt) {
                  final completed = submittedTypes.contains(prompt.type);
                  final isVote = prompt.type == 'vote';
                  final selectedTarget = _selectedTargets[prompt.type] ??
                      (isVote && previousVote.isNotEmpty
                          ? previousVote.last.targetId
                          : null);
                  final actionCompleted = completed && !isVote;
                  final targets = seats
                      .where((candidate) =>
                          prompt.availableTargets.contains(candidate.id))
                      .toList();
                  return Card(
                    color: const Color(0xFF17151A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: actionCompleted
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : Colors.orangeAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _actionTitle(prompt.type),
                            style: TextStyle(
                              color: actionCompleted
                                  ? Colors.greenAccent
                                  : Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (actionCompleted)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'تم إرسال هذه الحركة. بانتظار بقية الأدوار...',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            )
                          else ...[
                            if (isVote && previousVote.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'تصويتك الحالي: ${seats.where((candidate) => candidate.id == previousVote.last.targetId).firstOrNull?.playerName ?? 'لاعب غادر الجولة'}. يمكنك تغييره قبل فرز الأصوات.',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            ...targets.map((target) => RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Text(
                                        target.playerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      if (target.isCitizenSheikhRevealed) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.orangeAccent,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: const Text('x3',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        )
                                      ]
                                    ],
                                  ),
                                  value: target.id,
                                  groupValue: selectedTarget,
                                  activeColor: Colors.orangeAccent,
                                  onChanged: (value) => setState(() {
                                    if (value != null) {
                                      _selectedTargets[prompt.type] = value;
                                    }
                                  }),
                                )),
                            ElevatedButton(
                              onPressed: selectedTarget == null ||
                                      _submittingActions.contains(prompt.type)
                                  ? null
                                  : () => _submitAction(
                                      prompt.type, selectedTarget),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: _submittingActions.contains(prompt.type)
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Text(
                                      isVote && previousVote.isNotEmpty
                                          ? 'تأكيد / تغيير التصويت'
                                          : 'تأكيد وإرسال',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
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
        _ => 'اختر هدف الحركة',
      };

  Widget _buildPrivateResult(String result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Colors.greenAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dangerous, color: Colors.redAccent, size: 80),
          SizedBox(height: 20),
          Text(
            'لقد مت!',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 32,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'أنت الآن شبح، لا يمكنك الكلام أو التصويت.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMsg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
