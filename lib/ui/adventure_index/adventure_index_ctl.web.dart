import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/utils.dart';
import '../../persisters/meaning_tables_persister.dart';
import 'adventure_index_ctl.dart';

extension AdventureIndexControllerX on AdventureIndexController {
  Future<void> uploadMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: '上传自定义意义表？',
      message:
          '这将删除自定义意义表'
          '，然后在所选文件中上传意义表。\n\n'
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

    // upload the tables
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableUploading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importZipToRemote(
        zipContent,
        meaningTableTransferProgress,
      );
    } catch (e) {
      handleError('upload', e);
    }

    isMeaningTableUploading.value = false;
  }
}
