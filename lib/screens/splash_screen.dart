import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_chat_local/screens/rive_animation_screen.dart';
import 'chat_list_screen.dart';

/// Modern and elegant splash screen with animated logo and stylish layout.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RiveAnimationScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Local LLM Chat',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Powered by your Local LM Studio',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator.adaptive(),
            ],
          ),
        ),
      ),
    );
  }
}