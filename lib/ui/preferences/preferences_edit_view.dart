import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:io/io.dart';

import '../../helpers/inline_link.dart';
import '../../helpers/string_extensions.dart';
import '../../storages/local_storage.dart';
import '../layouts/layout.dart';
import '../styles.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/sub_label.dart';
import 'preferences.dart';

class PreferencesEditView extends HookWidget {
  const PreferencesEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<LocalPreferencesService>();

    final enableDarkMode = preferences.enableDarkMode().obs;

    final hasLocalFolder = !GetPlatform.isWeb;
    final TextEditingController localDataDirectoryController;
    final AsyncSnapshot<String> defaultLocalDataDirectory;
    final Future<PreferencesEditResult?> Function() onSave;

    void saveBrightness() {
      AppStyles.setBrightness(
        enableDarkMode() ? Brightness.dark : Brightness.light,
      );
      preferences.enableDarkMode.value = enableDarkMode();
    }

    if (hasLocalFolder) {
      localDataDirectoryController = useTextEditingController(
        text: preferences.localDataDirectoryOverride(),
      );

      final defaultLocalDataDirectoryFuture = useMemoized(
        () => LocalStorage.getDefaultRootDirectoryPath(),
      );
      defaultLocalDataDirectory = useFuture(defaultLocalDataDirectoryFuture);

      onSave = () async {
        // copy the files to the new directory?
        final currentDataDirectory = preferences.localDataDirectoryOverride();
        final newDataDirectory = localDataDirectoryController.text
            .nullIfEmpty();

        if (currentDataDirectory != newDataDirectory) {
          final doCopy = await _showConfirmationDialog(context);
          if (doCopy == null) {
            return null;
          }

          if (doCopy) {
            await copyPath(
              currentDataDirectory ?? defaultLocalDataDirectory.data!,
              newDataDirectory ?? defaultLocalDataDirectory.data!,
            );
          }
        }

        // save the settings
        preferences.localDataDirectoryOverride.value = newDataDirectory;

        saveBrightness();

        return PreferencesEditResult(currentDataDirectory != newDataDirectory);
      };
    } else {
      localDataDirectoryController = useTextEditingController();
      defaultLocalDataDirectory = const AsyncSnapshot<String>.waiting();

      onSave = () async {
        saveBrightness();

        return PreferencesEditResult(false);
      };
    }

    final theme = Theme.of(context);

    return EditDialog<PreferencesEditResult>(
      itemTypeLabel: '偏好设置',
      canDelete: false,
      onSave: onSave,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLocalFolder) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // data folder
                Expanded(
                  child: TextFormField(
                    controller: localDataDirectoryController,
                    decoration: const InputDecoration(
                      labelText: '本地数据文件夹',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    readOnly: true,
                  ),
                ),

                // choose folder
                IconButton(
                  onPressed: () async {
                    final initialDirectory =
                        localDataDirectoryController.text.nullIfEmpty() ??
                        defaultLocalDataDirectory.data;
                    final path = await FilePicker.getDirectoryPath(
                      dialogTitle: '本地数据文件夹',
                      initialDirectory: initialDirectory,
                      lockParentWindow: true,
                    );

                    if (path != null) {
                      localDataDirectoryController.text = path;
                    }
                  },
                  icon: const Icon(Icons.folder),
                ),

                // clear folder
                IconButton(
                  onPressed: () {
                    localDataDirectoryController.text = '';
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),

            // tip
            const SizedBox(height: 4),
            SubLabel(
              '留空则使用默认文件夹“${defaultLocalDataDirectory.data}”。',
            ),
            if (!GetPlatform.isWeb && GetPlatform.isDesktop)
              const SubLabel(
                '建议将本地 Google Drive、OneDrive 或 Dropbox 文件夹设置到这里，'
                '以便轻松共享、快速保存，并获得带版本历史的自动备份。\n'
                '在将 Google Drive 用作线上存储的同时，又把本地 Google Drive 文件夹设为本地数据文件夹'
                '应予避免，因为通过 Drive 应用上传的文件对本应用不可见。',
              ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '更多信息见',
                    style: SubLabel.getTextStyle(theme),
                  ),
                  getUserManualLink(
                    anchor: 'storage',
                    textStyle: SubLabel.getTextStyle(theme),
                  ),
                  TextSpan(
                    text: '.',
                    style: SubLabel.getTextStyle(theme),
                  ),
                ],
              ),
            ),
          ],

          // brightness
          BooleanSetting(
            setting: enableDarkMode,
            text: '深色模式',
            withTopPadding: true,
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) async {
    final noCopyButton = TextButton(
      child: const Text('不复制'),
      onPressed: () {
        Get.back(result: false);
      },
    );

    final copyButton = TextButton(
      child: Text(
        '复制',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      onPressed: () {
        Get.back(result: true);
      },
    );

    final cancelButton = TextButton(
      child: const Text('取消'),
      onPressed: () {
        Get.back(result: null);
      },
    );

    var actions = [cancelButton, copyButton, noCopyButton];
    if (dialogButtonDirection == TextDirection.rtl) {
      actions = actions.reversed.toList();
    }

    return Get.dialog<bool>(
      AlertDialog.adaptive(
        title: const Text('是否复制数据？'),
        content: const Text(
          '数据文件夹已更改。\n\n'
          '你可以将原文件夹中的内容复制过去'
          '复制到新文件夹并覆盖其内容。\n\n'
          '或者，你也可以仅设置文件夹并手动向其中添加内容\n'
          '（此时应当现在就完成复制，以便退出对话框时加载新内容）。',
        ),
        actions: actions,
      ),
      barrierDismissible: false,
    );
  }
}

class PreferencesEditResult {
  final bool dataDirectoryChanged;

  PreferencesEditResult(this.dataDirectoryChanged);
}
