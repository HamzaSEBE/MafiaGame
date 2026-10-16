import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/data/repositories/theme_preferences_repository.dart';
import 'package:mafia_nightfall/presentation/auth/login_screen.dart';
import 'package:mafia_nightfall/presentation/splash/splash_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import 'package:mafia_nightfall/presentation/premium/theme_experience_preview.dart';

class QuietSplashAudio implements AudioManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class PreviewPreferences implements ThemePreferencesRepository {
  PreviewPreferences(this.themeId);
  final String themeId;
  @override
  Future<String?> load(String uid) async => themeId;
  @override
  Future<void> save(String uid, String themeId) async {}
}

Widget frame(
  Widget screen,
  ThemePalette palette, {
  double scale = 1,
  double keyboard = 0,
  GlobalKey? captureKey,
}) => ProviderScope(
  overrides: [
    audioManagerProvider.overrideWithValue(QuietSplashAudio()),
    selectedThemeProvider.overrideWith(
      (ref) => ThemeSelectionNotifier(
        repository: PreviewPreferences(palette.id),
        uid: 'preview',
        isPremium: true,
      ),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.previewTheme(palette),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(scale),
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: captureKey, child: child!),
      ),
    ),
    home: screen,
  ),
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

void phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Cairo',
    )..addFont(rootBundle.load('assets/fonts/Cairo.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final palette in ThemeCatalog.themes) {
    testWidgets('${palette.id} styles login and splash using the same palette', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      for (final screen in [const LoginScreen(), const SplashScreen()]) {
        await tester.pumpWidget(frame(screen, palette));
        await tester.pump();
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          palette.background,
        );
        expect(find.byType(AnimatedBackground), findsOneWidget);
        final decorations = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((w) => w.decoration)
            .whereType<BoxDecoration>()
            .toList();
        expect(
          decorations.any((d) => d.gradient == palette.backgroundGradient),
          isTrue,
        );
        expect(
          decorations.any((d) => d.gradient == palette.actionGradient),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        // Leaving splash cancels its delayed route, without touching Firebase.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 5));
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('login scrolls with large Arabic text and an open keyboard', (
    tester,
  ) async {
    phone(tester, const Size(320, 640));
    await tester.pumpWidget(
      frame(
        const LoginScreen(),
        ThemeCatalog.themes.first,
        scale: 2,
        keyboard: 250,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('دخول'));
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('مطلوب'), findsNWidgets(2));
    await tester.ensureVisible(find.text('إنشاء حساب'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('splash fits a short landscape screen with large Arabic text', (
    tester,
  ) async {
    phone(tester, const Size(640, 320));
    await tester.pumpWidget(
      frame(const SplashScreen(), ThemeCatalog.themes.first, scale: 2),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('مافيا عالشوارب'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
  test('two-color actions retain readable titles across every palette', () {
    for (final palette in ThemeCatalog.themes) {
      for (final background in [palette.cardStart, palette.cardEnd]) {
        final contrast =
            (palette.textPrimary.computeLuminance() + .05) /
            (background.computeLuminance() + .05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: palette.id);
      }
      final linkContrast =
          (palette.companion.computeLuminance() + .05) /
          (palette.surface.computeLuminance() + .05);
      expect(
        linkContrast,
        greaterThanOrEqualTo(4.5),
        reason: '${palette.id} links',
      );
    }
  });
  testWidgets('capture actual login splash and all in-game palette previews', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    final key = GlobalKey();
    await tester.pumpWidget(
      frame(const LoginScreen(), ThemeCatalog.themes.first, captureKey: key),
    );
    await tester.pumpAndSettle();
    await capture(tester, key, 'login-1.2.2');
    await tester.pumpWidget(
      frame(const SplashScreen(), ThemeCatalog.themes.first, captureKey: key),
    );
    await tester.pump();
    await capture(tester, key, 'splash-1.2.2');
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = const Size(1000, 850);
    await tester.pumpWidget(
      frame(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.25,
              children: [
                for (final palette in ThemeCatalog.themes)
                  Theme(
                    data: AppTheme.previewTheme(palette),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          palette.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 12),
                        const ThemeExperiencePreview(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        ThemeCatalog.themes.first,
        captureKey: key,
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, key, 'palette-previews-1.2.2');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
