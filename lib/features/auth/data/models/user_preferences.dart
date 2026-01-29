class UserPreferences {
  final String? systemInstructions;
  final String? model;
  final bool? streamResponse;
  final String? themeMode; // 'system', 'light', 'dark'
  final bool? hapticFeedback;

  const UserPreferences({
    this.systemInstructions,
    this.model,
    this.streamResponse,
    this.themeMode,
    this.hapticFeedback,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      systemInstructions: json['systemInstructions'] as String?,
      model: json['model'] as String?,
      streamResponse: json['streamResponse'] as bool?,
      themeMode: json['themeMode'] as String?,
      hapticFeedback: json['hapticFeedback'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (systemInstructions != null) 'systemInstructions': systemInstructions,
      if (model != null) 'model': model,
      if (streamResponse != null) 'streamResponse': streamResponse,
      if (themeMode != null) 'themeMode': themeMode,
      if (hapticFeedback != null) 'hapticFeedback': hapticFeedback,
    };
  }
}
