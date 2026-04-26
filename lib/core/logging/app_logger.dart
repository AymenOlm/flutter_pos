import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Defines severity levels for structured application logs.
enum AppLogLevel { debug, info, warning, error, critical }

/// Immutable representation of a structured log entry.
class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.feature,
    required this.action,
    required this.outcome,
    this.message,
    this.correlationId,
    this.errorCode,
    this.context = const <String, Object?>{},
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final String feature;
  final String action;
  final String outcome;
  final String? message;
  final String? correlationId;
  final String? errorCode;
  final Map<String, Object?> context;
  final Object? error;
  final StackTrace? stackTrace;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'level': level.name,
      'feature': feature,
      'action': action,
      'outcome': outcome,
      if (message != null) 'message': message,
      if (correlationId != null) 'correlationId': correlationId,
      if (errorCode != null) 'errorCode': errorCode,
      if (context.isNotEmpty) 'context': context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}

/// Sink target for log entries.
abstract class AppLogSink {
  void write(AppLogEntry entry);
}

/// Console sink for debug and local development diagnostics.
class ConsoleAppLogSink implements AppLogSink {
  @override
  void write(AppLogEntry entry) {
    debugPrint(jsonEncode(entry.toJson()));
  }
}

/// In-memory sink that can later be replaced by persisted or remote transport.
class BufferedAppLogSink implements AppLogSink {
  final List<AppLogEntry> _entries = <AppLogEntry>[];

  @override
  void write(AppLogEntry entry) {
    _entries.add(entry);
  }

  List<AppLogEntry> drain() {
    final snapshot = List<AppLogEntry>.unmodifiable(_entries);
    _entries.clear();
    return snapshot;
  }
}

/// Entry point for structured logging across app layers.
class AppLogger {
  AppLogger({required List<AppLogSink> sinks, Set<String>? redactedKeys})
    : _sinks = List<AppLogSink>.unmodifiable(sinks),
      _redactedKeys = (redactedKeys ?? _defaultRedactedKeys)
          .map((k) => k.toLowerCase())
          .toSet();

  final List<AppLogSink> _sinks;
  final Set<String> _redactedKeys;

  static const Set<String> _defaultRedactedKeys = <String>{
    'password',
    'token',
    'accessToken',
    'refreshToken',
    'cardNumber',
    'cvv',
    'pin',
    'email',
    'phone',
  };

  void debug({
    required String feature,
    required String action,
    required String outcome,
    String? message,
    String? correlationId,
    String? errorCode,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _write(
      level: AppLogLevel.debug,
      feature: feature,
      action: action,
      outcome: outcome,
      message: message,
      correlationId: correlationId,
      errorCode: errorCode,
      context: context,
    );
  }

  void info({
    required String feature,
    required String action,
    required String outcome,
    String? message,
    String? correlationId,
    String? errorCode,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _write(
      level: AppLogLevel.info,
      feature: feature,
      action: action,
      outcome: outcome,
      message: message,
      correlationId: correlationId,
      errorCode: errorCode,
      context: context,
    );
  }

  void warning({
    required String feature,
    required String action,
    required String outcome,
    String? message,
    String? correlationId,
    String? errorCode,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _write(
      level: AppLogLevel.warning,
      feature: feature,
      action: action,
      outcome: outcome,
      message: message,
      correlationId: correlationId,
      errorCode: errorCode,
      context: context,
    );
  }

  void error({
    required String feature,
    required String action,
    required String outcome,
    String? message,
    String? correlationId,
    String? errorCode,
    Map<String, Object?> context = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      level: AppLogLevel.error,
      feature: feature,
      action: action,
      outcome: outcome,
      message: message,
      correlationId: correlationId,
      errorCode: errorCode,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void critical({
    required String feature,
    required String action,
    required String outcome,
    String? message,
    String? correlationId,
    String? errorCode,
    Map<String, Object?> context = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      level: AppLogLevel.critical,
      feature: feature,
      action: action,
      outcome: outcome,
      message: message,
      correlationId: correlationId,
      errorCode: errorCode,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _write({
    required AppLogLevel level,
    required String feature,
    required String action,
    required String outcome,
    String? message,
    String? correlationId,
    String? errorCode,
    Map<String, Object?> context = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      feature: feature,
      action: action,
      outcome: outcome,
      message: message,
      correlationId: correlationId,
      errorCode: errorCode,
      context: _redactContext(context),
      error: error,
      stackTrace: stackTrace,
    );

    for (final sink in _sinks) {
      sink.write(entry);
    }
  }

  Map<String, Object?> _redactContext(Map<String, Object?> source) {
    if (source.isEmpty) {
      return const <String, Object?>{};
    }

    final redacted = <String, Object?>{};
    source.forEach((key, value) {
      final normalized = key.toLowerCase();
      if (_redactedKeys.contains(normalized)) {
        redacted[key] = '<redacted>';
      } else {
        redacted[key] = value;
      }
    });

    return redacted;
  }
}
