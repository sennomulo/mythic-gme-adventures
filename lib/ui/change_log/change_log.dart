import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLogVersion {
  final String version;
  final List<String> entries;

  const ChangeLogVersion(this.version, this.entries);
}

class ChangeLogService extends GetxService {
  static const _versionKey = 'changeLogVersion';

  static const keys = {
    _versionKey,
  };

  final SharedPreferencesWithCache _preferences;

  ChangeLogService(this._preferences);

  List<ChangeLogVersion> getVersions() {
    final versions = <ChangeLogVersion>[];

    final lastViewedVersion = _preferences.getString(_versionKey);

    if (lastViewedVersion != null) {
      final _Platform platform;
      if (GetPlatform.isWeb) {
        platform = _Platform.web;
      } else if (GetPlatform.isAndroid) {
        platform = _Platform.android;
      } else {
        platform = _Platform.windows;
      }

      for (final version in _versions) {
        if (version.version == lastViewedVersion) {
          break;
        } else {
          final entries = version.entries
              .where(
                (e) => e.platform == _Platform.all || e.platform == platform,
              )
              .map((e) {
                if (e.platform == _Platform.all) {
                  return e.text;
                } else {
                  return '[${platform.name.capitalize}] ${e.text}';
                }
              })
              .toList();
          if (entries.isNotEmpty) {
            versions.add(ChangeLogVersion(version.version, entries));
          }
        }
      }
    }

    return versions;
  }

  void markRead() {
    _preferences.setString(_versionKey, _versions[0].version);
  }
}

enum _Platform {
  all,
  windows,
  android,
  web,
}

class _Entry {
  final _Platform platform;
  final String text;

  const _Entry(this.platform, this.text);
}

class _Version {
  final String version;
  final List<_Entry> entries;

  const _Version(this.version, this.entries);
}

// add the new version before the previous versions
const _versions = [
  _Version('1.17.0', [
    _Entry(
      _Platform.all,
      '意义表新增西班牙语支持。',
    ),
  ]),
  _Version('1.16.0', [
    _Entry(
      _Platform.all,
      '新增选项：可在命运图表中显示“实体骰模式”开关，便于快速访问。'
      '可在全局设置中开启。',
    ),
    _Entry(
      _Platform.all,
      '修复：使用中文意义表时掷特征结果为空的问题。',
    ),
  ]),
  _Version('1.15.1', [
    _Entry(
      _Platform.all,
      '修复：多余意义表的错误。',
    ),
  ]),
  _Version('1.15.0', [
    _Entry(
      _Platform.all,
      '意义表新增中文支持（由 sennomulo 提供）。',
    ),
  ]),
  _Version('1.14.0', [
    _Entry(
      _Platform.android,
      '新增：支持从 zip 文件导入自定义意义表。',
    ),
    _Entry(
      _Platform.windows,
      '新增：支持从 zip 文件导入自定义意义表。',
    ),
  ]),
  _Version('1.13.1', [
    _Entry(
      _Platform.android,
      '修复：应用程序无法加载的问题。给你带来不便，深表歉意。',
    ),
  ]),
  _Version('1.13.0', [
    _Entry(
      _Platform.all,
      '意义表新增葡萄牙语支持。'
      '该版本使用 Retropunk 的翻译，其表格条目顺序与英文版不同，'
      '因此切换到葡萄牙语时，掷骰记录中的既有条目会显示错误。',
    ),
  ]),
  _Version('1.12.0', [
    _Entry(_Platform.all, '笔记新增全屏编辑模式。'),
    _Entry(
      _Platform.all,
      '新增“战斗判定”开关：使用 Mythic 叙事战斗规则时，将命运问题的混乱因子强制为 5。'
      '可在全局设置中开启。',
    ),
    _Entry(
      _Platform.all,
      '提升使用 Google Drive 中的自定义意义表时冒险的加载速度。',
    ),
    _Entry(_Platform.all, '在富文本编辑器中禁用富文本粘贴。'),
  ]),
  _Version('1.11.0', [
    _Entry(_Platform.all, '补充了部分缺失的意义表。'),
  ]),
  _Version('1.10.0', [
    _Entry(
      _Platform.all,
      '支持单独备份各个冒险，便于手动同步。'
      '可在冒险菜单中使用。',
    ),
  ]),
  _Version('1.9.2', [
    _Entry(
      _Platform.web,
      '修复：掷骰记录未能正确保存，导致其他平台上出现“未知”条目。'
      '遗憾的是，之前的掷骰记录将会丢失。'
      '给你带来不便，深表歉意。',
    ),
    _Entry(
      _Platform.all,
      '修复：载入冒险时，以线索为焦点的随机事件在掷骰记录中被误判为“当前情境”。',
    ),
  ]),
  _Version('1.9.1', [
    _Entry(
      _Platform.all,
      '恢复笔记富文本编辑器的默认行高。',
    ),
    _Entry(
      _Platform.all,
      '场景的全屏编辑更易访问。',
    ),
  ]),
  _Version('1.9.0', [
    _Entry(
      _Platform.all,
      '为场景、笔记等中的笔记新增文本格式选项。',
    ),
    _Entry(_Platform.all, '支持清空掷骰记录。'),
  ]),
  _Version('1.8.1', []),
  _Version('1.8.0', [
    _Entry(
      _Platform.all,
      '新增帮助系统，提供部分 Mythic 规则摘要。'
      '可在全局设置中关闭帮助按钮。',
    ),
    _Entry(
      _Platform.all,
      '修复：命运答案用词错误（“Extreme”应为“Exceptional”）。',
    ),
    _Entry(
      _Platform.all,
      '将角色/线索列表的计数上限锁定为 3（遵循规则建议）。'
      '可在全局设置中切换。',
    ),
  ]),
  _Version('1.7.0', [
    _Entry(
      _Platform.all,
      '为列表和线索进度跟踪器添加动画。',
    ),
    _Entry(_Platform.all, '支持对部分列表排序。'),
    _Entry(_Platform.all, '标题和表头使用更易读的字体。'),
  ]),
  _Version('1.6.1', [
    _Entry(_Platform.all, '修复：混乱因子不可用的问题。抱歉。'),
    _Entry(_Platform.all, '处理数据格式升级，防止数据丢失。'),
  ]),
  _Version('1.6.0', [
    _Entry(
      _Platform.all,
      '新增预设冒险支持，包含冒险特征和适配的事件焦点表。'
      '可在冒险设置中切换。',
    ),
  ]),
  _Version('1.5.0', [
    _Entry(
      _Platform.all,
      '应用的网页版已上线：https://mythic-gme-adventures.idispatch.ovh。'
      '详见用户手册。',
    ),
    _Entry(
      _Platform.all,
      '如果你错过了上一版本：新增实体骰模式。'
      '切换到此模式后，你可以自己掷骰并在应用中查找结果。'
      '可在冒险菜单中切换。',
    ),
    _Entry(_Platform.all, '支持备份本地冒险。'),
    _Entry(
      _Platform.windows,
      '或许修复了 Windows 10 上关闭应用时的崩溃。',
    ),
  ]),
];
