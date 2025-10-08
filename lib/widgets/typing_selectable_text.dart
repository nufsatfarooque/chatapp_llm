import 'package:flutter/material.dart';

class TypingSelectableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;

  const TypingSelectableText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 30),
  });

  @override
  _TypingSelectableTextState createState() => _TypingSelectableTextState();
}

class _TypingSelectableTextState extends State<TypingSelectableText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _charCount;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.charDuration * widget.text.length,
    );

    _charCount = StepTween(begin: 0, end: widget.text.length).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.text.substring(0, _charCount.value);

    return SelectableText(
      currentText,
      style: widget.style ?? const TextStyle(color: Colors.white70, fontSize: 16),
    );
  }
}
