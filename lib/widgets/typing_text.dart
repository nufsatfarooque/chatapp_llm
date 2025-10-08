import 'package:flutter/material.dart';

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const TypingText({super.key, required this.text, this.style, this.duration = const Duration(milliseconds: 50)});

  @override
  _TypingTextState createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration * widget.text.length,
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
    return Text(
      widget.text.substring(0, _charCount.value),
      style: widget.style,
    );
  }
}
