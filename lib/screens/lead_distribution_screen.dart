import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class LeadDistributionScreen extends StatefulWidget {
  const LeadDistributionScreen({super.key});

  @override
  State<LeadDistributionScreen> createState() => _LeadDistributionScreenState();
}

class _LeadDistributionScreenState extends State<LeadDistributionScreen> {
  final _searchCtrl = TextEditingController();
  String _viewMode = 'table'; // 'table' or 'tree'
  String _activeCompartment = 'unassigned'; // 'unassigned' (Pending), 'assigned' (Sent), 'all'
  String _selectedOrgFilter = 'all';
  String _selectedTimeSlot = 'all'; // 'all', 'today', 'morning', 'afternoon', 'evening'
  String _selectedSourceFilter = 'all'; // 'all', 'webhook', 'sheet'
  int _currentPage = 0;
  static const int _pageSize = 15;

  final Set<String> _selectedLeadIds = {};

  // Palette for Organization distribution chart & badges
  static const List<Color> _chartColors = [
    Color(0xFF38BDF8), // Sky blue
    Color(0xFF10B981), // Emerald green
    Color(0xFFF59E0B), // Amber
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF6366F1), // Indigo
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesTimeSlot(AdminLead lead) {
    if (_selectedTimeSlot == 'all') return true;
    final dt = lead.createdAt;
    final now = DateTime.now();

    if (_selectedTimeSlot == 'today') {
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } else if (_selectedTimeSlot == 'morning') {
      return dt.hour >= 6 && dt.hour < 12;
    } else if (_selectedTimeSlot == 'afternoon') {
      return dt.hour >= 12 && dt.hour < 18;
    } else if (_selectedTimeSlot == 'evening') {
      return dt.hour >= 18 || dt.hour < 6;
    }
    return true;
  }

  bool _matchesSource(AdminLead lead) {
    if (_selectedSourceFilter == 'all') return true;
    if (_selectedSourceFilter == 'webhook') return lead.isWebhookSource;
    if (_selectedSourceFilter == 'sheet') return lead.isSheetSource;
    return true;
  }

