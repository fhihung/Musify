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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/main.dart';
import 'package:musify/services/auth_service.dart';
import 'package:pocketbase/pocketbase.dart';

class CloudBackupResult {
  CloudBackupResult({required this.success, this.error, this.message});
  final bool success;
  final String? error;
  final String? message;
}

class CloudBackupService {
  static PocketBase get _pb => AuthService.pb;

  static Future<CloudBackupResult> backupToCloud() async {
    try {
      if (!AuthService.isAuthenticated) {
        return CloudBackupResult(
          success: false,
          error: 'Người dùng chưa đăng nhập'
        );
      }

      final backupData = await _collectBackupData();

      final record = {
        'user_id': AuthService.userId,
        'backup_data': jsonEncode(backupData),
        'backup_version': '1.0',
        'app_version': '9.6.2',
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        final existingBackups = await _pb.collection('user_backups').getList(
          filter: 'user_id = "${AuthService.userId}"',
          sort: '-created',
        );

        if (existingBackups.items.isNotEmpty) {
          await _pb.collection('user_backups').update(
            existingBackups.items.first.id,
            body: record,
          );
        } else {
          await _pb.collection('user_backups').create(body: record);
        }
      } catch (e) {
        await _pb.collection('user_backups').create(body: record);
      }

      return CloudBackupResult(
        success: true,
        message: 'Sao lưu đám mây thành công!'
      );
    } catch (e, stackTrace) {
      logger.log('Cloud backup failed', e, stackTrace);
      return CloudBackupResult(
        success: false,
        error: 'Sao lưu thất bại: ${e.toString()}'
      );
    }
  }

