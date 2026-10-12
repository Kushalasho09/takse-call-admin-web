import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class CallAuditScreen extends StatefulWidget {
  const CallAuditScreen({super.key});

  @override
  State<CallAuditScreen> createState() => _CallAuditScreenState();
}

class _CallAuditScreenState extends State<CallAuditScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedType = 'all';
  String _selectedOrg = 'all';
  int _currentPage = 0;
  static const int _pageSize = 15;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showPlayAudioDialog(BuildContext context, AdminCallLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AdminColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: AdminColors.accentCyan),
            const SizedBox(width: 10),
            Text(
              'Call Audio Recording Audit',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${log.clientName} (${log.clientNumber})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Handled by: ${log.agentName} • ${log.orgName}',
                style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Waveform Player Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AdminColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('00:00', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textPrimary)),
                                  Text(
                                    '${log.durationSeconds ~/ 60}:${(log.durationSeconds % 60).toString().padLeft(2, '0')}',
                                    style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.35,
                                  backgroundColor: AdminColors.surfaceElevated,
                                  color: AdminColors.accentCyan,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final query = _searchCtrl.text.toLowerCase().trim();
        final list = state.callLogs.where((log) {
          if (_selectedType != 'all') {
            if (_selectedType == 'incoming' && log.type != CallType.incoming) return false;
            if (_selectedType == 'outgoing' && log.type != CallType.outgoing) return false;
            if (_selectedType == 'missed' && log.type != CallType.missed) return false;
            if (_selectedType == 'rejected' && log.type != CallType.rejected) return false;
          }
          if (_selectedOrg != 'all' && log.orgName != _selectedOrg) {
            return false;
          }
          if (query.isNotEmpty) {
            final mClient = log.clientName.toLowerCase().contains(query);
            final mNum = log.clientNumber.toLowerCase().contains(query);
            final mAgent = log.agentName.toLowerCase().contains(query);
            final mOrg = log.orgName.toLowerCase().contains(query);
            if (!mClient && !mNum && !mAgent && !mOrg) return false;
          }
          return true;
        }).toList();

        final uniqueOrgs = state.callLogs.map((l) => l.orgName).toSet().toList();
        final totalPages = max(1, (list.length / _pageSize).ceil());
        final safeCurrentPage = _currentPage.clamp(0, totalPages - 1);
        final startIndex = safeCurrentPage * _pageSize;
        final pageItems = list.skip(startIndex).take(_pageSize).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Sync Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Call Logs & Storage Audit',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live SIM call sync stream across all client organizations and field devices.',
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await state.refreshFromFirestore();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Synchronized latest call stream from Firestore!'),
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
                    // Search
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() => _currentPage = 0),
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by client phone, client name, agent, or company...',
                          prefixIcon: Icon(Icons.search_rounded, color: AdminColors.textSecondary, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () => setState(() {
                                    _searchCtrl.clear();
                                    _currentPage = 0;
                                  }),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Organization Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOrg,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Organizations')),
                            ...uniqueOrgs.map((o) => DropdownMenuItem(value: o, child: Text(o))),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedOrg = v ?? 'all';
                            _currentPage = 0;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Call Type Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Types')),
                            DropdownMenuItem(value: 'incoming', child: Text('Incoming')),
                            DropdownMenuItem(value: 'outgoing', child: Text('Outgoing')),
                            DropdownMenuItem(value: 'missed', child: Text('Missed')),
                            DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedType = v ?? 'all';
                            _currentPage = 0;
                          }),
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
                        '${list.length} Records',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Call Records Table or Empty State
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
                              Icon(Icons.receipt_long_rounded, size: 48, color: AdminColors.textTertiary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                state.isLiveConnected ? 'No matching call logs found.' : 'Loading live call logs from Firestore...',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Calls will stream in real-time as telecallers make calls on Android devices.',
                                style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                horizontalMargin: 20,
                                columnSpacing: 28,
                                headingRowColor: WidgetStateProperty.all(AdminColors.surfaceElevated),
                                columns: [
                                  DataColumn(label: Text('CLIENT NUMBER & NAME', style: _colHeaderStyle)),
                                  DataColumn(label: Text('TYPE', style: _colHeaderStyle)),
                                  DataColumn(label: Text('DURATION', style: _colHeaderStyle)),
                                  DataColumn(label: Text('AGENT & SIM', style: _colHeaderStyle)),
                                  DataColumn(label: Text('ORGANIZATION', style: _colHeaderStyle)),
                                  DataColumn(label: Text('TIMESTAMP', style: _colHeaderStyle)),
                                  DataColumn(label: Text('RECORDING', style: _colHeaderStyle)),
                                ],
                                rows: pageItems.map((log) => _buildLogRow(context, log)).toList(),
                              ),
                            ),
                          ),

                          // Pagination Controls
                          if (list.length > _pageSize)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceElevated,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                border: Border(top: BorderSide(color: AdminColors.border)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Showing ${startIndex + 1}-${min(startIndex + _pageSize, list.length)} of ${list.length} calls',
                                    style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                        onPressed: safeCurrentPage > 0
                                            ? () => setState(() => _currentPage = safeCurrentPage - 1)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Page ${safeCurrentPage + 1} of $totalPages',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                        onPressed: safeCurrentPage < totalPages - 1
                                            ? () => setState(() => _currentPage = safeCurrentPage + 1)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  TextStyle get _colHeaderStyle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AdminColors.textSecondary,
      );

  DataRow _buildLogRow(BuildContext context, AdminCallLog log) {
    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (log.type) {
      case CallType.incoming:
        typeColor = AdminColors.success;
        typeLabel = 'Incoming';
        typeIcon = Icons.call_received_rounded;
        break;
      case CallType.outgoing:
        typeColor = AdminColors.warning;
        typeLabel = 'Outgoing';
        typeIcon = Icons.call_made_rounded;
        break;
      case CallType.missed:
        typeColor = AdminColors.error;
        typeLabel = 'Missed';
        typeIcon = Icons.call_missed_rounded;
        break;
      case CallType.rejected:
        typeColor = Colors.purpleAccent;
        typeLabel = 'Rejected';
        typeIcon = Icons.phone_disabled_rounded;
        break;
    }

    final durationStr = log.durationSeconds > 0
        ? '${log.durationSeconds ~/ 60}m ${log.durationSeconds % 60}s'
        : (log.type == CallType.missed ? 'Missed' : '0s');

    return DataRow(
      cells: [
        // Client
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                log.clientName.isNotEmpty ? log.clientName : log.clientNumber,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 13),
              ),
              if (log.clientNumber.isNotEmpty && log.clientNumber != log.clientName)
                Text(log.clientNumber, style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),

        // Type
        DataCell(
          Row(
            children: [
              Icon(typeIcon, color: typeColor, size: 14),
              const SizedBox(width: 6),
              Text(typeLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor)),
            ],
          ),
        ),

        // Duration
        DataCell(
          Text(durationStr, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 12)),
        ),

        // Agent & SIM
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(log.agentName, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AdminColors.textPrimary, fontSize: 13)),
              Text(
                log.agentPhone.isNotEmpty ? '${log.agentPhone} • ${log.simSlot}' : log.simSlot,
                style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),

        // Org
        DataCell(
          Text(log.orgName, style: GoogleFonts.inter(color: AdminColors.primaryLight, fontWeight: FontWeight.w500, fontSize: 12)),
        ),

        // Timestamp
        DataCell(
          Text(
            DateFormat('d MMM, hh:mm a').format(log.timestamp),
            style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12),
          ),
        ),

        // Recording
        DataCell(
          log.hasRecording
              ? IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: AdminColors.accentCyan, size: 20),
                  tooltip: 'Play Call Recording',
                  onPressed: () => _showPlayAudioDialog(context, log),
                )
              : Text('No Audio', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary)),
        ),
      ],
    );
  }
}
