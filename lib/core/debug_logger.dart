/// Simple debug logger for troubleshooting
class DebugLogger {
  static bool _enabled = true;
  
  static void log(String message, {String tag = 'DEBUG'}) {
    if (_enabled) {
      final timestamp = DateTime.now().toString().substring(11, 23);
      print('[$tag][$timestamp] $message');
    }
  }
  
  static void logError(String message, dynamic error, {StackTrace? stackTrace}) {
    if (_enabled) {
      final timestamp = DateTime.now().toString().substring(11, 23);
      print('[ERROR][$timestamp] $message');
      print('[ERROR][$timestamp] Error: $error');
      if (stackTrace != null) {
        print('[ERROR][$timestamp] Stack trace: $stackTrace');
      }
    }
  }
  
  static void logFlow(String step, {Map<String, dynamic>? data}) {
    if (_enabled) {
      final timestamp = DateTime.now().toString().substring(11, 23);
      print('[FLOW][$timestamp] $step');
      if (data != null) {
        for (final entry in data.entries) {
          print('[FLOW][$timestamp]   ${entry.key}: ${entry.value}');
        }
      }
    }
  }
  
  static void enable() => _enabled = true;
  static void disable() => _enabled = false;
}