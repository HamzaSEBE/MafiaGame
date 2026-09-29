import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_session_ended_screen.dart';
import 'dart:async';

class WebPlayerScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String seatId;

  const WebPlayerScreen(
      {super.key, required this.sessionId, required this.seatId});

  @override
  ConsumerState<WebPlayerScreen> createState() => _WebPlayerScreenState();
}

class _WebPlayerScreenState extends ConsumerState<WebPlayerScreen> {
  String? _selectedTargetId;
  bool _isSubmitting = false;
  bool _hasSubmittedLocally = false;
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

  Future<void> _submitAction(String actionType) async {
    if (_selectedTargetId == null) return;
    setState(() => _isSubmitting = true);

    final service = ref.read(interactiveServiceProvider);
    try {
      await service.submitAction(
          widget.sessionId, widget.seatId, actionType, _selectedTargetId!);
      if (mounted) setState(() => _hasSubmittedLocally = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في إرسال الحركة: $e',
                style: const TextStyle(fontFamily: 'Cairo'))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionEnded) return const WebSessionEndedScreen();

    final service = ref.read(interactiveServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title:
            const Text('بطاقتك السرية', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<InteractiveSession?>(
        stream: service.streamSession(widget.sessionId),
        builder: (context, sessionSnap) {
          if (sessionSnap.hasError)
            return _buildError('خطأ في جلب الجلسة: ${sessionSnap.error}');
          final session = sessionSnap.data;

          if (session?.status == SessionStatus.finished) {
            return const WebSessionEndedScreen();
          }

          if (session != null &&
              (_lastPhase != session.phase ||
                  _lastActionRevision != session.actionRevision)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastPhase = session.phase;
                  _lastActionRevision = session.actionRevision;
                  _hasSubmittedLocally = false;
                  _selectedTargetId = null;
                });
              }
            });
          }

          return StreamBuilder<InteractiveSeat?>(
            stream: service.streamMySeat(widget.sessionId, widget.seatId),
            builder: (context, seatSnap) {
              if (seatSnap.hasError)
                return _buildError('خطأ في جلب المقعد: ${seatSnap.error}');
              final seat = seatSnap.data;

              return StreamBuilder<InteractiveSecret?>(
                stream: service.streamMySecret(widget.sessionId, widget.seatId),
                builder: (context, secretSnap) {
                  if (secretSnap.hasError)
                    return _buildError('خطأ في جلب السر: ${secretSnap.error}');
                  final secret = secretSnap.data;

                  if (session == null || seat == null || secret == null) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.orangeAccent));
                  }

                  if (!seat.isAlive) {
                    return _buildDeadScreen();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Role Card
                        if (secret.role != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.orangeAccent.withOpacity(0.2),
                                  radius: 30,
                                  child: const Icon(Icons.person,
                                      color: Colors.orangeAccent, size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(seat.playerName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          AppTheme.roleArabicName(secret.role!),
                                          style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 16,
                                              fontFamily: 'Cairo')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 30),

                        // Action Area
                        Expanded(
                          child:
                              _buildActionArea(session, seat, secret, service),
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

  Widget _buildError(String errorMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(errorMsg,
              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              textAlign: TextAlign.center),
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
          Text('لقد مت!',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 32,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold)),
          Text('أنت الآن شبح، لا يمكنك الكلام أو التصويت.',
              style: TextStyle(
                  color: Colors.white54, fontSize: 16, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildActionArea(InteractiveSession session, InteractiveSeat seat,
      InteractiveSecret secret, InteractiveService service) {
    if (secret.hasSubmittedAction || _hasSubmittedLocally) {
      return const Center(
        child: Text('تم إرسال حركتك بنجاح.\nبانتظار البقية...',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.greenAccent, fontSize: 20, fontFamily: 'Cairo')),
      );
    }

    if (secret.requiredActionType == null || secret.availableTargets == null) {
      return Center(
        child: Text(
          session.phase == Phase.day
              ? 'نهار هادئ... تحدث مع الجميع.'
              : 'انتظر دورك...',
          style: const TextStyle(
              color: Colors.white54, fontSize: 20, fontFamily: 'Cairo'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          secret.requiredActionType == 'vote'
              ? 'صوّت ضد لاعب للإقصاء:'
              : 'اختر هدفك لهذه الليلة:',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<InteractiveSeat>>(
            stream: service.streamSeats(session.id),
            builder: (context, seatsSnap) {
              if (seatsSnap.hasError)
                return Text('خطأ: ${seatsSnap.error}',
                    style: const TextStyle(color: Colors.red));
              final allSeats = seatsSnap.data ?? [];
              final targets = allSeats
                  .where((s) => secret.availableTargets!.contains(s.id))
                  .toList();

              return ListView.builder(
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final target = targets[index];
                  return RadioListTile<String>(
                    title: Text(target.playerName,
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'Cairo')),
                    value: target.id,
                    groupValue: _selectedTargetId,
                    activeColor: Colors.orangeAccent,
                    onChanged: (val) => setState(() => _selectedTargetId = val),
                  );
                },
              );
            },
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _isSubmitting
              ? null
              : () => _submitAction(secret.requiredActionType!),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text('تأكيد وإرسال',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
