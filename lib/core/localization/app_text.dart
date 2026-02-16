import 'package:flutter/widgets.dart';

class AppText {
  final String _languageCode;

  const AppText._(this._languageCode);

  factory AppText.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return AppText._(code);
  }

  bool get _isKhmer => _languageCode == 'km';

  String tr(String english, String khmer) => _isKhmer ? khmer : english;

  String get appearanceSettings =>
      _isKhmer ? 'ការកំណត់រូបរាង' : 'Appearance Settings';
  String get fontSize => _isKhmer ? 'ទំហំអក្សរ' : 'Font Size';
  String get fontFamily => _isKhmer ? 'ពុម្ពអក្សរ' : 'Font Family';
  String get language => _isKhmer ? 'ភាសា' : 'Language';
  String get systemLanguage => _isKhmer ? 'តាមប្រព័ន្ធ' : 'System';
  String get english => _isKhmer ? 'អង់គ្លេស' : 'English';
  String get khmer => _isKhmer ? 'ខ្មែរ' : 'Khmer';

  String get welcomeBack => _isKhmer ? 'ស្វាគមន៍ត្រឡប់មកវិញ' : 'Welcome Back';
  String get signInToYourAccount =>
      _isKhmer ? 'ចូលទៅកាន់គណនីរបស់អ្នក' : 'Sign in to your account';
  String get createAccount => _isKhmer ? 'បង្កើតគណនី' : 'Create Account';
  String get joinToStartChatting =>
      _isKhmer ? 'ចូលរួមជាមួយយើងដើម្បីចាប់ផ្តើមជជែក' : 'Join us to start chatting';
  String get firstName => _isKhmer ? 'នាមខ្លួន' : 'First Name';
  String get lastName => _isKhmer ? 'នាមត្រកូល' : 'Last Name';
  String get requiredField => _isKhmer ? 'ត្រូវបំពេញ' : 'Required';
  String get emailAddress => _isKhmer ? 'អ៊ីមែល' : 'Email address';
  String get password => _isKhmer ? 'ពាក្យសម្ងាត់' : 'Password';
  String get confirmPassword =>
      _isKhmer ? 'បញ្ជាក់ពាក្យសម្ងាត់' : 'Confirm Password';
  String get forgotPassword =>
      _isKhmer ? 'ភ្លេចពាក្យសម្ងាត់?' : 'Forgot Password?';
  String get login => _isKhmer ? 'ចូល' : 'Login';
  String get signIn => _isKhmer ? 'ចូល' : 'Sign In';
  String get orContinueWith => _isKhmer ? 'ឬបន្តជាមួយ' : 'Or continue with';
  String get dontHaveAccount =>
      _isKhmer ? 'មិនទាន់មានគណនីមែនទេ?' : "Don't have an account?";
  String get alreadyHaveAccount =>
      _isKhmer ? 'មានគណនីរួចហើយ?' : 'Already have an account?';
  String get signUp => _isKhmer ? 'ចុះឈ្មោះ' : 'Sign Up';
  String get pleaseEnterEmail =>
      _isKhmer ? 'សូមបញ្ចូលអ៊ីមែល' : 'Please enter your email';
  String get pleaseEnterValidEmail =>
      _isKhmer ? 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ' : 'Please enter a valid email';
  String get pleaseEnterPassword =>
      _isKhmer ? 'សូមបញ្ចូលពាក្យសម្ងាត់' : 'Please enter your password';
  String get minEightCharacters =>
      _isKhmer ? 'យ៉ាងតិច 8 តួអក្សរ' : 'Min 8 characters';
  String get pleaseConfirmPassword =>
      _isKhmer ? 'សូមបញ្ជាក់ពាក្យសម្ងាត់' : 'Please confirm password';
  String get passwordsDoNotMatch =>
      _isKhmer ? 'ពាក្យសម្ងាត់មិនត្រូវគ្នា' : 'Passwords do not match';
  String get passwordAtLeastSix => _isKhmer
      ? 'ពាក្យសម្ងាត់យ៉ាងតិច 6 តួអក្សរ'
      : 'Password must be at least 6 characters';

  String get search => _isKhmer ? 'ស្វែងរក' : 'Search';
  String get newChat => _isKhmer ? 'ជជែកថ្មី' : 'New Chat';
  String get images => _isKhmer ? 'រូបភាព' : 'Images';
  String get prompts => _isKhmer ? 'ពាក្យបញ្ជា' : 'Prompts';
  String get newPrompt => _isKhmer ? 'ពាក្យបញ្ជាថ្មី' : 'New Prompt';
  String get promptLibrary =>
      _isKhmer ? 'បណ្ណាល័យពាក្យបញ្ជា' : 'Prompt Library';
  String get newConversation =>
      _isKhmer ? 'ការសន្ទនាថ្មី' : 'New Conversation';
  String get all => _isKhmer ? 'ទាំងអស់' : 'All';
  String get loading => _isKhmer ? 'កំពុងផ្ទុក...' : 'Loading...';
  String get noMatchingConversations =>
      _isKhmer ? 'មិនមានការសន្ទនាត្រូវគ្នា' : 'No matching conversations';
  String get noConversationsYet =>
      _isKhmer ? 'មិនទាន់មានការសន្ទនា' : 'No conversations yet';
  String get myProfile => _isKhmer ? 'ប្រវត្តិរូបខ្ញុំ' : 'My Profile';
  String get basicAccount => _isKhmer ? 'គណនីមូលដ្ឋាន' : 'Basic Account';
  String get rename => _isKhmer ? 'ប្តូរឈ្មោះ' : 'Rename';
  String get moveToFolder => _isKhmer ? 'ផ្លាស់ទៅថត' : 'Move to Folder';
  String get delete => _isKhmer ? 'លុប' : 'Delete';
  String get cancel => _isKhmer ? 'បោះបង់' : 'Cancel';
  String get create => _isKhmer ? 'បង្កើត' : 'Create';
  String get deleteConversation =>
      _isKhmer ? 'លុបការសន្ទនា' : 'Delete Conversation';
  String get thisConversation =>
      _isKhmer ? 'ការសន្ទនានេះ' : 'this conversation';
  String deleteConversationConfirm(String title) => _isKhmer
      ? 'តើអ្នកប្រាកដថាចង់លុប "$title" មែនទេ?'
      : 'Are you sure you want to delete "$title"?';
  String get renameConversation =>
      _isKhmer ? 'ប្តូរឈ្មោះការសន្ទនា' : 'Rename Conversation';
  String get conversationTitle =>
      _isKhmer ? 'ចំណងជើងការសន្ទនា' : 'Conversation Title';
  String get enterNewTitle =>
      _isKhmer ? 'បញ្ចូលចំណងជើងថ្មី' : 'Enter a new title';
  String get renameFolder => _isKhmer ? 'ប្តូរឈ្មោះថត' : 'Rename Folder';
  String get deleteFolder => _isKhmer ? 'លុបថត' : 'Delete Folder';
  String get folderName => _isKhmer ? 'ឈ្មោះថត' : 'Folder Name';
  String get enterNewName =>
      _isKhmer ? 'បញ្ចូលឈ្មោះថ្មី' : 'Enter new name';
  String get newFolder => _isKhmer ? 'ថតថ្មី' : 'New Folder';
  String get folderNameExamples =>
      _isKhmer ? 'ឧ. ការងារ, ផ្ទាល់ខ្លួន' : 'e.g., Work, Personal';
  String get noFolderUncategorized =>
      _isKhmer ? 'មិនមានថត (មិនបានចាត់ថ្នាក់)' : 'No Folder (Uncategorized)';
  String deleteFolderConfirm(String folderName) => _isKhmer
      ? 'តើអ្នកប្រាកដថាចង់លុបថត "$folderName" មែនទេ?\nការសន្ទនាខាងក្នុងនឹងត្រូវផ្លាស់ទៅ "ទាំងអស់".'
      : 'Are you sure you want to delete folder "$folderName"?\nConversations inside will be moved to "All".';

  String get user => _isKhmer ? 'អ្នកប្រើ' : 'User';
  String get editProfile => _isKhmer ? 'កែប្រវត្តិរូប' : 'Edit Profile';
  String get logout => _isKhmer ? 'ចាកចេញ' : 'Logout';
  String get yourStats => _isKhmer ? 'ស្ថិតិរបស់អ្នក' : 'Your Stats';
  String get conversations => _isKhmer ? 'ការសន្ទនា' : 'Conversations';
  String get messages => _isKhmer ? 'សារ' : 'Messages';
  String get badges => _isKhmer ? 'ផ្លាកសញ្ញា' : 'Badges';
  String get quickActions => _isKhmer ? 'សកម្មភាពរហ័ស' : 'Quick Actions';
  String get bookmarks => _isKhmer ? 'ចំណាំ' : 'Bookmarks';
  String get viewSavedMessages =>
      _isKhmer ? 'មើលសារដែលបានរក្សាទុក' : 'View saved messages';
  String get discover => _isKhmer ? 'ស្វែងរក' : 'Discover';
  String get aiTipsAndPrompts =>
      _isKhmer ? 'គន្លឹះ AI និងពាក្យបញ្ជា' : 'AI tips and prompts';
  String get personalization => _isKhmer ? 'កំណត់ផ្ទាល់ខ្លួន' : 'Personalization';
  String get aiPersonaAndPreferences =>
      _isKhmer ? 'តួនាទី AI និងចំណូលចិត្ត' : 'AI Persona & Preferences';
  String get appearance => _isKhmer ? 'រូបរាង' : 'Appearance';
  String get customizeChatLook =>
      _isKhmer ? 'ប្ដូររូបរាងការជជែក' : 'Customize chat look';
  String get activeSessions =>
      _isKhmer ? 'សម័យកំពុងប្រើ' : 'Active Sessions';
  String get manageDevices => _isKhmer ? 'គ្រប់គ្រងឧបករណ៍' : 'Manage devices';
  String get logoutAllDevices =>
      _isKhmer ? 'ចាកចេញពីគ្រប់ឧបករណ៍' : 'Logout All Devices';
  String get endEveryActiveSession =>
      _isKhmer ? 'បញ្ចប់សម័យទាំងអស់' : 'End every active session';
  String get clearLocalData =>
      _isKhmer ? 'សម្អាតទិន្នន័យក្នុងម៉ាស៊ីន' : 'Clear Local Data';
  String get resetBookmarksAndSettings =>
      _isKhmer ? 'កំណត់ចំណាំ និងការកំណត់ឡើងវិញ' : 'Reset bookmarks & settings';
  String get profilePictureUpdated =>
      _isKhmer ? 'បានធ្វើបច្ចុប្បន្នភាពរូបភាពប្រវត្តិរូប' : 'Profile picture updated';
  String get savedLocallyUploadFailed =>
      _isKhmer ? 'បានរក្សាទុកក្នុងម៉ាស៊ីន (បង្ហោះបរាជ័យ)' : 'Saved locally (upload failed)';
  String failedToPickImage(String error) =>
      _isKhmer ? 'មិនអាចជ្រើសរូបភាពបាន: $error' : 'Failed to pick image: $error';
  String get enterFirstName =>
      _isKhmer ? 'បញ្ចូលនាមខ្លួនរបស់អ្នក' : 'Enter your first name';
  String get enterLastName =>
      _isKhmer ? 'បញ្ចូលនាមត្រកូលរបស់អ្នក' : 'Enter your last name';
  String get save => _isKhmer ? 'រក្សាទុក' : 'Save';
  String get profileUpdated =>
      _isKhmer ? 'បានធ្វើបច្ចុប្បន្នភាពប្រវត្តិរូប' : 'Profile updated';
  String get clear => _isKhmer ? 'សម្អាត' : 'Clear';
  String get clearLocalDataWarning => _isKhmer
      ? 'វានឹងលុបចំណាំ ការសន្ទនាដែលបានភ្ជាប់ កិត្តិយស និងការកំណត់ទាំងអស់។ មិនអាចត្រឡប់វិញបានទេ។'
      : 'This will clear all bookmarks, pinned conversations, achievements, and settings. This cannot be undone.';
  String get localDataCleared =>
      _isKhmer ? 'បានសម្អាតទិន្នន័យក្នុងម៉ាស៊ីន' : 'Local data cleared';
  String get logoutFromAllDevices =>
      _isKhmer ? 'ចាកចេញពីគ្រប់ឧបករណ៍' : 'Logout From All Devices';
  String get logoutAllWarning =>
      _isKhmer ? 'វានឹងបញ្ចប់សម័យដែលកំពុងប្រើទាំងអស់ រួមទាំងឧបករណ៍នេះ។' : 'This will end all active sessions, including this device.';
  String get logoutAll => _isKhmer ? 'ចាកចេញទាំងអស់' : 'Logout All';

  String promptCategoryName(String value) {
    if (!_isKhmer) return value;
    switch (value) {
      case 'Writing':
        return 'ការសរសេរ';
      case 'Coding':
        return 'ការសរសេរកូដ';
      case 'Brainstorm':
        return 'គំនិតច្នៃប្រឌិត';
      case 'Learning':
        return 'ការរៀន';
      case 'Work':
        return 'ការងារ';
      default:
        return value;
    }
  }

  String promptTitle(String value) {
    if (!_isKhmer) return value;
    switch (value) {
      case 'Summarize Text':
        return 'សង្ខេបអត្ថបទ';
      case 'Improve Writing':
        return 'កែលម្អការសរសេរ';
      case 'Translate':
        return 'បកប្រែ';
      case 'Explain Simply':
        return 'ពន្យល់ឱ្យងាយ';
      case 'Debug Code':
        return 'ដោះកំហុសកូដ';
      case 'Explain Code':
        return 'ពន្យល់កូដ';
      case 'Write Tests':
        return 'សរសេរតេស្ត';
      case 'Optimize Code':
        return 'បង្កើនប្រសិទ្ធភាពកូដ';
      case 'Convert Language':
        return 'បម្លែងភាសា';
      case 'Generate Ideas':
        return 'បង្កើតគំនិត';
      case 'Pros and Cons':
        return 'គុណសម្បត្តិ និងគុណវិបត្តិ';
      case 'Compare Options':
        return 'ប្រៀបធៀបជម្រើស';
      case 'Problem Solve':
        return 'ដោះស្រាយបញ្ហា';
      case 'Teach Topic':
        return 'បង្រៀនប្រធានបទ';
      case 'Quiz Me':
        return 'សាកសំណួរ';
      case 'Study Plan':
        return 'ផែនការសិក្សា';
      case 'Key Concepts':
        return 'គំនិតសំខាន់ៗ';
      case 'Write Email':
        return 'សរសេរអ៊ីមែល';
      case 'Meeting Agenda':
        return 'របៀបវារៈកិច្ចប្រជុំ';
      case 'Project Plan':
        return 'ផែនការគម្រោង';
      case 'Cover Letter':
        return 'លិខិតស្នើសុំការងារ';
      default:
        return value;
    }
  }

  String promptDescription(String value) {
    if (!_isKhmer) return value;
    switch (value) {
      case 'Get a concise summary':
        return 'ទទួលបានសេចក្តីសង្ខេបខ្លីច្បាស់';
      case 'Enhance grammar and style':
        return 'កែលម្អវេយ្យាករណ៍ និងរចនាប័ទ្ម';
      case 'Translate to another language':
        return 'បកប្រែទៅភាសាផ្សេង';
      case "Explain like I'm 5":
        return 'ពន្យល់ឱ្យងាយៗដូចក្មេង';
      case 'Find and fix bugs':
        return 'រក និងជួសជុលកំហុស';
      case 'Understand code logic':
        return 'យល់អំពីតក្កកូដ';
      case 'Generate unit tests':
        return 'បង្កើតតេស្តឯកតា';
      case 'Improve performance':
        return 'បង្កើនល្បឿន និងប្រសិទ្ធភាព';
      case 'Get creative suggestions':
        return 'ទទួលបានយោបល់ច្នៃប្រឌិត';
      case 'Analyze advantages and disadvantages':
        return 'វិភាគគុណសម្បត្តិ និងគុណវិបត្តិ';
      case 'Compare different choices':
        return 'ប្រៀបធៀបជម្រើសផ្សេងៗ';
      case 'Find solutions step by step':
        return 'រកដំណោះស្រាយជាជំហានៗ';
      case 'Learn something new':
        return 'រៀនអ្វីថ្មី';
      case 'Test your knowledge':
        return 'សាកល្បងចំណេះដឹងរបស់អ្នក';
      case 'Create a learning schedule':
        return 'បង្កើតកាលវិភាគសិក្សា';
      case 'Extract main ideas':
        return 'ដកស្រង់គំនិតសំខាន់ៗ';
      case 'Draft professional emails':
        return 'រៀបរាប់អ៊ីមែលវិជ្ជាជីវៈ';
      case 'Create meeting structure':
        return 'បង្កើតរចនាសម្ព័ន្ធកិច្ចប្រជុំ';
      case 'Outline project steps':
        return 'រៀបរាប់ជំហានគម្រោង';
      case 'Write job applications':
        return 'សរសេរឯកសារដាក់ពាក្យការងារ';
      default:
        return value;
    }
  }
}

extension AppTextX on BuildContext {
  AppText get t => AppText.of(this);
}
