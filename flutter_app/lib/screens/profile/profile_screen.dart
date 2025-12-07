import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final profile = authState.profile;
    final progressState = ref.watch(progressNotifierProvider);
    
    // Calculate stats from progress entries
    final daysActive = progressState.entries.length;
    final streak = _calculateStreak(progressState.entries);
    final goalsMetCount = 0; // TODO: Calculate from actual goals completion
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user?.firstName.isNotEmpty == true ? user!.firstName.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, 'Days Active', daysActive.toString(), Icons.calendar_today),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, 'Goals Met', goalsMetCount.toString(), Icons.emoji_events),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, 'Streak', streak.toString(), Icons.local_fire_department),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Settings
            _buildSettingsSection(context, ref),
          ],
        ),
      ),
    );
  }

  static int _calculateStreak(List entries) {
    if (entries.isEmpty) return 0;
    
    // Sort entries by date descending
    final sortedEntries = List.from(entries)
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
    
    int streak = 0;
    DateTime? lastDate;
    
    for (var entry in sortedEntries) {
      final entryDate = DateTime.parse(entry.entryDate);
      
      if (lastDate == null) {
        // First entry
        final today = DateTime.now();
        final daysDiff = today.difference(entryDate).inDays;
        if (daysDiff > 1) break; // Not current
        streak = 1;
        lastDate = entryDate;
      } else {
        final daysDiff = lastDate.difference(entryDate).inDays;
        if (daysDiff == 1) {
          streak++;
          lastDate = entryDate;
        } else {
          break; // Streak broken
        }
      }
    }
    
    return streak;
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                'Personal Information',
                'Update your profile details',
                Icons.person_outline,
                onTap: () {
                  // TODO: Navigate to personal info
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                'Goals & Preferences',
                'Fitness and nutrition goals',
                Icons.track_changes,
                onTap: () {
                  // TODO: Navigate to goals
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                'Notifications',
                'Manage your notifications',
                Icons.notifications,
                onTap: () {
                  // TODO: Navigate to notifications
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                'Privacy & Security',
                'Account security settings',
                Icons.shield_outlined,
                onTap: () {
                  // TODO: Navigate to privacy settings
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                'Help & Support',
                'FAQs and contact support',
                Icons.help_outline,
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              
              if (shouldLogout == true) {
                ref.read(authNotifierProvider.notifier).logout();
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}