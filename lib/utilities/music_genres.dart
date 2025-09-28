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

import 'package:musify/models/music_genre.dart';

// Danh sách các thể loại nhạc phổ biến
final List<MusicGenre> availableMusicGenres = [
  MusicGenre(
    id: 'pop',
    name: 'Pop',
    description: 'Nhạc đại chúng, phổ biến toàn cầu',
    iconUrl: 'https://example.com/icons/pop.png',
  ),
  MusicGenre(
    id: 'rock',
    name: 'Rock',
    description: 'Nhạc rock với guitar và trống nổi bật',
    iconUrl: 'https://example.com/icons/rock.png',
  ),
  MusicGenre(
    id: 'hip_hop',
    name: 'Hip Hop',
    description: 'Rap và nhạc urban',
    iconUrl: 'https://example.com/icons/hiphop.png',
  ),
  MusicGenre(
    id: 'rnb',
    name: 'R&B',
    description: 'Rhythm and Blues hiện đại',
    iconUrl: 'https://example.com/icons/rnb.png',
  ),
  MusicGenre(
    id: 'electronic',
    name: 'Electronic',
    description: 'EDM, house, techno và các thể loại nhạc điện tử',
    iconUrl: 'https://example.com/icons/electronic.png',
  ),
  MusicGenre(
    id: 'jazz',
    name: 'Jazz',
    description: 'Nhạc jazz truyền thống và hiện đại',
    iconUrl: 'https://example.com/icons/jazz.png',
  ),
  MusicGenre(
    id: 'classical',
    name: 'Classical',
    description: 'Nhạc cổ điển từ các nhà soạn nhạc nổi tiếng',
    iconUrl: 'https://example.com/icons/classical.png',
  ),
  MusicGenre(
    id: 'country',
    name: 'Country',
    description: 'Nhạc đồng quê Mỹ',
    iconUrl: 'https://example.com/icons/country.png',
  ),
  MusicGenre(
    id: 'folk',
    name: 'Folk',
    description: 'Nhạc dân gian truyền thống và hiện đại',
    iconUrl: 'https://example.com/icons/folk.png',
  ),
  MusicGenre(
    id: 'indie',
    name: 'Indie',
    description: 'Nhạc độc lập, alternative',
    iconUrl: 'https://example.com/icons/indie.png',
  ),
  MusicGenre(
    id: 'metal',
    name: 'Metal',
    description: 'Heavy metal và các thể loại phái sinh',
    iconUrl: 'https://example.com/icons/metal.png',
  ),
  MusicGenre(
    id: 'blues',
    name: 'Blues',
    description: 'Nhạc blues truyền thống',
    iconUrl: 'https://example.com/icons/blues.png',
  ),
  MusicGenre(
    id: 'reggae',
    name: 'Reggae',
    description: 'Nhạc reggae Jamaica',
    iconUrl: 'https://example.com/icons/reggae.png',
  ),
  MusicGenre(
    id: 'funk',
    name: 'Funk',
    description: 'Nhạc funk với bass và tiết tấu nổi bật',
    iconUrl: 'https://example.com/icons/funk.png',
  ),
  MusicGenre(
    id: 'soul',
    name: 'Soul',
    description: 'Nhạc soul với vocal nổi bật',
    iconUrl: 'https://example.com/icons/soul.png',
  ),
  MusicGenre(
    id: 'kpop',
    name: 'K-Pop',
    description: 'Nhạc pop Hàn Quốc',
    iconUrl: 'https://example.com/icons/kpop.png',
  ),
  MusicGenre(
    id: 'jpop',
    name: 'J-Pop',
    description: 'Nhạc pop Nhật Bản',
    iconUrl: 'https://example.com/icons/jpop.png',
  ),
  MusicGenre(
    id: 'latin',
    name: 'Latin',
    description: 'Nhạc Latin với nhiều phong cách như reggaeton, salsa',
    iconUrl: 'https://example.com/icons/latin.png',
  ),
  MusicGenre(
    id: 'ambient',
    name: 'Ambient',
    description: 'Nhạc môi trường, thư giãn',
    iconUrl: 'https://example.com/icons/ambient.png',
  ),
  MusicGenre(
    id: 'lofi',
    name: 'Lo-fi',
    description: 'Nhạc lo-fi hip hop, nhạc học tập và thư giãn',
    iconUrl: 'https://example.com/icons/lofi.png',
  ),
];

// Hàm lấy thể loại nhạc theo ID
MusicGenre? getGenreById(String id) {
  try {
    return availableMusicGenres.firstWhere((genre) => genre.id == id);
  } catch (e) {
    return null;
  }
}

// Hàm lấy danh sách thể loại nhạc theo danh sách ID
List<MusicGenre> getGenresByIds(List<String> ids) {
  return availableMusicGenres
      .where((genre) => ids.contains(genre.id))
      .toList();
}

// Hàm chuyển đổi danh sách thể loại nhạc thành danh sách ID
List<String> genresToIds(List<MusicGenre> genres) {
  return genres.map((genre) => genre.id).toList();
}
