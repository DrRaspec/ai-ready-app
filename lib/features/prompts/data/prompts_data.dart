/// Quick prompt templates for the AI chat
class PromptsData {
  static const List<PromptCategory> categories = [
    PromptCategory(
      name: 'Writing',
      icon: 'edit',
      color: 0xFF6366F1,
      prompts: [
        Prompt(
          title: 'Summarize Text',
          description: 'Get a concise summary',
          content:
              'Please summarize the following text in a clear and concise manner:\n\n',
        ),
        Prompt(
          title: 'Improve Writing',
          description: 'Enhance grammar and style',
          content:
              'Please improve the following text, fixing grammar and enhancing clarity:\n\n',
        ),
        Prompt(
          title: 'Translate',
          description: 'Translate to another language',
          content:
              'Please translate the following text to [TARGET LANGUAGE]:\n\n',
        ),
        Prompt(
          title: 'Explain Simply',
          description: 'Explain like I\'m 5',
          content:
              'Please explain the following concept in simple terms that anyone can understand:\n\n',
        ),
      ],
    ),
    PromptCategory(
      name: 'Coding',
      icon: 'code',
      color: 0xFF10B981,
      prompts: [
        Prompt(
          title: 'Debug Code',
          description: 'Find and fix bugs',
          content:
              'Please help me debug the following code and explain what\'s wrong:\n\n```\n\n```',
        ),
        Prompt(
          title: 'Explain Code',
          description: 'Understand code logic',
          content:
              'Please explain what this code does step by step:\n\n```\n\n```',
        ),
        Prompt(
          title: 'Write Tests',
          description: 'Generate unit tests',
          content:
              'Please write unit tests for the following function:\n\n```\n\n```',
        ),
        Prompt(
          title: 'Optimize Code',
          description: 'Improve performance',
          content:
              'Please optimize the following code for better performance:\n\n```\n\n```',
        ),
        Prompt(
          title: 'Convert Language',
          description: 'Translate to another language',
          content:
              'Please convert the following code to [TARGET LANGUAGE]:\n\n```\n\n```',
        ),
      ],
    ),
    PromptCategory(
      name: 'Brainstorm',
      icon: 'lightbulb',
      color: 0xFFF59E0B,
      prompts: [
        Prompt(
          title: 'Generate Ideas',
          description: 'Get creative suggestions',
          content: 'Please brainstorm 10 creative ideas for:\n\n',
        ),
        Prompt(
          title: 'Pros and Cons',
          description: 'Analyze advantages and disadvantages',
          content: 'Please list the pros and cons of:\n\n',
        ),
        Prompt(
          title: 'Compare Options',
          description: 'Compare different choices',
          content: 'Please compare and contrast the following options:\n\n',
        ),
        Prompt(
          title: 'Problem Solve',
          description: 'Find solutions step by step',
          content: 'Please help me solve this problem step by step:\n\n',
        ),
      ],
    ),
    PromptCategory(
      name: 'Learning',
      icon: 'school',
      color: 0xFFEC4899,
      prompts: [
        Prompt(
          title: 'Teach Topic',
          description: 'Learn something new',
          content: 'Please teach me about the following topic in detail:\n\n',
        ),
        Prompt(
          title: 'Quiz Me',
          description: 'Test your knowledge',
          content: 'Please create 5 quiz questions about:\n\n',
        ),
        Prompt(
          title: 'Study Plan',
          description: 'Create a learning schedule',
          content: 'Please create a study plan for learning:\n\n',
        ),
        Prompt(
          title: 'Key Concepts',
          description: 'Extract main ideas',
          content:
              'Please list the key concepts and terms I should know about:\n\n',
        ),
      ],
    ),
    PromptCategory(
      name: 'Work',
      icon: 'work',
      color: 0xFF8B5CF6,
      prompts: [
        Prompt(
          title: 'Write Email',
          description: 'Draft professional emails',
          content: 'Please help me write a professional email about:\n\n',
        ),
        Prompt(
          title: 'Meeting Agenda',
          description: 'Create meeting structure',
          content: 'Please create a meeting agenda for:\n\n',
        ),
        Prompt(
          title: 'Project Plan',
          description: 'Outline project steps',
          content: 'Please create a project plan with milestones for:\n\n',
        ),
        Prompt(
          title: 'Cover Letter',
          description: 'Write job applications',
          content: 'Please help me write a cover letter for a position as:\n\n',
        ),
      ],
    ),
  ];
}

class PromptCategory {
  final String name;
  final String icon;
  final int color;
  final List<Prompt> prompts;

  const PromptCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.prompts,
  });
}

class Prompt {
  final String title;
  final String description;
  final String content;

  const Prompt({
    required this.title,
    required this.description,
    required this.content,
  });
}
