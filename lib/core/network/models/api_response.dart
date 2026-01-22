class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int status;
  final String path;
  final String? error;
  final Map<String, dynamic>? details;

  ApiResponse({
    required this.success,
    required this.message,
    required this.status,
    required this.path,
    this.data,
    this.error,
    this.details,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'],
      message: json['message'],
      status: json['status'],
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
    return message;
  }
}
