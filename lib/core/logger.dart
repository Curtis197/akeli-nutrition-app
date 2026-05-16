import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logger for the Akeli Nutrition App
/// 
/// This logger provides consistent, structured logging across the application
/// with emoji indicators for different operation types and automatic log level
/// management based on debug/release mode.
/// 
/// ## Usage
/// 
/// ```dart
/// // Import this file
/// import 'package:akeli/core/logger.dart';
/// 
/// // Create a logger instance in your class
/// class MyProvider extends AsyncNotifier<List<Item>> {
///   final _logger = appLogger;
///   
///   @override
///   Future<List<Item>> build() async {
///     _logger.d('🔄 Provider: MyProvider initialized');
///     return _fetchItems();
///   }
/// }
/// ```
/// 
/// ## Log Levels
/// 
/// - `trace`: Extremely detailed (every state change, variable values)
/// - `debug`: Developer debugging (query details, provider lifecycle)
/// - `info`: Important events (auth success, user actions)
/// - `warning`: Potential issues (deprecated API, near limits, RLS blocks)
/// - `error`: Actual errors (exceptions, failed operations)
/// 
/// ## Emoji Legend
/// 
/// | Emoji | Meaning |
/// |-------|---------|
/// | 🔐 | Authentication |
/// | 📡 | Database query |
/// | 🔍 | RLS check |
/// | 🔄 | Provider lifecycle |
/// | ⚡ | Edge function |
/// | 🎯 | User action |
/// | ✅ | Success |
/// | ❌ | Error |
/// | ⚠️ | Warning |
/// | 🚫 | Blocked/Denied |
/// | 💥 | Critical failure |
/// | 👤 | User context |
/// | 🗑️ | Cleanup/Dispose |

class AkeliLogger {
  static final Logger _instance = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  static Logger get instance => _instance;

  /// Private constructor to prevent instantiation
  AkeliLogger._();
}

/// Global logger instance for easy access throughout the app
final appLogger = AkeliLogger.instance;

/// Extension methods for category-specific logging
extension AkeliLoggerExtension on Logger {
  // ==================== Authentication Logs ====================

  /// Log authentication events (sign-in, sign-up, sign-out, token refresh)
  void auth(String message, {dynamic error, StackTrace? stackTrace}) {
    if (error != null) {
      e('🔐 Auth: $message', error: error, stackTrace: stackTrace);
    } else {
      i('🔐 Auth: $message');
    }
  }

  // ==================== Database Logs ====================

  /// Log database operations (queries, inserts, updates, deletes)
  void db(String message, {dynamic error, StackTrace? stackTrace}) {
    if (error != null) {
      e('📡 DB: $message', error: error, stackTrace: stackTrace);
    } else {
      d('📡 DB: $message');
    }
  }

  // ==================== RLS Logs ====================

  /// Log Row Level Security checks and violations
  void rls(String message, {dynamic error, StackTrace? stackTrace}) {
    if (error != null) {
      e('🚫 RLS: $message', error: error, stackTrace: stackTrace);
    } else {
      w('🔍 RLS: $message');
    }
  }

  // ==================== Provider Lifecycle Logs ====================

  /// Log Riverpod provider lifecycle events (init, rebuild, dispose)
  void provider(String message, {dynamic error, StackTrace? stackTrace}) {
    if (error != null) {
      e('🔄 Provider: $message', error: error, stackTrace: stackTrace);
    } else {
      d('🔄 Provider: $message');
    }
  }

  // ==================== Edge Function Logs ====================

  /// Log edge function invocations and results
  void edge(String functionName, String message, {dynamic error, StackTrace? stackTrace}) {
    if (error != null) {
      e('⚡ Function: $functionName - $message', error: error, stackTrace: stackTrace);
    } else {
      i('⚡ Function: $functionName - $message');
    }
  }

  // ==================== User Action Logs ====================

