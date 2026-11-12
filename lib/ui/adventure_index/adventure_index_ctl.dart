import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../helpers/datetime_extensions.dart';
import '../../helpers/dialogs.dart';
import '../../helpers/json_utils.dart';
import '../../helpers/utils.dart';
import '../../persisters/adventure_persister.dart';
import '../../persisters/global_settings_persister.dart';
import '../../persisters/meaning_tables_persister.dart';
import '../../persisters/persister.dart';
import '../../storages/data_storage.dart';
import '../../storages/google_auth_service.dart';
import '../../storages/local_storage.dart';
import '../adventure/adventure.dart';
import '../adventure/adventure_view.dart';
import '../global_settings/global_settings.dart';
import '../meaning_tables/meaning_table.dart';
import '../preferences/preferences.dart';
import '../preferences/preferences_edit_view.dart';
import 'adventure_index.dart';

class IndexAdventureVM {
  final IndexAdventure source;
  final String saveDateText;

  const IndexAdventureVM(this.source, this.saveDateText);
}

class AdventureIndexController extends GetxController {
  final status = RxStatus.loading().obs;

  final isMeaningTableUploading = false.obs;
  final isMeaningTableDownloading = false.obs;
  final meaningTableTransferProgress = 0.obs;

  final isSynchronizing = false.obs;

  List<IndexAdventureVM> adventures = [];

  @override
  Future<void> onInit() async {
    super.onInit();

    await _loadAdventures();
  }

  Future<void> reload() {
    return _loadAdventures();
  }

  Future<void> enableGoogleStorage(bool value) async {
    Get.find<LocalPreferencesService>().enableGoogleStorage(value);
    Get.find<MeaningTablesPersisterService>().needsLoading = true;

    await _loadAdventures();
  }

  Future<void> disableLocalStorage(bool value) async {
    Get.find<LocalPreferencesService>().enableLocalStorage(!value);
    Get.find<MeaningTablesPersisterService>().needsLoading = true;

    await _loadAdventures();
  }

  Future<void> googleSignOut() async {
    await Get.find<GoogleAuthService>().authManager.signOut();

    await enableGoogleStorage(false);
  }

  Future<void> showPreferences() async {
    final result = await Get.dialog<PreferencesEditResult>(
      const PreferencesEditView(),
      barrierDismissible: false,
    );

    if (result != null && result.dataDirectoryChanged) {
      await reload();
    }
  }

