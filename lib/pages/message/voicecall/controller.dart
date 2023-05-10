import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chatty/common/apis/apis.dart';
import 'package:chatty/common/entities/chat.dart';
import 'package:chatty/common/values/server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common/store/user.dart';
import '../../frame/welcome/state.dart';
import 'state.dart';

import 'package:get/get.dart';

import '../../../../common/routes/names.dart';

class VoiceCallController extends GetxController {
  VoiceCallController();

  final State = VoiceCallState();
  final player = AudioPlayer();
  String appId = APPID;
  final db = FirebaseFirestore.instance;
  final profile_token = UserStore.to.profile.token;
  late final RtcEngine engine;

  ChannelProfileType channelProfileType =
      ChannelProfileType.channelProfileCommunication;

  @override
  void onInit() {
    super.onInit();
    var data = Get.parameters;
    State.to_name.value = data["to_name"] ?? "";
    State.to_avatar.value = data["to_avatar"] ?? "";
    State.call_role.value = data["call_role"] ?? "";
    State.doc_id.value = data["doc_id"] ?? "";
    State.to_token.value = data['to_token'] ?? "";
    print("...your name id ${State.to_name.value}");
    initEngine();
  }

  Future<void> initEngine() async {
    await player.setAsset("assets/Sound_Horizon.mp3");
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    engine.registerEventHandler(RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) {
      print('[onError] err:$err,msg:$msg');
    }, onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
      print('onConnection ${connection.toJson()}');
      State.isJoined.value = true;
    }, onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) async {
      await player.pause();
    }, onLeaveChannel: (RtcConnection connection, RtcStats stats) {
      print('... user left the room...');
      State.isJoined.value = false;
    }, onRtcStats: (RtcConnection connection, RtcStats stats) {
      print('time...');
      print(stats.duration);
    }));

    await engine.enableAudio();

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming);
    await joinChannel();
    if (State.call_role == "anchor") {
      //send notification to the other user
      await sendNotification("voice");
      await player.play();
    }
  }

  Future<void> sendNotification(String call_type) async {
    CallRequestEntity callRequestEntity = CallRequestEntity();
    callRequestEntity.call_type = call_type;
    callRequestEntity.to_token = State.to_token.value;
    callRequestEntity.to_avatar = State.to_avatar.value;
    callRequestEntity.doc_id = State.doc_id.value;
    callRequestEntity.to_name = State.to_name.value;
    print("... the other user's token is ${State.to_token.value}");
    var res = await ChatAPI.call_notifications(params: callRequestEntity);
    if (res.code == 0) {
      print("notification success");
    } else {
      print("could not send notification");
    }
  }

  Future<String> getToken() async {
    if (State.call_role == "anchor") {
      State.channelId.value = md5
          .convert(utf8.encode("${profile_token}_${State.to_token}"))
          .toString();
    } else {
      State.channelId.value = md5
          .convert(utf8.encode("${State.to_token}_${profile_token}"))
          .toString();
    }

    CallTokenRequestEntity callTokenRequestEntity = CallTokenRequestEntity();
    callTokenRequestEntity.channel_name = State.channelId.value;
    print(".... channel id is ${State.channelId.value}");
    print("... my access token is ${UserStore.to.token}");
    var res = await ChatAPI.call_token(params: callTokenRequestEntity);
    if (res.code == 0) {
      return res.data!;
    }
    return "";
  }

  Future<void> joinChannel() async {
    await Permission.microphone.request();
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);

    String token = await getToken();
    if (token.isEmpty) {
      EasyLoading.dismiss();
      Get.back();
      return;
    }

    await engine.joinChannel(
        token: token,
        channelId: State.channelId.value,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: channelProfileType,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));
    EasyLoading.dismiss();
  }

  void leaveChannel() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    await player.pause();
    State.isJoined.value = false;
    EasyLoading.dismiss();
    Get.back();
  }

  void _dispose() async {
    await player.pause();
    await engine.leaveChannel();
    await engine.release();
    await player.stop();
  }

  @override
  void onClose() {
    _dispose();
    super.onClose();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
