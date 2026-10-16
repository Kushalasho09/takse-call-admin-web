import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header with Live Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Platform Command Center',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AdminColors.successSubtle,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AdminColors.success.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AdminColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Live Node Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Global telemetry, department health, and real-time SIM call sync overview.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => state.setSection('organizations'),
                        icon: const Icon(Icons.add_business_rounded, size: 16),
                        label: const Text('Add Department'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Stats Cards (Responsive grid with mainAxisExtent)
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1150) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 650) {
                    crossAxisCount = 2;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 142,
                    children: [
                      _buildMetricCard(
                        title: 'Total Departments',
                        value: '${state.totalOrganizations}',
                        subtext: '${state.activeOrganizations} Active Departments',
                        icon: Icons.corporate_fare_rounded,
                        accentColor: AdminColors.primary,
                        growth: state.newOrgsThisWeek > 0 ? '+${state.newOrgsThisWeek} this week' : 'Active units',
                      ),
                      _buildMetricCard(
                        title: 'Active Agents / Phones',
                        value: '${state.totalAgents}',
                        subtext: '${state.onlineAgentsNow} Online & Syncing Now',
                        icon: Icons.phone_android_rounded,
                        accentColor: AdminColors.accentCyan,
                        growth: state.newDevicesThisWeek > 0 ? '+${state.newDevicesThisWeek} this week' : '${state.onlineAgentsNow} online',
                      ),
                      _buildMetricCard(
                        title: 'Calls Synced Today',
                        value: NumberFormat('#,###').format(state.totalCallsToday),
                        subtext: '${state.totalCallsAllTime} Total Synced Calls',
                        icon: Icons.sync_rounded,
                        accentColor: AdminColors.success,
                        growth: '100% cloud sync',
                      ),
                      _buildMetricCard(
                        title: 'System Uptime & SLA',
                        value: '${state.systemUptime}%',
                        subtext: 'Firestore cluster optimal',
                        icon: Icons.speed_rounded,
                        accentColor: AdminColors.warning,
                        growth: state.isLiveConnected ? 'Live Stream Active' : 'Connecting...',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Two columns: Live Call Stream & Organization Quick Status
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1000;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Live Call Stream
                      Expanded(
                        flex: isWide ? 6 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AdminColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AdminColors.border),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.stream_rounded, color: AdminColors.primaryLight, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Real-Time Call Stream',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => state.setSection('calls'),
                                    child: Row(
                                      children: [
                                        Text('View All Logs', style: GoogleFonts.inter(fontSize: 12, color: AdminColors.primaryLight)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, size: 14, color: AdminColors.primaryLight),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (state.callLogs.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 36),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.stream_rounded, size: 36, color: AdminColors.textTertiary.withValues(alpha: 0.5)),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Waiting for live SIM sync...',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Calls made or received on connected Android agent devices will appear here automatically.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...state.callLogs.take(6).map((log) => _buildLiveCallItem(log)),
                            ],
                          ),
                        ),
                      ),
                      if (isWide) const SizedBox(width: 20),

                      // Right: Top Organizations & Health
                      if (isWide)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              // Top Orgs
                              Container(
                                decoration: BoxDecoration(
                                  color: AdminColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.leaderboard_rounded, color: AdminColors.accentPurple, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Top Departments',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AdminColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (state.topOrganizations.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Center(
                                          child: Text(
                                            'No company departments registered yet.',
                                            style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textTertiary),
                                          ),
                                        ),
                                      )
                                    else
                                      ...state.topOrganizations.take(5).map((org) => _buildOrgRankItem(org)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // System Health Box
                              Container(
                                decoration: BoxDecoration(
                                  color: AdminColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Node Telemetry',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildTelemetryRow('Android App Releases', 'v2.17.2 Active', AdminColors.success),
                                    Divider(color: AdminColors.border, height: 20),
                                    _buildTelemetryRow(
                                      'Firestore Cloud Sync',
                                      state.isLiveConnected ? 'Live Active (${state.firestoreSyncCount} syncs)' : 'Connecting...',
                                      state.isLiveConnected ? AdminColors.success : AdminColors.warning,
                                    ),
                                    Divider(color: AdminColors.border, height: 20),
                                    _buildTelemetryRow('Connected Agents', '${state.onlineAgentsNow} Online / ${state.totalAgents} Registered', AdminColors.info),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required String growth,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtext,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      growth,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCallItem(AdminCallLog log) {
    final state = AdminStateService.instance;
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (log.type) {
      case CallType.incoming:
        typeColor = AdminColors.success;
        typeIcon = Icons.call_received_rounded;
        typeLabel = 'Incoming';
        break;
      case CallType.outgoing:
        typeColor = AdminColors.warning;
        typeIcon = Icons.call_made_rounded;
        typeLabel = 'Outgoing';
        break;
      case CallType.missed:
        typeColor = AdminColors.error;
        typeIcon = Icons.call_missed_rounded;
        typeLabel = 'Missed';
        break;
      case CallType.rejected:
        typeColor = Colors.purpleAccent;
        typeIcon = Icons.phone_disabled_rounded;
        typeLabel = 'Rejected';
        break;
    }

    final durationStr = log.durationSeconds > 0
        ? '${log.durationSeconds ~/ 60}m ${log.durationSeconds % 60}s'
        : (log.type == CallType.missed ? 'Missed' : '0s');

    final now = DateTime.now();
    final isToday = log.timestamp.year == now.year && log.timestamp.month == now.month && log.timestamp.day == now.day;
    final timeStr = isToday ? DateFormat('hh:mm a').format(log.timestamp) : DateFormat('MMM d, hh:mm a').format(log.timestamp);

    return InkWell(
      onTap: () => state.setSection('calls'),
      borderRadius: BorderRadius.circular(12),
      hoverColor: AdminColors.surfaceElevated,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminColors.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Tooltip(message: typeLabel, child: Icon(typeIcon, color: typeColor, size: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          log.clientName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (log.clientNumber.isNotEmpty && log.clientNumber != log.clientName) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${log.clientNumber})',
                          style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Agent: ${log.agentName}',
                        style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: GoogleFonts.inter(color: AdminColors.textTertiary)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          log.orgName,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.primaryLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  durationStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgRankItem(AdminOrganization org) {
    final state = AdminStateService.instance;
    final initial = org.name.trim().isNotEmpty ? org.name.trim().substring(0, 1).toUpperCase() : 'O';

    return InkWell(
      onTap: () => state.setSection('organizations'),
      borderRadius: BorderRadius.circular(10),
      hoverColor: AdminColors.surfaceElevated.withValues(alpha: 0.5),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AdminColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AdminColors.primaryLight),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${org.activeEmployeesCount}/${org.employeeLimit} Agents • ${org.plan}',
                    style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminColors.primaryGlow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${NumberFormat.compact().format(org.totalCallsSynced)} calls',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary)),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}
