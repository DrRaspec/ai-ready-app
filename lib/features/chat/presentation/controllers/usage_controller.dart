import 'package:ai_chat_bot/features/chat/presentation/controllers/chat_controller.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/chat_state.dart';
import 'package:get/get.dart';

class UsageController extends GetxController {
  final ChatController _chatController;

  UsageController(this._chatController);

  ChatState get state => _chatController.state;
  Rx<ChatState> get rxState => _chatController.rxState;

  @override
  void onInit() {
    super.onInit();
    _chatController.loadUsage();
  }

  Future<void> reloadUsage() async {
    await _chatController.loadUsage();
  }
}
