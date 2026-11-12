import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/inline_link.dart';
import '../../storages/data_storage.dart';
import '../preferences/preferences.dart';
import '../rules_help/rules_help_button.dart';
import '../rules_help/rules_help_view.dart';
import '../styles.dart';
import '../widgets/actions_menu.dart';
import '../widgets/progress_indicators.dart';
import 'adventure.dart';
import 'adventure_info_controller.dart';

class AdventureInfoView extends GetView<AdventureInfoController> {
  final bool dense;

  const AdventureInfoView({this.dense = false, super.key});

  @override
  Widget build(BuildContext context) {
    final adventure = Get.find<AdventureService>();
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Row(
            children: [
              // name
              Expanded(
                child: Text(
                  adventure.name().toUpperCase(),
                  style: dense
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium,
                  overflow: dense ? TextOverflow.fade : TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // save error
              if (controller.hasError() && !controller.saving())
                IconButton(
                  onPressed: _showError,
                  icon: const Icon(Icons.save_outlined),
                  color: theme.colorScheme.error,
                ),

              // saving indicator
              if (controller.saving())
                const StackedProgressIndicator(
                  child: Icon(Icons.save_outlined),
                ),

              // actions button
              _AdventureActionsButton(withSaveDate: dense),
            ],
          ),
        ),

        // save date
        if (!dense)
          Obx(
            () {
              final saveDate = controller.saveDate();

              return saveDate != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        saveDate,
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.right,
                      ),
                    )
                  : const SizedBox();
            },
          ),
      ],
    );
  }

  Future<void> _showError() async {
    String details;
    final error = controller.error;
    if (error is LocalStorageException) {
      details = '本地保存文件 "${error.filePath}" 时失败：${error.error}';
    } else if (error is RemoteStorageException) {
      details = '在线上保存文件 "${error.filePath}" 时失败：';
      if (error is RemoteStorageAuthenticationException) {
        details +=
            '身份验证已失效。\n'
            '请返回冒险列表并检查你的线上访问。';
      } else if (error is RemoteStorageNetworkException) {
        details +=
            '无法连接到 ${error.provider}。\n'
            '请检查你的网络连接。';
      } else if (error is RemoteStorageOperationException) {
        details +=
            '${error.provider} 拒绝保存该文件：'
            ' ${error.error}。';
      }
    } else {
      details = '发生意外错误：$error。';
    }

    await Dialogs.showAlert(
      title: '保存失败',
      message: '保存冒险失败。\n\n$details',
    );
  }
}

class _AdventureActionsButton extends GetView<AdventureInfoController> {
  final bool withSaveDate;

  const _AdventureActionsButton({this.withSaveDate = false});

  @override
  Widget build(BuildContext context) {
    Widget actionButtons(String? saveDate) {
      final theme = Theme.of(context);

      return ActionsMenu([
        // save date
        if (saveDate != null)
          MenuItemButton(
            onPressed: null,
            style: TextButton.styleFrom(
              textStyle: theme.textTheme.labelMedium,
            ),
            child: Text(saveDate),
          ),

        // change adventure
        MenuItemButton(
          onPressed: () => controller.showIndex(context),
          leadingIcon: const Icon(Icons.arrow_back),
          child: const Text('切换冒险'),
        ),

        // adventure settings
        MenuItemButton(
          onPressed: controller.showAdventureSettings,
          leadingIcon: const Icon(Icons.settings_outlined),
          child: const Text('冒险设置'),
        ),

        // global settings
        MenuItemButton(
          onPressed: controller.showGlobalSettings,
          leadingIcon: const Icon(Icons.settings_outlined),
          child: const Text('全局设置'),
        ),

        // physical dice mode
        Obx(() {
          final isPhysicalDiceModeEnabled = getPhysicalDiceModeEnabled;

          return MenuItemButton(
            onPressed: controller.togglePhysicalDiceMode,
            leadingIcon: Stack(
              children: [
                AppStyles.rollIcon,
                if (isPhysicalDiceModeEnabled) const Icon(Icons.clear),
              ],
            ),
            child: Text(
              '${isPhysicalDiceModeEnabled ? 'Disable' : 'Enable'} 实体骰模式',
            ),
          );
        }),

        // save
        MenuItemButton(
          onPressed: controller.save,
          leadingIcon: const Icon(Icons.save_outlined),
          child: const Text('保存'),
        ),

        // backup
        MenuItemButton(
          onPressed: controller.backup,
          leadingIcon: const Icon(Icons.save_alt_outlined),
          child: const Text('备份'),
        ),

        // export
        MenuItemButton(
          onPressed: controller.exportAsText,
          leadingIcon: const Icon(Icons.archive_outlined),
          child: const Text('导出为文本'),
        ),

        // rules help
        const MenuItemButton(
          onPressed: showRulesHelp,
          leadingIcon: Icon(Icons.help_outline),
          child: Text(RulesHelpView.title),
        ),

        // about
        MenuItemButton(
          onPressed: () async {
            final info = await PackageInfo.fromPlatform();

            if (context.mounted) {
              showAboutDialog(
                applicationName:
                    'Mythic GME Adventures', // info.appName is wrong for web (retrieved from generated version.json, where it is wrong)
                applicationVersion: info.version,
                context: context,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text:
                                    '使用《Mythic Game Master Emulator, 2nd Edition》规则管理冒险。\n'
                                    '了解更多请访问',
                              ),
                              getInlineLink(
                                text: '官方网站',
                                url:
                                    'https://idispatch75.github.io/mythic-gme-adventures/',
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            '本作品基于 Tana Pigeon 所著的 Mythic Game Master Emulator, 2nd Edition，'
                            '由 Word Mill Games 出版，依据以下许可授权使用：'
                            '知识共享 署名-非商业性使用 4.0 国际 (CC BY-NC 4.0) 许可协议。'
                            '详情请访问 www.wordmillgames.com。'
                            '\n'
                            '\nThe Portuguese translations are based on the work of Retropunk.'
                            ' Find out more at retropunk.com.br.'
                            '\n'
                            '\nThe Chinese translations are provided by sennomulo.'
                            '\n'
                            '\nThe App icon was created by Muhammad Miftakhul Rizky'
                            ' from thenounproject.com (CC BY 3.0).',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
          leadingIcon: const Icon(Icons.info_outline),
          child: const Text('关于'),
        ),
      ]);
    }

    return withSaveDate
        ? Obx(() => actionButtons(controller.saveDate()))
        : actionButtons(null);
  }
}
