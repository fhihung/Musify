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

import 'dart:convert';

class MusicGenre {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isSelected;

  MusicGenre({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.isSelected = false,
  });

  MusicGenre copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    bool? isSelected,
  }) {
    return MusicGenre(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'isSelected': isSelected,
    };
  }

  factory MusicGenre.fromMap(Map<String, dynamic> map) {
    return MusicGenre(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      iconUrl: map['iconUrl'],
      isSelected: map['isSelected'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory MusicGenre.fromJson(String source) => 
      MusicGenre.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MusicGenre(id: $id, name: $name, description: $description, iconUrl: $iconUrl, isSelected: $isSelected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is MusicGenre &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.iconUrl == iconUrl &&
      other.isSelected == isSelected;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      iconUrl.hashCode ^
      isSelected.hashCode;
  }
}

class UserMusicPreferences {
  final List<MusicGenre> favoriteGenres;
  final DateTime lastUpdated;

  UserMusicPreferences({
    required this.favoriteGenres,
    required this.lastUpdated,
  });

  UserMusicPreferences copyWith({
    List<MusicGenre>? favoriteGenres,
    DateTime? lastUpdated,
  }) {
    return UserMusicPreferences(
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'favoriteGenres': favoriteGenres.map((x) => x.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserMusicPreferences.fromMap(Map<String, dynamic> map) {
    return UserMusicPreferences(
      favoriteGenres: List<MusicGenre>.from(
        map['favoriteGenres']?.map((x) => MusicGenre.fromMap(x)) ?? [],
      ),
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserMusicPreferences.fromJson(String source) => 
      UserMusicPreferences.fromMap(json.decode(source));

  @override
  String toString() => 'UserMusicPreferences(favoriteGenres: $favoriteGenres, lastUpdated: $lastUpdated)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserMusicPreferences &&
      other.favoriteGenres.length == favoriteGenres.length &&
      other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => favoriteGenres.hashCode ^ lastUpdated.hashCode;
}
