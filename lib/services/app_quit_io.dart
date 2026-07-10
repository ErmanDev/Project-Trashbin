import 'dart:io';

/// Hard-terminates the process. Used as a fallback on iOS where
/// [SystemNavigator.pop] does not close the app.
void forceExit() => exit(0);
