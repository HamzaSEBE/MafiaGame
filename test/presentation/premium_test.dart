import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/premium_catalog.dart';
import 'package:mafia_nightfall/presentation/premium/premium_widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/presentation/premium/pricing_screen.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';
import 'package:mafia_nightfall/domain/entities/theme_id.dart';

Widget frame(Widget screen, {double scale = 1, Key? captureKey}) => MaterialApp(
  theme: AppTheme.getTheme('dark_blood'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: RepaintBoundary(key: captureKey, child: child!),
    ),
  ),
  home: screen,
);

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['UPDATE_REVIEW_SCREENSHOTS'] != 'true') return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/review').create(recursive: true);
    await File(
      'build/review/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  test('original identity retains dark blood red', () {
    final palette = ThemeCatalog.byId('dark_blood');
    expect(palette.accent, const Color(0xFF8B0000));
    expect(palette.cardEnd, const Color(0xFF4A0000));
  });

  testWidgets('voice assistant is an announced disabled game setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(const Scaffold(body: AiVoiceAssistantSetting())),
    );
    expect(find.text('AI Voice Assistant'), findsOneWidget);
    expect(find.text('Premium · قريباً'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
  });

  test('every persisted theme has one palette and readable text', () {
    expect(
      ThemeCatalog.themes.map((p) => p.id).toSet(),
      AppThemeId.values.map((p) => p.id).toSet(),
    );
    for (final palette in ThemeCatalog.themes) {
      expect(palette.isPremium, AppThemeId.fromId(palette.id)!.isPremium);
      final contrast =
          (palette.textSecondary.computeLuminance() + .05) /
          (palette.surface.computeLuminance() + .05);
      expect(contrast, greaterThanOrEqualTo(4.5), reason: palette.id);
    }
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('Premium hub fits $width px with large Arabic text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        frame(
          PremiumHubContent(isPremium: false, onExploreThemes: () {}),
          scale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('AI Voice Assistant'), 150);
      expect(find.text('AI Voice Assistant'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('الاشتراك غير متاح حالياً'),
        150,
      );
      expect(find.text('الاشتراك غير متاح حالياً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('free users can preview a locked theme without applying it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var applied = 0;
    await tester.pumpWidget(
      frame(
        ThemeGalleryContent(
          selectedThemeId: 'dark_blood',
          isPremium: false,
          onApply: (_) async {
            applied++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('منتصف الليل'), 250);
    await tester.tap(find.text('منتصف الليل'));
    await tester.pumpAndSettle();
    expect(find.text('معاينة الثيم'), findsOneWidget);
    expect(find.text('تطبيق هذا الثيم'), findsNothing);
    expect(applied, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Premium apply awaits persistence and reports a failed save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      frame(
        ThemeGalleryContent(
          selectedThemeId: 'dark_blood',
          isPremium: true,
          onApply: (_) async {
            throw StateError('offline');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('منتصف الليل'), 250);
    await tester.tap(find.text('منتصف الليل'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تطبيق هذا الثيم'));
    await tester.tap(find.text('تطبيق هذا الثيم'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر حفظ الثيم'), findsOneWidget);
    expect(find.text('معاينة الثيم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('second feature has its own action and no theme preview', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      frame(
        PremiumHubContent(
          isPremium: true,
          onExploreThemes: () {},
          features: const [
            PremiumFeature(
              id: 'second',
              title: 'ميزة تجريبية',
              description: 'وصف مستقل',
              icon: Icons.star_outline,
              actionLabel: 'افتح الميزة',
            ),
          ],
          featureActions: {'second': () => tapped = true},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ميزة تجريبية'), 200);
    await tester.tap(find.text('ميزة تجريبية'));
    await tester.pump();
    expect(tapped, true);
    expect(find.text('منتصف الليل'), findsNothing);
  });

  testWidgets(
    'nested preview tokens never alter the outer theme at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final outer = AppTheme.getTheme('dark_blood');
      final inner = AppTheme.getTheme('royal_gold');
      expect(outer.extension<GameVisualTokens>()!.palette.id, 'dark_blood');
      expect(inner.extension<GameVisualTokens>()!.palette.id, 'royal_gold');
      await tester.pumpWidget(
        frame(
          ThemeGalleryContent(
            selectedThemeId: 'dark_blood',
            isPremium: false,
            onApply: (_) async {},
          ),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('منتصف الليل'), 200);
      await tester.tap(find.text('منتصف الليل'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(outer.extension<GameVisualTokens>()!.palette.id, 'dark_blood');
    },
  );

  testWidgets('render Premium and theme collection review artifacts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      frame(
        PremiumHubContent(isPremium: false, onExploreThemes: () {}),
        captureKey: key,
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, key, 'premium');
    tester.view.physicalSize = const Size(900, 1240);
    await tester.pumpWidget(
      frame(
        ThemeGalleryContent(
          selectedThemeId: 'dark_blood',
          isPremium: false,
          onApply: (_) async {},
        ),
        captureKey: key,
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, key, 'themes');
    expect(tester.takeException(), isNull);
  });
}
