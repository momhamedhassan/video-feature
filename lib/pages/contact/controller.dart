import '../../common/apis/apis.dart';
import '../../common/entities/contact.dart';
import '../../common/store/store.dart';
import 'state.dart';
import '../frame/welcome/state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../common/routes/names.dart';
import '../../common/entities/msg.dart';

class ContactController extends GetxController {
  ContactController();

  final title = "chatty .";
  final State = ContactState();
  final token = UserStore.to.profile.token;
  final db = FirebaseFirestore.instance;

  @override
  void onReady() {
    super.onReady();
    EasyLoading.init();
    asyncLoadAllData();
  }

  Future<void> goChat(ContactItem contactItem) async {
    var from_messages = await db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: token)
        .where("to_token", isEqualTo: contactItem.token)
        .get();
    print("...from_messages ${from_messages.docs.isNotEmpty}");

    var to_messages = await db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: contactItem.token)
        .where("to_token", isEqualTo: token)
        .get();

    print("...to_messages ${to_messages.docs.isNotEmpty}");
//first time chatting
    if (from_messages.docs.isEmpty && to_messages.docs.isEmpty) {
      var profile = UserStore.to.profile;
      var msgData = Msg(
          from_token: profile.token,
          to_token: contactItem.token,
          from_name: profile.name,
          to_name: contactItem.name,
          to_avatar: contactItem.avatar,
          from_avatar: profile.avatar,
          from_online: profile.online,
          to_online: contactItem.online,
          last_msg: "",
          last_time: Timestamp.now(),
          msg_num: 0);

      var doc_id = await db
          .collection("message")
          .withConverter(
              fromFirestore: Msg.fromFirestore,
              toFirestore: (Msg msg, options) => msg.toFirestore())
          .add(msgData);

      Get.offAllNamed("/chat", parameters: {
        "doc_id": doc_id.id,
        "to_token": contactItem.token ?? "",
        "to_name": contactItem.name ?? "",
        "to_avatar": contactItem.avatar ?? "",
        "to_online": contactItem.online.toString()
      });
    } else {
      if (from_messages.docs.isNotEmpty) {
        Get.toNamed("/chat", parameters: {
          "doc_id": from_messages.docs.first.id,
          "to_token": contactItem.token ?? "",
          "to_name": contactItem.name ?? "",
          "to_avatar": contactItem.avatar ?? "",
          "to_online": contactItem.online.toString()
        });
      }
      if (to_messages.docs.isNotEmpty) {
        Get.toNamed("/chat", parameters: {
          "doc_id": to_messages.docs.first.id,
          "to_token": contactItem.token ?? "",
          "to_name": contactItem.name ?? "",
          "to_avatar": contactItem.avatar ?? "",
          "to_online": contactItem.online.toString()
        });
      }
    }
  }

  asyncLoadAllData() async {
    EasyLoading.show(
        indicator: const CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    State.contactList.clear();
    var result = await ContactAPI.post_contact();
    if (kDebugMode) {
      print(result.data!);
      print("... Test from asyncLoadData ...");
    }
    if (result.code == 0) {
      State.contactList.addAll(result.data!);
    }
    EasyLoading.dismiss();
  }
}