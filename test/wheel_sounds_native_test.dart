import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/wheel_sounds_native.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('the sounds mix with the music on ${platform.name}', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final context = PlatformWheelSounds.audioContext();

      expect(context.iOS.category, AVAudioSessionCategory.playback);
      expect(context.iOS.options, {AVAudioSessionOptions.mixWithOthers});
      expect(context.android.audioFocus, AndroidAudioFocus.none);
    });
  }
}
