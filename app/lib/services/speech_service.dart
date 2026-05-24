import 'package:speech_to_text/speech_to_text.dart';
import 'network_matcher.dart';

typedef NetworkCallback = void Function(String networkKey);
typedef ErrorCallback = void Function(String message);

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize({ErrorCallback? onError}) async {
    _initialized = await _stt.initialize(
      onError: (error) => onError?.call(error.errorMsg),
    );
    return _initialized;
  }

  bool get isListening => _stt.isListening;

  /// Startet Spracherkennung auf Deutsch.
  /// [onNetwork] wird mit dem erkannten Netzwerk-Schlüssel aufgerufen
  /// sobald ein finales Ergebnis vorliegt.
  /// [onPartial] erhält Zwischenergebnisse für UI-Feedback (optional).
  Future<void> listen({
    required NetworkCallback onNetwork,
    void Function(String partial)? onPartial,
    ErrorCallback? onError,
  }) async {
    if (!_initialized) {
      final ok = await initialize(onError: onError);
      if (!ok) {
        onError?.call('Mikrofon nicht verfügbar');
        return;
      }
    }

    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'de_DE',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        final words = result.recognizedWords;
        onPartial?.call(words);

        if (result.finalResult) {
          final key = NetworkMatcher.match(words);
          if (key != null) {
            onNetwork(key);
          } else {
            onError?.call('Netzwerk nicht erkannt: "$words"');
          }
        }
      },
    );
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
