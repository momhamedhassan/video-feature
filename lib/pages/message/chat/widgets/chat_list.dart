import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

import '../../../../common/values/colors.dart';
import '../controller.dart';
import 'chat_right_list.dart';

class ChatList extends GetView<ChatController> {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          color: AppColors.primaryBackground,
          padding: EdgeInsets.only(bottom: 70.h),
          child: CustomScrollView(reverse: true, slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 0.w, horizontal: 0.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  var item = controller.State.msgcontentList[index];
                  if (controller.token == item.token) {
                    return ChatRightList(item);
                  }
                }, childCount: controller.State.msgcontentList.length),
              ),
            )
          ]),
        ));
  }
}
