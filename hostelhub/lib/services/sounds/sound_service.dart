import 'package:audioplayers/audioplayers.dart';

/// App sound effects. Bundled as tiny generated WAVs so no network is needed.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();

  /// Piercing triple-beep for SOS (high alert).
  static Future<void> playSosAlert() =>
      _player.play(AssetSource('sounds/sos_alert.wav'));

  /// Soft chime for a new notice.
  static Future<void> playNotice() =>
      _player.play(AssetSource('sounds/notice.wav'));

  /// Light haptic tap for general actions.
  static Future<void> playNoticeOnce() async {
    await _player.stop();
    await playNotice();
  }
}
