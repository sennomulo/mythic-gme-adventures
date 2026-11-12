import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../chaos_factor/chaos_factor.dart';
import '../meaning_tables/meaning_table.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/sub_label.dart';
import 'global_settings.dart';

class GlobalSettingsEditController extends GetxController {
  static const _languages = {
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'es': 'Español',
    'pt': 'Português',
    'ru': 'Русский',
    'nl': 'Nederlands',
    'cs': 'Czeski',
    'pl': 'Polski',
    'zh': '中文',
  };

  final meaningTableLanguages = <String, String>{};

  @override
  void onInit() async {
    super.onInit();

    final languageCodes = Get.find<MeaningTablesService>().languageCodes;

    for (var code in languageCodes) {
      final languageName = _languages[code];
      if (languageName != null) {
        meaningTableLanguages[code] = languageName;
      } else {
        meaningTableLanguages[code] = code;
      }
    }
  }
}

class GlobalSettingsEditView extends HookWidget {
  final GlobalSettingsService _settings;

  GlobalSettingsEditView(this._settings, {super.key}) {
    Get.put(GlobalSettingsEditController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GlobalSettingsEditController>();
    final languageMenuEntries = controller.meaningTableLanguages.entries
        .map((e) => DropdownMenuEntry<String>(value: e.key, label: e.value))
        .toList();

    final allowChooseInLists = _settings.allowChooseInLists.obs;
    final allowUnlimitedListCount = _settings.allowUnlimitedListCount.obs;
    final hideHelpButtons = _settings.hideHelpButtons().obs;
    final showCombatClash = _settings.showCombatClash().obs;
    final showQuickPhysicalDiceMode = _settings.showQuickPhysicalDiceMode().obs;
    final meaningTablesLanguage = _settings.meaningTablesLanguage.obs;
    if (!controller.meaningTableLanguages.containsKey(
      meaningTablesLanguage(),
    )) {
      meaningTablesLanguage.value = 'en';
    }

    return EditDialog<bool>(
      itemTypeLabel: '全局设置',
      canDelete: false,
      onSave: () {
        _settings.allowChooseInLists = allowChooseInLists();
        _settings.allowUnlimitedListCount = allowUnlimitedListCount();
        _settings.hideHelpButtons.value = hideHelpButtons();
        _settings.showCombatClash.value = showCombatClash();
        _settings.showQuickPhysicalDiceMode.value = showQuickPhysicalDiceMode();
        if (!_settings.showCombatClash()) {
          Get.find<ChaosFactorService>().isCombatClash(false);
        }
        _settings.meaningTablesLanguage = meaningTablesLanguage();
        Get.find<MeaningTablesService>().language.value =
            _settings.meaningTablesLanguage;

        return Future.value(true);
      },
      body: Container(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // allow to roll "Choose"
            BooleanSetting(
              setting: allowChooseInLists,
              text:
                  '允许在角色和线索列表中掷出“自选”',
              subtext:
                  '若不勾选，掷骰将总是从列表中选取一个条目。',
            ),

            // allow unlimited list count
            BooleanSetting(
              withTopPadding: true,
              setting: allowUnlimitedListCount,
              text: '允许角色/线索列表中的计数不受限制',
              subtext:
                  '规则建议列表中相同条目不要超过'
                  ' ${GlobalSettingsService.maxNumberOfItemsInList} 个。'
                  '除非勾选此选项，否则将强制执行此限制。',
            ),

            // hide help buttons
            BooleanSetting(
              withTopPadding: true,
              setting: hideHelpButtons,
              text: '隐藏帮助按钮',
              subtext:
                  '隐藏应用程序中的帮助按钮。'
                  '你仍可在冒险菜单中访问帮助。',
            ),

            // show combat clash
            BooleanSetting(
              withTopPadding: true,
              setting: showCombatClash,
              text: '显示“战斗判定”开关',
              subtext:
                  '在命运图表中显示“战斗判定”开关。'
                  '启用战斗判定后，命运问题的混乱因子将强制为 5，'
                  '依据《Mythic Magazine Compilation 5》中的 Mythic 叙事战斗规则。',
            ),

            // show quick physical dice mode
            BooleanSetting(
              withTopPadding: true,
              setting: showQuickPhysicalDiceMode,
              text: '显示“实体骰模式”快速开关',
              subtext:
                  '在命运图表中显示“实体骰模式”开关，便于快速切换。',
            ),

            // meaning tables language
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => DropdownMenu<String>(
                      requestFocusOnTap: false,
                      width: 250,
                      initialSelection: meaningTablesLanguage(),
                      label: const Text('意义表语言'),
                      dropdownMenuEntries: languageMenuEntries,
                      onSelected: (value) {
                        meaningTablesLanguage.value = value ?? 'en';
                      },
                    ),
                  ),
                  const SubLabel(
                    '此设置仅作用于意义表，'
                    '而非整个应用程序。',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
