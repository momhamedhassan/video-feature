import 'package:chatty/common/widgets/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../common/entities/msg.dart';
import '../../../common/entities/msgcontent.dart';
import '../../../common/store/user.dart';
import 'state.dart';
import 'package:get/get.dart';

import '../../../common/routes/names.dart';

class ChatController extends GetxController {
  ChatController();
  final State = ChatState();
  late String doc_id;
  final myInputController = TextEditingController();
  // get the user or sender token
  final token = UserStore.to.profile.token;
  final db = FirebaseFirestore.instance;
  var listener;

  void gomore() {
    State.more_status.value = State.more_status.value ? false : true;
  }

  void audioCall() {
    State.more_status.value = false;
    Get.toNamed(AppRoutes.VoiceCall, parameters: {
      "to_token": State.to_token.value,
      "to_name": State.to_name.value,
      "to_avatar": State.to_avatar.value,
      "call_role": "anchor",
      "doc_id": doc_id
    });
  }

  @override
  void onInit() {
    super.onInit();
    print("This is onInit");
    var data = Get.parameters;
    print(data);
    doc_id = data['doc_id']!;
    State.to_token.value = data['to_token'] ?? "";
    State.to_name.value = data['to_name'] ?? "";
    State.to_avatar.value = data['to_avatar'] ?? "";
    State.to_online.value = data['to_online'] ?? "1";
  }

  @override
  void onReady() {
    super.onReady();
    print("this is onready");
    State.msgcontentList.clear();
    final messages = db
        .collection("message")
        .doc(doc_id)
        .collection("msglist")
        .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msg, options) => msg.toFirestore())
        .orderBy("addtime", descending: true)
        .limit(15);
    listener = messages.snapshots().listen((event) {
      List<Msgcontent> tempMsgList = <Msgcontent>[];
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            if (change.doc.data() != null) {
              tempMsgList.add(change.doc.data()!);
              print("${change.doc.data()!}");
              print("... newly added ${myInputController.text}");
            }
            break;
          case DocumentChangeType.modified:
            break;
          case DocumentChangeType.removed:
            break;
        }

        tempMsgList.reversed.forEach((element) {
          State.msgcontentList.value.insert(0, element);
        });

        State.msgcontentList.refresh();
      }
    });
  }

  Future<void> sendMessage() async {
    // var list = await db.collection("people").add({
    //   "name": myInputController.text,
    //   "age": 35,
    //   "addtime": Timestamp.now()
    // });

    // var Mylist = await db
    //     .collection("people")
    //     .orderBy("addtime", descending: true)
    //     .snapshots();

    String sendContent = myInputController.text;
    print("...$sendContent..");
    if (sendContent.isEmpty) {
      toastInfo(msg: "content is empty");
      return;
    }
    //created an object to send to firebase
    final content = Msgcontent(
        token: token,
        content: sendContent,
        type: "text",
        addtime: Timestamp.now());

    await db
        .collection("message")
        .doc(doc_id)
        .collection("msgList")
        .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msg, options) => msg.toFirestore())
        .add(content)
        .then((DocumentReference doc) {
      print("...base id is ${doc_id}..new message doc id is ${doc.id}");
      myInputController.clear();
    });

    var messageResult = await db
        .collection("message")
        .doc(doc_id)
        .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore())
        .get();
    //to know if we have any unread message or call
    if (messageResult.data() != null) {
      var item = messageResult.data()!;
      int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
      int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
      if (item.from_token == token) {
        from_msg_num = from_msg_num + 1;
      } else {
        to_msg_num = to_msg_num + 1;
      }
      await db.collection("message").doc(doc_id).update({
        "to_msg_num": to_msg_num,
        "from_msg_num": from_msg_num,
        "last_msg": sendContent,
        "last_time": Timestamp.now()
      });
    }

    // var list = await db
    //     .collection("chat")
    //     .doc("U26bc8YBKGhHLzSrBzxI")
    //     .update({"field1": "This is a shirt", "field2": 100});
    // var list = await db.collection("chat").get();
    // print("...number of documents${list.size}");

    // var list = await db.collection("message").get();
    // var listSub =
    //     await db.collection("message").doc(doc_id).collection("msglist").get();
    // listSub.docs.forEach((element) {
    //   print(element.data()["content"]);
    // });
  }

  @override
  void onClose() {
    super.onClose();
    listener.cancel();
    myInputController.dispose();
  }
}
