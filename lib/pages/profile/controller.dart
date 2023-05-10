import '../../common/store/store.dart';
import '../frame/welcome/state.dart';
import 'state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../common/routes/names.dart';

class ProfileController extends GetxController {
  ProfileController();

  final title = "chatty .";
  final State = ProfileState();

  Future<void> goLogout() async {
    await GoogleSignIn().signOut();
    await UserStore.to.onLogout();
  }
}