  /// Log user actions (button taps, form submissions, gestures)
  void userAction(String action, {String? screen, dynamic metadata}) {
    final screenContext = screen != null ? ' [screen: $screen]' : '';
    final metaStr = metadata != null ? ' | metadata: $metadata' : '';
    i('🎯 UI: $action$screenContext$metaStr');
  }

  // ==================== Navigation Logs ====================

  /// Log navigation/routing events (route changes, auth guards, deep links)
  void navigation(String from, String to, {String? reason}) {
    final reasonStr = reason != null ? ' [reason: $reason]' : '';
    d('🧭 Navigation: $from → $to$reasonStr');
  }

  // ==================== Performance Logs ====================

  /// Log performance metrics (query duration, operation timing)
  void performance(String operation, Duration duration, {String? context}) {
    final contextStr = context != null ? ' | $context' : '';
    if (duration.inMilliseconds > 1000) {
      w('⏱️ Perf: $operation took ${duration.inMilliseconds}ms$contextStr');
    } else {
      d('⏱️ Perf: $operation took ${duration.inMilliseconds}ms$contextStr');
    }
  }
}

/// Helper function to mask sensitive data in logs
class LogHelper {
  /// Mask email address (show first 3 chars and domain first 3 chars)
  /// Example: "john.doe@example.com" → "joh***@exa***"
  static String maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return '***';
      
      final localPart = parts[0];
      final domainPart = parts[1];
      
      final maskedLocal = localPart.length > 3 
          ? '${localPart.substring(0, 3)}***'
          : '***';
      
      final maskedDomain = domainPart.length > 3
          ? '${domainPart.substring(0, 3)}***'
          : '***';
      
      return '$maskedLocal@$maskedDomain';
    } catch (e) {
      return '***';
    }
  }

  /// Mask UUID (show first 4 and last 4 chars)
  /// Example: "abc123-def456-ghi789" → "abc1***h789"
  static String maskUuid(String uuid) {
    if (uuid.length <= 8) return '***';
    return '${uuid.substring(0, 4)}***${uuid.substring(uuid.length - 4)}';
  }

  /// Mask token (show first 10 and last 10 chars)
  static String maskToken(String token) {
    if (token.length <= 20) return '***';
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }

  /// Sanitize object for safe logging (removes sensitive fields)
  static Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    
    // Remove sensitive fields
    sanitized.remove('password');
    sanitized.remove('access_token');
    sanitized.remove('refresh_token');
    sanitized.remove('api_key');
    sanitized.remove('secret');
    sanitized.remove('card_number');
    sanitized.remove('cvv');
    
    // Mask email if present
    if (sanitized.containsKey('email')) {
      sanitized['email'] = maskEmail(sanitized['email']);
    }
    
    // Mask token if present
    if (sanitized.containsKey('token')) {
      sanitized['token'] = maskToken(sanitized['token']);
    }
    
    return sanitized;
  }
}

/// RLS Debug Helper
/// Use this when you suspect RLS is blocking access
class RLSDebugHelper {
  /// Log detailed RLS context when queries return unexpected results
  static void debugQuery(
    String tableName,
    String? userId, {
    Map<String, dynamic>? filters,
    int rowCount = 0,
  }) {
    appLogger.d('🔍 RLS DEBUG: Querying "$tableName" table');
    appLogger.d('  userId: ${userId ?? "null (not authenticated)"}');
    appLogger.d('  filters: ${filters ?? "none"}');
    appLogger.d('  rows returned: $rowCount');
    
    if (rowCount == 0 && userId != null) {
      appLogger.w('⚠️ RLS DEBUG: Possible RLS policy blocking userId: $userId');
      appLogger.w('  Check policies on "$tableName" table for auth_uid() match');
    }
  }

  /// Log RLS policy check result
  static void logPolicyCheck(
    String tableName,
    String policyName,
    bool allowed, {
    String? userId,
  }) {
    if (allowed) {
      appLogger.d('✅ RLS: Policy "$policyName" on "$tableName" allowed for userId: $userId');
    } else {
      appLogger.w('🚫 RLS: Policy "$policyName" on "$tableName" blocked for userId: $userId');
    }
  }
}
