import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
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

  Future<void> updateItems(List<NoteItem> value) async {
    final tmp = state.copyWith(items: value);
    await updateNote(ref, tmp);
    state = tmp;
  }
}

@Riverpod(keepAlive: true)
class CurrentController extends _$CurrentController {
  @override
  QuillController build() => ref.read(itemsProvider).first.$2;

  void update(QuillController value) => state = value;
}

@Riverpod(keepAlive: true)
class DebounceTimer extends _$DebounceTimer {
  @override
  Timer? build() => null;

  void update(Timer value) {
    state?.cancel();
    state = value;
  }
}

@Riverpod(keepAlive: true)
class Items extends _$Items {
  @override
  List<(NoteItem, QuillController, FocusNode)> build() =>
      ref
          .read(noteProvider)
          .items
          .map(
            (item) => (
              item,
              QuillController(
                document: Document.fromJson(jsonDecode(item.text)),
                selection: const TextSelection.collapsed(offset: 0),
              ),
              FocusNode(),
            ),
          )
          .toList();

  Future<void> onChanged(int index, String value) async {
    ref
        .read(debounceTimerProvider.notifier)
        .update(
          Timer(const Duration(milliseconds: 200), () async {
            final item = state.elementAt(index);

            final tmp = [...state];

            tmp[index] = (item.$1.copyWith(text: value), item.$2, item.$3);

            await ref
                .read(currentNoteProvider.notifier)
                .updateItems(tmp.map((item) => item.$1).toList());

            state = tmp;
          }),
        );
  }

  Future<void> toggle(int index) async {
    final item = state.elementAt(index);
    final data = item.$1;

    final tmp = [...state];

    tmp[index] = (item.$1.copyWith(checked: !data.checked), item.$2, item.$3);

    await ref
        .read(currentNoteProvider.notifier)
        .updateItems(tmp.map((item) => item.$1).toList());

    state = tmp;
  }

  Future<void> add(BuildContext context, int index) async {
    final tmp = [...state];

    final newItem = (
      NoteItem(text: jsonEncode(Document().toDelta().toJson()), checked: false),
      QuillController.basic(),
      FocusNode(),
    );

    final insertIndex = index + 1;
    if (insertIndex >= tmp.length) {
      tmp.add(newItem);
    } else {
      tmp.insert(insertIndex, newItem);
    }

    await ref
        .read(currentNoteProvider.notifier)
        .updateItems(tmp.map((item) => item.$1).toList());

    state = tmp;

    await Future.delayed(Duration(milliseconds: 100));
    if (!context.mounted) return;
    newItem.$3.requestFocus();
  }

  Future<void> delete(BuildContext context, int index) async {
    if (index == 0) {
      return;
    }

    final prevItem = state.elementAt(index - 1);
    final tmp = [...state];

    tmp.removeAt(index);

    await ref
        .read(currentNoteProvider.notifier)
        .updateItems(tmp.map((item) => item.$1).toList());

    state = tmp;

    await Future.delayed(Duration(milliseconds: 100));
    if (!context.mounted) return;
    prevItem.$3.requestFocus();
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
