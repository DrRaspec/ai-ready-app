class ImageGenerationRequest {
  final String prompt;
  final String? aspectRatio;

  const ImageGenerationRequest({required this.prompt, this.aspectRatio});

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
    };
  }
}
