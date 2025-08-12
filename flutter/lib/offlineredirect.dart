import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eventmangment/onlinestatus.dart';

class OfflineRedirector extends StatefulWidget {
  final String homeRoute;
  final String? reason; // optional snackbar reason

  const OfflineRedirector({super.key, required this.homeRoute, this.reason});

  @override
  State<OfflineRedirector> createState() => _OfflineRedirectorState();
}

class _OfflineRedirectorState extends State<OfflineRedirector> {
  late final ValueNotifier<bool> _notifier;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _notifier = OnlineStatus.instance.isOnline;
    // If already offline, redirect immediately next frame
    if (!_notifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }
    _sub = _notifier.asStream().listen((online) {
      if (!online) _goHome();
    });
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (widget.reason != null && messenger != null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(content: Text(widget.reason!)));
    }
    Navigator.of(context).pushNamedAndRemoveUntil(widget.homeRoute, (r) => r.isFirst || r.settings.name == widget.homeRoute);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

extension _ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> asStream() async* {
    yield value;
    yield* Stream<T>.multi((controller) {
      void listener() => controller.add(value);
      addListener(listener);
      controller.onCancel = () => removeListener(listener);
    });
  }
}
