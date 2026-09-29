import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_dashboard_screen.dart';

class JudgeLobbyScreen extends ConsumerStatefulWidget {
  const JudgeLobbyScreen({super.key});

  @override
  ConsumerState<JudgeLobbyScreen> createState() => _JudgeLobbyScreenState();
}

class _JudgeLobbyScreenState extends ConsumerState<JudgeLobbyScreen> {
  String? _sessionId;
  bool _isCreating = true;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    final state = ref.read(gameOrchestratorProvider);
    final service = ref.read(interactiveServiceProvider);
    
    final sessionId = await service.createSession(state);
    if (mounted) {
      setState(() {
        _sessionId = sessionId;
        _isCreating = false;
      });
    }
  }

  void _startGame(List<InteractiveSeat> seats) {
    if (seats.any((s) => s.status != SeatStatus.linked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب ربط جميع المقاعد باللاعبين أولاً!')),
      );
      return;
    }
    
    // Proceed to interactive dashboard (Day phase equivalent start)
    final service = ref.read(interactiveServiceProvider);
    final state = ref.read(gameOrchestratorProvider);
    service.syncGameState(_sessionId!, state, null, null); // Sync initial state
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => JudgeDashboardScreen(sessionId: _sessionId!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating || _sessionId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF07070B),
        body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    final service = ref.read(interactiveServiceProvider);
    final joinUrl = 'https://mafiagame-351f8.web.app/?v=20260929-2#/?session=$_sessionId';

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title: const Text('انتظار اللاعبين 🌐', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
                const Text('امسح الرمز للانضمام', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: QrImageView(
                    data: joinUrl,
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
                const SizedBox(height: 20),
                Text('رمز الجلسة:', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontFamily: 'Cairo')),
                Text(_sessionId!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Right side: Seats & Requests
          Expanded(
            flex: 1,
            child: StreamBuilder<List<InteractiveSeat>>(
              stream: service.streamSeats(_sessionId!),
              builder: (context, seatsSnap) {
                if (!seatsSnap.hasData) return const Center(child: CircularProgressIndicator());
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
                              final reqsForSeat = requests.where((r) => r.seatId == seat.id).toList();
                              
                              return Card(
                                color: seat.status == SeatStatus.linked ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                child: ExpansionTile(
                                  title: Text(seat.playerName, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                                  subtitle: Text(seat.status == SeatStatus.linked ? 'متصل' : 'في الانتظار', style: TextStyle(color: seat.status == SeatStatus.linked ? Colors.greenAccent : Colors.orangeAccent)),
                                  children: reqsForSeat.map((req) => ListTile(
                                    title: Text(req.displayName, style: const TextStyle(color: Colors.white)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check, color: Colors.greenAccent),
                                          onPressed: () => service.approveJoinRequest(_sessionId!, seat.id, req.uid),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.redAccent),
                                          onPressed: () => service.rejectJoinRequest(_sessionId!, req.uid),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () => _startGame(seats),
                            child: const Text('بدء اللعبة', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
    );
  }
}
