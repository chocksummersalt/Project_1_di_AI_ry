import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/openai_service.dart';
import 'services/google_service.dart';
import 'viewmodels/emotion_viewmodel.dart';
import 'views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OpenAIService>(
          create: (_) => OpenAIService(
            apiKey: 'YOUR_OPENAI_API_KEY', // Replace with your OpenAI API key
          ),
        ),
        Provider<GoogleService>(
          create: (_) => GoogleService(),
        ),
        ChangeNotifierProxyProvider2<OpenAIService, GoogleService, EmotionViewModel>(
          create: (context) => EmotionViewModel(
            openAIService: context.read<OpenAIService>(),
            googleService: context.read<GoogleService>(),
          ),
          update: (context, openAIService, googleService, previous) => EmotionViewModel(
            openAIService: openAIService,
            googleService: googleService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Emotion Analyzer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeView(),
      ),
    );
  }
}
