import 'package:flutter/services.dart';

abstract interface class ScreenPrivacyController {
  Future<void> setSensitiveScreen(bool sensitive);
}

class MethodChannelScreenPrivacyController implements ScreenPrivacyController {
  const MethodChannelScreenPrivacyController();

  static const _channel = MethodChannel('com.pocketly/screen_privacy');

  @override
  Future<void> setSensitiveScreen(bool sensitive) async {
    try {
      await _channel.invokeMethod<void>('setSensitiveScreen', {
        'sensitive': sensitive,
      });
    } on MissingPluginException {
      // Platform yang belum memiliki adapter tetap dapat menjalankan aplikasi.
    } on PlatformException {
      // Kegagalan adapter tidak boleh merusak alur autentikasi aplikasi.
    }
  }
}
