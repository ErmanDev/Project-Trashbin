import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Picks the platform-specific implementation of [forceExit].
import 'app_quit_stub.dart' if (dart.library.io) 'app_quit_io.dart';

/// Quits the application.
///
/// On Android [SystemNavigator.pop] closes the app gracefully. On iOS that
/// call is a no-op, so we fall back to a hard [forceExit]. On web there is
/// nothing to quit, so this does nothing.
Future<void> quitApp() async {
  if (kIsWeb) return;

  if (defaultTargetPlatform == TargetPlatform.android) {
    await SystemNavigator.pop();
    return;
  }

  // iOS and other desktop targets.
  forceExit();
}
