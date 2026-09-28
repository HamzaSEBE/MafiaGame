import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class WebPlayerScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String seatId;

  const WebPlayerScreen({super.key, required this.sessionId, required this.seatId});

  @override
  ConsumerState<WebPlayerScreen> createState() => _WebPlayerScreenState();
}

class _WebPlayerScreenState extends ConsumerState<WebPlayerScreen> {
  String? _selectedTargetId;
  bool _isSubmitting = false;

  Future<void> _submitAction(String actionType) async {
    if (_selectedTargetId == null) return;
    setState(() => _isSubmitting = true);
    
    final service = ref.read(interactiveServiceProvider);
    await service.submitAction(widget.sessionId, widget.seatId, actionType, _selectedTargetId!);
    
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(interactiveServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title: const Text('بطاقتك السرية', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<InteractiveSession?>(
        stream: service.streamSession(widget.sessionId),
        builder: (context, sessionSnap) {
          final session = sessionSnap.data;
          
          return StreamBuilder<InteractiveSeat?>(
            stream: service.streamMySeat(widget.sessionId, widget.seatId),
            builder: (context, seatSnap) {
              final seat = seatSnap.data;
              
              if (session == null || seat == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
              }
              
              if (!seat.isAlive) {
                return _buildDeadScreen();
              }
              
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Role Card
                    if (seat.role != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                              radius: 30,
                              child: const Icon(Icons.person, color: Colors.orangeAccent, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(seat.playerName, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                  Text(AppTheme.roleArabicName(seat.role!), style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontFamily: 'Cairo')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    const SizedBox(height: 30),
                    
                    // Action Area
                    Expanded(
                      child: _buildActionArea(session, seat, service),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
          Text('لقد مت!', style: TextStyle(color: Colors.redAccent, fontSize: 32, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          Text('أنت الآن شبح، لا يمكنك الكلام أو التصويت.', style: TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildActionArea(InteractiveSession session, InteractiveSeat seat, InteractiveService service) {
    if (seat.hasSubmittedAction) {
      return const Center(
        child: Text('تم إرسال حركتك بنجاح.\nبانتظار البقية...', textAlign: TextAlign.center, style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontFamily: 'Cairo')),
      );
    }

    if (seat.requiredActionType == null || seat.availableTargets == null) {
      return Center(
        child: Text(
          session.phase == Phase.day ? 'نهار هادئ... تحدث مع الجميع.' : 'انتظر دورك...',
          style: const TextStyle(color: Colors.white54, fontSize: 20, fontFamily: 'Cairo'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          seat.requiredActionType == 'vote' ? 'صوّت ضد لاعب للإقصاء:' : 'اختر هدفك لهذه الليلة:',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Expanded(
          child: StreamBuilder<List<InteractiveSeat>>(
            stream: service.streamSeats(session.id),
            builder: (context, seatsSnap) {
              final allSeats = seatsSnap.data ?? [];
              final targets = allSeats.where((s) => seat.availableTargets!.contains(s.id)).toList();
              
              return ListView.builder(
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final target = targets[index];
                  return RadioListTile<String>(
                    title: Text(target.playerName, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
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
          onPressed: _isSubmitting ? null : () => _submitAction(seat.requiredActionType!),
          child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text('تأكيد وإرسال', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
