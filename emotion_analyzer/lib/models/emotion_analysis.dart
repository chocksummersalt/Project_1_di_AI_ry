class EmotionAnalysis {
  final String text;
  final String emotion;
  final double confidence;

  EmotionAnalysis({
    required this.text,
    required this.emotion,
    required this.confidence,
  });

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionAnalysis(
      text: json['text'] as String,
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'emotion': emotion,
      'confidence': confidence,
    };
  }
} 