class NetworkMatcher {
  // Geordnet nach Spezifität — mehrteilige Ausdrücke zuerst, damit "ewe go"
  // vor "ewe" matched wenn der User den vollen Namen sagt.
  static const List<(String keyword, String networkKey)> _rules = [
    ('shell recharge', 'shell'),
    ('aral pulse', 'aral'),
    ('ewe go', 'ewe'),
    ('tesla supercharger', 'tesla'),
    ('aldi süd', 'aldi'),
    ('maingau energie', 'maingau'),
    ('shell', 'shell'),
    ('ionity', 'ionity'),
    ('enbw', 'enbw'),
    ('aral', 'aral'),
    ('ewe', 'ewe'),
    ('fastned', 'fastned'),
    ('allego', 'allego'),
    ('tesla', 'tesla'),
    ('aldi', 'aldi'),
    ('lidl', 'lidl'),
    ('rewe', 'rewe'),
    ('maingau', 'maingau'),
    ('mer', 'mer'),
  ];

  /// Extrahiert den Netzwerk-Schlüssel aus einem gesprochenen Text.
  /// Gibt null zurück wenn kein bekanntes Netzwerk erkannt wurde.
  static String? match(String spokenText) {
    final lower = spokenText.trim().toLowerCase();
    for (final (keyword, key) in _rules) {
      if (lower.contains(keyword)) return key;
    }
    return null;
  }
}
