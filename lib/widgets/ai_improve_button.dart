import 'package:flutter/material.dart';

/// A right-aligned "Improve with AI" button that runs [onImprove], shows a
/// loading state while it's in flight, and surfaces failures inline.
///
/// Errors are shown as inline text rather than a SnackBar because this
/// button is often used inside a modal bottom sheet or dialog, where a
/// SnackBar from the underlying page's ScaffoldMessenger renders behind the
/// sheet and is invisible to the user.
class AiImproveButton extends StatefulWidget {
  final Future<String> Function() onImprove;
  final ValueChanged<String> onResult;
  final String label;

  const AiImproveButton({
    super.key,
    required this.onImprove,
    required this.onResult,
    this.label = 'Improve with AI',
  });

  @override
  State<AiImproveButton> createState() => _AiImproveButtonState();
}

class _AiImproveButtonState extends State<AiImproveButton> {
  bool _busy = false;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onImprove();
      widget.onResult(result);
    } catch (e) {
      if (mounted) {
        setState(() => _error = _messageFor(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('demand') ||
        text.contains('overloaded') ||
        text.contains('unavailable') ||
        text.contains('503')) {
      return 'Gemini is busy right now. Try again in a moment.';
    }
    if (text.contains('api key')) {
      return 'No Gemini API key configured.';
    }
    return 'AI request failed. Check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy ? null : _run,
            icon: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_busy ? 'Improving…' : widget.label),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
}
