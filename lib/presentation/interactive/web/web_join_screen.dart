import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_player_screen.dart';

class WebJoinScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const WebJoinScreen({super.key, required this.sessionId});

  @override
  ConsumerState<WebJoinScreen> createState() => _WebJoinScreenState();
}

class _WebJoinScreenState extends ConsumerState<WebJoinScreen> {
  final TextEditingController _nameController = TextEditingController();
  InteractiveSeat? _selectedSeat;
  bool _isRequesting = false;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final service = ref.read(interactiveServiceProvider);
    await service.signInAnonymouslyIfNeeded();
    setState(() {
      _myUid = service.uid;
    });
  }

  Future<void> _requestSeat() async {
    if (_selectedSeat == null || _nameController.text.trim().isEmpty) return;
    
    setState(() => _isRequesting = true);
    final service = ref.read(interactiveServiceProvider);
    
    try {
      await service.requestSeat(widget.sessionId, _selectedSeat!.id, _nameController.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الطلب: $e', style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF07070B),
        body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    final service = ref.read(interactiveServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title: const Text('الانضمام للعبة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<InteractiveSeat>>(
        stream: service.streamSeats(widget.sessionId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  Text('خطأ في جلب البيانات: ${snapshot.error}', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                  )
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }
          
          final seats = snapshot.data!;
          
          // Check if I am already linked to any seat!
          try {
            final myLinkedSeat = seats.firstWhere((s) => s.linkedUid == _myUid);
            // I am linked! Go to player screen.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => WebPlayerScreen(sessionId: widget.sessionId, seatId: myLinkedSeat.id)),
              );
            });
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          } catch (_) {
            // Not linked yet.
          }
          
          // Filter to only show unlinked seats
          final availableSeats = seats.where((s) => s.status == SeatStatus.unlinked).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    labelText: 'اسمك',
                    labelStyle: const TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('اختر مقعدك:', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo')),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableSeats.length,
                    itemBuilder: (context, index) {
                      final seat = availableSeats[index];
                      return RadioListTile<InteractiveSeat>(
                        title: Text(seat.playerName, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                        value: seat,
                        groupValue: _selectedSeat,
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) => setState(() => _selectedSeat = val),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isRequesting ? null : _requestSeat,
                  child: _isRequesting 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('طلب الانضمام', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
                
                // Show pending request status
                StreamBuilder<List<JoinRequest>>(
                  stream: service.streamJoinRequests(widget.sessionId),
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? [];
                    final myRequest = requests.where((r) => r.uid == _myUid).toList();
                    if (myRequest.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'طلبك قيد الانتظار لموافقة الحكم...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orangeAccent.withOpacity(0.8), fontFamily: 'Cairo'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
