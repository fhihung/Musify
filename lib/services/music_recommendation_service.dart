/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/models/music_genre.dart';
import 'package:musify/services/auth_service.dart';
import 'package:musify/utilities/music_genres.dart';

class MusicRecommendationService {
  // Singleton instance
  static final MusicRecommendationService _instance = 
      MusicRecommendationService._internal();

  factory MusicRecommendationService() {
    return _instance;
  }

  MusicRecommendationService._internal();

  // Danh sách các từ khóa tìm kiếm cho mỗi thể loại
  static final Map<String, List<String>> _genreSearchTerms = {
    'pop': ['pop hits', 'top pop songs', 'popular music', 'pop music'],
    'rock': ['rock hits', 'classic rock', 'rock music', 'rock anthems'],
    'hip_hop': ['hip hop hits', 'rap songs', 'hip hop music', 'urban beats'],
    'rnb': ['r&b hits', 'soul music', 'rhythm and blues', 'r&b jams'],
    'electronic': ['edm hits', 'electronic music', 'dance music', 'house music'],
    'jazz': ['jazz classics', 'jazz hits', 'smooth jazz', 'jazz standards'],
    'classical': ['classical music', 'piano classics', 'orchestra music'],
    'country': ['country hits', 'country music', 'country songs'],
    'folk': ['folk music', 'acoustic folk', 'folk songs', 'traditional folk'],
    'indie': ['indie hits', 'alternative music', 'indie rock', 'indie pop'],
    'metal': ['metal hits', 'heavy metal', 'metal music', 'rock metal'],
    'blues': ['blues classics', 'blues music', 'blues hits'],
    'reggae': ['reggae hits', 'reggae music', 'reggae classics'],
    'funk': ['funk hits', 'funk classics', 'funk music'],
    'soul': ['soul music', 'soul classics', 'soul hits'],
    'kpop': ['kpop hits', 'korean pop', 'kpop songs'],
    'jpop': ['jpop hits', 'japanese pop', 'anime songs'],
    'latin': ['latin hits', 'reggaeton', 'latin pop', 'salsa music'],
    'ambient': ['ambient music', 'chill music', 'relaxing sounds'],
    'lofi': ['lofi beats', 'lofi hip hop', 'study music', 'chill beats'],
  };

  // Lấy các gợi ý nhạc dựa trên thể loại ưa thích
  Future<List<dynamic>> getRecommendedSongs() async {
    try {
      final userPrefs = await AuthService.getUserMusicPreferences();
      
      // Nếu không có thể loại ưa thích, trả về danh sách trống
      if (userPrefs == null || userPrefs.favoriteGenres.isEmpty) {
        return [];
      }

      // Lấy ngẫu nhiên một thể loại từ danh sách ưa thích
      final random = Random();
      final randomGenre = userPrefs.favoriteGenres[
        random.nextInt(userPrefs.favoriteGenres.length)
      ];
      
      // Lấy danh sách từ khóa tìm kiếm cho thể loại đó
      final searchTerms = _genreSearchTerms[randomGenre.id] ?? 
          ['${randomGenre.name} music', '${randomGenre.name} hits'];
      
      // Chọn ngẫu nhiên một từ khóa tìm kiếm
      final searchQuery = searchTerms[random.nextInt(searchTerms.length)];
      
      // Tìm kiếm bài hát với từ khóa đã chọn
      final songs = await fetchSongsList(searchQuery);
      
      return songs;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recommended songs: $e');
      }
      return [];
    }
  }

  // Lấy các thể loại nhạc ưa thích của người dùng
  Future<List<MusicGenre>> getUserFavoriteGenres() async {
    final userPrefs = await AuthService.getUserMusicPreferences();
    if (userPrefs == null) {
      return [];
    }
    return userPrefs.favoriteGenres;
  }

  // Kiểm tra xem người dùng đã thiết lập thể loại ưa thích chưa
  Future<bool> hasUserSetPreferences() async {
    final userPrefs = await AuthService.getUserMusicPreferences();
    return userPrefs != null && userPrefs.favoriteGenres.isNotEmpty;
  }
}
