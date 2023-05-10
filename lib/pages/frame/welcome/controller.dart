import 'state.dart';
import 'package:get/get.dart';

import '../../../common/routes/names.dart';

class WelcomeController extends GetxController {
  WelcomeController();

  final title = "chatty .";
  final State = WelcomeState();

  @override
  void onReady() {
    //navigation
    super.onReady();
    Future.delayed(
        Duration(seconds: 3), () => Get.offAllNamed(AppRoutes.Message));
  }
}
