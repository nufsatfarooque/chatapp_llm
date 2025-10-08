import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// MarkdownSelectable
/// - Renders full Markdown (headings, lists, bold, italic, code, etc.)
/// - Text is selectable & copyable using SelectableRegion
/// - No typing animation
class MarkdownSelectable extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownSelectable({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ??
        const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          height: 1.4,
        );

    return SelectionArea(
      child: MarkdownBody(
        data: text,
        selectable: false, // handled by SelectionArea
        styleSheet: MarkdownStyleSheet(
          h1: defaultStyle.copyWith(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          h2: defaultStyle.copyWith(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          h3: defaultStyle.copyWith(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          p: defaultStyle,
          strong: defaultStyle.copyWith(fontWeight: FontWeight.bold),
          em: defaultStyle.copyWith(fontStyle: FontStyle.italic),
          listBullet: defaultStyle.copyWith(color: Colors.white70),
          code: defaultStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: Colors.black26,
              color: Colors.greenAccent),
        ),
      ),
    );
  }
}
