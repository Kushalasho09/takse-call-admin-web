import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';
import '../theme/takse_call_logo_data.dart';
import 'call_audit_screen.dart';
import 'devices_screen.dart';
import 'lead_distribution_screen.dart';
import 'lead_management_screen.dart';
import 'organizations_screen.dart';
import 'overview_screen.dart';
import 'plans_screen.dart';
import 'system_settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AdminColors.background,
          body: Row(
            children: [
              // Left Admin Navigation Sidebar
              _buildSidebar(context, state),

              // Vertical Divider
              Container(width: 1, color: AdminColors.border),

              // Main Workspace Area
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    _buildTopHeader(context, state),

                    // Top Bar Divider
                    Container(height: 1, color: AdminColors.border),

                    // Active Section Body
                    Expanded(
                      child: _buildCurrentScreen(state.selectedSection),
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

  Widget _buildSidebar(BuildContext context, AdminStateService state) {
    return Container(
      width: 260,
      color: AdminColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AdminColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TakseCallLogo.widget(
                    borderRadius: BorderRadius.circular(7),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TAKSE ',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'CALL',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.primaryGlow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SUPER ADMIN',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AdminColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: AdminColors.border, height: 1),
          const SizedBox(height: 12),

          // Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarSectionLabel('PLATFORM MANAGEMENT'),
                _buildSidebarNavItem(
                  id: 'overview',
                  label: 'Overview',
                  icon: Icons.dashboard_rounded,
                  state: state,
                ),
                _buildSidebarNavItem(
                  id: 'organizations',
                  label: 'Organizations',
                  icon: Icons.domain_rounded,
                  badge: '${state.totalOrganizations}',
                  state: state,
                ),
                _buildSidebarNavItem(
                  id: 'devices',
                  label: 'Telecallers & Devices',
                  icon: Icons.phone_android_rounded,
                  badge: '${state.totalAgents}',
                  state: state,
                ),
                const SizedBox(height: 16),

                _buildSidebarSectionLabel('LEAD OPERATIONS'),
                _buildSidebarNavItem(
                  id: 'leads',
                  label: 'Lead Management',
                  icon: Icons.assignment_ind_rounded,
                  badge: state.leads.isNotEmpty ? '${state.leads.length}' : null,
                  state: state,
                ),
                _buildSidebarNavItem(
                  id: 'lead_distribution',
                  label: 'Lead Distribution',
                  icon: Icons.shuffle_rounded,
                  badge: state.unassignedLeadsCount > 0 ? '${state.unassignedLeadsCount} new' : null,
                  state: state,
                ),
                const SizedBox(height: 16),

                _buildSidebarSectionLabel('BILLING & LOGS'),
                _buildSidebarNavItem(
                  id: 'plans',
                  label: 'Plans & Pricing',
                  icon: Icons.credit_card_rounded,
                  state: state,
                ),
                _buildSidebarNavItem(
                  id: 'calls',
                  label: 'Global Call Logs',
                  icon: Icons.receipt_long_rounded,
                  state: state,
                ),
                const SizedBox(height: 16),

                _buildSidebarSectionLabel('INFRASTRUCTURE'),
                _buildSidebarNavItem(
                  id: 'settings',
                  label: 'System & Releases',
                  icon: Icons.settings_suggest_rounded,
                  state: state,
                ),
              ],
            ),
          ),

          // Bottom Master Admin Profile Pill
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AdminColors.primaryGlow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.shield_rounded, size: 18, color: AdminColors.primaryLight),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.adminName,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Master Root Access',
                        style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout_rounded, size: 16, color: AdminColors.textSecondary),
                  tooltip: 'Sign Out',
                  onPressed: () => state.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AdminColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required String id,
    required String label,
    required IconData icon,
    String? badge,
    required AdminStateService state,
  }) {
    final isSelected = state.selectedSection == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => state.setSection(id),
          borderRadius: BorderRadius.circular(10),
          hoverColor: AdminColors.surfaceElevated,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AdminColors.primary.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: AdminColors.primary.withValues(alpha: 0.4)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AdminColors.primaryLight : AdminColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AdminColors.primary : AdminColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AdminColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, AdminStateService state) {
    String title = 'Command Center';
    switch (state.selectedSection) {
      case 'overview':
        title = 'System Overview';
        break;
      case 'organizations':
        title = 'Client Organizations';
        break;
      case 'devices':
        title = 'Telecallers & Device Fleet';
        break;
      case 'plans':
        title = 'Plans & Subscriptions';
        break;
      case 'leads':
        title = 'Lead Management Hub';
        break;
      case 'lead_distribution':
        title = 'Lead Distribution & Assignment Engine';
        break;
      case 'calls':
        title = 'Global Call Records';
        break;
      case 'settings':
        title = 'Infrastructure & APK Releases';
        break;
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: AdminColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Takse Call',
                style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textTertiary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(color: AdminColors.textMuted)),
              ),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
              ),
            ],
          ),

          Row(
            children: [
              // Firebase Live Sync Status Pill
              InkWell(
                onTap: () => state.refreshFromFirestore(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: state.isLiveConnected ? const Color(0x1A10B981) : AdminColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.isLiveConnected ? const Color(0xFF10B981).withValues(alpha: 0.5) : AdminColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 14,
                        color: state.isLiveConnected ? const Color(0xFF10B981) : AdminColors.accentCyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isLiveConnected ? 'Firebase Live' : 'Firebase Ready',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: state.isLiveConnected ? const Color(0xFF10B981) : AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Light Mode / Dark Mode Theme Toggle
              InkWell(
                onTap: () => state.toggleTheme(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 15,
                        color: state.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isDarkMode ? 'Dark (App)' : 'Light (Web)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Operational Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AdminColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      'Cluster 99.98% SLA',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Notification Bell
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: AdminColors.textSecondary, size: 20),
                tooltip: 'Alerts & System Logs',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All system services running within nominal limits.'),
                      backgroundColor: AdminColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Super Admin Profile Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AdminColors.primary,
                      child: Text('SA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Master Admin',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen(String section) {
    switch (section) {
      case 'overview':
        return const OverviewScreen();
      case 'organizations':
        return const OrganizationsScreen();
      case 'devices':
        return const DevicesScreen();
      case 'plans':
        return const PlansScreen();
      case 'calls':
        return const CallAuditScreen();
      case 'leads':
        return const LeadManagementScreen();
      case 'lead_distribution':
        return const LeadDistributionScreen();
      case 'settings':
        return const SystemSettingsScreen();
      default:
        return const OverviewScreen();
    }
  }
}
