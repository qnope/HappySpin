import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'wheel_haptics.dart';

/// Vibrates the phone from the browser.
///
/// Android browsers offer the Vibration API. Safari on iPhone does not, but
/// since iOS 18 toggling a switch gives a light haptic tap, so a hidden
/// switch is toggled instead; older iPhones stay still.
class PlatformWheelHaptics implements WheelHaptics {
  final bool _canVibrate = web.window.navigator.has('vibrate');
  web.HTMLLabelElement? _switch;

  @override
  void tick() => _canVibrate ? _vibrate(15.toJS) : _tapSwitch();

  @override
  void stop() =>
      _canVibrate ? _vibrate([40.toJS, 60.toJS, 40.toJS].toJS) : _tapSwitch();

  void _vibrate(JSAny pattern) {
    try {
      web.window.navigator.vibrate(pattern);
    } on Object {
      // Vibrating is a bonus, never worth interrupting the spin for.
    }
  }

  void _tapSwitch() {
    try {
      (_switch ??= _createSwitch()).click();
    } on Object {
      // Vibrating is a bonus, never worth interrupting the spin for.
    }
  }

  web.HTMLLabelElement _createSwitch() {
    final input = web.HTMLInputElement()
      ..type = 'checkbox'
      ..tabIndex = -1
      ..setAttribute('switch', '');
    final label = web.HTMLLabelElement()
      ..setAttribute('aria-hidden', 'true')
      ..style.cssText =
          'position:fixed;left:0;top:0;width:1px;height:1px;'
          'opacity:0;overflow:hidden;pointer-events:none;'
      ..append(input);
    web.document.body!.append(label);
    return label;
  }
}
