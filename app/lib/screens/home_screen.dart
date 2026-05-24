import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/station.dart';
import '../services/backend_service.dart';
import '../services/location_service.dart';
import '../services/speech_service.dart';
import '../widgets/mic_button.dart';
import '../widgets/network_chip.dart';
import '../widgets/station_card.dart';

enum _State { idle, listening, processing, confirming, sendError }

// Netzwerke die als Quick-Chips angezeigt werden — häufigste DE-Autobahn-Netze
const _quickNetworks = ['shell', 'ionity', 'enbw', 'aral', 'ewe', 'fastned', 'tesla'];

class HomeScreen extends StatefulWidget {
  final BackendService backendService;
  final LocationService locationService;
  final SpeechService speechService;

  const HomeScreen({
    super.key,
    required this.backendService,
    required this.locationService,
    required this.speechService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _State _state = _State.idle;
  String _partialText = '';
  Station? _station;
  StationCardState _cardState = StationCardState.sending;
  String? _errorMessage;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    widget.speechService.cancel();
    super.dispose();
  }

  // ── Mikrofon ────────────────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    if (_state == _State.listening) {
      await widget.speechService.stop();
      _reset();
      return;
    }
    if (_state != _State.idle) return;

    setState(() {
      _state = _State.listening;
      _partialText = '';
    });

    await widget.speechService.listen(
      onPartial: (text) => setState(() => _partialText = text),
      onNetwork: (key) => _processNetwork(key),
      onError: (msg) => _showError(msg),
    );
  }

  // ── Chip-Tipp ────────────────────────────────────────────────────────────
  Future<void> _onChipTap(String networkKey) async {
    if (_state != _State.idle) return;
    await _processNetwork(networkKey);
  }

  // ── Kern-Flow: Netzwerk → Station finden → senden ────────────────────────
  Future<void> _processNetwork(String networkKey) async {
    setState(() {
      _state = _State.processing;
      _partialText = '';
    });

    GpsPosition pos;
    try {
      pos = await widget.locationService.getPosition();
    } on LocationException catch (e) {
      _showError(e.message);
      return;
    } catch (_) {
      _showError('GPS-Fehler — bitte erneut versuchen.');
      return;
    }

    Station station;
    try {
      station = await widget.backendService.findStation(
        lat: pos.lat,
        lon: pos.lon,
        heading: pos.heading,
        network: networkKey,
      );
    } on BackendException catch (e) {
      _showError(e.message);
      return;
    } catch (_) {
      _showError('Backend nicht erreichbar');
      return;
    }

    // Station gefunden — Karte anzeigen, gleichzeitig senden
    setState(() {
      _state = _State.confirming;
      _station = station;
      _cardState = StationCardState.sending;
    });

    try {
      await widget.backendService.sendToKia(station);
      if (!mounted) return;
      setState(() => _cardState = StationCardState.sent);
      _scheduleAutoDismiss(const Duration(seconds: 3));
    } on BackendException catch (e) {
      if (!mounted) return;
      setState(() {
        _cardState = StationCardState.error;
        _errorMessage = e.message;
      });
      _scheduleAutoDismiss(const Duration(seconds: 4));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cardState = StationCardState.error;
        _errorMessage = 'Verbindungsfehler — bitte erneut versuchen.';
      });
      _scheduleAutoDismiss(const Duration(seconds: 4));
    }
  }

  // ── Fehler-Anzeige ───────────────────────────────────────────────────────
  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _state = _State.sendError;
      _errorMessage = message;
    });
    _scheduleAutoDismiss(const Duration(seconds: 4));
  }

  // ── Auto-Dismiss ─────────────────────────────────────────────────────────
  void _scheduleAutoDismiss(Duration delay) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(delay, _reset);
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _state = _State.idle;
      _station = null;
      _partialText = '';
      _errorMessage = null;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMain(),
            if (_state == _State.confirming && _station != null) _buildConfirmOverlay(),
            if (_state == _State.sendError) _buildErrorToast(),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    final isListening = _state == _State.listening;
    final isProcessing = _state == _State.processing;
    final inactive = _state == _State.confirming || _state == _State.sendError;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _StatusText(state: _state, partialText: _partialText),
          const Spacer(),
          AnimatedOpacity(
            opacity: inactive ? 0.2 : 1.0,
            duration: const Duration(milliseconds: 250),
            child: MicButton(
              isListening: isListening,
              onTap: inactive ? () {} : _toggleMic,
            ),
          ),
          if (isProcessing) ...[
            const SizedBox(height: 20),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.accent),
            ),
          ],
          const Spacer(),
          _buildChipGrid(inactive),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChipGrid(bool inactive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oder Netzwerk wählen:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: inactive ? 0.2 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: _quickNetworks
                .map((key) => NetworkChip(
                      networkKey: key,
                      onTap: inactive ? () {} : () => _onChipTap(key),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: StationCard(
        station: _station!,
        cardState: _cardState,
        errorMessage: _errorMessage,
        onDismiss: _reset,
      ),
    );
  }

  Widget _buildErrorToast() {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: _reset,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1515),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.error, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Unbekannter Fehler',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final _State state;
  final String partialText;

  const _StatusText({required this.state, required this.partialText});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state) {
      _State.idle => ('Sprechen Sie ein Netzwerk …', AppTheme.textSecondary),
      _State.listening when partialText.isNotEmpty => ('"$partialText"', AppTheme.accent),
      _State.listening => ('Ich höre zu …', AppTheme.accent),
      _State.processing => ('Suche Station …', AppTheme.textSecondary),
      _State.confirming => ('', AppTheme.textSecondary),
      _State.sendError => ('', AppTheme.error),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(color: color, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }
}
