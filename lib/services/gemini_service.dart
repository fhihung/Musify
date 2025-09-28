import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:musify/models/gemini_response.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyCyfhA318E_HwhzFzuR0k2F9U9hPaY3NzM';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  /// Lấy gợi ý nhạc dựa trên lịch sử nghe và thể loại yêu thích
  static Future<List<MusicRecommendation>> getMusicRecommendations() async {
    try {
      // Lấy danh sách nhạc vừa nghe từ local storage
      final recentlyPlayedSongs = await _getRecentlyPlayedSongs();
      
      // Lấy thể loại nhạc yêu thích từ local storage 
      final favoriteGenres = await _getFavoriteGenres();
      
      // Nếu không có dữ liệu cá nhân, sử dụng gợi ý mặc định
      if (recentlyPlayedSongs.isEmpty && favoriteGenres.isEmpty) {
        log('Không có dữ liệu cá nhân, sử dụng gợi ý mặc định');
        return _getDefaultRecommendations();
      }
      
      // Tạo prompt cho Gemini
      final prompt = _buildMusicRecommendationPrompt(recentlyPlayedSongs, favoriteGenres);
      
      // Gọi Gemini API
      final response = await _callGeminiAPI(prompt);
      
      if (response != null && response.candidates.isNotEmpty) {
        final text = response.candidates.first.content.parts.first.text;
        
        // Parse response thành danh sách MusicRecommendation
        return _parseMusicRecommendations(text);
      }
      
      return _getDefaultRecommendations();
    } catch (e) {
      log('Lỗi khi lấy gợi ý nhạc từ Gemini: $e');
      return _getDefaultRecommendations();
    }
  }
  
  /// Lấy danh sách nhạc vừa nghe từ Hive
  static Future<List<Map<String, String>>> _getRecentlyPlayedSongs() async {
    try {
      final userBox = await Hive.openBox('user');
      final recentSongs = userBox.get('recentlyPlayedSongs', defaultValue: []);
      
      if (recentSongs is List) {
        return recentSongs
            .take(10) // Lấy 10 bài gần nhất
            .map((song) {
              if (song is Map) {
                return {
                  'title': song['title']?.toString() ?? '',
                  'artist': song['artist']?.toString() ?? '',
                  'genre': song['genre']?.toString() ?? '',
                };
              }
              return <String, String>{};
            })
            .where((song) => song['title']?.isNotEmpty == true)
            .toList();
      }
      
      return [];
    } catch (e) {
      log('Lỗi khi lấy danh sách nhạc vừa nghe: $e');
      return [];
    }
  }
  
  /// Lấy thể loại nhạc yêu thích từ Hive
  static Future<List<String>> _getFavoriteGenres() async {
    try {
      final userBox = await Hive.openBox('user');
      final musicPrefsMap = userBox.get('musicPreferences');
      
      if (musicPrefsMap != null && musicPrefsMap is Map) {
        final favoriteGenres = musicPrefsMap['favoriteGenres'];
        if (favoriteGenres is List) {
          return favoriteGenres
              .map((genre) {
                if (genre is Map && genre['name'] != null) {
                  return genre['name'].toString();
                }
                return '';
              })
              .where((name) => name.isNotEmpty)
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      log('Lỗi khi lấy thể loại nhạc yêu thích: $e');
      return [];
    }
  }
  
  /// Tạo prompt cho Gemini API
  static String _buildMusicRecommendationPrompt(
    List<Map<String, String>> recentSongs,
    List<String> favoriteGenres,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Bạn là một chuyên gia tư vấn âm nhạc. Hãy gợi ý 10 bài hát dựa trên thông tin sau:');
    buffer.writeln('');
    
    if (favoriteGenres.isNotEmpty) {
      buffer.writeln('Thể loại nhạc yêu thích: ${favoriteGenres.join(", ")}');
      buffer.writeln('');
    }
    
    if (recentSongs.isNotEmpty) {
      buffer.writeln('Các bài hát đã nghe gần đây:');
      for (final song in recentSongs) {
        buffer.writeln('- "${song['title']}" by ${song['artist']}');
        if (song['genre']?.isNotEmpty == true) {
          buffer.writeln('  (Thể loại: ${song['genre']})');
        }
      }
      buffer.writeln('');
    }
    
    buffer.writeln('Yêu cầu:');
    buffer.writeln('1. Gợi ý 10 bài hát phù hợp với sở thích và lịch sử nghe nhạc');
    buffer.writeln('2. Ưu tiên các bài hát nổi tiếng, dễ tìm trên YouTube');
    buffer.writeln('3. Trả về kết quả theo định dạng JSON chính xác như sau:');
    buffer.writeln('');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "title": "Tên bài hát",');
    buffer.writeln('    "artist": "Tên nghệ sĩ",');
    buffer.writeln('    "genre": "Thể loại",');
    buffer.writeln('    "reason": "Lý do gợi ý"');
    buffer.writeln('  }');
    buffer.writeln(']');
    buffer.writeln('');
    buffer.writeln('Chỉ trả về JSON, không thêm text khác.');
    
    return buffer.toString();
  }
  
  /// Gọi Gemini API
  static Future<GeminiResponse?> _callGeminiAPI(String prompt) async {
    try {
      final headers = {
        'x-goog-api-key': _apiKey,
        'Content-Type': 'application/json',
      };
      
      final body = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      };
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return GeminiResponse.fromMap(jsonData);
      } else {
        log('Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Lỗi khi gọi Gemini API: $e');
      return null;
    }
  }
  
  /// Parse response từ Gemini thành danh sách MusicRecommendation
  static List<MusicRecommendation> _parseMusicRecommendations(String text) {
    try {
      // Tìm JSON trong text response
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']');
      
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        log('Không tìm thấy JSON hợp lệ trong response');
        return [];
      }
      
      final jsonString = text.substring(jsonStart, jsonEnd + 1);
      final jsonData = jsonDecode(jsonString) as List<dynamic>;
      
      return jsonData
          .map((item) {
            if (item is Map<String, dynamic>) {
              try {
                return MusicRecommendation.fromMap(item);
              } catch (e) {
                log('Lỗi parse item: $e');
                return null;
              }
            }
            return null;
          })
          .where((item) => item != null)
          .cast<MusicRecommendation>()
          .toList();
    } catch (e) {
      log('Lỗi parse music recommendations: $e');
      
      // Fallback: thử parse từng dòng nếu JSON không hợp lệ
      return _parseTextRecommendations(text);
    }
  }
  
  /// Parse recommendations từ text format (fallback)
  static List<MusicRecommendation> _parseTextRecommendations(String text) {
    try {
      final recommendations = <MusicRecommendation>[];
      final lines = text.split('\n');
      
      for (final line in lines) {
        // Tìm pattern: "Tên bài hát" by Nghệ sĩ
        final match = RegExp(r'"([^"]+)"\s+by\s+(.+?)(?:\s*\(|$)').firstMatch(line);
        if (match != null) {
          final title = match.group(1) ?? '';
          final artist = match.group(2) ?? '';
          
          if (title.isNotEmpty && artist.isNotEmpty) {
            recommendations.add(MusicRecommendation(
              title: title.trim(),
              artist: artist.trim(),
              genre: null,
              reason: 'Gợi ý từ Gemini AI',
            ));
          }
        }
      }
      
      return recommendations;
    } catch (e) {
      log('Lỗi parse text recommendations: $e');
      return [];
    }
  }
  
  /// Lấy gợi ý nhạc mặc định khi không có dữ liệu cá nhân
  static List<MusicRecommendation> _getDefaultRecommendations() {
    return [
      MusicRecommendation(
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        genre: 'Pop',
        reason: 'Bài hát hot nhất thế giới trong những năm gần đây',
      ),
      MusicRecommendation(
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        genre: 'Pop',
        reason: 'Một trong những bài hát được yêu thích nhất mọi thời đại',
      ),
      MusicRecommendation(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        genre: 'Rock',
        reason: 'Kiệt tác rock kinh điển của Queen',
      ),
      MusicRecommendation(
        title: 'Someone Like You',
        artist: 'Adele',
        genre: 'Pop Ballad',
        reason: 'Ballad cảm động và nổi tiếng của Adele',
      ),
      MusicRecommendation(
        title: 'Imagine',
        artist: 'John Lennon',
        genre: 'Classic Rock',
        reason: 'Bài hát hòa bình nổi tiếng nhất mọi thời đại',
      ),
      MusicRecommendation(
        title: 'Billie Jean',
        artist: 'Michael Jackson',
        genre: 'Pop',
        reason: 'Siêu phẩm của ông hoàng nhạc pop Michael Jackson',
      ),
      MusicRecommendation(
        title: 'Hotel California',
        artist: 'Eagles',
        genre: 'Rock',
        reason: 'Bài hát rock kinh điển với guitar solo huyền thoại',
      ),
      MusicRecommendation(
        title: 'Yesterday',
        artist: 'The Beatles',
        genre: 'Classic Pop',
        reason: 'Tác phẩm bất hủ của The Beatles',
      ),
      MusicRecommendation(
        title: 'Thinking Out Loud',
        artist: 'Ed Sheeran',
        genre: 'Pop Romance',
        reason: 'Bài hát tình yêu ngọt ngào và lãng mạn',
      ),
      MusicRecommendation(
        title: 'Perfect',
        artist: 'Ed Sheeran',
        genre: 'Pop Romance',
        reason: 'Một trong những bài hát cưới phổ biến nhất',
      ),
    ];
  }

  /// Test method để kiểm tra kết nối Gemini API
  static Future<bool> testConnection() async {
    try {
      final response = await _callGeminiAPI('Chào bạn, hãy trả lời ngắn gọn: AI hoạt động như thế nào?');
      return response != null && response.candidates.isNotEmpty;
    } catch (e) {
      log('Lỗi test Gemini connection: $e');
      return false;
    }
  }
}
