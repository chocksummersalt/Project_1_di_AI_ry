import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion_analysis.dart';
import '../services/openai_service.dart';
import '../services/google_service.dart';

class EmotionViewModel extends ChangeNotifier {
  final OpenAIService _openAIService;
  final GoogleService _googleService;
  
  String? _selectedFilePath;
  String? _fileContent;
  EmotionAnalysis? _analysisResult;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _takeoutFiles = [];

  EmotionViewModel({
    required OpenAIService openAIService,
    required GoogleService googleService,
  })  : _openAIService = openAIService,
        _googleService = googleService;

  String? get selectedFilePath => _selectedFilePath;
  String? get fileContent => _fileContent;
  EmotionAnalysis? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get takeoutFiles => _takeoutFiles;

  Future<void> pickFile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        _selectedFilePath = result.files.single.path;
        final file = File(_selectedFilePath!);
        _fileContent = await file.readAsString();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error picking file: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeText() async {
    if (_fileContent == null) {
      _error = 'No file content to analyze';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _analysisResult = await _openAIService.analyzeEmotion(_fileContent!);
      notifyListeners();
    } catch (e) {
      _error = 'Error analyzing text: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final account = await _googleService.signIn();
      if (account != null) {
        await loadTakeoutFiles();
      }
    } catch (e) {
      _error = 'Error signing in with Google: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTakeoutFiles() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _takeoutFiles = await _googleService.listTakeoutFiles();
      notifyListeners();
    } catch (e) {
      _error = 'Error loading takeout files: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _googleService.signOut();
      _takeoutFiles = [];
      notifyListeners();
    } catch (e) {
      _error = 'Error signing out: $e';
      notifyListeners();
    }
  }
} 