import 'package:boltscan/core/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Long text that shows [collapsedLines] with an ellipsis and expands to the
/// full text on tap. Expanded text is selectable. The layout is flexible so it
/// survives large text scales.
class ExpandableText extends ConsumerStatefulWidget {
  /// Creates expandable text.
  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.collapsedLines = 3,
  });

  /// Full text content.
  final String text;

  /// Text style for both collapsed and expanded states.
  final TextStyle? style;

  /// Lines shown before truncation when collapsed.
  final int collapsedLines;

  @override
  ConsumerState<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends ConsumerState<ExpandableText> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = ref.watch(appStringsProvider);
    return Semantics(
      button: true,
      label: widget.text,
      hint: _expanded ? strings.hide : strings.expandContent,
      onTap: _toggle,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _toggle,
        child: _expanded
            ? SelectableText(widget.text, style: widget.style)
            : Text(
                widget.text,
                style: widget.style,
                maxLines: widget.collapsedLines,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
