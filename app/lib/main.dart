import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'services/backend_service.dart';
import 'services/location_service.dart';
import 'services/speech_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Statusleiste transparent, Icons hell (passt zu Dark Mode)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Nur Portrait — Fahrerkontext braucht keine Rotation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(KiaChargeNavApp(
    backendService: BackendService(
      baseUrl: dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000',
      apiKey: dotenv.env['BACKEND_API_KEY'] ?? '',
    ),
    locationService: LocationService(),
    speechService: SpeechService(),
  ));
}

class KiaChargeNavApp extends StatelessWidget {
  final BackendService backendService;
  final LocationService locationService;
  final SpeechService speechService;

  const KiaChargeNavApp({
    super.key,
    required this.backendService,
    required this.locationService,
    required this.speechService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiaChargeNav',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeScreen(
        backendService: backendService,
        locationService: locationService,
        speechService: speechService,
      ),
    );
  }
}
