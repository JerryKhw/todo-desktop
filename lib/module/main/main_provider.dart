import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';
import 'package:todo_desktop/model/note.dart';
import 'package:todo_desktop/provider/app_provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

part 'main_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentNote extends _$CurrentNote {
  @override
  Note build() => ref.read(noteProvider);

  Future<void> toggleCheck() async {
    final tmp = state.copyWith(check: !state.check);
    await updateNote(ref, tmp);
    state = tmp;
  }

  Future<void> toggleLine() async {
    final tmp = state.copyWith(line: !state.line);
    await updateNote(ref, tmp);
    state = tmp;
  }

  Future<void> resize() async {
    final size = await WindowManagerPlus.current.getSize();
    final tmp = state.copyWith(width: size.width, height: size.height);
    await updateNote(ref, tmp);
    state = tmp;
  }

  Future<void> move() async {
    final position = await WindowManagerPlus.current.getPosition();
    final tmp = state.copyWith(
      offset: NoteOffset(x: position.dx, y: position.dy),
    );
    await updateNote(ref, tmp);
    state = tmp;
  }

  Future<void> delete() async {
    await deleteNote(ref);

    final ids = await WindowManagerPlus.getAllWindowManagerIds();

    if (ids.length > 1) {
      WindowManagerPlus.current.close();
    } else {
      WindowManagerPlus.current.destroy();
    }
  }
}

@Riverpod(keepAlive: true)
class Items extends _$Items {
  @override
  List<(NoteItem, TextEditingController, FocusNode)> build() =>
      ref
          .read(noteProvider)
          .items
          .map(
            (item) => (
              item,
              TextEditingController(text: item.text),
              FocusNode(),
            ),
          )
          .toList();

  Future<void> onChanged(int index, String value) async {
    final item = state.elementAt(index);

    final tmp = [...state];

    tmp[index] = (item.$1.copyWith(text: value), item.$2, item.$3);

    final note = ref.read(currentNoteProvider);

    await updateNote(
      ref,
      note.copyWith(items: tmp.map((item) => item.$1).toList()),
    );

    state = tmp;
  }

  Future<void> toggle(int index) async {
    final item = state.elementAt(index);
    final data = item.$1;

    final tmp = [...state];

    tmp[index] = (item.$1.copyWith(checked: !data.checked), item.$2, item.$3);

    final note = ref.read(currentNoteProvider);

    await updateNote(
      ref,
      note.copyWith(items: tmp.map((item) => item.$1).toList()),
    );

    state = tmp;
  }

  Future<void> add(BuildContext context, int index) async {
    final tmp = [...state];

    final newItem = (
      NoteItem(text: "", checked: false),
      TextEditingController(),
      FocusNode(),
    );

    final insertIndex = index + 1;
    if (insertIndex >= tmp.length) {
      tmp.add(newItem);
    } else {
      tmp.insert(insertIndex, newItem);
    }

    final note = ref.read(currentNoteProvider);

    await updateNote(
      ref,
      note.copyWith(items: tmp.map((item) => item.$1).toList()),
    );

    state = tmp;

    await Future.delayed(Duration(milliseconds: 100));
    if (!context.mounted) return;
    FocusScope.of(context).requestFocus(newItem.$3);
  }

  Future<void> delete(BuildContext context, int index) async {
    if (index == 0) {
      return;
    }

    final tmp = [...state];

    tmp.removeAt(index);

    final note = ref.read(currentNoteProvider);

    await updateNote(
      ref,
      note.copyWith(items: tmp.map((item) => item.$1).toList()),
    );

    state = tmp;

    if (index - 1 > 0) {
      final item = state.elementAt(index - 1);

      await Future.delayed(Duration(milliseconds: 100));
      if (!context.mounted) return;
      FocusScope.of(context).requestFocus(item.$3);
    }
  }
}

updateNote(Ref ref, Note value) async {
  final windowId = ref.read(windowIdProvider);
  final db = ref.read(databaseProvider);
  await db.reload();

  final store = intMapStoreFactory.store('notes');

  await store.record(windowId).put(db, value.toJson());
}

deleteNote(Ref ref) async {
  final windowId = ref.read(windowIdProvider);
  final db = ref.read(databaseProvider);
  await db.reload();

  final store = intMapStoreFactory.store('notes');

  await store.record(windowId).delete(db);
}

newNote({int? id, BuildContext? context}) async {
  final newWindow = await WindowManagerPlus.createWindow(["$id"]);

  if (newWindow == null && context != null && context.mounted) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text("Error"),
            content: Text("Failed to add note."),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text("Close"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
