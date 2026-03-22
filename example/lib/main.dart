import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_keyboard/smart_keyboard.dart';

void main() {
  runApp(const SmartKeyboardExampleApp());
}

class SmartKeyboardExampleApp extends StatelessWidget {
  const SmartKeyboardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartKeyboard Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const KeyboardDemoPage(),
    );
  }
}

class KeyboardDemoPage extends StatefulWidget {
  const KeyboardDemoPage({super.key});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  double _keyboardHeight = 0.0;
  bool _isVisible = false;
  bool _isAnimating = false;
  int _eventCount = 0;

  StreamSubscription<KeyboardHeightEvent>? _heightSubscription;
  StreamSubscription<bool>? _visibilitySubscription;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _heightSubscription =
        SmartKeyboard.listenHeight(
          interval: const Duration(milliseconds: 16),
        ).listen((event) {
          setState(() {
            _keyboardHeight = event.height;
            _isAnimating = event.isAnimating;
            _eventCount++;
          });
        });

    _visibilitySubscription = SmartKeyboard.onVisibilityChanged.listen((
      visible,
    ) {
      setState(() {
        _isVisible = visible;
      });
    });
  }

  Future<void> _showCurrentHeight() async {
    final height = await SmartKeyboard.keyboardHeight;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Current height: ${height.toStringAsFixed(1)} px'),
      ),
    );
  }

  @override
  void dispose() {
    _heightSubscription?.cancel();
    _visibilitySubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartKeyboard Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keyboard Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Visible',
                      _isVisible ? 'YES' : 'NO',
                      _isVisible ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Height',
                      '${_keyboardHeight.toStringAsFixed(1)} px',
                      null,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Animating',
                      _isAnimating ? 'YES' : 'NO',
                      _isAnimating ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Events', '$_eventCount', null),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_keyboardHeight > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 16),
                height: (_keyboardHeight / 4).clamp(0.0, 100.0),
                decoration: BoxDecoration(
                  color: (_isAnimating ? Colors.orange : Colors.blue)
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isAnimating ? Colors.orange : Colors.blue,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_keyboardHeight.toStringAsFixed(0)} px',
                    style: TextStyle(
                      color: _isAnimating ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Tap to show keyboard',
                border: OutlineInputBorder(),
                hintText: 'Type something...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => SmartKeyboard.showKeyboard(),
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Show'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => SmartKeyboard.hideKeyboard(),
                    icon: const Icon(Icons.keyboard_hide),
                    label: const Text('Hide'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showCurrentHeight,
              icon: const Icon(Icons.height),
              label: const Text('Get Current Height'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
