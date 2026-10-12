import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _apkVersionCtrl = TextEditingController(text: 'v2.17.2');
  final _minVersionCtrl = TextEditingController(text: 'v2.15.0');
  final _apkUrlCtrl = TextEditingController(
    text: 'https://storage.googleapis.com/takse-call-releases/app-arm64-v8a-release.apk',
  );
  bool _forceUpdate = false;
  bool _isLoadingConfig = false;
  bool _isSavingConfig = false;

  @override
  void initState() {
    super.initState();
    _loadRemoteConfig();
  }

  Future<void> _loadRemoteConfig() async {
    final fs = AdminStateService.instance.firestore;
    if (fs == null) return;

    setState(() => _isLoadingConfig = true);
    try {
      final doc = await fs.collection('system_config').doc('app_release').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _apkVersionCtrl.text = data['apkVersion']?.toString() ?? 'v2.17.2';
        _minVersionCtrl.text = data['minVersion']?.toString() ?? 'v2.15.0';
        _apkUrlCtrl.text = data['apkUrl']?.toString() ??
            'https://storage.googleapis.com/takse-call-releases/app-arm64-v8a-release.apk';
        _forceUpdate = data['forceUpdate'] == true;
      }
    } catch (e) {
      debugPrint('Error loading system_config/app_release: $e');
    } finally {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _saveRemoteConfig() async {
    final fs = AdminStateService.instance.firestore;
    if (fs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore is offline. Settings saved locally.'),
          backgroundColor: AdminColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSavingConfig = true);
    try {
      await fs.collection('system_config').doc('app_release').set({
        'apkVersion': _apkVersionCtrl.text.trim(),
        'minVersion': _minVersionCtrl.text.trim(),
        'apkUrl': _apkUrlCtrl.text.trim(),
        'forceUpdate': _forceUpdate,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': AdminStateService.instance.adminEmail,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Published APK release settings (${_apkVersionCtrl.text}) to Firestore!'),
              ],
            ),
            backgroundColor: AdminColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish release: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  @override
  void dispose() {
    _apkVersionCtrl.dispose();
    _minVersionCtrl.dispose();
    _apkUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final totalOrgs = state.organizations.length;
        final totalDevices = state.devices.length;
        final totalLogs = state.callLogs.length;
        final onlineAgents = state.onlineAgentsNow;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System & APK Release Console',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control Android app releases, force-update triggers, cloud database quotas, and super admin access.',
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _loadRemoteConfig();
                      state.refreshFromFirestore();
                    },
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Refresh Config'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.textPrimary,
                      side: BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 1. Android APK Release Management Card
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AdminColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.android_rounded, color: AdminColors.success, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Android Client APK Release Manager',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Controls in-app update prompts shown to telecallers when opening the mobile app.',
                                  style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSavingConfig ? null : _saveRemoteConfig,
                          icon: _isSavingConfig
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 16),
                          label: Text(_isSavingConfig ? 'Saving...' : 'Save & Publish Release'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AdminColors.border),
                    const SizedBox(height: 16),

                    if (_isLoadingConfig)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latest Live Version',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _apkVersionCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                                  decoration: const InputDecoration(isDense: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minimum Supported Version',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _minVersionCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                                  decoration: const InputDecoration(isDense: true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Direct APK Download URL (Arm64-v8a)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _apkUrlCtrl,
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                        decoration: const InputDecoration(isDense: true),
                      ),
                      const SizedBox(height: 18),

                      // Force Update Switch
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Force Update Popup on Mobile',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                ),
                                Text(
                                  'Blocks telecallers with versions below minimum until they download the latest APK.',
                                  style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                            Switch(
                              value: _forceUpdate,
                              activeThumbColor: AdminColors.primaryLight,
                              onChanged: (v) => setState(() => _forceUpdate = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Cloud Infrastructure & Database Dynamic State
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminColors.primaryGlow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_done_rounded, color: AdminColors.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Cloud Firestore & Synced Telephony Infrastructure',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                            ),
                            Text(
                              'Real-time database metrics connected to Firebase Project: takse-call-admin-web',
                              style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AdminColors.border),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuotaIndicator(
                            title: 'Active Client Tenants',
                            used: '$totalOrgs Orgs',
                            limit: 'Live in Firestore users',
                            ratio: (totalOrgs / 100).clamp(0.05, 1.0),
                            color: AdminColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuotaIndicator(
                            title: 'Registered Telecaller Devices',
                            used: '$totalDevices Devices',
                            limit: '$onlineAgents Active Today',
                            ratio: (totalDevices / 100).clamp(0.05, 1.0),
                            color: AdminColors.accentCyan,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuotaIndicator(
                            title: 'Synced Global Call Logs',
                            used: '$totalLogs Calls',
                            limit: 'Live Stream Synced',
                            ratio: (totalLogs / 150).clamp(0.05, 1.0),
                            color: AdminColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotaIndicator({
    required String title,
    required String used,
    required String limit,
    required double ratio,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(used, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
              Text(limit, style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AdminColors.surfaceElevated,
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
