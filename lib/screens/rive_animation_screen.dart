import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveAnimationScreen extends StatefulWidget {
  const RiveAnimationScreen({super.key});

  @override
  State<RiveAnimationScreen> createState() => _RiveAnimationScreenState();
}

class _RiveAnimationScreenState extends State<RiveAnimationScreen> {
  Artboard? _artboard;
  RiveAnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() async {
    // Load the Rive file from assets
    final file = await RiveFile.asset('assets/deer.riv');
    final artboard = file.mainArtboard;

    // First, try state machines
    if (artboard.stateMachines.isNotEmpty) {
      _controller =
          StateMachineController.fromArtboard(artboard, artboard.stateMachines.first.name);
    } 
    // Otherwise, fallback to normal animations
    else if (artboard.animations.isNotEmpty) {
      _controller = SimpleAnimation(artboard.animations.first.name);
    }

    // Attach controller if available
    if (_controller != null) artboard.addController(_controller!);

    setState(() => _artboard = artboard);

    // Navigate 5 seconds after animation starts (or finishes if needed)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _artboard != null
            ? Rive(
                artboard: _artboard!,
                fit: BoxFit.contain,
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
