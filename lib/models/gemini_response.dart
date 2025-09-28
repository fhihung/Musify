class GeminiResponse {
  final List<GeminiCandidate> candidates;
  final GeminiUsageMetadata? usageMetadata;
  final String? modelVersion;

  GeminiResponse({
    required this.candidates,
    this.usageMetadata,
    this.modelVersion,
  });

  factory GeminiResponse.fromMap(Map<String, dynamic> map) {
    return GeminiResponse(
      candidates: (map['candidates'] as List<dynamic>)
          .map((e) => GeminiCandidate.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      usageMetadata: map['usageMetadata'] != null
          ? GeminiUsageMetadata.fromMap(Map<String, dynamic>.from(map['usageMetadata']))
          : null,
      modelVersion: map['modelVersion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'candidates': candidates.map((e) => e.toMap()).toList(),
      'usageMetadata': usageMetadata?.toMap(),
      'modelVersion': modelVersion,
    };
  }
}

class GeminiCandidate {
  final GeminiContent content;
  final String finishReason;
  final int index;
  final List<GeminiSafetyRating>? safetyRatings;

  GeminiCandidate({
    required this.content,
    required this.finishReason,
    required this.index,
    this.safetyRatings,
  });

  factory GeminiCandidate.fromMap(Map<String, dynamic> map) {
    return GeminiCandidate(
      content: GeminiContent.fromMap(Map<String, dynamic>.from(map['content'])),
      finishReason: map['finishReason'] as String,
      index: map['index'] as int,
      safetyRatings: map['safetyRatings'] != null
          ? (map['safetyRatings'] as List<dynamic>)
              .map((e) => GeminiSafetyRating.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content.toMap(),
      'finishReason': finishReason,
      'index': index,
      'safetyRatings': safetyRatings?.map((e) => e.toMap()).toList(),
    };
  }
}

class GeminiContent {
  final List<GeminiPart> parts;
  final String? role;

  GeminiContent({
    required this.parts,
    this.role,
  });

  factory GeminiContent.fromMap(Map<String, dynamic> map) {
    return GeminiContent(
      parts: (map['parts'] as List<dynamic>)
          .map((e) => GeminiPart.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      role: map['role'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parts': parts.map((e) => e.toMap()).toList(),
      'role': role,
    };
  }
}

class GeminiPart {
  final String text;

  GeminiPart({
    required this.text,
  });

  factory GeminiPart.fromMap(Map<String, dynamic> map) {
    return GeminiPart(
      text: map['text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
    };
  }
}

class GeminiSafetyRating {
  final String category;
  final String probability;

  GeminiSafetyRating({
    required this.category,
    required this.probability,
  });

  factory GeminiSafetyRating.fromMap(Map<String, dynamic> map) {
    return GeminiSafetyRating(
      category: map['category'] as String,
      probability: map['probability'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'probability': probability,
    };
  }
}

class GeminiUsageMetadata {
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;

  GeminiUsageMetadata({
    required this.promptTokenCount,
    required this.candidatesTokenCount,
    required this.totalTokenCount,
  });

  factory GeminiUsageMetadata.fromMap(Map<String, dynamic> map) {
    return GeminiUsageMetadata(
      promptTokenCount: map['promptTokenCount'] as int,
      candidatesTokenCount: map['candidatesTokenCount'] as int,
      totalTokenCount: map['totalTokenCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'promptTokenCount': promptTokenCount,
      'candidatesTokenCount': candidatesTokenCount,
      'totalTokenCount': totalTokenCount,
    };
  }
}

// Model cho music recommendation từ Gemini
class MusicRecommendation {
  final String title;
  final String artist;
  final String? genre;
  final String? reason;

  MusicRecommendation({
    required this.title,
    required this.artist,
    this.genre,
    this.reason,
  });

  factory MusicRecommendation.fromMap(Map<String, dynamic> map) {
    return MusicRecommendation(
      title: map['title'] as String,
      artist: map['artist'] as String,
      genre: map['genre'] as String?,
      reason: map['reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'genre': genre,
      'reason': reason,
    };
  }
}
