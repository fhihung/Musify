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
import 'package:musify/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        leading: IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(FluentIcons.arrow_left_24_regular),
        ),
      ),
      body: ValueListenableBuilder<AuthState>(
        valueListenable: AuthService.authState,
        builder: (context, authState, child) {
          if (authState == AuthState.unauthenticated) {
            return _buildUnauthenticatedView(context);
          }

          return _buildAuthenticatedView(context);
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.person_24_regular, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text(
              'Chưa đăng nhập',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để đồng bộ dữ liệu và sao lưu playlist của bạn',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthService.currentUser,
      builder: (context, user, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: AuthService.userAvatar != null
                            ? ClipOval(
                                child: Image.network(
                                  AuthService.userAvatar!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    (AuthService.userDisplayName?.isNotEmpty == true
                                        ? AuthService.userDisplayName![0].toUpperCase()
                                        : 'U'),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                (AuthService.userDisplayName?.isNotEmpty == true
                                    ? AuthService.userDisplayName![0].toUpperCase()
                                    : 'U'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AuthService.userDisplayName ?? 'Người dùng',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (AuthService.isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(
                              FluentIcons.checkmark_circle_24_filled,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AuthService.userEmail ?? '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      if (AuthService.userCreated != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tham gia ${_formatDate(AuthService.userCreated!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(FluentIcons.cloud_sync_24_regular),
                      title: const Text('Sao lưu dữ liệu'),
                      subtitle: const Text('Đồng bộ playlist và cài đặt'),
                      trailing: const Icon(FluentIcons.chevron_right_24_regular),
                      onTap: () {
                        context.go('/cloud-backup');
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(FluentIcons.history_24_regular),
                      title: const Text('Lịch sử sao lưu'),
                      subtitle: const Text('Xem các bản sao lưu trước đó'),
                      trailing: const Icon(FluentIcons.chevron_right_24_regular),
                      onTap: () {
                        context.go('/cloud-backup');
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
                        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Đăng xuất')),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await AuthService.signOut();
                  }
                },
                icon: const Icon(FluentIcons.sign_out_24_regular),
                label: const Text('Đăng xuất'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