  static Future<CloudBackupResult> restoreFromCloud() async {
    try {
      if (!AuthService.isAuthenticated) {
        return CloudBackupResult(
          success: false,
          error: 'Người dùng chưa đăng nhập'
        );
      }

      final backups = await _pb.collection('user_backups').getList(
        filter: 'user_id = "${AuthService.userId}"',
        sort: '-created',
        perPage: 1,
      );

      if (backups.items.isEmpty) {
        return CloudBackupResult(
          success: false,
          error: 'Không tìm thấy bản sao lưu'
        );
      }

      final backupRecord = backups.items.first;
      final backupDataRaw = backupRecord.data['backup_data'];

      logger.log('Backup data type: ${backupDataRaw.runtimeType}', null, null);
      logger.log('Backup data: $backupDataRaw', null, null);

      Map<String, dynamic> backupData;
      if (backupDataRaw is String) {
        backupData = jsonDecode(backupDataRaw) as Map<String, dynamic>;
      } else if (backupDataRaw is Map<String, dynamic>) {
        backupData = backupDataRaw;
      } else {
        logger.log('Unknown backup data type: ${backupDataRaw.runtimeType}', null, null);
        throw Exception('Invalid backup data format: ${backupDataRaw.runtimeType}');
      }

      await _restoreBackupData(backupData);

      return CloudBackupResult(
        success: true,
        message: 'Khôi phục dữ liệu thành công!'
      );
    } catch (e, stackTrace) {
      logger.log('Cloud restore failed', e, stackTrace);
      return CloudBackupResult(
        success: false,
        error: 'Khôi phục thất bại: ${e.toString()}'
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      if (!AuthService.isAuthenticated) {
        return [];
      }

      final backups = await _pb.collection('user_backups').getList(
        filter: 'user_id = "${AuthService.userId}"',
        sort: '-created',
        perPage: 10,
      );

      return backups.items.map((item) {
        return {
          'id': item.id,
          'created_at': item.data['created_at'],
          'app_version': item.data['app_version'],
          'backup_version': item.data['backup_version'],
        };
      }).toList();
    } catch (e, stackTrace) {
      logger.log('Failed to get backup history', e, stackTrace);
      return [];
    }
  }

  static Future<Map<String, dynamic>> _collectBackupData() async {
    final backupData = <String, dynamic>{};
    final boxNames = ['user', 'settings'];

    for (final boxName in boxNames) {
      try {
        final box = await _openBox(boxName);
        final boxData = <String, dynamic>{};

        for (final key in box.keys) {
          final value = box.get(key);
          if (value != null) {
            boxData[key.toString()] = value;
          }
        }

        backupData[boxName] = boxData;
      } catch (e) {
        logger.log('Failed to collect data from box $boxName', e, null);
      }
    }

    // Add playlist data from current runtime state
    try {
      backupData['playlists'] = await _collectPlaylistData();
    } catch (e) {
      logger.log('Failed to collect playlist data', e, null);
    }

    // Add metadata
    backupData['metadata'] = {
      'timestamp': DateTime.now().toIso8601String(),
      'deviceInfo': await _getDeviceInfo(),
      'appVersion': '9.6.2',
      'backupVersion': '2.0',
    };

    return backupData;
  }

  static Future<Map<String, dynamic>> _collectPlaylistData() async {
    try {
      final userBox = await _openBox('user');
      final userNoBackupBox = await _openBox('userNoBackup');

      // Get all user music data from both boxes
      final playlistData = {
        'customPlaylists': userBox.get('customPlaylists', defaultValue: []),
        'likedSongs': userBox.get('likedSongs', defaultValue: []),
        'likedPlaylists': userBox.get('likedPlaylists', defaultValue: []),
        'userPlaylists': userBox.get('userPlaylists', defaultValue: []),
        'recentlyPlayedSongs': userBox.get('recentlyPlayedSongs', defaultValue: []),
        'mostPlayedSongs': userBox.get('mostPlayedSongs', defaultValue: []),
        // Offline songs are stored in userNoBackup box
        'offlineSongs': userNoBackupBox.get('offlineSongs', defaultValue: []),
        'downloadedSongs': userBox.get('downloadedSongs', defaultValue: []),
      };

      // Log backup statistics
      int totalItems = 0;
      playlistData.forEach((key, value) {
        if (value is List) {
          totalItems += value.length;
          logger.log('$key: ${value.length} items', null, null);
        }
      });

      logger.log('Total music items to backup: $totalItems', null, null);
      return playlistData;
    } catch (e) {
      logger.log('Error collecting playlist data', e, null);
      return {};
    }
  }

  static Future<Map<String, String>> _getDeviceInfo() async {
    try {
      return {
        'platform': 'flutter',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'platform': 'unknown'};
    }
  }

  static Future<void> _restoreBackupData(Map<String, dynamic> backupData) async {
    final boxNames = ['user', 'settings'];

    // Restore standard box data
    for (final boxName in boxNames) {
      if (!backupData.containsKey(boxName)) continue;

      try {
        final box = await _openBox(boxName);
        await box.clear();

        final boxData = backupData[boxName] as Map<String, dynamic>;
        for (final entry in boxData.entries) {
          await box.put(entry.key, entry.value);
        }
      } catch (e) {
        logger.log('Failed to restore data to box $boxName', e, null);
      }
    }

    // Restore playlist data if available
    if (backupData.containsKey('playlists')) {
      await _restorePlaylistData(backupData['playlists'] as Map<String, dynamic>);
    }

    // Log restore metadata if available
    if (backupData.containsKey('metadata')) {
      final metadata = backupData['metadata'] as Map<String, dynamic>;
      logger.log('Restored backup from ${metadata['timestamp']} (version: ${metadata['backupVersion']})', null, null);
    }
  }

  static Future<void> _restorePlaylistData(Map<String, dynamic> playlistData) async {
    try {
      final userBox = await _openBox('user');
      final userNoBackupBox = await _openBox('userNoBackup');

      // Map backup keys to storage keys for user box
      final userBoxMapping = {
        'customPlaylists': 'customPlaylists',
        'likedSongs': 'likedSongs',
        'likedPlaylists': 'likedPlaylists',
        'userPlaylists': 'userPlaylists',
        'recentlyPlayedSongs': 'recentlyPlayedSongs',
        'mostPlayedSongs': 'mostPlayedSongs',
        'downloadedSongs': 'downloadedSongs',
      };

      // Restore data to userNoBackup box
      final userNoBackupTypes = [
        'offlineSongs',
      ];

      int restoredCount = 0;

      // Restore to user box
      for (final entry in userBoxMapping.entries) {
        final backupKey = entry.key;
        final storageKey = entry.value;

        if (playlistData.containsKey(backupKey)) {
          await userBox.put(storageKey, playlistData[backupKey]);

          if (playlistData[backupKey] is List) {
            final count = (playlistData[backupKey] as List).length;
            restoredCount += count;
            logger.log('Restored $count items for $backupKey to user box', null, null);
          }
        }
      }

      // Restore to userNoBackup box
      for (final type in userNoBackupTypes) {
        if (playlistData.containsKey(type)) {
          await userNoBackupBox.put(type, playlistData[type]);

          if (playlistData[type] is List) {
            final count = (playlistData[type] as List).length;
            restoredCount += count;
            logger.log('Restored $count items for $type to userNoBackup box', null, null);
          }
        }
      }

      // Update runtime variables for all restored data
      await _updateRuntimePlaylists(playlistData);

      logger.log('Successfully restored $restoredCount playlist items', null, null);
    } catch (e) {
      logger.log('Failed to restore playlist data', e, null);
    }
  }

  static Future<void> _updateRuntimePlaylists(Map<String, dynamic> playlistData) async {
    try {
      int updatedCount = 0;

      // Update custom playlists
      if (playlistData.containsKey('customPlaylists')) {
        final customPlaylists = playlistData['customPlaylists'];
        if (customPlaylists is List) {
          userCustomPlaylists.value = List.from(customPlaylists);
          updatedCount += customPlaylists.length;
          logger.log('Updated runtime custom playlists: ${customPlaylists.length}', null, null);
        }
      }

      // Update user playlists if available
      if (playlistData.containsKey('userPlaylists')) {
        final userPlaylistsData = playlistData['userPlaylists'];
        if (userPlaylistsData is List) {
          userPlaylists.value = List.from(userPlaylistsData);
          updatedCount += userPlaylistsData.length;
          logger.log('Updated runtime user playlists: ${userPlaylistsData.length}', null, null);
        }
      }

      // Update liked songs list and counter
      if (playlistData.containsKey('likedSongs')) {
        final likedSongs = playlistData['likedSongs'];
        if (likedSongs is List) {
          userLikedSongsList.clear();
          userLikedSongsList.addAll(List.from(likedSongs));
          currentLikedSongsLength.value = likedSongs.length;
          updatedCount += likedSongs.length;
          logger.log('Updated liked songs list: ${likedSongs.length}', null, null);
        }
      }

      // Update offline songs list and counter
      if (playlistData.containsKey('offlineSongs')) {
        final offlineSongs = playlistData['offlineSongs'];
        if (offlineSongs is List) {
          userOfflineSongs.clear();
          userOfflineSongs.addAll(List.from(offlineSongs));
          currentOfflineSongsLength.value = offlineSongs.length;
          updatedCount += offlineSongs.length;
          logger.log('Updated offline songs list: ${offlineSongs.length}', null, null);
        }
      }

      // Update recently played songs list and counter
      if (playlistData.containsKey('recentlyPlayedSongs')) {
        final recentSongs = playlistData['recentlyPlayedSongs'];
        if (recentSongs is List) {
          userRecentlyPlayed.clear();
          userRecentlyPlayed.addAll(List.from(recentSongs));
          currentRecentlyPlayedLength.value = recentSongs.length;
          updatedCount += recentSongs.length;
          logger.log('Updated recently played list: ${recentSongs.length}', null, null);
        }
      }

      // Update liked playlists counter
      if (playlistData.containsKey('likedPlaylists')) {
        final likedPlaylists = playlistData['likedPlaylists'];
        if (likedPlaylists is List) {
          currentLikedPlaylistsLength.value = likedPlaylists.length;
          logger.log('Updated liked playlists count: ${likedPlaylists.length}', null, null);
        }
      }

      logger.log('Successfully updated $updatedCount runtime playlist items', null, null);
    } catch (e) {
      logger.log('Could not update runtime playlists', e, null);
    }
  }

  static Future<Box> _openBox(String category) async {
    if (Hive.isBoxOpen(category)) {
      return Hive.box(category);
    } else {
      return Hive.openBox(category);
    }
  }

  static Future<CloudBackupResult> deleteCloudBackup() async {
    try {
      if (!AuthService.isAuthenticated) {
        return CloudBackupResult(
          success: false,
          error: 'Người dùng chưa đăng nhập'
        );
      }

      final backups = await _pb.collection('user_backups').getList(
        filter: 'user_id = "${AuthService.userId}"',
      );

      for (final backup in backups.items) {
        await _pb.collection('user_backups').delete(backup.id);
      }

      return CloudBackupResult(
        success: true,
        message: 'Xóa sao lưu đám mây thành công!'
      );
    } catch (e, stackTrace) {
      logger.log('Failed to delete cloud backup', e, stackTrace);
      return CloudBackupResult(
        success: false,
        error: 'Xóa sao lưu thất bại: ${e.toString()}'
      );
    }
  }
}