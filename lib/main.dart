import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'screens/main_screen.dart';
import 'services/audio_player_service.dart';
import 'services/music_repository.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Background Audio for Android (MediaStyle notification & lock screen)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.muscia.app.channel.audio',
      androidNotificationChannelName: 'Muscia Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  } catch (e) {
    debugPrint('JustAudioBackground init notice: $e');
  }

  // Initialize local storage
  final storageService = await StorageService.init();

  // Initialize music repository and audio player service
  final musicRepository = MusicRepository();
  final audioPlayerService = AudioPlayerService(musicRepository, storageService);

  runApp(
    MusciaApp(
      audioPlayerService: audioPlayerService,
      musicRepository: musicRepository,
      storageService: storageService,
    ),
  );
}

class MusciaApp extends StatelessWidget {
  final AudioPlayerService audioPlayerService;
  final MusicRepository musicRepository;
  final StorageService storageService;

  const MusciaApp({
    super.key,
    required this.audioPlayerService,
    required this.musicRepository,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(audioPlayerService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => MusicProvider(musicRepository, storageService),
        ),
      ],
      child: MaterialApp(
        title: 'Muscia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainScreen(),
      ),
    );
  }
}
