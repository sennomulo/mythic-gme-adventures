import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/get_extensions.dart';
import '../../helpers/list_view_utils.dart';
import '../../helpers/utils.dart';
import '../adventure/adventure.dart';
import '../chaos_factor/chaos_factor.dart';
import '../keyed_scenes/keyed_scene.dart';
import '../keyed_scenes/keyed_scenes_view.dart';
import '../layouts/layout.dart';
import '../preferences/preferences.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_log.dart';
import '../rules_help/rules_help_button.dart';
import '../rules_help/rules_help_view.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import '../widgets/header.dart';
import '../widgets/responsive_dialog.dart';
import '../widgets/round_badge.dart';
import 'scene.dart';
import 'scene_adjustment_lookup_view.dart';
import 'scene_edit_page_view.dart';
import 'scene_edit_view.dart';
import 'scene_test_lookup_view.dart';

class ScenesView extends GetView<ScenesService> {
  final bool dense;
  final bool withHelpButton;

  const ScenesView({
    this.dense = false,
    this.withHelpButton = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scenes = controller.scenes;

    Widget? keyedScenesButton;
    if (!dense) {
      keyedScenesButton = Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: OutlinedButton.icon(
          icon: Obx(() {
            Widget icon = const Icon(Icons.bolt);

            final keyedScenesController = Get.find<KeyedScenesService>();
            if (keyedScenesController.scenes.isNotEmpty) {
              icon = Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  const Positioned(
                    top: 0,
                    left: 16,
                    child: Badge(smallSize: 8),
                  ),
                ],
              );
            }

            return icon;
          }),
          onPressed: _showKeyedScenes,
          label: const Text('插入场景'),
        ),
      );
    }

    return Obx(() {
      final isPhysicalDiceModeEnabled = getPhysicalDiceModeEnabled;

      Widget buttonRow = ButtonRow(
        children: [
          // keyed scenes
          if (keyedScenesButton != null) keyedScenesButton,

          // roll adjustment
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              onPressed: isPhysicalDiceModeEnabled
                  ? () => _showAdjustmentLookup(context)
                  : _rollAdjustment,
              child: Text(dense ? '掷调整' : '掷场景调整'),
            ),
          ),

          // test scene
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              onPressed: isPhysicalDiceModeEnabled
                  ? () => _showSceneTestLookup(context)
                  : _testScene,
              child: Text(dense ? '测试场景' : '测试预期场景'),
            ),
          ),

          // add scene
          IconButton.filled(
            onPressed: _create,
            icon: const Icon(Icons.add),
            tooltip: '新建场景',
          ),
        ],
      );

      if (withHelpButton) {
        buttonRow = RulesHelpWrapper(
          helpEntry: scenesHelp,
          alignment: Alignment.centerLeft,
          child: buttonRow,
        );
      }

      return Column(
        children: [
          buttonRow,

          // list
          Expanded(
            child: Obx(
              () => defaultAnimatedListView(
                items: scenes.reversed.toList(),
                itemBuilder: (_, item, index) {
                  return _SceneView(scenes.length - index - 1, item);
                },
                removedItemBuilder: (_, item) {
                  return _SceneView(0, item, isDeleted: true);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  void _create() async {
    final scene = Scene(summary: '');

    final result = await Get.dialog<bool>(
      SceneEditView(scene, isNew: true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(scene);
    }
  }

  Future<void> _testScene() async {
    final chaosFactor = Get.find<ChaosFactorService>().chaosFactor();
    final dieRoll = roll10Die();

    if (dieRoll > chaosFactor) {
      // expected
      await Dialogs.showAlert(
        title: '预期场景',
        message: '场景如预期发生。',
      );
    } else {
      final isPreparedAdventure = Get.find<AdventureService>()
          .isPreparedAdventure();

      if (isPreparedAdventure) {
        await Dialogs.showAlert(
          title: '随机事件',
          message:
              '预期被略微改变。\n'
              '将掷出一个随机事件。',
        );

        rollRandomEvent();
      } else {
        if (dieRoll.isOdd) {
          // altered
          await Dialogs.showAlert(
            title: '变更场景',
            message:
                '预期被略微改变。\n'
                '你可以查询命运图表或意义表。\n'
                '你也可以掷一次场景调整。',
          );
        } else {
          // interrupt
          await Dialogs.showAlert(
            title: '中断场景',
            message:
                'Mythic 彻底颠覆了你的预期。\n'
                '将掷出一个随机事件。',
          );

          rollRandomEvent();
        }
      }
    }
  }

  void _showSceneTestLookup(BuildContext context) {
    const content = SceneTestLookupView();

    showAppModalBottomSheet<void>(context, content);
  }

  void _rollAdjustment() {
    void addSceneAdjustmentRoll(int dieRoll) {
      final adjustment = switch (dieRoll) {
        1 => '移除一个角色',
        2 => '增加一个角色',
        3 => '减弱/移除一个活动',
        4 => '增强一个活动',
        5 => '移除一个物品',
        6 => '增加一个物品',
        _ => '进行两次调整',
      };

      Get.find<RollLogService>().addGenericRoll(
        title: '场景调整',
        value: adjustment,
        dieRoll: dieRoll,
      );
    }

    var dieRoll = roll10Die();
    if (dieRoll >= 7) {
      dieRoll = rollDie(6);
      addSceneAdjustmentRoll(dieRoll);

      var dieRoll2 = rollDie(6);
      while (dieRoll2 == dieRoll) {
        dieRoll2 = rollDie(6);
      }
      addSceneAdjustmentRoll(dieRoll2);
    } else {
      addSceneAdjustmentRoll(dieRoll);
    }
  }

  void _showAdjustmentLookup(BuildContext context) {
    const content = SceneAdjustmentLookupView();

    showAppModalBottomSheet<void>(context, content);
  }

  void _showKeyedScenes() {
    Get.dialog<bool>(
      Dialog(
        child: ConstrainedBox(
          constraints: ResponsiveDialog.boxConstraints,
          child: Column(
            children: [
              // scenes
              const Header('插入场景'),
              const Expanded(child: KeyedScenesView()),

              // close
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton(
                  onPressed: () => Get.back<void>(),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneView extends GetView<ScenesService> {
  final int _sceneIndex;
  final Rx<Scene> _scene;
  final bool isDeleted;

  const _SceneView(this._sceneIndex, this._scene, {this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        contentPadding: AppStyles.listTileTitlePadding,
        leading: RoundBadge(
          backgroundColor: AppStyles.sceneBadgeBackground,
          color: AppStyles.sceneBadgeOnBackground,
          text: !isDeleted ? (_sceneIndex + 1).toString() : '',
        ),
        title: Text(
          _scene().summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: !isDeleted ? _edit : null,
        trailing: !isDeleted
            ? IconButton(
                onPressed: _editFullscreen,
                icon: const Icon(Icons.fullscreen),
                tooltip: '全屏编辑',
              )
            : null,
      ),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      SceneEditView(_scene(), isNew: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _scene.refresh();

      controller.requestSave();
    }
  }

  void _editFullscreen() {
    final temporaryData = Scene(
      summary: _scene.value.summary,
      notes: _scene.value.notes,
    );
    Get.replaceForced(
      SceneEditPageService(
        _scene.value,
        temporaryData: temporaryData,
        isNew: false,
      ),
    );
    Get.find<LayoutController>().hasEditScenePage.value = true;
  }
}
