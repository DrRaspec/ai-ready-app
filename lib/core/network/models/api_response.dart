class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final DateTime? timestamp;
  final int status;
  final String? path;
  final String? error;
  final Map<String, dynamic>? details;

  ApiResponse({
    required this.success,
    required this.message,
    this.timestamp,
    required this.status,
    this.path,
    this.data,
    this.error,
    this.details,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      status: json['status'] ?? 500,
      path: json['path'],
      error: json['error'],
      details: json['details'],
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }

  String getDetailedMessage() {
    if (details != null && details!.isNotEmpty) {
      final firstError = details!.values.first;
      if (firstError is String) {
        return firstError;
      } else if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }
    return message ?? 'Something went wrong';
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
