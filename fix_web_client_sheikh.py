import re

with open('lib/presentation/interactive/web/web_player_screen.dart', 'r') as f:
    content = f.read()

old_column = """                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPrivateRoleCard(seat, secret),
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
                  );"""

new_column = """                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPrivateRoleCard(seat, secret),
                        if (seat.isAlive && secret.role == Role.citizensSheikh && !seat.isCitizenSheikhRevealed) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              service.submitAction(widget.sessionId, widget.seatId, 'citizenSheikhReveal', widget.seatId);
                            },
                            icon: const Icon(Icons.campaign, color: Colors.black),
                            label: const Text('إفصاح هويتك علناً (مرة واحدة)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
                  );"""

content = content.replace(old_column, new_column)

with open('lib/presentation/interactive/web/web_player_screen.dart', 'w') as f:
    f.write(content)
