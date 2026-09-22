// Picks the sembast backend for the current platform: files on mobile and
// desktop, IndexedDB on the web.
export 'platform_database_io.dart'
    if (dart.library.js_interop) 'platform_database_web.dart';
