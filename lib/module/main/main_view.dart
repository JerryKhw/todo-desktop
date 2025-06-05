import 'dart:convert';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todo_desktop/asset/index.dart';
import 'package:todo_desktop/model/note.dart';
import 'package:todo_desktop/module/main/main_provider.dart';
import 'package:todo_desktop/util/extension.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => MainViewState();
}

class MainViewState extends ConsumerState<MainView> with WindowListener {
  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowResized([int? windowId]) async =>
      await ref.read(currentNoteProvider.notifier).resize();

  @override
  Future<void> onWindowMoved([int? windowId]) async =>
      await ref.read(currentNoteProvider.notifier).move();

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);

    return Scaffold(
      backgroundColor: Color(0xFFFFF8E6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBar(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return MainItem(
                  item: item,
                  onChanged:
                      (value) => ref
                          .read(itemsProvider.notifier)
                          .onChanged(index, value),
                  onToogle:
                      () => ref.read(itemsProvider.notifier).toggle(index),
                  onAdd:
                      () =>
                          ref.read(itemsProvider.notifier).add(context, index),
                  onDelete:
                      () => ref
                          .read(itemsProvider.notifier)
                          .delete(context, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MainItem extends HookConsumerWidget {
  final (NoteItem, QuillController, FocusNode) item;
  final void Function(String) onChanged;
  final void Function() onToogle;
  final void Function() onAdd;
  final void Function() onDelete;

  const MainItem({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onToogle,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(currentNoteProvider);

    final data = item.$1;
    final controller = item.$2;
    final focusNode = item.$3;

    final listener = useState(() {
      if (focusNode.hasFocus) {
        ref.read(currentControllerProvider.notifier).update(controller);
      }
    });

    useEffect(() {
      controller.changes.listen((event) {
        onChanged(jsonEncode(controller.document.toDelta().toJson()));
      });

      focusNode.addListener(listener.value);

      return () {
        focusNode.removeListener(listener.value);
      };
    });

    return Listener(
      onPointerDown: (PointerDownEvent event) {
        if (event.kind == PointerDeviceKind.mouse) {
          if (event.buttons == kMiddleMouseButton) {
            onToogle();
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.check)
              InkWell(
                onTap: onToogle,
                child: Container(
                  height: 22,
                  margin: EdgeInsets.only(right: 6),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    data.checked
                        ? SvgImage.selectorCheckboxOn
                        : SvgImage.selectorCheckboxOff,
                    height: 16,
                    width: 16,
                  ),
                ),
              ),
            Expanded(
              child: QuillEditor.basic(
                controller: controller,
                focusNode: focusNode,
                config: QuillEditorConfig(
                  onKeyPressed: (event, node) {
                    final isShiftPressed =
                        HardwareKeyboard.instance.isShiftPressed;

                    if (event is KeyDownEvent) {
                      switch (event.logicalKey) {
                        case LogicalKeyboardKey.backspace:
                          if (controller.document
                              .toPlainText()
                              .trim()
                              .isEmpty) {
                            onDelete();
                            return KeyEventResult.handled;
                          }
                          break;
                        case LogicalKeyboardKey.enter:
                          if (!isShiftPressed) {
                            onAdd();
                            return KeyEventResult.handled;
                          }
                          break;
                        default:
                          break;
                      }
                    }

                    return KeyEventResult.ignored;
                  },
                  textSelectionThemeData: TextSelectionThemeData(
                    cursorColor: Color(0xFF443731),
                  ),
                  placeholder: 'Please enter the contents.',
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                      TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 22.toFigmaLineHeight(16),
                        color: Color(0xFF443731),
                      ),
                      HorizontalSpacing(0, 0),
                      VerticalSpacing.zero,
                      VerticalSpacing.zero,
                      null,
                    ),
                    placeHolder: DefaultTextBlockStyle(
                      TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 22.toFigmaLineHeight(16),
                        color: Color(0xFF443731).withValues(alpha: 0.3),
                      ),
                      HorizontalSpacing(0, 0),
                      VerticalSpacing.zero,
                      VerticalSpacing.zero,
                      null,
                    ),
                    strikeThrough: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 22.toFigmaLineHeight(16),
                      color: Color(0xFF443731),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Color(0xFF443731),
                    ),
                  ),
                ),
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppBar extends ConsumerWidget {
  const AppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(currentNoteProvider);
    final controller = ref.watch(currentControllerProvider);

    return GestureDetector(
      onTapDown: (_) => WindowManagerPlus.current.startDragging(),
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: 11),
        color: Color(0xFFCFB094),
        child: Row(
          children: [
            AppBarButton(
              SvgImage.icAdd,
              onTap: () => newNote(context: context),
            ),
            SizedBox(width: 10),
            AppBarButton(
              onTap: ref.read(currentNoteProvider.notifier).toggleCheck,
              note.check ? SvgImage.selectorCheckOn : SvgImage.selectorCheckOff,
            ),
            SizedBox(width: 10),
            QuillToolbarToggleStyleButton(
              controller: controller,
              attribute: Attribute.strikeThrough,
              baseOptions: QuillToolbarBaseButtonOptions(
                childBuilder: (optionsDynamic, extraOptionsDynamic) {
                  final extraOptions =
                      extraOptionsDynamic
                          as QuillToolbarToggleStyleButtonExtraOptions;

                  return AppBarButton(
                    onTap: extraOptions.onPressed,
                    extraOptions.isToggled
                        ? SvgImage.selectorLineOn
                        : SvgImage.selectorLineOff,
                  );
                },
              ),
            ),
            const Spacer(),
            AppBarButton(
              onTap: ref.read(currentNoteProvider.notifier).delete,
              SvgImage.icDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class AppBarButton extends StatelessWidget {
  final String image;
  final void Function()? onTap;

  const AppBarButton(this.image, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SvgPicture.asset(image, height: 24, width: 24),
    );
  }
}
