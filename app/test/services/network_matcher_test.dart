import 'package:flutter_test/flutter_test.dart';
import 'package:kia_charge_nav/services/network_matcher.dart';

void main() {
  group('NetworkMatcher.match', () {
    test('erkennt exakte Keywords', () {
      expect(NetworkMatcher.match('shell'), 'shell');
      expect(NetworkMatcher.match('ionity'), 'ionity');
      expect(NetworkMatcher.match('enbw'), 'enbw');
      expect(NetworkMatcher.match('aral'), 'aral');
      expect(NetworkMatcher.match('tesla'), 'tesla');
    });

    test('erkennt Keywords mit führenden/nachfolgenden Leerzeichen', () {
      expect(NetworkMatcher.match('  shell  '), 'shell');
      expect(NetworkMatcher.match('\tionity\n'), 'ionity');
    });

    test('ist case-insensitiv', () {
      expect(NetworkMatcher.match('SHELL'), 'shell');
      expect(NetworkMatcher.match('Ionity'), 'ionity');
      expect(NetworkMatcher.match('EnBW'), 'enbw');
    });

    test('erkennt Netzwerk als Teil eines längeren Satzes', () {
      expect(NetworkMatcher.match('fahre zur shell station'), 'shell');
      expect(NetworkMatcher.match('nächste ionity bitte'), 'ionity');
    });

    test('erkennt mehrteilige Netzwerknamen', () {
      expect(NetworkMatcher.match('ewe go'), 'ewe');
      expect(NetworkMatcher.match('tesla supercharger'), 'tesla');
    });

    test('gibt null zurück wenn kein Netzwerk erkannt', () {
      expect(NetworkMatcher.match('guten morgen'), isNull);
      expect(NetworkMatcher.match(''), isNull);
      expect(NetworkMatcher.match('starbucks'), isNull);
    });
  });
}
