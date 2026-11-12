import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/rich_text_editor.dart';
import 'player_character.dart';

class PlayerCharacterEditView extends HookWidget {
  final PlayerCharacter _player;
  final bool _canDelete;

  const PlayerCharacterEditView(this._player, this._canDelete, {super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: _player.name);
    final notesController = useRichTextEditorController(_player.notes);

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: '玩家角色',
      canDelete: _canDelete,
      onSave: () {
        _player.name = nameController.text;
        _player.notes = notesController.text;

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      onDelete: () {
        Get.find<PlayerCharactersService>().delete(_player);

        return Future.value();
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: '名称'),
            autofocus: _player.name.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: RichTextEditor(
              controller: notesController,
              title: '笔记',
            ),
          ),
        ],
      ),
    );
  }
}
