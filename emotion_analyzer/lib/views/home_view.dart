import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/emotion_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Analyzer'),
        actions: [
          Consumer<EmotionViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: viewModel.signOut,
              );
            },
          ),
        ],
      ),
      body: Consumer<EmotionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Text(
                viewModel.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: viewModel.signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: viewModel.pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload TXT File'),
                ),
                if (viewModel.selectedFilePath != null) ...[
                  const SizedBox(height: 16),
                  Text('Selected file: ${viewModel.selectedFilePath}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.analyzeText,
                    child: const Text('Analyze Emotion'),
                  ),
                ],
                if (viewModel.analysisResult != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emotion: ${viewModel.analysisResult!.emotion}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confidence: ${(viewModel.analysisResult!.confidence * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (viewModel.takeoutFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Google Takeout Files:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.takeoutFiles.length,
                    itemBuilder: (context, index) {
                      final file = viewModel.takeoutFiles[index];
                      return ListTile(
                        title: Text(file['name']),
                        subtitle: Text('Size: ${file['size']} bytes'),
                        leading: const Icon(Icons.archive),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
} 