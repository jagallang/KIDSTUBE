import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'core/service_locator.dart';
import 'providers/video_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/recommendation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await initializeServices();
  
  runApp(const KidsTubeApp());
}

class KidsTubeApp extends StatelessWidget {
  const KidsTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChannelProvider>(
          create: (_) => ProviderFactory.createChannelProvider(),
        ),
        ChangeNotifierProvider<RecommendationProvider>(
          create: (_) => ProviderFactory.createRecommendationProvider(),
        ),
        ChangeNotifierProxyProvider<ChannelProvider, VideoProvider>(
          create: (_) => ProviderFactory.createVideoProvider(),
          update: (_, channelProvider, videoProvider) {
            videoProvider?.setChannelProvider(channelProvider);
            return videoProvider ?? ProviderFactory.createVideoProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'KidsTube',
        theme: ThemeData(
          primarySwatch: Colors.red,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/splash': (context) => const SplashScreen(),
        },
      ),
    );
  }
}