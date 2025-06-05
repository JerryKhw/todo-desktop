import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';
import 'package:todo_desktop/model/note.dart';

part 'app_provider.g.dart';

@riverpod
int windowId(Ref ref) => throw UnimplementedError();

@riverpod
Database database(Ref ref) => throw UnimplementedError();

@riverpod
Note note(Ref ref) => throw UnimplementedError();
