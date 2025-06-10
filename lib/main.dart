import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodels/file_viewmodel.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileViewModel(),
      child: const CupertinoApp(
        title: 'OpenAI File Uploader',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          brightness: Brightness.light,
        ),
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('OpenAI File Uploader'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Consumer<FileViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoButton.filled(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.pickAndProcessFile(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.cloud_upload),
                        const SizedBox(width: 8),
                        Text(viewModel.isLoading
                            ? 'Processing...'
                            : 'Select File'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (viewModel.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            color: CupertinoColors.systemRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.error!,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (viewModel.selectedFile != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.doc_text,
                                  color: CupertinoColors.systemBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    viewModel.selectedFile!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.info_circle,
                                  color: CupertinoColors.systemGrey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Size: ${(viewModel.selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                            if (viewModel.selectedFile!.response != null) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'OpenAI Response',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.systemBlue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  viewModel.selectedFile!.response!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: viewModel.clearFile,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(CupertinoIcons.clear_circled),
                          SizedBox(width: 8),
                          Text('Clear'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 