  void _confirmBulkRevoke(BuildContext context, AdminStateService state) {
    if (_selectedLeadIds.isEmpty) return;

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.undo_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Revoke Leads to Pending Pool',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Kya aap ${_selectedLeadIds.length} leads ko organizations se wapis kheench kar Pending master pool me daalna chahte hain?',
          style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in _selectedLeadIds) {
                await state.unassignLeadFromOrganization(id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_selectedLeadIds.length} leads revoked and returned to Pending pool!'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
                setState(() => _selectedLeadIds.clear());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke Leads Now'),
          ),
        ],
      ),
    );
  }

  Color _getOrgColor(int index) {
    return _chartColors[index % _chartColors.length];
  }

  // ==========================================
  // 1. AUTO DISTRIBUTE DIALOG (Equal Quota)
  // ==========================================
  void _showAutoDistributeDialog(BuildContext context, AdminStateService state) {
    final unassignedLeads = state.unassignedLeads;
    if (unassignedLeads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sabhi leads already organizations ko send ho chuki hain! Koi pending lead nahi hai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final allOrgs = state.organizations;
    if (allOrgs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koi client organization nahi mili. Pehle Organizations create karein.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedOrgIds = Set<String>.from(allOrgs.map((o) => o.id));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final activeOrgs = allOrgs.where((o) => selectedOrgIds.contains(o.id)).toList();
          final leadsCount = unassignedLeads.length;
          final orgCount = activeOrgs.length;
          final basePerOrg = orgCount > 0 ? (leadsCount / orgCount).floor() : 0;
          final remainder = orgCount > 0 ? (leadsCount % orgCount) : 0;

          return AlertDialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AdminColors.border),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Distribute Leads to Organizations',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AdminColors.textPrimary),
                      ),
                      Text(
                        'Equal quota division across Client Organizations (Admin ➔ Organizations)',
                        style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ORGANIZATION QUOTA PREVIEW',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF10B981), letterSpacing: 1.0),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$leadsCount Pending Leads',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Selected Orgs', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text('$orgCount Organizations', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 32, color: AdminColors.border),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Equal Share', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text('$basePerOrg leads / org', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
                                  ],
                                ),
                              ),
                              if (remainder > 0) ...[
                                Container(width: 1, height: 32, color: AdminColors.border),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Remainder (+1)', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary)),
                                      const SizedBox(height: 2),
                                      Text('$remainder orgs get ${basePerOrg + 1}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            orgCount > 0
                                ? 'Super Admin se ye leads sidha Client Organizations ke pool me transfer hongi ($basePerOrg-each). Fir Organization owner apne portal se telecallers ko distribute karega.'
                                : 'Please select at least one organization.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: AdminColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Target Organizations (${activeOrgs.length}/${allOrgs.length}):',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              if (selectedOrgIds.length == allOrgs.length) {
                                selectedOrgIds.clear();
                              } else {
                                selectedOrgIds.addAll(allOrgs.map((o) => o.id));
                              }
                            });
                          },
                          child: Text(
                            selectedOrgIds.length == allOrgs.length ? 'Deselect All' : 'Select All',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allOrgs.length,
                        itemBuilder: (c, idx) {
                          final org = allOrgs[idx];
                          final isChecked = selectedOrgIds.contains(org.id);
                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            activeColor: const Color(0xFF10B981),
                            title: Text(org.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                            subtitle: Text('${org.connectCode} • ${org.ownerName} (${org.plan})', style: GoogleFonts.inter(fontSize: 10.5, color: AdminColors.textSecondary)),
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedOrgIds.add(org.id);
                                } else {
                                  selectedOrgIds.remove(org.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: activeOrgs.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final leadIdsToDistribute = unassignedLeads.map((l) => l.id).toList();

                        final count = await state.autoDistributeLeadsToOrganizations(
                          leadIds: leadIdsToDistribute,
                          targetOrgs: activeOrgs,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 $count leads successfully sent across ${activeOrgs.length} organizations!'),
                              backgroundColor: const Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: Text('Distribute $leadsCount Leads to Orgs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 2. MANUAL QUOTA DISTRIBUTION DIALOG
  // (e.g. Org A: 10, Org B: 5, Org C: 15)
  // ==========================================
  void _showManualQuotasDialog(BuildContext context, AdminStateService state) {
    final unassignedLeads = state.unassignedLeads;
    if (unassignedLeads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sabhi leads already organizations ko assign ho chuki hain! Koi pending lead nahi hai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final allOrgs = state.organizations;
    if (allOrgs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koi organization nahi mili. Pehle Organizations create karein.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Map<String, int> quotas = {for (final o in allOrgs) o.id: 0};
    final Map<String, TextEditingController> controllers = {
      for (final o in allOrgs) o.id: TextEditingController(text: '0'),
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalPending = unassignedLeads.length;
          final totalAllocated = quotas.values.fold(0, (sum, v) => sum + v);
          final remaining = totalPending - totalAllocated;
          final isOverAllocated = remaining < 0;

          return AlertDialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AdminColors.border),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Quota Allocation',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AdminColors.textPrimary),
                      ),
                      Text(
                        'Custom lead counts per Organization (e.g. Org 1: 10, Org 2: 5, Org 3: 15)',
                        style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOverAllocated
                              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                              : const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PENDING LEADS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.textTertiary, letterSpacing: 0.8)),
                                const SizedBox(height: 2),
                                Text('$totalPending Fresh', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: AdminColors.border),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ALLOCATED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.textTertiary, letterSpacing: 0.8)),
                                const SizedBox(height: 2),
                                Text('$totalAllocated Leads', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: AdminColors.border),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REMAINING', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.textTertiary, letterSpacing: 0.8)),
                                const SizedBox(height: 2),
                                Text(
                                  '$remaining',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isOverAllocated
                                        ? const Color(0xFFEF4444)
                                        : (remaining == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Enter custom lead count for each Organization:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                    const SizedBox(height: 10),

                    ...allOrgs.map((org) {
                      final assignedNow = quotas[org.id] ?? 0;
                      final orgTotalLeads = state.leads.where((l) => l.assignedOrgId == org.id).length;
                      final ctrl = controllers[org.id]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: assignedNow > 0 ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : AdminColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AdminColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AdminColors.primaryLight),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(org.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                                  Text('Code: ${org.connectCode} • Current: $orgTotalLeads leads', style: GoogleFonts.inter(fontSize: 10.5, color: AdminColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                              color: AdminColors.textSecondary,
                              onPressed: () {
                                final current = quotas[org.id] ?? 0;
                                if (current > 0) {
                                  setModalState(() {
                                    quotas[org.id] = current - 1;
                                    ctrl.text = '${current - 1}';
                                  });
                                }
                              },
                            ),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  filled: true,
                                  fillColor: AdminColors.surfaceElevated,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AdminColors.border)),
                                ),
                                onChanged: (val) {
                                  final num = int.tryParse(val) ?? 0;
                                  setModalState(() {
                                    quotas[org.id] = max(0, num);
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                              color: const Color(0xFF10B981),
                              onPressed: () {
                                final current = quotas[org.id] ?? 0;
                                if (remaining > 0) {
                                  setModalState(() {
                                    quotas[org.id] = current + 1;
                                    ctrl.text = '${current + 1}';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: (totalAllocated <= 0 || isOverAllocated)
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final count = await state.distributeCustomQuotasToOrganizations(quotas);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 $count leads allocated successfully across organizations!'),
                              backgroundColor: const Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text('Confirm Quotas ($totalAllocated Leads)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 3. SINGLE LEAD ALLOCATE / TRANSFER MODAL
  // ==========================================
  void _showSingleAssignDialog(BuildContext context, AdminLead lead, AdminStateService state) {
    final allOrgs = state.organizations;
    if (allOrgs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No organizations found to assign.')),
      );
      return;
    }

    String selectedOrgId = allOrgs.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedOrg = allOrgs.firstWhere(
            (o) => o.id == selectedOrgId,
            orElse: () => allOrgs.first,
          );

          return AlertDialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AdminColors.border),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminColors.primaryGlow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(lead.isAssigned ? Icons.replay_rounded : Icons.domain_add_rounded, color: AdminColors.primaryLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.isAssigned ? 'Transfer Lead to Another Organization' : 'Send Lead to Organization',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary),
                      ),
                      Text(
                        'Target Lead: ${lead.name.isNotEmpty ? lead.name : lead.mobileNumber} (${lead.mobileNumber})',
                        style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lead.isAssigned) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Currently Assigned to: ${lead.assignedOrgName} (${lead.assignedOrgId}). Super Admin is lead ko kisi doosri organization ko transfer kar sakta hai.',
                              style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Text('Select Target Client Organization:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: allOrgs.any((o) => o.id == selectedOrgId) ? selectedOrgId : allOrgs.first.id,
                    dropdownColor: AdminColors.surfaceElevated,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AdminColors.surfaceSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AdminColors.border)),
                    ),
                    items: allOrgs.map((o) {
                      return DropdownMenuItem(
                        value: o.id,
                        child: Text('${o.name} (${o.connectCode}) • ${o.ownerName}', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedOrgId = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (lead.isAssigned)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await state.unassignLeadFromOrganization(lead.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lead revoked back to Pending master pool!')),
                      );
                    }
                  },
                  child: const Text('Revoke to Pending Pool', style: TextStyle(color: Color(0xFFEF4444))),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await state.assignLeadsToOrganization(
                    leadIds: [lead.id],
                    orgId: selectedOrg.id,
                    orgName: selectedOrg.name,
                    connectCode: selectedOrg.connectCode,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lead allocated to ${selectedOrg.name}!'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(lead.isAssigned ? 'Confirm Transfer' : 'Confirm Send'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 4. BULK ALLOCATE SELECTED LEADS MODAL
  // ==========================================
  void _showBulkAssignDialog(BuildContext context, AdminStateService state) {
    if (_selectedLeadIds.isEmpty) return;

    final allOrgs = state.organizations;
    if (allOrgs.isEmpty) return;
    String selectedOrgId = allOrgs.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedOrg = allOrgs.firstWhere(
            (o) => o.id == selectedOrgId,
            orElse: () => allOrgs.first,
          );

          return AlertDialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AdminColors.border),
            ),
            title: Text('Send ${_selectedLeadIds.length} Selected Leads to Organization', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Allocate ${_selectedLeadIds.length} leads to:', style: GoogleFonts.inter(fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOrgId,
                    dropdownColor: AdminColors.surfaceElevated,
                    items: allOrgs.map((o) {
                      return DropdownMenuItem(
                        value: o.id,
                        child: Text('${o.name} (${o.connectCode})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedOrgId = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await state.assignLeadsToOrganization(
                    leadIds: _selectedLeadIds.toList(),
                    orgId: selectedOrg.id,
                    orgName: selectedOrg.name,
                    connectCode: selectedOrg.connectCode,
                  );
                  setState(() => _selectedLeadIds.clear());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_selectedLeadIds.length} leads allocated to ${selectedOrg.name}!')),
                    );
                  }
                },
                child: const Text('Send to Org'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final query = _searchCtrl.text.toLowerCase().trim();
        final rawLeads = state.leads;
        final timeFilteredLeads = rawLeads.where(_matchesTimeSlot).where(_matchesSource).toList();

        // Compartment filtering
        List<AdminLead> compartmentLeads;
        if (_activeCompartment == 'unassigned') {
          compartmentLeads = timeFilteredLeads.where((l) => !l.isAssigned).toList();
        } else if (_activeCompartment == 'assigned') {
          compartmentLeads = timeFilteredLeads.where((l) => l.isAssigned).toList();
        } else {
          compartmentLeads = List.from(timeFilteredLeads);
          // When viewing 'All Leads', sort with Pending on top and Sent below
          compartmentLeads.sort((a, b) {
            if (!a.isAssigned && b.isAssigned) return -1;
            if (a.isAssigned && !b.isAssigned) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
        }

        // Filter by organization & query
        final filtered = compartmentLeads.where((lead) {
          if (_selectedOrgFilter != 'all') {
            if (lead.assignedOrgId != _selectedOrgFilter && lead.assignedOrgName != _selectedOrgFilter) {
              return false;
            }
          }
          if (query.isNotEmpty) {
            final mName = lead.name.toLowerCase().contains(query);
            final mPhone = lead.mobileNumber.toLowerCase().contains(query);
            final mState = lead.state.toLowerCase().contains(query);
            final mShop = lead.shopName.toLowerCase().contains(query);
            final mOrg = lead.assignedOrgName.toLowerCase().contains(query);
            if (!mName && !mPhone && !mState && !mShop && !mOrg) {
              return false;
            }
          }
          return true;
        }).toList();

        final totalPages = max(1, (filtered.length / _pageSize).ceil());
        final safePage = _currentPage.clamp(0, totalPages - 1);
        final startIndex = safePage * _pageSize;
        final pageItems = filtered.skip(startIndex).take(_pageSize).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header & Action Controls
              _buildHeader(context, state),
              const SizedBox(height: 20),

              // 2. Metric KPI Cards
              _buildMetricsRow(state, rawLeads),
              const SizedBox(height: 20),

              // 3. View Mode Switcher Tab (Table View vs Visual Hierarchy Tree)
              _buildViewModeSwitcher(),
              const SizedBox(height: 20),

              // 4. Main Body: Either Visual Hierarchy Tree or Table View
              if (_viewMode == 'tree')
                _buildHierarchyTreeView(state, rawLeads)
              else
                _buildTableView(state, rawLeads, filtered, pageItems, safePage, totalPages),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeader(BuildContext context, AdminStateService state) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                Text(
                  'Super Admin Lead Distribution Hub',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'SUPER ADMIN ➔ CLIENT ORGANIZATIONS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Global Inflow Webhook leads are received here. Super Admin distributes quotas only to Client Organizations.',
              style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
            ),
          ],
        ),

        // Actions
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAutoDistributeDialog(context, state),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
              label: Text('Auto Distribute (${state.unassignedLeadsCount} Pending)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showManualQuotasDialog(context, state),
              icon: const Icon(Icons.edit_note_rounded, size: 16),
              label: const Text('Manual Quotas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_selectedLeadIds.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () => _showBulkAssignDialog(context, state),
                icon: const Icon(Icons.domain_rounded, size: 16),
                label: Text('Send Selected (${_selectedLeadIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmBulkRevoke(context, state),
                icon: const Icon(Icons.undo_rounded, size: 16, color: Color(0xFFEF4444)),
                label: Text('Revoke Selected (${_selectedLeadIds.length})', style: const TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            OutlinedButton.icon(
              onPressed: () async {
                await state.refreshFromFirestore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synchronized latest distribution state from Firestore!')),
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Sync'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.textPrimary,
                side: BorderSide(color: AdminColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // METRICS KPI CARDS
  // ==========================================
  Widget _buildMetricsRow(AdminStateService state, List<AdminLead> rawLeads) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = _buildMetricCard(
          title: 'Total Global Leads Pool',
          value: '${rawLeads.length}',
          subtitle: 'Master Webhook Inflow',
          icon: Icons.layers_rounded,
          color: AdminColors.primaryLight,
        );
        final card2 = _buildMetricCard(
          title: '⏳ Pending Leads',
          value: '${state.unassignedLeadsCount}',
          subtitle: 'Waiting for Org Distribution',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFF59E0B),
        );
        final card3 = _buildMetricCard(
          title: '📤 Sent to Organizations',
          value: '${state.assignedLeadsCount}',
          subtitle: 'Distributed to Client Orgs',
          icon: Icons.domain_verification_rounded,
          color: const Color(0xFF10B981),
        );
        final card4 = _buildMetricCard(
          title: 'Client Organizations',
          value: '${state.organizations.length} Orgs',
          subtitle: '${state.devices.length} Total Telecallers',
          icon: Icons.domain_rounded,
          color: const Color(0xFF38BDF8),
        );

        if (constraints.maxWidth < 950) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 14),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 14),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
            const SizedBox(width: 16),
            Expanded(child: card4),
          ],
        );
      },
    );
  }

  // ==========================================
  // VIEW MODE SWITCHER
  // ==========================================
  Widget _buildViewModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton(
            id: 'table',
            icon: Icons.table_chart_rounded,
            label: 'Leads Table & Allocation',
          ),
          const SizedBox(width: 6),
          _buildViewButton(
            id: 'tree',
            icon: Icons.account_tree_rounded,
            label: '🌳 Distribution Flow & Hierarchy Tree',
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({required String id, required IconData icon, required String label}) {
    final isSelected = _viewMode == id;
    return InkWell(
      onTap: () => setState(() => _viewMode = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AdminColors.primaryLight : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AdminColors.primaryLight : AdminColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 5. VISUAL HIERARCHY TREE VIEW (Master Pool ➔ Orgs ➔ Telecallers)
  // =========================================================================
  Widget _buildHierarchyTreeView(AdminStateService state, List<AdminLead> rawLeads) {
    final allOrgs = state.organizations;
    final totalAssigned = state.assignedLeadsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Lead Distribution Breakdown Bar & Records Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      Text(
                        'ORGANIZATION QUOTA SHARE & DISTRIBUTION RECORDS',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  Text(
                    '${allOrgs.length} Registered Organizations',
                    style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stacked Distribution Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 16,
                  color: AdminColors.surfaceSubtle,
                  child: totalAssigned > 0
                      ? Row(
                          children: allOrgs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final org = entry.value;
                            final orgLeads = rawLeads.where((l) => l.assignedOrgId == org.id).length;
                            final flex = ((orgLeads / totalAssigned) * 1000).round();
                            if (flex <= 0) return const SizedBox.shrink();

                            return Expanded(
                              flex: flex,
                              child: Container(
                                color: _getOrgColor(idx),
                              ),
                            );
                          }).toList(),
                        )
                      : Container(color: AdminColors.surfaceSubtle),
                ),
              ),
              const SizedBox(height: 14),

              // Legend items
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: allOrgs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final org = entry.value;
                  final orgLeads = rawLeads.where((l) => l.assignedOrgId == org.id).length;
                  final pct = totalAssigned > 0 ? ((orgLeads / totalAssigned) * 100).toStringAsFixed(1) : '0';
                  final color = _getOrgColor(idx);

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        '${org.name}: ',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                      ),
                      Text(
                        '$orgLeads leads ($pct%)',
                        style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // B. TIER 1: Master Root Node (Super Admin Inflow Pool)
        Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1B4B),
                  const Color(0xFF0F172A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AdminColors.primary.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AdminColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AdminColors.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SUPER ADMIN MASTER INFLOW POOL',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${rawLeads.length} Total Ingested Leads',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '⏳ ${state.unassignedLeadsCount} Pending',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '📤 ${state.assignedLeadsCount} Sent to Orgs',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showAutoDistributeDialog(context, state),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                      label: const Text('Auto Distribute'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showManualQuotasDialog(context, state),
                      icon: const Icon(Icons.edit_note_rounded, size: 14),
                      label: const Text('Manual Quotas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // C. CONNECTOR 1: Flow Arrow (Super Admin ➔ Organizations)
        Center(
          child: Column(
            children: [
              Container(width: 2, height: 28, color: AdminColors.primaryLight),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.south_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'Distributed Quotas to Client Organizations',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(width: 2, height: 28, color: AdminColors.primaryLight),
            ],
          ),
        ),

        // D. TIER 2 & TIER 3: Organizations & their Telecallers Branches
        if (allOrgs.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: Text(
                'No Client Organizations registered yet. Create Organizations to distribute leads.',
                style: GoogleFonts.inter(color: AdminColors.textSecondary),
              ),
            ),
          )
        else
          Wrap(
            spacing: 24,
            runSpacing: 28,
            alignment: WrapAlignment.center,
            children: allOrgs.asMap().entries.map((entry) {
              final idx = entry.key;
              final org = entry.value;
              final orgLeads = rawLeads.where((l) => l.assignedOrgId == org.id).toList();
              final orgDevices = state.getDevicesForOrganization(org);
              final orgColor = _getOrgColor(idx);

              return SizedBox(
                width: 380,
                child: Column(
                  children: [
                    // Organization Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AdminColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: orgColor.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: orgColor.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: orgColor.withValues(alpha: 0.2),
                                child: Text(
                                  org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: orgColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      org.name,
                                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                                    ),
                                    Text(
                                      'Code: ${org.connectCode} • ${org.ownerName}',
                                      style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: orgColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  org.plan,
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: orgColor),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Lead Quota Metrics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('LEADS ALLOCATED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.textTertiary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${orgLeads.length} Leads',
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: orgColor),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AdminColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF38BDF8)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${orgDevices.length} Telecallers',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // CONNECTOR 2: Flow Arrow (Organization ➔ Telecallers)
                    Container(width: 2, height: 20, color: orgColor),
                    Icon(Icons.arrow_downward_rounded, size: 14, color: AdminColors.textSecondary),
                    Container(width: 2, height: 10, color: orgColor),

                    // TIER 3: Registered Telecallers under this Organization
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TELECALLERS IN ORG',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.textSecondary, letterSpacing: 0.8),
                              ),
                              Text(
                                '${orgDevices.length} active',
                                style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textTertiary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (orgDevices.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No telecallers paired yet.\nDevices will appear here once connected using Connect Code: ${org.connectCode}',
                                style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textMuted, height: 1.4),
                              ),
                            )
                          else
                            Column(
                              children: orgDevices.map((device) {
                                final isOnline = device.status == DeviceStatus.online || device.status == DeviceStatus.syncing;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AdminColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AdminColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              device.agentName,
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                            ),
                                            Text(
                                              device.phone.isNotEmpty ? device.phone : device.deviceModel,
                                              style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${device.totalCalls} calls',
                                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // =========================================================================
  // 6. LEADS TABLE VIEW (Compartments: Pending, Sent, All)
  // =========================================================================
  Widget _buildTableView(
    AdminStateService state,
    List<AdminLead> rawLeads,
    List<AdminLead> filtered,
    List<AdminLead> pageItems,
    int safePage,
    int totalPages,
  ) {
    return Column(
      children: [
        // Organization Roster Badges
        if (state.organizations.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ORGANIZATION ALLOCATION ROSTER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.textSecondary, letterSpacing: 0.8)),
                    Text('${state.organizations.length} Total Client Organizations', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: state.organizations.map((org) {
                    final orgLeadsCount = rawLeads.where((l) => l.assignedOrgId == org.id || l.assignedOrgName == org.name).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AdminColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.primaryLight),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(org.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                              Text('${org.connectCode} • ${org.ownerName}', style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$orgLeadsCount leads',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Compartment Segmented Switcher & Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildCompartmentTab(
                    id: 'unassigned',
                    title: '⏳ Pending Leads',
                    badgeCount: state.unassignedLeadsCount,
                    badgeColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  _buildCompartmentTab(
                    id: 'assigned',
                    title: '📤 Sent to Orgs',
                    badgeCount: state.assignedLeadsCount,
                    badgeColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildCompartmentTab(
                    id: 'all',
                    title: '📋 All Leads Pool',
                    badgeCount: rawLeads.length,
                    badgeColor: AdminColors.primaryLight,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() => _currentPage = 0),
                      decoration: InputDecoration(
                        hintText: 'Search by lead name, phone, shop, or target organization...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: AdminColors.textMuted),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: AdminColors.textSecondary),
                        filled: true,
                        fillColor: AdminColors.surfaceSubtle,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AdminColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

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
                        style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textPrimary),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Organizations')),
                          ...state.organizations.map((o) => DropdownMenuItem(
                                value: o.id,
                                child: Text('${o.name} (${o.connectCode})'),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedOrgFilter = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Time-Slot Partition Dropdown (Audio 2 requirement)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTimeSlot,
                        dropdownColor: AdminColors.surfaceElevated,
                        style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('🕒 All Time')),
                          DropdownMenuItem(value: 'today', child: Text('📅 Today Only')),
                          DropdownMenuItem(value: 'morning', child: Text('🌅 Morning (6 AM - 12 PM)')),
                          DropdownMenuItem(value: 'afternoon', child: Text('☀️ Afternoon (12 PM - 6 PM)')),
                          DropdownMenuItem(value: 'evening', child: Text('🌙 Evening / Night (6 PM - 12 AM)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTimeSlot = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Lead Source Filter (Webhook API vs Excel Sheet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSourceFilter,
                        dropdownColor: AdminColors.surfaceElevated,
                        style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('⚡ All Sources (Webhook & Excel)')),
                          DropdownMenuItem(value: 'webhook', child: Text('🌐 Webhook / API Inflow')),
                          DropdownMenuItem(value: 'sheet', child: Text('📊 Excel / CSV / Sheet')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSourceFilter = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedLeadIds.length == pageItems.length) {
                          _selectedLeadIds.clear();
                        } else {
                          _selectedLeadIds.addAll(pageItems.map((l) => l.id));
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _selectedLeadIds.length == pageItems.length ? 'Deselect Page' : 'Select Page',
                      style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // DataTable
        Container(
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AdminColors.surfaceSubtle),
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('LEAD PROFILE')),
                    DataColumn(label: Text('SOURCE')),
                    DataColumn(label: Text('BUSINESS / LOCATION')),
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('STATUS & ALLOCATED ORG')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: pageItems.map((lead) {
                    final isSelected = _selectedLeadIds.contains(lead.id);

                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedLeadIds.add(lead.id);
                          } else {
                            _selectedLeadIds.remove(lead.id);
                          }
                        });
                      },
                      cells: [
                        // Lead Profile
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                lead.name.isNotEmpty ? lead.name : lead.mobileNumber,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 11, color: AdminColors.primaryLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    lead.mobileNumber,
                                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AdminColors.accentCyan),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Source Badge (Webhook API vs Excel Sheet)
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: lead.isWebhookSource
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                                  : const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: lead.isWebhookSource
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                    : const Color(0xFF10B981).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  lead.isWebhookSource ? Icons.bolt_rounded : Icons.table_chart_rounded,
                                  size: 13,
                                  color: lead.isWebhookSource ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  lead.isWebhookSource ? 'Webhook' : 'Excel Sheet',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: lead.isWebhookSource ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Business / Location
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                lead.shopName.isNotEmpty ? lead.shopName : 'Direct Lead',
                                style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textPrimary),
                              ),
                              Text(
                                '${lead.state} ${lead.district.isNotEmpty ? "• ${lead.district}" : ""}',
                                style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                        ),

                        // Type
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminColors.primaryGlow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lead.userType,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.primaryLight),
                            ),
                          ),
                        ),

                        // Status & Allocated Org
                        DataCell(
                          lead.isAssigned
                              ? Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.domain_verification_rounded, size: 14, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          lead.assignedOrgName.isNotEmpty ? lead.assignedOrgName : 'Client Organization',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                        ),
                                        Text(
                                          'Org Code: ${lead.assignedOrgId}',
                                          style: GoogleFonts.inter(fontSize: 10.5, color: AdminColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.hourglass_empty_rounded, size: 12, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Pending / Fresh Pool',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B)),
                                      ),
                                    ],
                                  ),
                                ),
                        ),

                        // Actions
                        DataCell(
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _showSingleAssignDialog(context, lead, state),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lead.isAssigned ? AdminColors.surfaceElevated : const Color(0xFF10B981),
                                  foregroundColor: lead.isAssigned ? AdminColors.textPrimary : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  lead.isAssigned ? 'Transfer Org' : 'Send to Org',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Pagination Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${pageItems.length} of ${filtered.length} leads',
                      style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: safePage > 0 ? () => setState(() => _currentPage--) : null,
                        ),
                        Text(
                          'Page ${safePage + 1} of $totalPages',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: safePage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
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
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildCompartmentTab({
    required String id,
    required String title,
    required int badgeCount,
    required Color badgeColor,
  }) {
    final isSelected = _activeCompartment == id;

    return InkWell(
      onTap: () {
        setState(() {
          _activeCompartment = id;
          _currentPage = 0;
          _selectedLeadIds.clear();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AdminColors.primary.withValues(alpha: 0.5)) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
