import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';
import 'package:mafia_nightfall/presentation/premium/premium_widgets.dart';

class RuleSettingsScreen extends ConsumerStatefulWidget {
  const RuleSettingsScreen({super.key});

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
    ref.watch(selectedThemeProvider);
    return Scaffold(
      backgroundColor: context.visual.background,
      appBar: AppBar(
        title: const Text(
          'إعدادات وقوانين اللعبة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: context.visual.surface,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'حفظ',
              style: TextStyle(
                color: context.visual.accent,
                fontSize: 18,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AiVoiceAssistantSetting(),
          const SizedBox(height: 24),
          _buildSectionHeader('شروط الفوز (VICTORY RULES)'),
          Material(
            color: context.visual.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: RadioGroup<VictoryMode>(
              groupValue: rules.victoryRules.mode,
              onChanged: (mode) {
                if (mode == null) return;
                setState(() {
                  rules = GameRuleset(
                    allowMultipleAssassinationsPerNight:
                        rules.allowMultipleAssassinationsPerNight,
                    abilityRules: rules.abilityRules,
                    victoryRules: VictoryRules(
                      mode: mode,
                      requiredCorrectExecutions:
                          rules.victoryRules.requiredCorrectExecutions,
                    ),
                  );
                });
              },
              child: Column(
                children: [
                  RadioListTile<VictoryMode>(
                    title: const Text(
                      'الانتصار الكلاسيكي',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    subtitle: const Text(
                      'تُقارن المافيا الأحياء بالمواطنين الأحياء؛ الجوكر مستقل ولا يُحسب مواطناً. تفوز المافيا عند التعادل أو التفوق العددي، ويفوز المواطنون عند القضاء على جميع المافيا. عند التعادل فقط تُمنح فرصة إذا اجتمع قنّاص مواطن حي لم يستخدم رصاصته وبنت مواطنين حية تستطيع حماية لاعب حي أو نفسها. مثال: 2 مافيا ضد 2 مواطنين صالحين ينتهي بفوز المافيا.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    value: VictoryMode.classic,
                    activeColor: context.visual.accent,
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  RadioListTile<VictoryMode>(
                    title: const Text(
                      'التعادل مع العدد الأصلي للمافيا',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    subtitle: const Text(
                      'يُثبّت عدد المافيا عند بداية المباراة، ويُقارن به عدد المواطنين الأحياء لاحقاً. تفوز المافيا عندما يصبح عدد المواطنين مساوياً لذلك العدد أو أقل، حتى لو مات بعض المافيا. مثال: إذا بدأت المافيا بثلاثة، يكفي بقاء 3 مواطنين أو أقل. القضاء على جميع المافيا يفوز به المواطنون. استثناء القنص والحماية خاص بالنظام الكلاسيكي.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    value: VictoryMode.equalCount,
                    activeColor: context.visual.accent,
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  RadioListTile<VictoryMode>(
                    title: const Text(
                      'الإعدامات الصحيحة للمافيا',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    subtitle: const Text(
                      'يفوز المواطنون عند إعدام العدد المطلوب من المافيا بالتصويت النهاري. قتل المافيا بالقنص أو الانتقام لا يُحسب إعداماً صحيحاً. يجب أن يكون الهدف قابلاً للتحقيق بعدد المافيا الموجودين؛ إذا لم يعد قابلاً للتحقيق تفوز المافيا. تظل مقارنة الأعداد والقدرات المتبقية مؤثرة قبل بلوغ الهدف.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    value: VictoryMode.exactMafiaExecutions,
                    activeColor: context.visual.accent,
                  ),
                ],
              ),
            ),
          ),
          if (rules.victoryRules.mode == VictoryMode.exactMafiaExecutions)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ListTile(
                tileColor: context.visual.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white12),
                ),
                subtitle: const Text(
                  'اختر من 1 إلى 5. تُحسب إعدامات أعضاء المافيا بالتصويت فقط، ولا تُحسب إعدامات المواطنين أو القتل الليلي. لا يمكن بدء المباراة بهدف أكبر من عدد المافيا الموزّعين.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                title: const Text(
                  'عدد الإعدامات المطلوبة:',
                  style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                ),
                trailing: DropdownButton<int>(
                  value: rules.victoryRules.requiredCorrectExecutions,
                  dropdownColor: context.visual.surface,
                  style: TextStyle(
                    color: context.visual.accent,
                    fontFamily: 'Cairo',
                    fontSize: 18,
                  ),
                  items: [1, 2, 3, 4, 5]
                      .map((i) => DropdownMenuItem(value: i, child: Text('$i')))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      rules = GameRuleset(
                        allowMultipleAssassinationsPerNight:
                            rules.allowMultipleAssassinationsPerNight,
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
            title: const Text(
              'حد الحماية المتكررة',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'عدد مرات حماية اللاعب نفسه بواسطة بنت المواطنين نفسها طوال المباراة، وليس في ليالٍ متتالية فقط. العدد 1 يعني حماية كل هدف مرة واحدة، و2 مرتين. يمكنها حماية نفسها أو لاعب حي آخر. «لا محدود» يتيح تكرار الحماية دون حد، والحماية تمنع قتله في تلك الليلة سواء بالمافيا أو بالقنص.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            trailing: DropdownButton<int>(
              value: rules.abilityRules.protectionTargetLimit,
              dropdownColor: context.visual.surface,
              style: TextStyle(
                color: context.visual.accent,
                fontFamily: 'Cairo',
                fontSize: 18,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: -1, child: Text('لا محدود')),
              ],
              onChanged: (val) {
                setState(() {
                  rules = GameRuleset(
                    allowMultipleAssassinationsPerNight:
                        rules.allowMultipleAssassinationsPerNight,
                    victoryRules: rules.victoryRules,
                    abilityRules: AbilityRules(
                      protectionTargetLimit: val ?? 1,
                      silenceTargetLimit: rules.abilityRules.silenceTargetLimit,
                      mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                      jokerReveal: rules.abilityRules.jokerReveal,
                      citizenSheikhReveal:
                          rules.abilityRules.citizenSheikhReveal,
                      sniper: rules.abilityRules.sniper,
                    ),
                  );
                });
              },
            ),
          ),
          ListTile(
            title: const Text(
              'حد الإسكات المتكرر',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'عدد مرات إسكات اللاعب نفسه بواسطة بنت المافيا نفسها طوال المباراة، وليس في ليالٍ متتالية فقط. العدد 1 يتيح إسكات كل هدف مرة واحدة، و2 مرتين. «لا محدود» يزيل الحد. الإسكات يخص النهار التالي ويمنع الكلام؛ يزول عند دورة الليل التالية ولا يستهلك تصويت اللاعب.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            trailing: DropdownButton<int>(
              value: rules.abilityRules.silenceTargetLimit,
              dropdownColor: context.visual.surface,
              style: TextStyle(
                color: context.visual.accent,
                fontFamily: 'Cairo',
                fontSize: 18,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: -1, child: Text('لا محدود')),
              ],
              onChanged: (val) {
                setState(() {
                  rules = GameRuleset(
                    allowMultipleAssassinationsPerNight:
                        rules.allowMultipleAssassinationsPerNight,
                    victoryRules: rules.victoryRules,
                    abilityRules: AbilityRules(
                      protectionTargetLimit:
                          rules.abilityRules.protectionTargetLimit,
                      silenceTargetLimit: val ?? 1,
                      mafiaSheikhReveal: rules.abilityRules.mafiaSheikhReveal,
                      jokerReveal: rules.abilityRules.jokerReveal,
                      citizenSheikhReveal:
                          rules.abilityRules.citizenSheikhReveal,
                      sniper: rules.abilityRules.sniper,
                    ),
                  );
                });
              },
            ),
          ),
          SwitchListTile(
            title: const Text(
              'كشف شيخ المافيا بشكل مستقل',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'يغيّر نتيجة تحقيق شيخ المواطنين في شيخ المافيا فقط: عند التفعيل يظهر أنه من المافيا، وعند الإيقاف يتموّه كمواطن. بقية أعضاء المافيا يظهرون كمافيا في التحقيق. هذا لا يكشف الهوية للجميع ولا يغيّر الفريق أو شرط الفوز.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            value: rules.abilityRules.mafiaSheikhReveal,
            activeThumbColor: context.visual.accent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  allowMultipleAssassinationsPerNight:
                      rules.allowMultipleAssassinationsPerNight,
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit:
                        rules.abilityRules.protectionTargetLimit,
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
            title: const Text(
              'كشف الجوكر بشكل مستقل',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'عند تحقيق شيخ المواطنين في الجوكر، يُظهر التفعيل هويته كجوكر؛ عند الإيقاف تظهر النتيجة كمواطن. يبقى الجوكر مستقلاً في الحالتين، ويفوز عندما يُقصى بالتصويت النهاري. النتيجة تخص التحقيق ولا تعلن الدور للجميع.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            value: rules.abilityRules.jokerReveal,
            activeThumbColor: context.visual.accent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  allowMultipleAssassinationsPerNight:
                      rules.allowMultipleAssassinationsPerNight,
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit:
                        rules.abilityRules.protectionTargetLimit,
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
            title: const Text(
              'إفصاح شيخ المواطنين',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'يسمح لشيخ المواطنين الحي بإعلان دوره في النهار أو التصويت. الإعلان متاح مرة واحدة طوال المباراة، وبعده يظل صوته محسوباً بثلاثة أصوات في التصويتات التالية. يمكنه الاحتفاظ بالإفصاح لوقت لاحق؛ التحقيق الليلي قدرة منفصلة.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            value: rules.abilityRules.citizenSheikhReveal,
            activeThumbColor: context.visual.accent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  allowMultipleAssassinationsPerNight:
                      rules.allowMultipleAssassinationsPerNight,
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit:
                        rules.abilityRules.protectionTargetLimit,
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
            title: const Text(
              'القناص',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'قدرة إضافية تُوزّع عشوائياً على مواطن واحد، وقد يحملها المواطن الصالح أو أحد أدوار المواطنين الأخرى. يملك رصاصة واحدة طوال المباراة، ويمكنه إطلاقها ليلاً على لاعب حي غير نفسه، أو تخطي دوره والاحتفاظ بها لليلة لاحقة. الرصاصة تُستهلك عند إطلاقها حتى إذا أنقذت الحماية الهدف. الإيقاف يلغي توزيع القدرة.',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontSize: 13,
                height: 1.7,
              ),
            ),
            value: rules.abilityRules.sniper,
            activeThumbColor: context.visual.accent,
            onChanged: (val) {
              setState(() {
                rules = GameRuleset(
                  allowMultipleAssassinationsPerNight:
                      rules.allowMultipleAssassinationsPerNight,
                  victoryRules: rules.victoryRules,
                  abilityRules: AbilityRules(
                    protectionTargetLimit:
                        rules.abilityRules.protectionTargetLimit,
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
        style: TextStyle(
          color: context.visual.accent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