  Future<void> showAdventure(
    BuildContext context,
    IndexAdventureVM adventure,
  ) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AdventureView(adventure.source.id),
      ),
    );
  }

  Future<void> addAdventure(AdventureService adventure) async {
    status.value = RxStatus.loading();

    try {
      await Get.find<AdventurePersisterService>().saveNewAdventure(adventure);
    } catch (e) {
      handleError('save', e);

      return;
    }

    await _loadAdventures();
  }

  Future<void> deleteAdventure(IndexAdventureVM adventure) async {
    if (await Dialogs.showConfirmation(
      title: '删除冒险？',
      message:
          '冒险“${adventure.source.name}”将被永久删除。',
    )) {
      status.value = RxStatus.loading();

      try {
        await Get.find<AdventurePersisterService>().deleteAdventure(
          adventure.source.id,
        );
      } catch (e) {
        handleError('delete', e);

        return;
      }

      await _loadAdventures();
    }
  }

  Future<void> synchronizeAdventures() async {
    if (await Dialogs.showConfirmation(
      title: '同步存储？',
      message:
          '这将更新本地与线上存储'
          '（含最新的冒险版本）。',
    )) {
      try {
        isSynchronizing.value = true;

        await Get.find<AdventurePersisterService>().synchronizeAdventures();
      } catch (e) {
        handleError('sync', e);

        return;
      } finally {
        isSynchronizing.value = false;
      }

      await _loadAdventures();
    }
  }

  Future<void> restoreAdventure(
    JsonObj json,
    IndexAdventureVM adventure,
  ) async {
    if (!await Dialogs.showConfirmation(
      title: '恢复冒险？',
      message:
          '这将替换当前冒险的全部内容'
          '为所选文件的内容。',
    )) {
      return;
    }

    // ask confirmation if the adventure IDs do not match
    try {
      final adventureId = json['id'] as int?;
      if (adventureId == null) {
        throw Exception('无效的冒险文件');
      }

      if (adventureId != adventure.source.id) {
        if (!await Dialogs.showConfirmation(
          title: '冒险不匹配',
          message:
              '所选文件与当前冒险不匹配。'
              '如果恢复到新建的冒险中，这可能属于正常现象。\n'
              '是否继续？',
        )) {
          return;
        }
      }
    } catch (e) {
      await Dialogs.showAlert(
        title: '无效的冒险',
        message: '所选文件不包含有效的冒险数据。',
      );
    }

    // restore
    try {
      status.value = RxStatus.loading();

      await Get.find<AdventurePersisterService>().restoreAdventure(
        json,
        adventure.source.id,
      );
    } catch (e) {
      handleError('save', e);
    } finally {
      status.value = RxStatus.success();
    }

    await _loadAdventures();
  }

  Future<void> backupLocalAdventures() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: '备份本地冒险？',
      message:
          '这将创建一个包含所有冒险的 zip 文件'
          '（本地存储中）。\n'
          '之后需要时可以从该文件中挑选冒险进行恢复。',
    )) {
      return;
    }

    // create the archive
    final archive = Archive();

    final storage = LocalStorage();
    await storage.loadJsonFiles(
      [AdventurePersister.directory],
      (filePath, jsonContent) {
        if (filePath.length == 1) {
          // we store only the files at the root

          // use .string() constructor when fixed
          // https://github.com/brendan-duncan/archive/issues/354
          final content = utf8.encode(jsonContent);
          archive.addFile(ArchiveFile(filePath[0], content.length, content));
        }

        return Future.value();
      },
    );

    final zipContent = ZipEncoder().encode(
      archive,
      level: DeflateLevel.bestCompression,
    );

    // save the archive
    return saveBinaryFile(
      Uint8List.fromList(zipContent),
      fileName:
          'Mythic_GME_Adventures-backup-${DateFormat('y-MM-dd_HH-mm').format(DateTime.now())}.zip',
      dialogTitle: '冒险备份',
    );
  }

  Future<void> importLocalCustomMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: '导入自定义意义表？',
      message:
          '这将删除自定义意义表'
          '，然后导入所选文件。\n\n'
          '可能需要重启应用程序才能使更改生效。',
      userManualAnchor: 'custom-meaning-tables',
    )) {
      return;
    }

    // pick a zip file
    final zipContent = await pickFileAsBytes(
      dialogTitle: '意义表 Zip 文件',
      extension: 'zip',
    );
    if (zipContent == null) {
      return;
    }

    // import the tables
    try {
      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importZipToLocal(zipContent);

      await Dialogs.showAlert(
        title: '导入成功',
        message:
            '自定义意义表已导入到本地存储。',
      );
    } catch (e) {
      handleError('import', e);
    }
  }

  Future<void> deleteLocalCustomMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: '删除自定义意义表？',
      message:
          '这将永久删除自定义意义表'
          '（本地存储中）。\n\n'
          '可能需要重启应用程序才能使更改生效。',
    )) {
      return;
    }

    // delete
    try {
      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.deleteLocal();

      await Dialogs.showAlert(
        title: '删除成功',
        message:
            '本地存储中的自定义意义表已被删除。',
      );
    } catch (e) {
      handleError('_delete_meaning_tables', e);
    }
  }

  Future<void> downloadMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: '下载自定义意义表？',
      message:
          '这将删除自定义意义表'
          '，然后从线上存储下载意义表。\n'
          '可能需要重启应用程序才能使更改生效。\n\n'
          '注意：应用只能看到由本应用上传的文件。\n'
          '必须先上传意义表，才能下载它们。'
          '如果你通过 Google Drive 网页版手动放入文件，应用将不会下载任何内容。',
      userManualAnchor: 'online-storage',
    )) {
      return;
    }

    // download to local storage
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableDownloading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importFromRemote(meaningTableTransferProgress);
    } catch (e) {
      handleError('download', e);
    }

    isMeaningTableDownloading.value = false;
  }

  static final DateFormat _dateFormat = DateFormat.yMMMEd()
      .addPattern("'at'")
      .add_jms();
  static final DateFormat _timeFormat = DateFormat.jms();

  Future<void> _loadAdventures() async {
    status.value = RxStatus.loading();

    try {
      await Get.find<GlobalSettingsPersisterService>().loadSettings();
      await Get.find<AdventurePersisterService>().loadIndex();
      Get.find<MeaningTablesService>().language.value =
          Get.find<GlobalSettingsService>().meaningTablesLanguage;
    } on UnsupportedSchemaVersionException catch (e) {
      handleUnsupportedSchemaVersion(e).ignore();

      return;
    } catch (e) {
      handleError('load', e);

      return;
    }

    final preferences = Get.find<LocalPreferencesService>();
    final hasBothStorages =
        preferences.enableGoogleStorage() && preferences.enableLocalStorage();

    final maxInt = double.maxFinite.toInt(); // works for web and io
    adventures = Get.find<AdventureIndexService>().adventures
        .where((e) => !e.isDeleted)
        .sorted(
          (a, b) => (b.saveTimestamp ?? maxInt) - (a.saveTimestamp ?? maxInt),
        )
        .map((adventure) {
          // compute the save date text
          String saveDateText;
          if (adventure.saveTimestamp != null) {
            final saveDate = DateTime.fromMillisecondsSinceEpoch(
              adventure.saveTimestamp!,
            );
            final now = DateTime.now();
            final yesterday = DateTime.now().subtract(const Duration(days: 1));
            if (now.isSameDay(saveDate)) {
              saveDateText = '今天 ${_timeFormat.format(saveDate)}';
            } else if (yesterday.day == saveDate.day &&
                yesterday.month == saveDate.month &&
                yesterday.year == saveDate.year) {
              saveDateText = '昨天 ${_timeFormat.format(saveDate)}';
            } else {
              saveDateText = _dateFormat.format(saveDate);
            }

            String saveDateSource;
            if (!hasBothStorages ||
                adventure.localSaveTimestamp == adventure.remoteSaveTimestamp) {
              saveDateSource = '';
            } else if (adventure.localSaveTimestamp >
                adventure.remoteSaveTimestamp) {
              saveDateSource = '本地';
            } else {
              saveDateSource = '线上';
            }

            saveDateText = '保存于 $saveDateSource$saveDateText';
          } else {
            saveDateText = '尚未保存';
          }

          return IndexAdventureVM(adventure, saveDateText);
        })
        .toList();

    status.value = adventures.isEmpty ? RxStatus.empty() : RxStatus.success();
  }

  void handleError(String action, Object error) {
    final actionLabel = switch (action) {
      'save' => '保存',
      'delete' => '删除',
      'sync' => '同步',
      'import' => '导入',
      'download' => '下载',
      'load' => '载入',
      'upload' => '上传',
      _ => action,
    };

    String message;
    if (error is LocalStorageNotSupportedException) {
      message =
          '你的浏览器不支持本地存储。\n\n'
          '你必须开启“使用 Google Drive”并勾选“禁用本地存储”。';
    } else if (error is LocalStorageException) {
      message =
          '本地${actionLabel}文件 "${error.filePath}" 时失败：${error.error}。\n\n';
      switch (action) {
        case 'load':
          message +=
              '如果线上有最新存档，'
              '你可以删除本地文件，'
              '或者禁用本地存储。';
          break;

        case 'save':
          message +=
              '请检查保存目录的访问权限，'
              '或者，如果能在线上保存，'
              '你可以禁用本地存储。';
          break;

        case 'delete':
          message +=
              '请检查保存目录的访问权限，'
              '或者手动删除该文件。';
          break;

        case 'upload':
          message += '请确认文件可以读取。';

        case 'download':
          message += '请检查下载目录的访问权限。';
          break;
      }
    } else if (error is RemoteStorageException) {
      final actionText = switch (action) {
        'save' => '无法将文件 "${error.filePath}" 保存到 ${error.provider}',
        'delete' => '无法从 ${error.provider} 删除文件 "${error.filePath}"',
        'load' => '无法从 ${error.provider} 载入文件 "${error.filePath}"',
        'upload' => '无法将文件 "${error.filePath}" 上传到 ${error.provider}',
        'download' => '无法从 ${error.provider} 下载文件 "${error.filePath}"',
        _ => '无法在 ${error.provider} 上操作文件 "${error.filePath}"',
      };

      message = '$actionText。\n\n';

      if (error is RemoteStorageAuthenticationException) {
        message +=
            '身份验证已失效。\n'
            '请重新授权 ${error.provider} 以进行静默登录，'
            '或退出登录后重新启用 ${error.provider}。';
      } else if (error is RemoteStorageNetworkException) {
        message +=
            '无法连接到 ${error.provider}。\n'
            '请检查你的网络连接。';
      } else if (error is RemoteStorageOperationException) {
        message +=
            '${error.provider} 拒绝执行该操作：'
            ' ${error.error}。';
      }
    } else {
      message =
          '${actionLabel}数据失败。\n\n'
          '发生意外错误：$error。';
    }

    if (action == 'load') {
      status.value = RxStatus.error(message);
    } else {
      Dialogs.showAlert(title: '${actionLabel}失败', message: message);

      status.value = RxStatus.success();
    }
  }
}
