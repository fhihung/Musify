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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/models/music_genre.dart';
import 'package:musify/services/auth_service.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/music_genres.dart';

class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({
    super.key,
    this.onComplete,
    this.isFirstSetup = false,
  });

  final Function? onComplete;
  final bool isFirstSetup;

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  final List<MusicGenre> _selectedGenres = [];
  bool _isLoading = false;
  List<MusicGenre> _allGenres = [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy danh sách thể loại nhạc
      _allGenres = List.from(availableMusicGenres);
      
      // Nếu người dùng đã chọn thể loại trước đó, đánh dấu là đã chọn
      if (!widget.isFirstSetup) {
        final userPrefs = await AuthService.getUserMusicPreferences();
        if (userPrefs != null) {
          final selectedIds = userPrefs.favoriteGenres.map((g) => g.id).toList();
          
          for (int i = 0; i < _allGenres.length; i++) {
            if (selectedIds.contains(_allGenres[i].id)) {
              _selectedGenres.add(_allGenres[i]);
            }
          }
        }
      }
    } catch (e) {
      // Xử lý lỗi nếu có
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleGenre(MusicGenre genre) {
    setState(() {
      if (_selectedGenres.any((g) => g.id == genre.id)) {
        _selectedGenres.removeWhere((g) => g.id == genre.id);
      } else {
        // Giới hạn số lượng thể loại được chọn (tối đa 5)
        if (_selectedGenres.length < 5) {
          _selectedGenres.add(genre);
        } else {
          showToast(
            context,
            context.l10n?.maxGenresSelected ?? 'Bạn chỉ có thể chọn tối đa 5 thể loại',
          );
        }
      }
    });
  }

  Future<void> _saveGenres() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedIds = _selectedGenres.map((genre) => genre.id).toList();
      final result = await AuthService.updateUserMusicPreferences(selectedIds);

      if (result.success) {
        // Xóa flag cần chọn thể loại sau khi lưu thành công
        await AuthService.clearGenreSelectionFlag();
        
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          if (widget.isFirstSetup) {
            // Nếu là lần đầu thiết lập, chuyển đến trang chính
            GoRouter.of(context).go('/home');
          } else {
            // Nếu không, quay lại trang trước
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        }
        
        if (context.mounted) {
          showToast(
            context, 
            context.l10n?.savedSuccessfully ?? 'Đã lưu thành công!',
          );
        }
      } else {
        if (context.mounted) {
          showToast(context, result.error ?? 'Có lỗi xảy ra');
        }
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Có lỗi xảy ra khi lưu thể loại nhạc ưa thích');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n?.selectFavoriteGenres ?? 'Chọn thể loại nhạc yêu thích',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.l10n?.selectUpToFiveGenres ?? 
                        'Chọn tối đa 5 thể loại nhạc bạn yêu thích để nhận gợi ý phù hợp',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _allGenres.length,
                    itemBuilder: (context, index) {
                      final genre = _allGenres[index];
                      final isSelected = _selectedGenres.any((g) => g.id == genre.id);
                      
                      return GestureDetector(
                        onTap: () => _toggleGenre(genre),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                Text(
                                  genre.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!widget.isFirstSetup)
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.l10n?.cancel ?? 'Hủy'),
                          ),
                        ),
                      FilledButton(
                        onPressed: _selectedGenres.isNotEmpty ? _saveGenres : null,
                        child: Text(context.l10n?.save ?? 'Lưu'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
