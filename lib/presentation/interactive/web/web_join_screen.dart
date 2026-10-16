import 'dart:async';
import 'package:mafia_nightfall/presentation/interactive/web/player_components.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/interactive/web/room_theme_scope.dart';
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
  bool _choosingAnotherSeat = false;
  Stream<List<InteractiveSeat>>? _seatsStream;
  Stream<JoinRequest?>? _myRequestStream;
  StreamSubscription<InteractiveSession?>? _sessionSubscription;
  StreamSubscription<String?>? _membershipSubscription;

  @override
  void initState() {
    super.initState();
    final service = ref.read(interactiveServiceProvider);
    _sessionSubscription = service
        .streamSession(widget.sessionId)
        .listen(
          (session) {
            if (!mounted || session?.status != SessionStatus.finished) return;
            setState(() => _sessionEnded = true);
          },
          onError: (Object error) {
            if (mounted) setState(() => _errorMessage = _friendlyError(error));
          },
        );
    _initAuth();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _membershipSubscription?.cancel();
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
      await service.signInAnonymouslyIfNeeded().timeout(
        const Duration(seconds: 20),
      );
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
      _watchMembership(service, uid);
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
      _choosingAnotherSeat = false;
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
          return 'تعذر دخول هذه الجلسة. اطلب من الحكم التأكد من الرابط ثم أعد المحاولة.';
        case 'unauthenticated':
          return 'تعذر تفعيل اتصالك المؤقت. أعد المحاولة.';
        case 'operation-not-allowed':
          return 'خدمة الانضمام غير متاحة حالياً. أخبر الحكم.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'تعذر الاتصال بالخادم. افحص الإنترنت ثم أعد المحاولة.';
        case 'not-found':
          return 'الجلسة غير موجودة أو انتهت.';
      }
      return 'تعذر إكمال الطلب (${error.code}). أعد المحاولة.';
    }
    return 'تعذر إكمال الطلب. تحقق من الاتصال ثم أعد المحاولة.';
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
    _watchMembership(service, uid);
  }

  void _watchMembership(InteractiveService service, String uid) {
    _membershipSubscription?.cancel();
    _membershipSubscription = service
        .streamMyMembership(widget.sessionId, uid)
        .listen(
          (seatId) {
            if (seatId != null && mounted && !_sessionEnded) {
              _openPlayer(seatId);
            }
          },
          onError: (Object error) {
            if (mounted) setState(() => _errorMessage = _friendlyError(error));
          },
        );
  }

  void _openPlayer(String seatId) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sessionEnded) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoomThemeScope(
            sessionId: widget.sessionId,
            child: WebPlayerScreen(sessionId: widget.sessionId, seatId: seatId),
          ),
        ),
      );
    });
    // Membership may arrive between frames, without a roster/UI update.
    // Schedule the frame whose end performs navigation immediately.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Widget _errorPanel(String message, {VoidCallback? onRetry}) => PlayerNotice(
    title: 'تعذر الاتصال',
    message: message,
    icon: Icons.wifi_off_rounded,
    error: true,
    action: onRetry == null
        ? null
        : OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
  );
  Widget _page(
    Widget child, {
    String title = 'خذ مكانك في المدينة',
    String subtitle = 'اختر اسمك، ثم انتظر موافقة الحكم لتبدأ ليلتك.',
    Widget? bottom,
  }) => PlayerPage(
    title: title,
    subtitle: subtitle,
    status: 'صالة الانتظار',
    bottom: bottom,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    if (_sessionEnded) return const WebSessionEndedScreen();
    if (_isInitializing) {
      return _page(
        const PlayerNotice(
          title: 'نجهّز مقعدك…',
          message: 'لحظات ونوصلك بطاولة اللعب.',
          icon: Icons.hourglass_empty_rounded,
        ),
      );
    }
    if (_myUid == null) {
      return _page(
        _errorPanel(
          _errorMessage ?? 'تعذر الاتصال بخدمة اللعبة.',
          onRetry: _initAuth,
        ),
      );
    }
    return StreamBuilder<List<InteractiveSeat>>(
      stream: _seatsStream,
      builder: (context, seatsSnapshot) {
        if (seatsSnapshot.hasError) {
          return _page(
            _errorPanel(
              _friendlyError(seatsSnapshot.error!),
              onRetry: _retryStreams,
            ),
          );
        }
        if (!seatsSnapshot.hasData) {
          return _page(
            const PlayerNotice(
              title: 'نبحث عن طاولتك…',
              message: 'جارٍ تحميل أسماء اللاعبين.',
            ),
          );
        }
        final seats = seatsSnapshot.data!;
        final mySeat = _firstOrNull(seats.where((s) => s.linkedUid == _myUid));
        if (mySeat != null) {
          _openPlayer(mySeat.id);
          return _page(
            const PlayerNotice(
              title: 'أهلاً بك في اللعبة',
              message: 'تم اعتماد مقعدك. نفتح بطاقتك الآن.',
              icon: Icons.check_circle_outline_rounded,
            ),
          );
        }
        if (seats.isEmpty) {
          return _page(
            _errorPanel(
              'لم تتوفر مقاعد بعد. اطلب من الحكم تجهيز الجلسة.',
              onRetry: _retryStreams,
            ),
          );
        }
        return StreamBuilder<JoinRequest?>(
          stream: _myRequestStream,
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return _page(
                _errorPanel(
                  _friendlyError(requestSnapshot.error!),
                  onRetry: _retryStreams,
                ),
              );
            }
            final request = requestSnapshot.data;
            if (request != null && !_choosingAnotherSeat) {
              final seat = _firstOrNull(
                seats.where((s) => s.id == request.seatId),
              );
              return _page(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      _errorPanel(
                        _errorMessage!,
                        onRetry: seat == null
                            ? _retryStreams
                            : () => _requestSeat(seat),
                      ),
                      const SizedBox(height: 16),
                    ],
                    PlayerNotice(
                      title: _isRequesting
                          ? 'جارٍ إرسال طلبك…'
                          : 'مقعدك بانتظار الموافقة',
                      message: _isRequesting
                          ? 'نؤكد وصول طلبك إلى الحكم. أبقِ الصفحة مفتوحة.'
                          : seat?.status == SeatStatus.linked &&
                                seat?.linkedUid != _myUid
                          ? 'تم ربط هذا المقعد بلاعب آخر. اختر مقعداً آخر متاحاً.'
                          : 'طلب ${seat?.playerName ?? request.displayName} بانتظار الحكم. ستدخل تلقائياً بعد الموافقة.',
                      icon: Icons.verified_user_outlined,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isRequesting
                          ? null
                          : () => setState(() {
                              _choosingAnotherSeat = true;
                              _selectedSeatId = null;
                              _errorMessage = null;
                            }),
                      child: const Text('اختيار مقعد آخر'),
                    ),
                  ],
                ),
                title: 'بقيت إشارة الحكم',
                subtitle: 'المدينة تنتظر. دورك سيبقى سراً بينك وبين الشاشة.',
              );
            }
            final available = seats
                .where((s) => s.status == SeatStatus.unlinked)
                .toList();
            final selected = _firstOrNull(
              available.where((s) => s.id == _selectedSeatId),
            );
            return _page(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    _errorPanel(_errorMessage!, onRetry: _retryStreams),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Text(
                        'المقاعد المتاحة',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      PlayerTag(
                        label: '${available.length} مقاعد',
                        icon: Icons.person_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (available.isEmpty)
                    const PlayerNotice(
                      title: 'الطاولة مكتملة',
                      message:
                          'جميع المقاعد مرتبطة بلاعبين. تواصل مع الحكم إذا كان اسمك غير موجود.',
                      icon: Icons.groups_outlined,
                    ),
                  for (final seat in available)
                    PlayerChoice(
                      name: seat.playerName,
                      subtitle: 'اضغط لاختيار اسمك',
                      selected: selected?.id == seat.id,
                      onTap: _isRequesting
                          ? null
                          : () => setState(() => _selectedSeatId = seat.id),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'لا تحتاج إلى حساب. يبقى دورك مخفياً حتى تكشفه بنفسك.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              bottom: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selected == null || _isRequesting
                      ? null
                      : () => _requestSeat(selected),
                  icon: Icon(
                    _isRequesting
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _isRequesting
                        ? 'جارٍ إرسال طلبك…'
                        : selected == null
                        ? 'اختر اسمك للمتابعة'
                        : 'انضمام باسم ${selected.playerName}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
