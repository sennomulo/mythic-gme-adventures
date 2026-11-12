import 'package:flutter/material.dart';

import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';

class SceneAdjustmentLookupView extends StatelessWidget {
  const SceneAdjustmentLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    return RollLookupView(
      header: '场景调整 - 1d10',
      rollColors: AppStyles.genericColors,
      entries: const [
        RollLookupEntry(value: '1', label: '移除一个角色'),
        RollLookupEntry(value: '2', label: '增加一个角色'),
        RollLookupEntry(value: '3', label: '减弱/移除一个活动'),
        RollLookupEntry(value: '4', label: '增强一个活动'),
        RollLookupEntry(value: '5', label: '移除一个物品'),
        RollLookupEntry(value: '6', label: '增加一个物品'),
        RollLookupEntry(value: '7 - 10', label: '进行两次调整'),
      ],
    );
  }
}
