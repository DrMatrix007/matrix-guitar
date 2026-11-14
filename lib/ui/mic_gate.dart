import 'package:flutter/material.dart';

import '../practice/mic_controller.dart';

const correctColor = Color(0xFF66BB6A);

class MicGate extends StatelessWidget {
  final MicController controller;
  final Widget child;

  const MicGate({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    if (controller.isComplete) return child;
    return switch (controller.micState) {
      MicState.requesting => const Center(child: CircularProgressIndicator()),
      MicState.denied => _MicMessage(
        message: 'Microphone access is needed to hear your playing.',
        actionLabel: 'Try again',
        onAction: controller.start,
      ),
      MicState.permanentlyDenied => _MicMessage(
        message: 'Microphone access is blocked. Allow it in settings.',
        actionLabel: 'Open settings',
        onAction: controller.openSettings,
      ),
      MicState.listening => child,
      MicState.paused => const Center(child: Text('Paused')),
      MicState.error => _MicMessage(
        message: 'The microphone could not be started.',
        actionLabel: 'Try again',
        onAction: controller.start,
      ),
    };
  }
}

class _MicMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MicMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
