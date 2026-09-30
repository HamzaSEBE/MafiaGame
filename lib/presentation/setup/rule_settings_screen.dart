import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';

class RuleSettingsScreen extends ConsumerStatefulWidget {
  const RuleSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RuleSettingsScreen> createState() => _RuleSettingsScreenState();
}

class _RuleSettingsScreenState extends ConsumerState<RuleSettingsScreen> {
  late GameRuleset rules;

  @override
  void initState() {
    super.initState();
    rules = ref.read(gameOrchestratorProvider).rules;
  }

  void _save() {
    ref.read(gameOrchestratorProvider.notifier).updateRules(rules);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title: const Text('إعدادات وقوانين اللعبة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF130E0A),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('حفظ', style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontFamily: 'Cairo')),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('شروط الفوز (VICTORY RULES)'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                RadioListTile<VictoryMode>(
                  title: const Text('الانتصار الكلاسيكي', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  subtitle: const Text('تفوز المافيا إذا استحال على المواطنين القضاء عليها قانونياً. يفوز المواطنون بإبادة المافيا.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
                  value: VictoryMode.classic,
                  groupValue: rules.victoryRules.mode,
                  activeColor: Colors.orangeAccent,
                  onChanged: (val) {
                    setState(() {
                      rules = GameRuleset(
                        abilityRules: rules.abilityRules,
                        victoryRules: VictoryRules(
                          mode: val!,
                          requiredCorrectExecutions: rules.victoryRules.requiredCorrectExecutions,
                        ),
                      );
                    });
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                RadioListTile<VictoryMode>(
                  title: const Text('التعادل مع العدد الأصلي للمافيا', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  subtitle: const Text('تفوز المافيا إذا أصبح عدد المواطنين الأحياء مساوياً لعدد المافيا الأصلي (عند بدء اللعبة).', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
                  value: VictoryMode.equalCount,
                  groupValue: rules.victoryRules.mode,
                  activeColor: Colors.orangeAccent,
                  onChanged: (val) {
                    setState(() {
                      rules = GameRuleset(
                        abilityRules: rules.abilityRules,
                        victoryRules: VictoryRules(
                          mode: val!,
                          requiredCorrectExecutions: rules.victoryRules.requiredCorrectExecutions,
                        ),
                      );
                    });
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                RadioListTile<VictoryMode>(
                  title: const Text('الإعدامات الصحيحة للمافيا', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  subtitle: const Text('يفوز المواطنون إذا قاموا بإعدام عدد معين من المافيا نهاراً بشكل صحيح.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
                  value: VictoryMode.exactMafiaExecutions,
                  groupValue: rules.victoryRules.mode,
                  activeColor: Colors.orangeAccent,
                  onChanged: (val) {
                    setState(() {
                      rules = GameRuleset(
                        abilityRules: rules.abilityRules,
                        victoryRules: VictoryRules(
                          mode: val!,
                          requiredCorrectExecutions: rules.victoryRules.requiredCorrectExecutions,
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          
          if (rules.victoryRules.mode == VictoryMode.exactMafiaExecutions)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ListTile(
                tileColor: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white12)),
                title: const Text('عدد الإعدامات المطلوبة:', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                trailing: DropdownButton<int>(
                  value: rules.victoryRules.requiredCorrectExecutions,
                  dropdownColor: const Color(0xFF1E1E24),
                  style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo', fontSize: 18),
                  items: [1, 2, 3, 4, 5].map((i) => DropdownMenuItem(value: i, child: Text('$i'))).toList(),
                  onChanged: (val) {
                    setState(() {
                      rules = GameRuleset(
                        abilityRules: rules.abilityRules,
                        victoryRules: VictoryRules(
                          mode: rules.victoryRules.mode,
                          requiredCorrectExecutions: val ?? 3,
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
            
          const Divider(color: Colors.white24, height: 40),
          _buildSectionHeader('قواعد القدرات (ABILITY RULES)'),
          
          ListTile(
            title: const Text('حد الحماية المتكررة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: const Text('كم ليلة مختلفة يمكن للطبيب حماية نفس الشخص.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
            trailing: DropdownButton<int>(
              value: rules.abilityRules.protectionTargetLimit,
              dropdownColor: const Color(0xFF1E1E24),
              style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo', fontSize: 18),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: -1, child: Text('لا محدود')),
              ],
              onChanged: (val) {
                setState(() {
                  rules = GameRuleset(
                    victoryRules: rules.victoryRules,
                    abilityRules: AbilityRules(
                      protectionTargetLimit: val ?? 1,
                      silenceTargetLimit: rules.abilityRules.silenceTargetLimit,
                      mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                      jokerReveal: rules.abilityRules.jokerReveal,
                      citizenSheikhReveal: rules.abilityRules.citizenSheikhReveal,
                      sniper: rules.abilityRules.sniper,
                    ),
                  );
                });
              },
            ),
          ),
          
          ListTile(
            title: const Text('حد الإسكات المتكرر', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: const Text('كم ليلة مختلفة يمكن للسفاح إسكات نفس الشخص.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
            trailing: DropdownButton<int>(
              value: rules.abilityRules.silenceTargetLimit,
              dropdownColor: const Color(0xFF1E1E24),
              style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo', fontSize: 18),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: -1, child: Text('لا محدود')),
              ],
              onChanged: (val) {
                setState(() {
                  rules = GameRuleset(
                    victoryRules: rules.victoryRules,
                    abilityRules: AbilityRules(
                      protectionTargetLimit: rules.abilityRules.protectionTargetLimit,
                      silenceTargetLimit: val ?? 1,
                      mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                      jokerReveal: rules.abilityRules.jokerReveal,
                      citizenSheikhReveal: rules.abilityRules.citizenSheikhReveal,
                      sniper: rules.abilityRules.sniper,
                    ),
                  );
                });
              },
            ),
          ),
          
          SwitchListTile(
            title: const Text('كشف شيخ المافيا بشكل مستقل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: const Text('إذا حقق المحقق في شيخ المافيا، يظهر له كـ "شيخ المافيا" بدلاً من إخفائه كمواطن.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
            value: rules.abilityRules.mafiaSheikhReveal,
            activeColor: Colors.orangeAccent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit: rules.abilityRules.protectionTargetLimit,
                    silenceTargetLimit: rules.abilityRules.silenceTargetLimit,
                    mafiaSheikhReveal: val,
                    jokerReveal: rules.abilityRules.jokerReveal,
                    citizenSheikhReveal: rules.abilityRules.citizenSheikhReveal,
                    sniper: rules.abilityRules.sniper,
                  ),
                );
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('كشف الجوكر بشكل مستقل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: const Text('هل يظهر الجوكر لشيخ المواطنين كجوكر أم يبقى مخفياً كمواطن؟', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
            value: rules.abilityRules.jokerReveal,
            activeColor: Colors.orangeAccent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit: rules.abilityRules.protectionTargetLimit,
                    silenceTargetLimit: rules.abilityRules.silenceTargetLimit,
                    mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                    jokerReveal: val,
                    citizenSheikhReveal: rules.abilityRules.citizenSheikhReveal,
                    sniper: rules.abilityRules.sniper,
                  ),
                );
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('إفصاح شيخ المواطنين', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: const Text('قدرة مستقلة: يسمح لشيخ المواطنين بالكشف علناً ليصبح صوته بـ 3 أصوات.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
            value: rules.abilityRules.citizenSheikhReveal,
            activeColor: Colors.orangeAccent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit: rules.abilityRules.protectionTargetLimit,
                    silenceTargetLimit: rules.abilityRules.silenceTargetLimit,
                    mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                    jokerReveal: rules.abilityRules.jokerReveal,
                    citizenSheikhReveal: val,
                    sniper: rules.abilityRules.sniper,
                  ),
                );
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('القناص', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: const Text('منح قدرة قنص (لمرة واحدة) لأحد المواطنين العشوائيين.', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12)),
            value: rules.abilityRules.sniper,
            activeColor: Colors.orangeAccent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit: rules.abilityRules.protectionTargetLimit,
                    silenceTargetLimit: rules.abilityRules.silenceTargetLimit,
                    mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                    jokerReveal: rules.abilityRules.jokerReveal,
                    citizenSheikhReveal: rules.abilityRules.citizenSheikhReveal,
                    sniper: val,
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),
    );
  }
}
