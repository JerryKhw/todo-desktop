import 'package:flutter/semantics.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

@freezed
abstract class Note with _$Note {
  const factory Note({
    required bool check,
    required double width,
    required double height,
    NoteOffset? offset,
    required List<NoteItem> items,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}

@freezed
abstract class NoteOffset with _$NoteOffset {
  const factory NoteOffset({required double x, required double y}) =
      _NoteOffset;

  factory NoteOffset.fromJson(Map<String, dynamic> json) =>
      _$NoteOffsetFromJson(json);
}

extension NoteOffsetExtension on NoteOffset {
  Offset toOffset() => Offset(x, y);
}

@freezed
abstract class NoteItem with _$NoteItem {
  const factory NoteItem({required String text, required bool checked}) =
      _NoteItem;

  factory NoteItem.fromJson(Map<String, dynamic> json) =>
      _$NoteItemFromJson(json);
}
