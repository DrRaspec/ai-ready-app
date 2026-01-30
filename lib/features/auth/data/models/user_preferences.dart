class UserPreferences {
  final String? systemInstructions;
  final String? model;
  final bool? streamResponse;
  final String? themeMode; // 'system', 'light', 'dark'
  final bool? hapticFeedback;
  final String? preferredName;
  final String? preferredTone;
  final String? preferredLanguage;
  final bool? enableMemory;

  const UserPreferences({
    this.systemInstructions,
    this.model,
    this.streamResponse,
    this.themeMode,
    this.hapticFeedback,
    this.preferredName,
    this.preferredTone,
    this.preferredLanguage,
    this.enableMemory,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      systemInstructions:
          (json['systemInstructions'] ?? json['customInstructions']) as String?,
      model: json['model'] as String?,
      streamResponse:
          (json['streamResponse'] ?? json['enableMemory'])
              as bool?, // Fallback or mapping?
      themeMode: json['themeMode'] as String?,
      hapticFeedback: json['hapticFeedback'] as bool?,
      preferredName: json['preferredName'] as String?,
      preferredTone: json['preferredTone'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      enableMemory: json['enableMemory'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (systemInstructions != null) 'systemInstructions': systemInstructions,
      'customInstructions': systemInstructions, // Send both for compatibility
      if (model != null) 'model': model,
      if (streamResponse != null) 'streamResponse': streamResponse,
      if (themeMode != null) 'themeMode': themeMode,
      if (hapticFeedback != null) 'hapticFeedback': hapticFeedback,
      if (preferredName != null) 'preferredName': preferredName,
      if (preferredTone != null) 'preferredTone': preferredTone,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      if (enableMemory != null) 'enableMemory': enableMemory,
    };
  }
}
