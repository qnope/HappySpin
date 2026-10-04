import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_theme.dart';
import 'choice_lists.dart';
import 'spinning_wheel.dart';
import 'wheel_feedback.dart';
import 'wheel_math.dart';
import 'wheel_physics.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.random,
    this.store,
    this.themeController,
    this.feedback,
  });

  /// Injectable for tests; defaults to a fresh [math.Random].
  final math.Random? random;

  /// Injectable for tests; defaults to storage on the device.
  final ChoiceListStore? store;

  /// Changes the app's theme; the theme button is hidden without it.
  final AppThemeController? themeController;

  /// Sounds and vibrations of the wheel; defaults to the device's.
  final WheelFeedback? feedback;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late final Ticker _ticker = createTicker(_onTick);
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  late final ChoiceListStore _store =
      widget.store ?? PreferencesChoiceListStore();

  ChoiceLists? _lists;
  // Start with the pointer inside the first choice, away from its peg.
  double _rotation = -segmentAngle(4) / 4;
  double _pointer = 0;
  WheelPhysics? _physics;
  Duration _lastTick = Duration.zero;
  // Fingers pressing on the wheel, which brakes it while it spins.
  final Set<int> _pressing = {};

  bool get _spinning => _physics != null;

  late final WheelFeedback _deviceFeedback =
      widget.feedback ?? DeviceWheelFeedback();

  /// Sounds and vibrations, unless the user turned them off in the settings.
  WheelFeedback get _feedback => widget.themeController?.theme.sounds ?? true
      ? _deviceFeedback
      : const SilentWheelFeedback();

  List<String> get _choices => _lists!.selected.choices;

  /// Whether the user turned weights on in the settings.
  bool get _weighted => widget.themeController?.theme.weightedChoices ?? false;

  /// Weights the wheel uses: all the same when weights are turned off, while
  /// the ones saved with the list are kept for when they are turned back on.
  List<int> get _weights =>
      _weighted ? _lists!.selected.weights : List.filled(_choices.length, 1);

  WheelLayout get _layout => WheelLayout(_weights);

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    ChoiceLists? saved;
    try {
      saved = await _store.load();
    } on Object {
      // Start from the default list if storage is unavailable.
    }
    if (!mounted) return;
    setState(() => _lists = saved ?? ChoiceLists.initial());
    _resetRotation();
  }

  void _updateLists(List<ChoiceList> lists, int current) {
    final updated = ChoiceLists(lists: lists, current: current);
    setState(() => _lists = updated);
    _store.save(updated).catchError((Object _) {});
  }

  void _setSelected(ChoiceList list) {
    final lists = [..._lists!.lists];
    lists[_lists!.current] = list;
    _updateLists(lists, _lists!.current);
  }

  void _resetRotation() {
    // Keep the pointer inside the first choice, away from its peg.
    setState(() => _rotation = _choices.isEmpty ? 0 : -_layout.sweep(0) / 4);
  }

  void _selectList(int index) {
    _updateLists(_lists!.lists, index);
    _resetRotation();
  }

  Future<void> _createList() async {
    final name = await _askListName(title: 'Nouvelle liste', action: 'Créer');
    if (name == null) return;
    _updateLists([
      ..._lists!.lists,
      ChoiceList(name: name, choices: const []),
    ], _lists!.lists.length);
    _resetRotation();
    _inputFocus.requestFocus();
  }

  Future<void> _renameList() async {
    final name = await _askListName(
      title: 'Renommer la liste',
      action: 'Renommer',
      initial: _lists!.selected.name,
    );
    if (name == null) return;
    final lists = [..._lists!.lists];
    lists[_lists!.current] = _lists!.selected.copyWith(name: name);
    _updateLists(lists, _lists!.current);
  }

  Future<void> _deleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la liste ?'),
        content: Text(
          '« ${_lists!.selected.name} » et ses choix seront perdus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('confirmDeleteList'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final current = _lists!.current;
    _updateLists([..._lists!.lists]..removeAt(current), current - 1);
    _resetRotation();
  }

  Future<String?> _askListName({
    required String title,
    required String action,
    String initial = '',
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _ListNameDialog(title: title, action: action, initial: initial),
    );
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

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
    _setSelected(_lists!.selected.withChoice(text));
    _input.clear();
    _inputFocus.requestFocus();
  }

  void _removeChoice(int index) {
    _setSelected(_lists!.selected.withoutChoice(index));
  }

  void _setWeight(int index, int weight) {
    _setSelected(_lists!.selected.withWeight(index, weight));
  }

  void _clearChoices() {
    _setSelected(_lists!.selected.copyWith(choices: [], weights: []));
  }

  void _spinWheel() {
    if (_spinning || _choices.length < 2) return;
    setState(() {
      _physics = WheelPhysics(
        layout: _layout,
        angle: _rotation,
        // Between 0.7 and 1 turn per second.
        velocity: 4.5 + _random.nextDouble() * 2,
      );
    });
    _feedback.preload();
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final physics = _physics!;
    final clicks = physics.clicks;
    final knocks = physics.knocks;
    physics.braking = _pressing.isNotEmpty;
    // Cap the step so that a dropped frame does not make the wheel jump.
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    physics.advance(math.min(seconds, 0.1));
    _lastTick = elapsed;
    // A tick for every peg getting past the pointer, and for a peg knocking
    // against it without getting past.
    if (physics.clicks != clicks || physics.knocks != knocks) {
      _feedback.tick(physics.velocity);
    }

    final done = physics.isAtRest;
    setState(() {
      _rotation = physics.angle;
      _pointer = done ? 0 : physics.pointer;
      if (done) _physics = null;
    });
    if (done) {
      _ticker.stop();
      _feedback.stop();
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
    if (_lists == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: _buildListMenu(),
        centerTitle: true,
        actions: [
          if (widget.themeController case final controller?)
            IconButton(
              key: const Key('themeButton'),
              tooltip: 'Réglages',
              onPressed: () => ThemeSheet.show(context, controller),
              icon: const Icon(Icons.settings_outlined),
            ),
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

  Widget _buildListMenu() {
    final lists = _lists!;
    return PopupMenuButton<VoidCallback>(
      key: const Key('listMenu'),
      tooltip: 'Changer de liste',
      enabled: !_spinning,
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        for (var i = 0; i < lists.lists.length; i++)
          PopupMenuItem(
            value: () => _selectList(i),
            child: ListTile(
              leading: Icon(
                i == lists.current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(lists.lists[i].name),
              subtitle: Text(_choiceCount(lists.lists[i].choices.length)),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('newList'),
          value: _createList,
          child: const ListTile(
            leading: Icon(Icons.playlist_add),
            title: Text('Nouvelle liste'),
          ),
        ),
        PopupMenuItem(
          key: const Key('renameList'),
          value: _renameList,
          child: const ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Renommer la liste'),
          ),
        ),
        PopupMenuItem(
          key: const Key('deleteList'),
          value: _deleteList,
          enabled: lists.lists.length > 1,
          child: const ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Supprimer la liste'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                lists.selected.name,
                key: const Key('listName'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  static String _choiceCount(int count) => switch (count) {
    0 => 'Aucun choix',
    1 => '1 choix',
    _ => '$count choix',
  };

  Widget _buildWheel() {
    final canSpin = !_spinning && _choices.length >= 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Listener(
                onPointerDown: (event) => _pressing.add(event.pointer),
                onPointerUp: (event) => _pressing.remove(event.pointer),
                onPointerCancel: (event) => _pressing.remove(event.pointer),
                child: GestureDetector(
                  key: const Key('wheel'),
                  onTap: canSpin ? _spinWheel : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SpinningWheel(
                      choices: _choices,
                      weights: _weights,
                      rotation: _rotation,
                      pointerDeflection: _pointer,
                    ),
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

  /// Buttons making the choice at [index] more or less likely.
  List<Widget> _buildWeightStepper(int index) {
    final weight = _lists!.selected.weightOf(index);
    return [
      IconButton(
        key: Key('lighter$index'),
        tooltip: 'Moins de chances',
        visualDensity: VisualDensity.compact,
        onPressed: _spinning || weight <= ChoiceList.minWeight
            ? null
            : () => _setWeight(index, weight - 1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 28,
        child: Text(
          '×$weight',
          key: Key('weight$index'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      IconButton(
        key: Key('heavier$index'),
        tooltip: 'Plus de chances',
        visualDensity: VisualDensity.compact,
        onPressed: _spinning || weight >= ChoiceList.maxWeight
            ? null
            : () => _setWeight(index, weight + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ];
  }

  Widget _buildEditor() {
    final palette = WheelTheme.of(context);
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
                        backgroundColor: palette.segmentColor(
                          i,
                          _choices.length,
                        ),
                      ),
                      title: Text(_choices[i]),
                      subtitle: _weighted
                          ? Text(
                              _chanceLabel(_lists!.selected.chanceOf(i)),
                              key: Key('chance$i'),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_weighted) ..._buildWeightStepper(i),
                          IconButton(
                            tooltip: 'Retirer',
                            onPressed: _spinning
                                ? null
                                : () => _removeChoice(i),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "25 %", in the French style, for a [chance] between 0 and 1.
String _chanceLabel(double chance) {
  final percent = chance * 100;
  if (percent > 0 && percent < 1) return '< 1\u00a0%';
  return '${percent.round()}\u00a0%';
}

class _ListNameDialog extends StatefulWidget {
  const _ListNameDialog({
    required this.title,
    required this.action,
    required this.initial,
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<_ListNameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_name.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('listNameInput'),
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Nom de la liste',
          hintText: 'Ex. : Sorties du week-end',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('confirmListName'),
          onPressed: _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
