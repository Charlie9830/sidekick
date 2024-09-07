import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

class DropZone extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context) draggingBuilder;
  final void Function(List<XFile> files) onDragDrop;

  const DropZone({
    Key? key,
    required this.child,
    required this.draggingBuilder,
    required this.onDragDrop,
  }) : super(key: key);

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      enable: true,
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        widget.onDragDrop(details.files);
      },
      child: _isDragging ? widget.draggingBuilder(context) : widget.child,
    );
  }
}
