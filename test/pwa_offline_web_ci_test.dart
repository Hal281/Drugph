import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Milestone 1 — 100% Offline-First Clinical PWA & CI/CD Verification', () {
    test('1. web/manifest.json conforms to clinical PWA requirements', () {
      final manifestFile = File('web/manifest.json');
      expect(manifestFile.existsSync(), isTrue, reason: 'web/manifest.json must exist');

      final rawContent = manifestFile.readAsStringSync();
      expect(rawContent.contains('drug_dosage_calculator'), isFalse,
          reason: 'web/manifest.json must not retain boilerplate name');
      expect(rawContent.contains('A new Flutter project.'), isFalse,
          reason: 'web/manifest.json must not retain boilerplate description');

      final manifest = jsonDecode(rawContent) as Map<String, dynamic>;

      expect(manifest['name'], equals('Drugph — Clinical Dosage & Medication Safety'));
      expect(manifest['short_name'], equals('Drugph'));
      expect(manifest['display'], equals('standalone'));
      expect(manifest['orientation'], equals('any'));
      expect(manifest['theme_color'], equals('#00796B'));
      expect(manifest['background_color'], equals('#F8FAFC'));
      expect(manifest['start_url'], equals('.'));
      expect(manifest['scope'], equals('.'));
      expect(manifest['lang'], equals('th'));
      expect(manifest['dir'], equals('ltr'));
      expect(manifest['description'], contains('Clinical Dosage Calculation'));

      final icons = manifest['icons'] as List<dynamic>;
      expect(icons, isNotEmpty);

      // Verify that all declared icon assets physically exist on disk
      for (final icon in icons) {
        final iconMap = icon as Map<String, dynamic>;
        final iconSrc = iconMap['src'] as String;
        final iconFile = File('web/$iconSrc');
        expect(
          iconFile.existsSync(),
          isTrue,
          reason: 'Declared manifest icon "$iconSrc" must physically exist in web/',
        );
      }

      // Verify maskable and standard icons are both present
      final hasStandard192 = icons.any((i) => i['sizes'] == '192x192' && i['purpose'] != 'maskable');
      final hasStandard512 = icons.any((i) => i['sizes'] == '512x512' && i['purpose'] != 'maskable');
      final hasMaskable192 = icons.any((i) => i['sizes'] == '192x192' && i['purpose'] == 'maskable');
      final hasMaskable512 = icons.any((i) => i['sizes'] == '512x512' && i['purpose'] == 'maskable');

      expect(hasStandard192, isTrue, reason: 'Standard 192x192 icon must be present');
      expect(hasStandard512, isTrue, reason: 'Standard 512x512 icon must be present');
      expect(hasMaskable192, isTrue, reason: 'Maskable 192x192 icon must be present');
      expect(hasMaskable512, isTrue, reason: 'Maskable 512x512 icon must be present');
    });

    test('2. web/index.html includes viewport, clinical meta, and #loading-indicator', () {
      final indexFile = File('web/index.html');
      expect(indexFile.existsSync(), isTrue, reason: 'web/index.html must exist');

      final html = indexFile.readAsStringSync();

      expect(html.contains('drug_dosage_calculator'), isFalse,
          reason: 'web/index.html must not contain boilerplate app title');
      expect(html.contains('A new Flutter project.'), isFalse,
          reason: 'web/index.html must not contain boilerplate description');

      // Viewport & theme color
      expect(html, contains('<base href="\$FLUTTER_BASE_HREF">'));
      expect(html, contains('name="viewport"'));
      expect(html, contains('width=device-width'));
      expect(html, contains('content="#00796B"'));
      expect(html, contains('<title>Drugph — Clinical Dosage & Medication Safety</title>'));

      // iOS standalone meta
      expect(html, contains('content="Drugph"'));
      expect(html, contains('apple-mobile-web-app-capable'));

      // Loading indicator pre-frame DOM
      expect(html, contains('id="loading-indicator"'));
      expect(html, contains('class="spinner"'));
      expect(html, contains('Drugph'));
      expect(html, contains('flutter_bootstrap.js'));
    });

    test('3. pubspec.yaml registers local ThaiFont & Sarabun fonts', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final yaml = pubspecFile.readAsStringSync();

      // Check font declarations
      expect(yaml, contains('family: ThaiFont'));
      expect(yaml, contains('family: Sarabun'));
      expect(yaml, contains('asset: assets/fonts/ThaiFont.ttf'));

      // Check physical font file on disk
      final fontFile = File('assets/fonts/ThaiFont.ttf');
      expect(fontFile.existsSync(), isTrue, reason: 'assets/fonts/ThaiFont.ttf must physically exist');
      expect(fontFile.lengthSync(), greaterThan(500000),
          reason: 'ThaiFont.ttf should be a complete font file (~900KB)');
    });

    test('4. lib/main.dart configures ThaiFont and Sarabun fallbacks in ThemeData', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);

      final content = mainFile.readAsStringSync();

      expect(content, contains("fontFamily: 'ThaiFont'"),
          reason: 'ThemeData must set primary fontFamily to ThaiFont');
      expect(content, contains("'ThaiFont', 'Sarabun', 'sans-serif'"),
          reason: 'ThemeData must configure fontFamilyFallback with ThaiFont, Sarabun, and sans-serif');
    });

    test('5. .github/workflows/flutter_web.yml enforces security gates and zero secret exposure', () {
      final workflowFile = File('.github/workflows/flutter_web.yml');
      expect(workflowFile.existsSync(), isTrue);

      final yaml = workflowFile.readAsStringSync();

      // Permissions block for GitHub Pages deployment
      expect(yaml, contains('permissions:'));
      expect(yaml, contains('contents: write'));

      // CI quality gates before build
      expect(yaml, contains('run: flutter test --no-pub'),
          reason: 'Must run unit tests with --no-pub before build');
      expect(yaml, contains('run: dart analyze'),
          reason: 'Must enforce static analysis before build');

      // Offline-first PWA flags
      expect(yaml, contains('--release'));
      expect(yaml, contains('--base-href "/Drugph/"'));
      expect(yaml, contains('--no-web-resources-cdn'),
          reason: 'Must bundle web resources locally for ward offline use');
      expect(yaml, contains('--pwa-strategy=offline-first'),
          reason: 'Must specify offline-first PWA strategy');

      // Security: AI proxy URL allowed, but GEMINI_API_KEY MUST NOT be exposed
      expect(yaml, contains('AI_PROXY_URL'));
      expect(yaml.contains('GEMINI_API_KEY'), isFalse,
          reason: 'GEMINI_API_KEY must NEVER be embedded in client-side build flags');
    });
  });
}
