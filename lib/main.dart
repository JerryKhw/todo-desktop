import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:todo_desktop/model/note.dart';
import 'package:todo_desktop/module/main/main_provider.dart';
import 'package:todo_desktop/module/main/main_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todo_desktop/provider/app_provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:velopack_flutter/velopack_flutter.dart';

void main(List<String> args) async {
  await RustLib.init();

  final veloCommands = [
    '--veloapp-install',
    '--veloapp-updated',
    '--veloapp-obsolete',
    '--veloapp-uninstall',
  ];
  if (veloCommands.any((cmd) => args.contains(cmd))) {
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationSupportDirectory();
  final dbPath = join(dir.path, 'todo_desktop.json');
  final db = await databaseFactoryIo.openDatabase(dbPath);

  int windowId = 0;
  late Note note;

  final store = intMapStoreFactory.store('notes');

  final initNote = Note(
    check: false,
    width: 300,
    height: 500,
    offset: null,
    items: [
      NoteItem(text: jsonEncode(Document().toDelta().toJson()), checked: false),
    ],
  );

  if (args.isEmpty) {
    final ids = await store.findKeys(db);
    windowId = ids.isEmpty ? 0 : ids.first;

    final record = store.record(windowId);
    final data = await record.get(db);

    if (data != null) {
      note = Note.fromJson(data);
    } else {
      await record.put(db, initNote.toJson());
      note = initNote;
    }

    if (ids.length > 1) {
      final otherIds = [...ids];
      otherIds.removeAt(0);
      for (final id in otherIds) {
        newNote(id: id);
      }
    }
  } else {
    windowId = int.tryParse(args[1]) ?? await store.generateIntKey(db);

    final record = store.record(windowId);
    final data = await record.get(db);

    if (data != null) {
      note = Note.fromJson(data);
    } else {
      await record.put(db, initNote.toJson());
      note = initNote;
    }
  }

  await WindowManagerPlus.ensureInitialized(windowId);

  final offset = note.offset?.toOffset();

  final windowOptions = WindowOptions(
    size: Size(note.width, note.height),
    center: offset == null,
    minimumSize: Size(300, 300),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  if (offset != null) {
    await WindowManagerPlus.current.setPosition(offset);
  }

  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });

  return runApp(
    ProviderScope(
      overrides: [
        windowIdProvider.overrideWithValue(windowId),
        databaseProvider.overrideWithValue(db),
        noteProvider.overrideWithValue(note),
      ],
      observers: [TalkerRiverpodObserver()],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      home: MainView(),
    );
  }
}
