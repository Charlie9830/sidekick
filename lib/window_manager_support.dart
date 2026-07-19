import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether the current platform supports `window_manager`.
///
/// Web is excluded because the plugin does not support it — browser close
/// interception is a different mechanism (`beforeunload`) entirely. Callers
/// must check this before touching `windowManager`; on unsupported platforms
/// its method channel is not registered.
bool get supportsWindowManager =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
