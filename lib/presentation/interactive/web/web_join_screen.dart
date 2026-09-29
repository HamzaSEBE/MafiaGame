import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_player_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_session_ended_screen.dart';

T? _firstOrNull<T>(Iterable<T> values) => values.isEmpty ? null : values.first;

class WebJoinScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const WebJoinScreen({super.key, required this.sessionId});

  @override
  ConsumerState<WebJoinScreen> createState() => _WebJoinScreenState();
}

class _WebJoinScreenState extends ConsumerState<WebJoinScreen> {
  String? _myUid;
  String? _selectedSeatId;
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isRequesting = false;
  bool _isNavigating = false;
  bool _sessionEnded = false;
  Stream<List<InteractiveSeat>>? _seatsStream;
  Stream<JoinRequest?>? _myRequestStream;
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
    _initAuth();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
    }

    try {
      final service = ref.read(interactiveServiceProvider);
      await service
          .signInAnonymouslyIfNeeded()
          .timeout(const Duration(seconds: 20));
      final uid = service.uid;
      if (uid == null) {
        throw StateError('لم يرجع Firebase هوية للاتصال المؤقت.');
      }
      if (!mounted) return;

      setState(() {
        _myUid = uid;
        _seatsStream = service.streamSeats(widget.sessionId);
        _myRequestStream = service.streamMyJoinRequest(widget.sessionId, uid);
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  Future<void> _requestSeat(InteractiveSeat seat) async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(interactiveServiceProvider);
      // The seat name is the player's name; there is no separate name field.
      await service
          .requestSeat(widget.sessionId, seat.id, seat.playerName)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'وصل طلب ${seat.playerName} للحكم. انتظر الموافقة.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال. افحص الإنترنت ثم اضغط إعادة المحاولة.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'رفض Firebase الطلب. تأكد من نشر قواعد Firestore المحدّثة ثم أعد المحاولة.';
        case 'unauthenticated':
          return 'تعذر تفعيل الدخول المؤقت. فعّل Anonymous sign-in في Firebase ثم أعد المحاولة.';
        case 'operation-not-allowed':
          return 'الدخول المؤقت غير مفعّل في Firebase Authentication.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'تعذر الاتصال بالخادم. افحص الإنترنت ثم أعد المحاولة.';
        case 'not-found':
          return 'الجلسة غير موجودة أو انتهت.';
      }
      return 'تعذر إكمال الطلب (${error.code}). أعد المحاولة.';
    }
    return 'تعذر إكمال الطلب. ${error.toString()}';
  }

  void _retryStreams() {
    final uid = _myUid;
    if (uid == null) {
      _initAuth();
      return;
    }
    final service = ref.read(interactiveServiceProvider);
    setState(() {
      _errorMessage = null;
      _seatsStream = service.streamSeats(widget.sessionId);
      _myRequestStream = service.streamMyJoinRequest(widget.sessionId, uid);
    });
  }

  void _openPlayer(String seatId) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WebPlayerScreen(
            sessionId: widget.sessionId,
            seatId: seatId,
          ),
        ),
      );
    });
  }

  Widget _errorPanel(String message, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
              label: const Text(
                'إعادة المحاولة',
                style:
                    TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionEnded) return const WebSessionEndedScreen();

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFF07070B),
        body: Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    if (_myUid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF07070B),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _errorPanel(
              _errorMessage ?? 'تعذر الاتصال بخدمة اللعبة.',
              onRetry: _initAuth,
            ),
          ),
        ),
      );
    }

    final service = ref.read(interactiveServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title:
            const Text('الانضمام للعبة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<InteractiveSeat>>(
        stream: _seatsStream ?? service.streamSeats(widget.sessionId),
        builder: (context, seatsSnapshot) {
          if (seatsSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _errorPanel(
                  _friendlyError(seatsSnapshot.error!),
                  onRetry: _retryStreams,
                ),
              ),
            );
          }
          if (seatsSnapshot.connectionState == ConnectionState.waiting &&
              !seatsSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final seats = seatsSnapshot.data ?? const <InteractiveSeat>[];
          final mySeat =
              _firstOrNull(seats.where((seat) => seat.linkedUid == _myUid));
          if (mySeat != null) {
            _openPlayer(mySeat.id);
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (seats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _errorPanel(
                  'ما لقينا مقاعد لهذه الجلسة. تأكد أن الحكم فتح الجلسة من نسخة التطبيق المحدّثة.',
                  onRetry: _retryStreams,
                ),
              ),
            );
          }

          return StreamBuilder<JoinRequest?>(
            stream: _myRequestStream ??
                service.streamMyJoinRequest(widget.sessionId, _myUid!),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _errorPanel(
                      _friendlyError(requestSnapshot.error!),
                      onRetry: _retryStreams,
                    ),
                  ),
                );
              }

              final myRequest = requestSnapshot.data;
              if (myRequest != null) {
                final requestedSeat = _firstOrNull(
                  seats.where((seat) => seat.id == myRequest.seatId),
                );
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top,
                            size: 64, color: Colors.orangeAccent),
                        const SizedBox(height: 16),
                        Text(
                          'طلب ${requestedSeat?.playerName ?? myRequest.displayName} قيد انتظار موافقة الحكم.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final availableSeats = seats
                  .where((seat) => seat.status == SeatStatus.unlinked)
                  .toList();
              final selectedSeat = _firstOrNull(
                availableSeats.where((seat) => seat.id == _selectedSeatId),
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'اختر اسمك من المقاعد:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'سيُستخدم اسم المقعد نفسه، ما في داعي تكتبه مرة ثانية.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_errorMessage != null)
                          _errorPanel(_errorMessage!, onRetry: _retryStreams),
                        Expanded(
                          child: availableSeats.isEmpty
                              ? const Center(
                                  child: Text(
                                    'كل المقاعد مرتبطة أو ما في مقاعد متاحة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: availableSeats.length,
                                  itemBuilder: (context, index) {
                                    final seat = availableSeats[index];
                                    return RadioListTile<String>(
                                      title: Text(
                                        seat.playerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      value: seat.id,
                                      groupValue: _selectedSeatId,
                                      activeColor: Colors.orangeAccent,
                                      onChanged: _isRequesting
                                          ? null
                                          : (value) => setState(
                                                () => _selectedSeatId = value,
                                              ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: selectedSeat == null || _isRequesting
                              ? null
                              : () => _requestSeat(selectedSeat),
                          child: _isRequesting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  selectedSeat == null
                                      ? 'اختر مقعدك أولاً'
                                      : 'طلب الانضمام باسم ${selectedSeat.playerName}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
