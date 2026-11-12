import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../fate_chart/fate_chart.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import 'adventure.dart';

class AdventureEditView extends HookWidget {
  static final _fateChartTypeEntries = [
    const DropdownMenuEntry(value: FateChartType.standard, label: '标准'),
    const DropdownMenuEntry(value: FateChartType.mid, label: '中等'),
    const DropdownMenuEntry(value: FateChartType.low, label: '低'),
    const DropdownMenuEntry(value: FateChartType.none, label: '无'),
  ];

  final AdventureService _adventure;

  const AdventureEditView(this._adventure, {super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: _adventure.name());
    final chartType = _adventure.fateChartType.obs;
    final isPreparedAdventure = _adventure.isPreparedAdventure().obs;

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: '冒险',
      canDelete: false,
      onSave: () {
        _adventure.name(nameController.text);
        _adventure.fateChartType = chartType();
        _adventure.isPreparedAdventure(isPreparedAdventure());

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: '名称'),
            autofocus: _adventure.name().isEmpty,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: DropdownMenu<FateChartType>(
                requestFocusOnTap: false,
                initialSelection: chartType(),
                label: const Text('命运图表'),
                dropdownMenuEntries: _fateChartTypeEntries,
                onSelected: (value) {
                  chartType.value = value ?? FateChartType.standard;
                },
              ),
            ),
          ),
          BooleanSetting(
            setting: isPreparedAdventure,
            text: '预设冒险',
            subtext:
                '勾选后，特征列表将显示在“更多”标签页中，'
                '随机事件将使用预设冒险的事件焦点表，'
                '且变更/中断场景会被随机事件取代。',
            withTopPadding: true,
          ),
        ],
      ),
    );
  }
}
