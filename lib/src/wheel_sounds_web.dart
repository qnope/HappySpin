import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'wheel_sounds.dart';

/// Plays the sounds with the Web Audio API, which starts them right away
/// where an audio element would lag behind the pegs.
class PlatformWheelSounds implements WheelSounds {
  PlatformWheelSounds({required this._enabled}) {
    // Safari only lets a page start its sounds while it handles a touch or
    // a click, so the first one gets the audio ready, before the app even
    // hears about it.
    for (final type in ['touchend', 'pointerup', 'click', 'keydown']) {
      web.document.addEventListener(type, _onUserGesture, true.toJS);
    }
  }

  final bool Function() _enabled;

  late final JSFunction _onUserGesture = ((web.Event _) {
    if (_enabled() && _context == null) _start(_audio);
  }).toJS;

  web.AudioContext? _context;
  web.AudioBuffer? _tick;
  web.AudioBuffer? _chime;

  /// Gives the audio back to the user's music once the wheel has stopped.
  Timer? _release;

  web.AudioContext get _audio => _context ??= web.AudioContext();

  /// Called from the tap that spins the wheel.
  @override
  void unlock() {
    _release?.cancel();
    _setSessionType('playback');
    _start(_audio);
  }

  void _start(web.AudioContext context) {
    try {
      if (context.state != 'running') context.resume();
      // Safari also wants a sound to start during the touch: a silent one.
      final source = context.createBufferSource()
        ..buffer = context.createBuffer(1, 1, 22050);
      source.connect(context.destination);
      source.start();
    } on Object {
      // Without Web Audio, the wheel spins in silence.
    }
  }

  /// On iPhone, Web Audio is mixed in like a game's background sound and can
  /// stay inaudible where a video would be heard. The "playback" audio
  /// session (iOS 17 and later) makes the wheel's sounds play like media,
  /// but like a video it pauses the user's music, so the wheel only holds it
  /// while it spins and goes back to "auto" once it has stopped.
  void _setSessionType(String type) {
    try {
      final navigator = web.window.navigator as JSObject;
      if (navigator.has('audioSession')) {
        (navigator['audioSession'] as JSObject)['type'] = type.toJS;
      }
    } on Object {
      // Older browsers have no audio session to choose.
    }
  }

  /// Once the chime has rung out, stops the audio so that the music the
  /// spin paused can play again.
  void _releaseAfter(Duration delay) {
    _release?.cancel();
    _release = Timer(delay, () {
      try {
        _context?.suspend();
      } on Object {
        // The audio stays on; the music just does not come back by itself.
      }
      _setSessionType('auto');
    });
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
  void chime() {
    _play(_chime, 1);
    final seconds = _chime?.duration ?? 0;
    _releaseAfter(Duration(milliseconds: (seconds * 1000).round() + 300));
  }

  void _play(web.AudioBuffer? buffer, double volume) {
    final context = _context;
    if (context == null || buffer == null) return;
    try {
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
