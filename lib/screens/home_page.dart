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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/models/gemini_response.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/auth_service.dart';
import 'package:musify/services/gemini_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/announcement_box.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MusicRecommendation>? _geminiRecommendations;
  bool _isLoadingGeminiRecommendations = false;
  
  @override
  void initState() {
    super.initState();
    _loadGeminiRecommendations();
  }
  
  Future<void> _loadGeminiRecommendations() async {
    setState(() {
      _isLoadingGeminiRecommendations = true;
    });
    
    try {
      final recommendations = await GeminiService.getMusicRecommendations();
      setState(() {
        _geminiRecommendations = recommendations;
      });
    } catch (e) {
      logger.log('Error loading Gemini recommendations', e, null);
    } finally {
      setState(() {
        _isLoadingGeminiRecommendations = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musify.'),
        actions: [
          ValueListenableBuilder<AuthState>(
            valueListenable: AuthService.authState,
            builder: (context, authState, child) {
              return ValueListenableBuilder(
                valueListenable: AuthService.currentUser,
                builder: (context, user, child) {
                  if (authState == AuthState.authenticated && user != null) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            (AuthService.userName?.isNotEmpty == true
                              ? AuthService.userName![0].toUpperCase()
                              : 'U'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(FluentIcons.person_24_regular),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: announcementURL,
              builder: (_, _url, __) {
                if (_url == null) return const SizedBox.shrink();

                return AnnouncementBox(
                  message: context.l10n!.newAnnouncement,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  url: _url,
                );
              },
            ),
            _buildSuggestedPlaylists(playlistHeight),
            _buildGeminiRecommendations(),
            _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true),
            _buildRecommendedSongsSection(playlistHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(padding: EdgeInsets.all(35), child: Spinner()),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Text(
        '${context.l10n!.error}!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    final sectionTitle =
        showOnlyLiked
            ? context.l10n!.backToFavorites
            : context.l10n!.suggestedPlaylists;
    return FutureBuilder<List<dynamic>>(
      future: getPlaylists(
        playlistsNum: recommendedCubesNumber,
        onlyLiked: showOnlyLiked,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildSuggestedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _buildErrorWidget(context);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final playlists = snapshot.data ?? [];
        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        return Column(
          children: [
            SectionHeader(title: sectionTitle),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child:
                  isLargeScreen
                      ? _buildHorizontalList(
                        playlists,
                        itemsNumber,
                        playlistHeight,
                      )
                      : _buildCarouselView(
                        playlists,
                        itemsNumber,
                        playlistHeight,
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalList(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlaylistPage(playlistId: playlist['ytid']),
                  ),
                ),
            child: PlaylistCube(playlist, size: height),
          ),
        );
      },
    );
  }

  Widget _buildCarouselView(
    List<dynamic> playlists,
    int itemCount,
    double height,
  ) {
    return CarouselView.weighted(
      flexWeights: const <int>[3, 2, 1],
      itemSnapping: true,
      onTap:
          (index) => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PlaylistPage(playlistId: playlists[index]['ytid']),
            ),
          ),
      children: List.generate(itemCount, (index) {
        return PlaylistCube(playlists[index], size: height * 2);
      }),
    );
  }

  Widget _buildGeminiRecommendations() {
    // Nếu đang tải, hiển thị spinner
    if (_isLoadingGeminiRecommendations) {
      return Column(
        children: [
          SectionHeader(title: 'Gợi ý từ AI'),
          _buildLoadingWidget(),
        ],
      );
    }
    
    // Nếu không có đề xuất, không hiển thị gì
    if (_geminiRecommendations == null || _geminiRecommendations!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Hiển thị đề xuất từ Gemini AI
    return Column(
      children: [
        SectionHeader(
          title: 'Gợi ý từ AI',
          actionButton: IconButton(
            onPressed: () async {
              await _loadGeminiRecommendations();
            },
            icon: Icon(
              FluentIcons.arrow_clockwise_24_regular,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _geminiRecommendations!.length.clamp(0, 10),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final recommendation = _geminiRecommendations![index];
              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.artist,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (recommendation.genre != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              recommendation.genre!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                        if (recommendation.reason != null) ...[
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              recommendation.reason!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () async {
                                // Tìm kiếm bài hát trên YouTube và phát
                                final query = '${recommendation.title} ${recommendation.artist}';
                                final results = await fetchSongsList(query);
                                if (results.isNotEmpty) {
                                  await audioHandler.stop();
                                  await setActivePlaylist({
                                    'title': 'Gợi ý từ AI',
                                    'list': results,
                                  });
                                  await audioHandler.skipToQueueItem(0);
                                }
                              },
                              icon: Icon(
                                FluentIcons.play_circle_24_filled,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSongsSection(double playlistHeight) {
    return ValueListenableBuilder<bool>(
      valueListenable: defaultRecommendations,
      builder: (_, recommendations, __) {
        return FutureBuilder<dynamic>(
          future: getRecommendedSongs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            if (snapshot.hasError) {
              logger.log(
                'Error in _buildRecommendedSongsSection',
                snapshot.error,
                snapshot.stackTrace,
              );
              return _buildErrorWidget(context);
            }

            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final data = snapshot.data as List<dynamic>;
            if (data.isEmpty) return const SizedBox.shrink();

            return _buildRecommendedForYouSection(context, data);
          },
        );
      },
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.recommendedForYou,
          actionButton: IconButton(
            onPressed: () async {
              await Future.microtask(
                () => setActivePlaylist({
                  'title': context.l10n!.recommendedForYou,
                  'list': data,
                }),
              );
            },
            icon: Icon(
              FluentIcons.play_circle_24_filled,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: data.length,
          padding: commonListViewBottmomPadding,
          itemBuilder: (context, index) {
            final borderRadius = getItemBorderRadius(index, data.length);
            return RepaintBoundary(
              key: ValueKey('song_${data[index]['ytid']}'),
              child: SongBar(data[index], true, borderRadius: borderRadius),
            );
          },
        ),
      ],
    );
  }
}
