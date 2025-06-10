class FileModel {
  final String name;
  final String path;
  final int size;
  final String? response;

  FileModel({
    required this.name,
    required this.path,
    required this.size,
    this.response,
  });

  FileModel copyWith({
    String? name,
    String? path,
    int? size,
    String? response,
  }) {
    return FileModel(
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      response: response ?? this.response,
    );
  }
} 