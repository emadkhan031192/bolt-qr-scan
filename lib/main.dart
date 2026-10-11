// Bolt QR Scan and Generator — entry point.
// Cold start: no splash, no blocking work. The database and settings load
// lazily in the background after the first frame; the scan screen goes
// straight to the camera.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BoltApp()));
}
