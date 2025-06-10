import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_model.dart';
import '../services/openai_service.dart';

class FileViewModel extends ChangeNotifier {
  FileModel? _selectedFile;
  bool _isLoading = false;
  String? _error;
  final OpenAIService _openAIService = OpenAIService();

  FileModel? get selectedFile => _selectedFile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> pickAndProcessFile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = File(result.files.single.path!);
      _selectedFile = FileModel(
        name: result.files.single.name,
        path: result.files.single.path!,
        size: result.files.single.size,
      );
      notifyListeners();

      final response = await _openAIService.processFile(file);
      _selectedFile = _selectedFile!.copyWith(response: response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFile() {
    _selectedFile = null;
    _error = null;
    notifyListeners();
  }
} 