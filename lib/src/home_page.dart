import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
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
  // Where the wheel and its pointer are. They change on every frame of a
  // spin, so only the wheel listens to them instead of the whole page
  // rebuilding. Start with the pointer inside the first choice, away from
  // its peg.
  final ValueNotifier<({double rotation, double pointer})> _pose =
      ValueNotifier((rotation: -segmentAngle(4) / 4, pointer: 0));

  double get _rotation => _pose.value.rotation;
  set _rotation(double rotation) =>
      _pose.value = (rotation: rotation, pointer: 0);
  WheelPhysics? _physics;
  Duration _lastTick = Duration.zero;
  // Fingers pressing on the wheel, which brakes it while it spins.
  final Set<int> _pressing = {};

  bool get _spinning => _physics != null;

  // Made as the page opens, so that on the web it can already unlock sound
  // on the very first touch.
  late final WheelFeedback _deviceFeedback;

  /// Whether the user wants sounds and vibrations.
  bool get _soundsOn => widget.themeController?.theme.sounds ?? true;

  /// Sounds and vibrations, unless the user turned them off in the settings.
  WheelFeedback get _feedback =>
      _soundsOn ? _deviceFeedback : const SilentWheelFeedback();

  List<String> get _choices => _lists!.selected.choices;

  /// Whether the user turned weights on in the settings.
  bool get _weighted => widget.themeController?.theme.weightedChoices ?? false;

  /// Whether the user turned elimination mode on in the settings.
  bool get _eliminating => widget.themeController?.theme.elimination ?? false;

  /// Indexes of the choices on the wheel: all of them, or in elimination mode
  /// only the ones that have not come out yet. Choices that came out are
  /// kept for when elimination mode is turned back on.
  List<int> get _onWheel => _eliminating
      ? _lists!.selected.remaining
      : [for (var i = 0; i < _choices.length; i++) i];

  /// Color of the choice at [index]: the one the user gave it, or else the
  /// theme's.
  Color _colorOf(int index, WheelPalette palette) =>
      _lists!.selected.colorOf(index) ??
      palette.segmentColor(index, _choices.length);

  List<String> get _wheelChoices => [for (final i in _onWheel) _choices[i]];

  /// Weights the wheel uses: all the same when weights are turned off, while
  /// the ones saved with the list are kept for when they are turned back on.
  List<int> get _weights => [
    for (final i in _onWheel) _weighted ? _lists!.selected.weightOf(i) : 1,
  ];

  WheelLayout get _layout => WheelLayout(_weights);

  @override
  void initState() {
    super.initState();
    _deviceFeedback =
        widget.feedback ?? DeviceWheelFeedback(enabled: () => _soundsOn);
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
    // A first launch starts with an example list in the user's language.
    final l10n = AppLocalizations.of(context);
    setState(
      () => _lists =
          saved ??
          ChoiceLists.initial(
            name: l10n.defaultListName,
            choices: l10n.defaultChoices.split('|'),
          ),
    );
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
    setState(() => _rotation = _onWheel.isEmpty ? 0 : -_layout.sweep(0) / 4);
  }

  /// Keeps the pointer inside the choice under it, away from its peg, once
  /// choices came out of the wheel or went back in.
  void _settleRotation() {
    if (_onWheel.isEmpty) return;
    final layout = _layout;
    final index = layout.indexAtRotation(_rotation);
    setState(
      () => _rotation = -(layout.start(index) + layout.sweep(index) / 4),
    );
  }

  void _selectList(int index) {
    _updateLists(_lists!.lists, index);
    _resetRotation();
  }

  Future<void> _createList() async {
    final l10n = AppLocalizations.of(context);
    final name = await _askListName(title: l10n.newList, action: l10n.create);
    if (name == null) return;
    _updateLists([
      ..._lists!.lists,
      ChoiceList(name: name, choices: const []),
    ], _lists!.lists.length);
    _resetRotation();
    _inputFocus.requestFocus();
  }

  Future<void> _renameList() async {
    final l10n = AppLocalizations.of(context);
    final name = await _askListName(
      title: l10n.renameList,
      action: l10n.rename,
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
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteListQuestion),
          content: Text(l10n.deleteListWarning(_lists!.selected.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('confirmDeleteList'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
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
      builder: (context) => _NameDialog(
        title: title,
        action: action,
        label: AppLocalizations.of(context).listName,
        hint: AppLocalizations.of(context).listNameHint,
        initial: initial,
      ),
    );
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
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

  /// Lets the user pick another color for the choice at [index], or give it
  /// back the theme's.
  Future<void> _pickColor(int index) async {
    final palette = WheelTheme.of(context);
    final picked = await showDialog<({Color? color})>(
      context: context,
      builder: (context) => _ChoiceColorDialog(
        current: _colorOf(index, palette),
        themeColor: palette.segmentColor(index, _choices.length),
        isThemeColor: _lists!.selected.colorOf(index) == null,
        palette: palette,
      ),
    );
    if (picked == null || !mounted || index >= _choices.length) return;
    _setSelected(_lists!.selected.withColor(index, picked.color));
  }

  /// Asks for a new name for the choice at [index], in a popup that stays
  /// clear of the keyboard; an empty name keeps the old one.
  Future<void> _renameChoice(int index) async {
    if (_spinning) return;
    final l10n = AppLocalizations.of(context);
    final list = _lists!.selected;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(
        title: l10n.renameChoice,
        action: l10n.rename,
        label: l10n.choiceName,
        initial: list.choices[index],
        selectAll: true,
        fieldKey: const Key('choiceNameInput'),
        confirmKey: const Key('confirmChoiceName'),
      ),
    );
    final trimmed = name?.trim() ?? '';
    // The list may have changed while the popup was open.
    if (!mounted || trimmed.isEmpty || _lists!.selected != list) return;
    if (trimmed == list.choices[index]) return;
    _setSelected(list.withRenamed(index, trimmed));
  }

  void _setWeight(int index, int weight) {
    _setSelected(_lists!.selected.withWeight(index, weight));
  }

  void _eliminate(int index) {
    _setSelected(_lists!.selected.withEliminated(index));
    _settleRotation();
  }

  void _restore(int index) {
    _setSelected(_lists!.selected.withRestored(index));
    _settleRotation();
  }

  void _restoreAll() {
    _setSelected(_lists!.selected.withAllRestored());
    _settleRotation();
  }

  void _clearChoices() {
    _setSelected(_lists!.selected.copyWith(choices: [], weights: []));
  }

  void _spinWheel() {
    if (_spinning || _onWheel.length < 2) return;
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
    _pose.value = (
      rotation: physics.angle,
      pointer: done ? 0 : physics.pointer,
    );
    if (done) {
      // Only the end of the spin changes the rest of the page.
      setState(() => _physics = null);
      _ticker.stop();
      _feedback.stop(celebrate: !_eliminating);
      _showResult(_onWheel[physics.selectedIndex]);
    }
  }

  /// Shows the choice at [index] the wheel picked: the winner, or in
  /// elimination mode the choice that comes out of the wheel.
  Future<void> _showResult(int index) =>
      _eliminating ? _showElimination(index) : _showWinner(_choices[index]);

  Future<void> _showWinner(String winner) => showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        icon: const Icon(Icons.celebration, size: 40),
        title: Text(l10n.resultTitle),
        content: Text(
          winner,
          key: const Key('result'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.great),
          ),
        ],
      );
    },
  );

  /// Takes the choice at [index] out of the wheel, right away or if the user
  /// says so. Once a single choice is left, it wins like a normal pick.
  Future<void> _showElimination(int index) async {
    final loser = _choices[index];
    final confirm = widget.themeController?.theme.confirmElimination ?? false;
    final eliminate = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          icon: Icon(
            Icons.remove_circle_outline,
            size: 40,
            color: theme.colorScheme.outline,
          ),
          title: Text(confirm ? l10n.eliminateQuestion : l10n.eliminatedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loser,
                key: const Key('result'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  decoration: confirm ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                confirm ? l10n.eliminationAsk : l10n.eliminationNote,
                key: const Key('eliminationNote'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            if (confirm) ...[
              TextButton(
                key: const Key('keepChoice'),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.keepChoice),
              ),
              FilledButton(
                key: const Key('eliminateChoice'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.eliminateChoice),
              ),
            ] else
              TextButton(
                key: const Key('next'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.next),
              ),
          ],
        );
      },
    );
    // Without confirmation, the choice comes out however the dialog closes.
    if (!mounted || (confirm && eliminate != true)) return;
    _eliminate(index);
    final left = _lists!.selected.remaining;
    if (left.length == 1) {
      _feedback.celebrate();
      await _showWinner(_choices[left.single]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lists == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = AppLocalizations.of(context);
    // Read here: the Scaffold hides the keyboard from its body.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        // Tinted when the list of choices scrolls, not the page behind it.
        notificationPredicate: (notification) => notification.depth == 1,
        title: _buildListMenu(),
        centerTitle: true,
        actions: [
          if (widget.themeController case final controller?)
            IconButton(
              key: const Key('themeButton'),
              tooltip: l10n.settings,
              onPressed: () => ThemeSheet.show(context, controller),
              icon: const Icon(Icons.settings_outlined),
            ),
          IconButton(
            tooltip: l10n.clearAll,
            onPressed: _choices.isEmpty || _spinning ? null : _clearChoices,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            // The keyboard slides over the page instead of shrinking the
            // wheel: the page keeps its full height and scrolls if needed to
            // show the field being typed in.
            final height = constraints.maxHeight + keyboard;
            final editor = _buildEditor();
            final Widget page;
            if (wide) {
              page = Row(
                children: [
                  Expanded(child: _buildWheel()),
                  SizedBox(width: 380, child: editor),
                ],
              );
            } else {
              // While typing on a phone, the spin button makes way for the
              // field, which moves up under the wheel, above the keyboard.
              final typing = keyboard > 0 && !_exhausted;
              final wheelHeight = (height - bottomInset) * 5 / 9;
              page = Column(
                children: [
                  SizedBox(
                    height: typing ? wheelHeight - _spinRowHeight : wheelHeight,
                    child: _buildWheel(spinButton: !typing),
                  ),
                  Expanded(child: editor),
                ],
              );
            }
            return SingleChildScrollView(
              key: const Key('page'),
              physics: keyboard > 0
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: page,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListMenu() {
    final lists = _lists!;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<VoidCallback>(
      key: const Key('listMenu'),
      tooltip: l10n.switchList,
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
              subtitle: Text(l10n.choiceCount(lists.lists[i].choices.length)),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('newList'),
          value: _createList,
          child: ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(l10n.newList),
          ),
        ),
        PopupMenuItem(
          key: const Key('renameList'),
          value: _renameList,
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.renameList),
          ),
        ),
        PopupMenuItem(
          key: const Key('deleteList'),
          value: _deleteList,
          enabled: lists.lists.length > 1,
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteList),
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

  /// Whether, in elimination mode, too few choices are left to spin.
  bool get _exhausted =>
      _eliminating &&
      _lists!.selected.eliminated.isNotEmpty &&
      _onWheel.length < 2;

  /// Height of the spin button and the gap above it.
  static const _spinRowHeight = 16.0 + 52;

  Widget _buildWheel({bool spinButton = true}) {
    final palette = WheelTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final onWheel = _onWheel;
    final canSpin = !_spinning && onWheel.length >= 2;
    // In elimination mode, once too few choices are left to spin, the wheel
    // says so and offers to put the others back.
    final exhausted = _exhausted;
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
                    child: _buildSpinningWheel(palette, onWheel),
                  ),
                ),
              ),
            ),
          ),
          if (exhausted || spinButton) const SizedBox(height: 16),
          if (exhausted) ...[
            Text(
              onWheel.isEmpty
                  ? l10n.allChoicesOut
                  : l10n.lastChoiceWins(_choices[onWheel.single]),
              key: const Key('lastChoice'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('restoreAllWheel'),
              onPressed: _restoreAll,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.restoreAllWheel),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ] else if (spinButton)
            FilledButton.icon(
              key: const Key('spin'),
              onPressed: canSpin ? _spinWheel : null,
              icon: const Icon(Icons.refresh),
              label: Text(onWheel.length < 2 ? l10n.addAtLeastTwo : l10n.spin),
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
    final l10n = AppLocalizations.of(context);
    return [
      IconButton(
        key: Key('lighter$index'),
        tooltip: l10n.lessLikely,
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
        tooltip: l10n.moreLikely,
        visualDensity: VisualDensity.compact,
        onPressed: _spinning || weight >= ChoiceList.maxWeight
            ? null
            : () => _setWeight(index, weight + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ];
  }

  Widget _buildSpinningWheel(WheelPalette palette, List<int> onWheel) {
    // Made once per build of the page, so that the wheel keeps the same
    // choices on every frame of a spin and does not paint them again.
    final choices = _wheelChoices;
    // Choices keep their color when others come out.
    final colors = [for (final i in onWheel) _colorOf(i, palette)];
    final weights = _weights;
    return ValueListenableBuilder(
      valueListenable: _pose,
      builder: (context, pose, _) => SpinningWheel(
        choices: choices,
        colors: colors,
        weights: weights,
        rotation: pose.rotation,
        pointerDeflection: pose.pointer,
      ),
    );
  }

  Widget _buildEditor() {
    final palette = WheelTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final onWheel = _onWheel;
    final out = _eliminating ? _lists!.selected.eliminated.length : 0;
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
              labelText: l10n.newChoice,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const Key('addChoice'),
                tooltip: l10n.add,
                onPressed: _spinning ? null : _addChoice,
                icon: const Icon(Icons.add_circle),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (out > 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eliminatedCount(out),
                    key: const Key('eliminatedCount'),
                  ),
                ),
                TextButton.icon(
                  key: const Key('restoreAll'),
                  onPressed: _spinning ? null : _restoreAll,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.restoreAll),
                ),
              ],
            ),
          Expanded(
            child: _choices.isEmpty
                ? Center(child: Text(l10n.noChoicesYet))
                : ListView.builder(
                    itemCount: _choices.length,
                    itemBuilder: (context, i) {
                      final eliminated =
                          _eliminating && _lists!.selected.isEliminated(i);
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 4,
                          end: 16,
                        ),
                        minLeadingWidth: 0,
                        leading: IconButton(
                          key: Key('color$i'),
                          tooltip: l10n.changeColor,
                          onPressed: _spinning ? null : () => _pickColor(i),
                          icon: CircleAvatar(
                            radius: 9,
                            // Same color as the choice's segment on the wheel.
                            backgroundColor: eliminated
                                ? scheme.outlineVariant
                                : _colorOf(i, palette),
                          ),
                        ),
                        title: GestureDetector(
                          key: Key('choiceName$i'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _spinning ? null : () => _renameChoice(i),
                          child: Semantics(
                            button: true,
                            hint: l10n.renameChoice,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                _choices[i],
                                style: eliminated
                                    ? TextStyle(
                                        color: scheme.outline,
                                        decoration: TextDecoration.lineThrough,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        subtitle: eliminated
                            ? Text(
                                l10n.eliminated,
                                key: Key('eliminated$i'),
                                style: TextStyle(color: scheme.outline),
                              )
                            : _weighted
                            ? Text(
                                _chanceLabel(
                                  l10n,
                                  _lists!.selected.chanceOf(i, among: onWheel),
                                ),
                                key: Key('chance$i'),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (eliminated)
                              IconButton(
                                key: Key('restore$i'),
                                tooltip: l10n.restore,
                                onPressed: _spinning ? null : () => _restore(i),
                                icon: const Icon(Icons.undo),
                              )
                            else if (_weighted)
                              ..._buildWeightStepper(i),
                            IconButton(
                              tooltip: l10n.remove,
                              onPressed: _spinning
                                  ? null
                                  : () => _removeChoice(i),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Asks for a choice's color, with sliders over every color, shortcuts to
/// the palette's, and a color code. Closes with the color picked, with a null
/// color to give the choice the theme's, or with nothing if dismissed.
class _ChoiceColorDialog extends StatefulWidget {
  const _ChoiceColorDialog({
    required this.current,
    required this.themeColor,
    required this.isThemeColor,
    required this.palette,
  });

  final Color current;

  /// The color the theme gives the choice.
  final Color themeColor;

  /// Whether the choice has the theme's color, rather than one of its own.
  final bool isThemeColor;
  final WheelPalette palette;

  @override
  State<_ChoiceColorDialog> createState() => _ChoiceColorDialogState();
}

class _ChoiceColorDialogState extends State<_ChoiceColorDialog> {
  late HSLColor _color = HSLColor.fromColor(widget.current);
  // Whether the choice is to keep the theme's color, and follow the theme
  // when it changes.
  late bool _themeColor = widget.isThemeColor;
  late final TextEditingController _code = TextEditingController(
    text: _hex(widget.current),
  );

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// "0077B6" for a color, without its opacity.
  static String _hex(Color color) => (color.toARGB32() & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();

  void _set(HSLColor color, {bool themeColor = false}) {
    setState(() {
      _color = color;
      _themeColor = themeColor;
    });
    _code.text = _hex(color.toColor());
  }

  void _typeCode(String code) {
    if (code.length != 6) return;
    final value = int.tryParse(code, radix: 16);
    if (value == null) return;
    setState(() {
      _color = HSLColor.fromColor(Color(0xFF000000 | value));
      _themeColor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = _color;
    final picked = color.toColor();
    final pure = HSLColor.fromAHSL(1, color.hue, 1, 0.5).toColor();
    return AlertDialog(
      title: Text(l10n.choiceColor),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const Key('colorPreview'),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: picked,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: TextField(
                  key: const Key('colorCode'),
                  controller: _code,
                  onChanged: _typeCode,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.colorCode,
                    prefixText: '#',
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ColorSlider(
                key: const Key('hue'),
                label: l10n.hue,
                value: color.hue,
                max: 360,
                colors: [
                  for (var hue = 0; hue <= 360; hue += 60)
                    HSLColor.fromAHSL(1, hue.toDouble(), 1, 0.5).toColor(),
                ],
                onChanged: (hue) => _set(color.withHue(hue)),
              ),
              _ColorSlider(
                key: const Key('saturation'),
                label: l10n.saturation,
                value: color.saturation,
                colors: [
                  color.withSaturation(0).toColor(),
                  color.withSaturation(1).toColor(),
                ],
                onChanged: (saturation) =>
                    _set(color.withSaturation(saturation)),
              ),
              _ColorSlider(
                key: const Key('lightness'),
                label: l10n.lightness,
                value: color.lightness,
                colors: [Colors.black, pure, Colors.white],
                onChanged: (lightness) => _set(color.withLightness(lightness)),
              ),
              const SizedBox(height: 8),
              // Shortcuts to the colors of the theme.
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < widget.palette.colors.length; i++)
                    _Swatch(
                      key: Key('swatch$i'),
                      color: widget.palette.colors[i],
                      selected: widget.palette.colors[i] == picked,
                      outline: scheme.outline,
                      onTap: () =>
                          _set(HSLColor.fromColor(widget.palette.colors[i])),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          key: const Key('restoreDefaultColor'),
          onPressed: _themeColor
              ? null
              : () => _set(
                  HSLColor.fromColor(widget.themeColor),
                  themeColor: true,
                ),
          icon: CircleAvatar(radius: 8, backgroundColor: widget.themeColor),
          label: Text(l10n.restoreDefaultColor),
        ),
        FilledButton(
          key: const Key('confirmColor'),
          onPressed: () =>
              Navigator.of(context).pop((color: _themeColor ? null : picked)),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

/// A slider whose track shows the colors it goes through.
class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.max = 1,
  });

  final String label;
  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black12),
              gradient: LinearGradient(colors: colors),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.black12,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 3,
              ),
            ),
            child: Semantics(
              label: label,
              child: Slider(
                value: value.clamp(0, max),
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.selected,
    required this.outline,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final Color outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light;
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? outline : outline.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: light ? Colors.black87 : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

/// "25 %", in the style of the user's language, for a [chance] between 0
/// and 1.
String _chanceLabel(AppLocalizations l10n, double chance) {
  final percent = chance * 100;
  if (percent > 0 && percent < 1) return '< ${l10n.percent('1')}';
  return l10n.percent('${percent.round()}');
}

/// Asks for a name: of a list, or of a choice. Sits in the upper part of the
/// screen, so that the keyboard does not cover it.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.label,
    this.hint,
    required this.initial,
    this.selectAll = false,
    this.fieldKey = const Key('listNameInput'),
    this.confirmKey = const Key('confirmListName'),
  });

  final Key fieldKey;
  final Key confirmKey;

  final String title;
  final String action;
  final String label;
  final String? hint;
  final String initial;

  /// Whether the name starts selected, to be typed over.
  final bool selectAll;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _name = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.initial,
      selection: widget.selectAll
          ? TextSelection(baseOffset: 0, extentOffset: widget.initial.length)
          : TextSelection.collapsed(offset: widget.initial.length),
    ),
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_name.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      alignment: const Alignment(0, -0.6),
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: widget.confirmKey,
          onPressed: _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
