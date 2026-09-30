import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    if (_isStarting || _sessionId == null) return;
    if (seats.any((s) => s.status != SeatStatus.linked)) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح لوحة الحكم: $error')),
      );
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
      ref.read(gameOrchestratorProvider.notifier).resetGame();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('تعذر إنهاء الجلسة. افحص الاتصال ثم أعد المحاولة: $error'),
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

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    if (_isCreating || _sessionId == null) {
      return _guardSystemBack(Scaffold(
        
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _isExiting ? null : _exitSession,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: _creationError == null
              ? const CircularProgressIndicator(color: Colors.orangeAccent)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر إنشاء الجلسة: $_creationError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
        ),
      ));
    }

    final service = ref.read(interactiveServiceProvider);
    final joinUrl =
        'https://mafiagame-351f8.web.app/?v=20260929-5#/?session=$_sessionId';

    final gamePhase = ref.watch(gameOrchestratorProvider).phase;

    return _guardSystemBack(Scaffold(
      
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'إنهاء الجلسة',
          onPressed: _isExiting ? null : _exitSession,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('انتظار اللاعبين 🌐',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left side: QR Code
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('امسح الرمز للانضمام',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: QrImageView(
                    data: joinUrl,
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
                const SizedBox(height: 20),
                Text('رمز الجلسة:',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontFamily: 'Cairo')),
                Text(_sessionId!,
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Right side: Seats & Requests
          Expanded(
            flex: 1,
            child: StreamBuilder<List<InteractiveSeat>>(
              stream: service.streamSeats(_sessionId!),
              builder: (context, seatsSnap) {
                if (!seatsSnap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final seats = seatsSnap.data!;

                return StreamBuilder<List<JoinRequest>>(
                  stream: service.streamJoinRequests(_sessionId!),
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? [];

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: seats.length,
                            itemBuilder: (context, index) {
                              final seat = seats[index];
                              final reqsForSeat = requests
                                  .where((r) => r.seatId == seat.id)
                                  .toList();

                              return Card(
                                color: seat.status == SeatStatus.linked
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                child: ExpansionTile(
                                  title: Text(seat.playerName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Cairo')),
                                  subtitle: Text(
                                      seat.status == SeatStatus.linked
                                          ? 'متصل'
                                          : 'في الانتظار',
                                      style: TextStyle(
                                          color:
                                              seat.status == SeatStatus.linked
                                                  ? Colors.greenAccent
                                                  : Colors.orangeAccent)),
                                  children: reqsForSeat
                                      .map((req) => ListTile(
                                            title: Text(req.displayName,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.check,
                                                      color:
                                                          Colors.greenAccent),
                                                  onPressed: () => service
                                                      .approveJoinRequest(
                                                          _sessionId!,
                                                          seat.id,
                                                          req.uid),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.redAccent),
                                                  onPressed: () =>
                                                      service.rejectJoinRequest(
                                                          _sessionId!, req.uid),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (gamePhase == Phase.roleReveal) ...[
                                OutlinedButton.icon(
                                  onPressed: _isStarting ? null : _reviewRoles,
                                  icon: const Icon(
                                    Icons.style,
                                    color: Colors.orangeAccent,
                                  ),
                                  label: const Text(
                                    'مراجعة الأدوار أو إعادة توزيعها',
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.orangeAccent,
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed:
                                    _isStarting || gamePhase == Phase.winCheck
                                        ? null
                                        : () => _startGame(seats),
                                child: Text(
                                  _isStarting
                                      ? 'جارٍ فتح اللعبة...'
                                      : gamePhase == Phase.roleReveal
                                          ? 'بدء اللعبة'
                                          : gamePhase == Phase.winCheck
                                              ? 'انتهت اللعبة'
                                              : 'استئناف اللعبة',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}
