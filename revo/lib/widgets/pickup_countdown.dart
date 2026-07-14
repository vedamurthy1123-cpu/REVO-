import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class PickupCountdown extends StatefulWidget {
  final String deadline;
  final bool compact;

  const PickupCountdown({
    super.key,
    required this.deadline,
    this.compact = false,
  });

  @override
  State<PickupCountdown> createState() => _PickupCountdownState();
}

class _PickupCountdownState extends State<PickupCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(PickupCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _calculateRemaining();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final deadline = DateTime.parse(widget.deadline).toLocal();
    final now = DateTime.now();

    if (mounted) {
      setState(() {
        if (now.isBefore(deadline)) {
          _remaining = deadline.difference(now);
        } else {
          _remaining = Duration.zero;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isExpiring = _remaining.inMinutes < 2;

    if (widget.compact) {
      return Text(
        '$minutes:$seconds',
        style: TextStyle(
          color: isExpiring ? Colors.red : AppTheme.brandAccent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'COLLECT IN',
          style: TextStyle(
            fontSize: 10,
            color: isExpiring ? Colors.red : AppTheme.brandAccent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        Text(
          '$minutes:$seconds',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isExpiring ? Colors.red : AppTheme.brandAccent,
          ),
        ),
      ],
    );
  }
}
