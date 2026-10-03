import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'spinning_wheel.dart';
import 'wheel_math.dart';
import 'wheel_physics.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.random});

  /// Injectable for tests; defaults to a fresh [math.Random].
  final math.Random? random;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late final Ticker _ticker = createTicker(_onTick);
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  List<String> _choices = ['Pizza', 'Sushi', 'Burger', 'Salade'];
  // Start with the pointer inside the first choice, away from its peg.
  double _rotation = -segmentAngle(4) / 4;
  double _pointer = 0;
  WheelPhysics? _physics;
  Duration _lastTick = Duration.zero;

  bool get _spinning => _physics != null;

  @override
  void dispose() {
    _ticker.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _addChoice() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _choices = [..._choices, text]);
    _input.clear();
    _inputFocus.requestFocus();
  }

  void _removeChoice(int index) {
    setState(() => _choices = [..._choices]..removeAt(index));
  }

  void _clearChoices() {
    setState(() => _choices = []);
  }

  void _spinWheel() {
    if (_spinning || _choices.length < 2) return;
    setState(() {
      _physics = WheelPhysics(
        pegCount: _choices.length,
        angle: _rotation,
        // Between 0.7 and 1 turn per second.
        velocity: 4.5 + _random.nextDouble() * 2,
      );
    });
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final physics = _physics!;
    final clicks = physics.clicks;
    // Cap the step so that a dropped frame does not make the wheel jump.
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    physics.advance(math.min(seconds, 0.1));
    _lastTick = elapsed;
    if (physics.clicks != clicks) HapticFeedback.selectionClick();

    final done = physics.isAtRest;
    setState(() {
      _rotation = physics.angle;
      _pointer = done ? 0 : physics.pointer;
      if (done) _physics = null;
    });
    if (done) {
      _ticker.stop();
      _showResult(physics.selectedIndex);
    }
  }

  void _showResult(int index) {
    final winner = _choices[index];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration, size: 40),
        title: const Text('Le sort a choisi'),
        content: Text(
          winner,
          key: const Key('result'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Super !'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HappySpin'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tout effacer',
            onPressed: _choices.isEmpty || _spinning ? null : _clearChoices,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final wheel = _buildWheel();
            final editor = _buildEditor();
            if (wide) {
              return Row(
                children: [
                  Expanded(child: wheel),
                  SizedBox(width: 380, child: editor),
                ],
              );
            }
            return Column(
              children: [
                Flexible(flex: 5, child: wheel),
                Expanded(flex: 4, child: editor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWheel() {
    final canSpin = !_spinning && _choices.length >= 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: canSpin ? _spinWheel : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SpinningWheel(
                    choices: _choices,
                    rotation: _rotation,
                    pointerDeflection: _pointer,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('spin'),
            onPressed: canSpin ? _spinWheel : null,
            icon: const Icon(Icons.refresh),
            label: Text(
              _choices.length < 2 ? 'Ajoute au moins 2 choix' : 'Faire tourner',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(220, 52),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          TextField(
            key: const Key('choiceInput'),
            controller: _input,
            focusNode: _inputFocus,
            enabled: !_spinning,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addChoice(),
            decoration: InputDecoration(
              labelText: 'Nouveau choix',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const Key('addChoice'),
                tooltip: 'Ajouter',
                onPressed: _spinning ? null : _addChoice,
                icon: const Icon(Icons.add_circle),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _choices.isEmpty
                ? const Center(child: Text('Aucun choix pour le moment.'))
                : ListView.builder(
                    itemCount: _choices.length,
                    itemBuilder: (context, i) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 8,
                        backgroundColor: wheelColor(i, _choices.length),
                      ),
                      title: Text(_choices[i]),
                      trailing: IconButton(
                        tooltip: 'Retirer',
                        onPressed: _spinning ? null : () => _removeChoice(i),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
