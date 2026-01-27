enum ChatMode {
  general(
    id: 'general',
    label: 'General Assistant',
    systemPrompt: 'You are a helpful AI assistant.',
    iconName: 'auto_awesome',
  ),
  coding(
    id: 'coding',
    label: 'Coding Wizard',
    systemPrompt:
        'You are an expert software engineer. Provide clean, efficient, and well-documented code.',
    iconName: 'code',
  ),
  creative(
    id: 'creative',
    label: 'Creative Writer',
    systemPrompt:
        'You are a creative writer. Engage in storytelling and imaginative responses.',
    iconName: 'edit_note',
  ),
  concise(
    id: 'concise',
    label: 'Concise',
    systemPrompt: 'Be extremely concise. Answer in as few words as possible.',
    iconName: 'short_text',
  ),
  imageGeneration(
    id: 'image_generation',
    label: 'Image Generator',
    systemPrompt: 'Describe the image you want to generate.',
    iconName: 'image',
  );

  final String id;
  final String label;
  final String systemPrompt;
  final String iconName;

  const ChatMode({
    required this.id,
    required this.label,
    required this.systemPrompt,
    required this.iconName,
  });
}
