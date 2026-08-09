import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'services/msg91_widget_bridge.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Flutter framework errors (widget build/layout/paint errors)
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error('FlutterError', details.exception, details.stack);
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Platform-level uncaught errors (e.g. from platform channels)
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('PlatformDispatcher', error, stack);
      return true; // handled, don't crash
    };

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Debug mode mein Crashlytics collection off rakho, taaki testing ke
    // crashes production dashboard mein noise na banayein
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    runApp(const ProviderScope(child: ChhatApp()));
    FlutterNativeSplash.remove();
  }, (error, stack) {
    // Catches everything else (async errors outside Flutter's own error zone)
    AppLogger.error('UncaughtZoneError', error, stack);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

class ChhatApp extends ConsumerWidget {
  const ChhatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Chhat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Light theme define kiya
      darkTheme: AppTheme.darkTheme, // Dark theme define kiya
      themeMode: ThemeMode
          .light, // TODO: Dark mode screens fix hone ke baad system pe switch karna
      routerConfig: router,
      localizationsDelegates: const [
        // AppLocalizations.delegate,  ← baad mein uncomment karna
      ],
      supportedLocales: const [
        Locale('hi'), // Hindi
        Locale('mr'), // Marathi
        Locale('en'), // English fallback
      ],
      // NAYA: MSG91 OTP widget ke liye ek hidden, hamesha-zinda WebView —
      // yeh route change hone par disappear nahi hota (builder ke bahar
      // Navigator hai), isliye phone->otp jaate waqt session nahi tootta.
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const _HiddenMsg91WebView(),
          ],
        );
      },
    );
  }
}

class _HiddenMsg91WebView extends StatefulWidget {
  const _HiddenMsg91WebView();

  @override
  State<_HiddenMsg91WebView> createState() => _HiddenMsg91WebViewState();
}

class _HiddenMsg91WebViewState extends State<_HiddenMsg91WebView> {
  @override
  void initState() {
    super.initState();
    Msg91WidgetBridge.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return const Offstage(
      offstage: true,
      child: SizedBox(
        width: 1,
        height: 1,
        child: _Msg91WebViewWidget(),
      ),
    );
  }
}

class _Msg91WebViewWidget extends StatelessWidget {
  const _Msg91WebViewWidget();

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: Msg91WidgetBridge.instance.controller);
  }
}
