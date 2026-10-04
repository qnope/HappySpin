import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'wheel_sounds.dart';

/// Plays the sounds with the Web Audio API, which starts them right away
/// where an audio element would lag behind the pegs.
class PlatformWheelSounds implements WheelSounds {
  PlatformWheelSounds() {
    // Safari only lets a page start its sounds while it handles a touch or
    // a click, so every one of them gets a chance to unlock the sounds,
    // before the app even hears about it.
    for (final type in ['touchend', 'pointerup', 'click', 'keydown']) {
      web.document.addEventListener(type, _onUserGesture, true.toJS);
    }
  }

  late final JSFunction _onUserGesture = ((web.Event _) => unlock()).toJS;

  web.AudioContext? _context;
  web.AudioBuffer? _tick;
  web.AudioBuffer? _chime;

  web.AudioContext get _audio => _context ??= web.AudioContext();

  @override
  void unlock() {
    try {
      final context = _audio;
      if (context.state == 'running') return;
      context.resume();
      // Safari also wants a sound to start during the touch: a silent one.
      final source = context.createBufferSource()
        ..buffer = context.createBuffer(1, 1, 22050);
      source.connect(context.destination);
      source.start();
    } on Object {
      // Without Web Audio, the wheel spins in silence.
    }
  }

  @override
  Future<void> load() async {
    final context = _audio;
    _tick = await _decode(context, 'assets/sounds/tick.wav');
    _chime = await _decode(context, 'assets/sounds/stop.wav');
  }

  Future<web.AudioBuffer> _decode(
    web.AudioContext context,
    String asset,
  ) async {
    final data = await rootBundle.load(asset);
    // Decoding takes ownership of the bytes, so hand it a copy.
    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return context.decodeAudioData(bytes.buffer.toJS).toDart;
  }

  @override
  void tick(double volume) => _play(_tick, volume);

  @override
  void chime() => _play(_chime, 1);

  void _play(web.AudioBuffer? buffer, double volume) {
    final context = _context;
    if (context == null || buffer == null) return;
    try {
      if (context.state == 'suspended') context.resume();
      final source = context.createBufferSource()..buffer = buffer;
      final gain = context.createGain()..gain.value = volume;
      source.connect(gain);
      gain.connect(context.destination);
      source.start();
    } on Object {
      // A missed sound is not worth interrupting the spin for.
    }
  }
}
