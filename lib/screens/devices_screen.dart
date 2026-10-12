import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedOrgFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final query = _searchCtrl.text.toLowerCase().trim();
        final list = state.devices.where((d) {
          if (_selectedOrgFilter != 'all' && d.organizationName != _selectedOrgFilter) {
            return false;
          }
          if (query.isNotEmpty) {
            final mName = d.agentName.toLowerCase().contains(query);
            final mPhone = d.phone.toLowerCase().contains(query);
            final mOrg = d.organizationName.toLowerCase().contains(query);
            final mModel = d.deviceModel.toLowerCase().contains(query);
            final mCode = d.connectCode.toLowerCase().contains(query);
            if (!mName && !mPhone && !mOrg && !mModel && !mCode) return false;
          }
          return true;
        }).toList();

        final uniqueOrgs = state.devices.map((d) => d.organizationName).toSet().toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Sync Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telecallers & Device Fleet',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitor all paired Android mobile phones, active work SIMs, APK versions, and live sync heartbeats.',
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await state.refreshFromFirestore();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Synchronized connected devices from Firestore!'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Sync Now'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminColors.textPrimary,
                          side: BorderSide(color: AdminColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AdminColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_rounded, color: AdminColors.success, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${state.onlineAgentsNow} Devices Active Now',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter & Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search agent name, mobile number, device model, or company...',
                          prefixIcon: Icon(Icons.search_rounded, color: AdminColors.textSecondary, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () => setState(() => _searchCtrl.clear()),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Org Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOrgFilter,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Organizations')),
                            ...uniqueOrgs.map((o) => DropdownMenuItem(value: o, child: Text(o))),
                          ],
                          onChanged: (v) => setState(() => _selectedOrgFilter = v ?? 'all'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Total Count Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${list.length} Devices',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Devices Table or Empty State
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_android_rounded, size: 48, color: AdminColors.textTertiary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                state.isLiveConnected ? 'No matching agent devices found.' : 'Loading registered devices from Firestore...',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Devices paired via Android telecaller app using organization connect codes will appear here.',
                                style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            horizontalMargin: 20,
                            columnSpacing: 28,
                            headingRowColor: WidgetStateProperty.all(AdminColors.surfaceElevated),
                            columns: [
                              DataColumn(label: Text('AGENT & SIM NUMBER', style: _colHeaderStyle)),
                              DataColumn(label: Text('ORGANIZATION', style: _colHeaderStyle)),
                              DataColumn(label: Text('CONNECT CODE', style: _colHeaderStyle)),
                              DataColumn(label: Text('DEVICE HARDWARE', style: _colHeaderStyle)),
                              DataColumn(label: Text('APP VERSION', style: _colHeaderStyle)),
                              DataColumn(label: Text('STATUS', style: _colHeaderStyle)),
                              DataColumn(label: Text('LAST SYNC', style: _colHeaderStyle)),
                              DataColumn(label: Text('CALLS SYNCED', style: _colHeaderStyle)),
                            ],
                            rows: list.map((dev) => _buildDeviceRow(context, dev)).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle get _colHeaderStyle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AdminColors.textSecondary,
      );

  DataRow _buildDeviceRow(BuildContext context, AdminDevice dev) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (dev.status) {
      case DeviceStatus.online:
        statusColor = AdminColors.success;
        statusLabel = 'Online';
        statusIcon = Icons.check_circle_rounded;
        break;
      case DeviceStatus.syncing:
        statusColor = AdminColors.primaryLight;
        statusLabel = 'Syncing...';
        statusIcon = Icons.sync_rounded;
        break;
      case DeviceStatus.idle:
        statusColor = AdminColors.warning;
        statusLabel = 'Idle';
        statusIcon = Icons.pause_circle_rounded;
        break;
      case DeviceStatus.offline:
        statusColor = AdminColors.error;
        statusLabel = 'Offline';
        statusIcon = Icons.cancel_rounded;
        break;
    }

    final diff = DateTime.now().difference(dev.lastSyncAt);
    String syncTimeStr = '';
    if (diff.inMinutes < 1) {
      syncTimeStr = 'Just now';
    } else if (diff.inMinutes < 60) {
      syncTimeStr = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      syncTimeStr = '${diff.inHours}h ago';
    } else {
      syncTimeStr = '${diff.inDays}d ago';
    }

    return DataRow(
      cells: [
        // Agent & Phone
        DataCell(
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AdminColors.primaryGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_rounded, size: 16, color: AdminColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dev.agentName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 13),
                  ),
                  Text(
                    dev.phone.isNotEmpty ? '${dev.phone} • ${dev.simSlot}' : dev.simSlot,
                    style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Organization
        DataCell(
          Text(
            dev.organizationName,
            style: GoogleFonts.inter(color: AdminColors.primaryLight, fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),

        // Connect Code
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.codePillBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AdminColors.border),
            ),
            child: Text(
              dev.connectCode.isNotEmpty ? dev.connectCode : 'N/A',
              style: GoogleFonts.sourceCodePro(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AdminColors.codePillText,
              ),
            ),
          ),
        ),

        // Device Hardware
        DataCell(
          Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 14, color: AdminColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                dev.deviceModel,
                style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 12),
              ),
            ],
          ),
        ),

        // App Version
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AdminColors.border),
            ),
            child: Text(
              dev.appVersion,
              style: GoogleFonts.sourceCodePro(fontSize: 10, color: AdminColors.textSecondary),
            ),
          ),
        ),

        // Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 12),
                const SizedBox(width: 4),
                Text(statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ],
            ),
          ),
        ),

        // Last Sync
        DataCell(
          Text(syncTimeStr, style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12)),
        ),

        // Calls Synced
        DataCell(
          Text(
            NumberFormat('#,###').format(dev.totalCalls),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
