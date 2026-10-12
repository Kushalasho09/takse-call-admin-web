import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'all'; // all, active, trial, suspended
  final _selectedPlanFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddOrgDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 ');
    final emailCtrl = TextEditingController();
    String selectedPlan = 'Starter Plan';
    int limit = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_business_rounded, color: AdminColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Register New Organization',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AdminColors.textPrimary),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create an enterprise client tenant with an auto-generated Device Connect Code.',
                    style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  _buildDialogField('Company / Business Name', nameCtrl, 'e.g. Apex Marketing Labs'),
                  const SizedBox(height: 14),

                  _buildDialogField('Owner / Admin Full Name', ownerCtrl, 'e.g. Rajesh Kumar'),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(child: _buildDialogField('Admin Mobile Number', phoneCtrl, '+91 98765 43210')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDialogField('Admin Email Address', emailCtrl, 'rajesh@company.in')),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subscription Plan', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPlan,
                                  isExpanded: true,
                                  dropdownColor: AdminColors.surfaceElevated,
                                  style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                                  items: ['Starter Plan', 'Growth Plan', 'Scale Pro', 'Enterprise']
                                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDlgState(() {
                                        selectedPlan = val;
                                        if (val == 'Starter Plan') limit = 5;
                                        if (val == 'Growth Plan') limit = 15;
                                        if (val == 'Scale Pro') limit = 35;
                                        if (val == 'Enterprise') limit = 50;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Max Employees Allowed', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$limit Employees', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: AdminColors.textSecondary),
                                        onPressed: limit > 1 ? () => setDlgState(() => limit--) : null,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AdminColors.primaryLight),
                                        onPressed: () => setDlgState(() => limit++),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                AdminStateService.instance.addOrganization(
                  name: nameCtrl.text,
                  ownerName: ownerCtrl.text,
                  phone: phoneCtrl.text,
                  email: emailCtrl.text,
                  plan: selectedPlan,
                  employeeLimit: limit,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Organization "${nameCtrl.text}" created successfully with unique Connect Code!'),
                    backgroundColor: AdminColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Create Organization'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLimitDialog(BuildContext context, AdminOrganization org) {
    int currentLimit = org.employeeLimit;
    String currentPlan = org.plan;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AdminColors.border),
          ),
          title: Text(
            'Modify Limits: ${org.name}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AdminColors.textPrimary),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjust the max employee/agent seat quota for this client. They can connect phones up to this limit.',
                  style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                ),
                const SizedBox(height: 20),

                Text('Plan Tier', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentPlan,
                      isExpanded: true,
                      dropdownColor: AdminColors.surfaceElevated,
                      style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                      items: ['Starter Plan', 'Growth Plan', 'Scale Pro', 'Enterprise']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() {
                            currentPlan = val;
                            if (val == 'Starter Plan') currentLimit = 5;
                            if (val == 'Growth Plan') currentLimit = 15;
                            if (val == 'Scale Pro') currentLimit = 35;
                            if (val == 'Enterprise') currentLimit = 50;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Employee Seat Limit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Text(
                          '$currentLimit Allowed Seats',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded, color: AdminColors.textSecondary),
                      onPressed: currentLimit > 1 ? () => setDlgState(() => currentLimit--) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AdminColors.primaryLight),
                      onPressed: () => setDlgState(() => currentLimit++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                AdminStateService.instance.updateOrgLimit(org.id, currentLimit, currentPlan);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Updated ${org.name} limit to $currentLimit seats ($currentPlan).'),
                    backgroundColor: AdminColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final query = _searchCtrl.text.toLowerCase().trim();
        final list = state.organizations.where((org) {
          if (_selectedStatusFilter != 'all') {
            if (_selectedStatusFilter == 'active' && org.status != OrgStatus.active) return false;
            if (_selectedStatusFilter == 'trial' && org.status != OrgStatus.trial) return false;
            if (_selectedStatusFilter == 'suspended' && org.status != OrgStatus.suspended) return false;
          }
          if (_selectedPlanFilter != 'all') {
            if (!org.plan.toLowerCase().contains(_selectedPlanFilter)) return false;
          }
          if (query.isNotEmpty) {
            final matchName = org.name.toLowerCase().contains(query);
            final matchOwner = org.ownerName.toLowerCase().contains(query);
            final matchCode = org.connectCode.toLowerCase().contains(query);
            final matchPhone = org.phone.toLowerCase().contains(query);
            if (!matchName && !matchOwner && !matchCode && !matchPhone) return false;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Add Org Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Organizations',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage company accounts, employee seat quotas, connect codes, and subscription status.',
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
                                content: Text('Synchronized with live Firestore database!'),
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
                      ElevatedButton.icon(
                        onPressed: () => _showAddOrgDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Organization'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    // Search Field
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search company, owner, connect code, or phone...',
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

                    // Status Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatusFilter,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                            DropdownMenuItem(value: 'active', child: Text('Active Only')),
                            DropdownMenuItem(value: 'trial', child: Text('Trial Accounts')),
                            DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                          ],
                          onChanged: (v) => setState(() => _selectedStatusFilter = v ?? 'all'),
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
                        '${list.length} Organizations',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data Table or Empty State
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
                              Icon(Icons.business_outlined, size: 48, color: AdminColors.textTertiary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                state.isLiveConnected ? 'No matching client organizations found.' : 'Loading live organizations from Firestore...',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Click "Sync Now" to refresh or "Add Organization" to register a new tenant.',
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
                            columnSpacing: 24,
                            headingRowColor: WidgetStateProperty.all(AdminColors.surfaceElevated),
                            dataRowColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.hovered)
                                  ? AdminColors.surfaceSubtle.withValues(alpha: 0.5)
                                  : AdminColors.surface,
                            ),
                            columns: [
                              DataColumn(label: Text('ORGANIZATION & CODE', style: _colHeaderStyle)),
                              DataColumn(label: Text('OWNER & CONTACT', style: _colHeaderStyle)),
                              DataColumn(label: Text('SEAT QUOTA', style: _colHeaderStyle)),
                              DataColumn(label: Text('PLAN', style: _colHeaderStyle)),
                              DataColumn(label: Text('CALLS SYNCED', style: _colHeaderStyle)),
                              DataColumn(label: Text('STATUS', style: _colHeaderStyle)),
                              DataColumn(label: Text('RENEWAL DATE', style: _colHeaderStyle)),
                              DataColumn(label: Text('ACTIONS', style: _colHeaderStyle)),
                            ],
                            rows: list.map((org) => _buildOrgRow(context, org)).toList(),
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

  DataRow _buildOrgRow(BuildContext context, AdminOrganization org) {
    Color statusColor;
    String statusLabel;
    switch (org.status) {
      case OrgStatus.active:
        statusColor = AdminColors.success;
        statusLabel = 'Active';
        break;
      case OrgStatus.trial:
        statusColor = AdminColors.warning;
        statusLabel = 'Trial';
        break;
      case OrgStatus.suspended:
        statusColor = AdminColors.error;
        statusLabel = 'Suspended';
        break;
    }

    final usageRatio = org.activeEmployeesCount / (org.employeeLimit == 0 ? 1 : org.employeeLimit);
    final isFull = org.activeEmployeesCount >= org.employeeLimit;

    return DataRow(
      cells: [
        // Org Name & Connect Code
        DataCell(
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0D9488)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  org.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    org.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminColors.codePillBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Text(
                          org.connectCode,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.codePillText,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.copy_rounded, size: 12, color: AdminColors.textSecondary),
                        tooltip: 'Copy Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: org.connectCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied ${org.connectCode} to clipboard'),
                              backgroundColor: AdminColors.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Owner & Phone
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(org.ownerName, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AdminColors.textPrimary, fontSize: 13)),
              Text(org.phone, style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),

        // Seat Quota Progress
        DataCell(
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${org.activeEmployeesCount} / ${org.employeeLimit}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFull ? AdminColors.warning : AdminColors.textPrimary,
                      ),
                    ),
                    Text('${(usageRatio * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usageRatio.clamp(0.0, 1.0),
                    backgroundColor: AdminColors.surfaceSubtle,
                    color: isFull ? AdminColors.warning : AdminColors.primaryLight,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Plan Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.primaryGlow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              org.plan,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.primaryLight),
            ),
          ),
        ),

        // Calls Synced
        DataCell(
          Text(
            NumberFormat('#,###').format(org.totalCallsSynced),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 13),
          ),
        ),

        // Status Pill
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ],
            ),
          ),
        ),

        // Renewal Date
        DataCell(
          Text(
            DateFormat('d MMM yyyy').format(org.renewalDate),
            style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12),
          ),
        ),

        // Action Buttons
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 16, color: AdminColors.primaryLight),
                tooltip: 'Modify Limits & Plan',
                onPressed: () => _showEditLimitDialog(context, org),
              ),
              IconButton(
                icon: Icon(
                  org.status == OrgStatus.active ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                  size: 16,
                  color: org.status == OrgStatus.active ? AdminColors.warning : AdminColors.success,
                ),
                tooltip: org.status == OrgStatus.active ? 'Suspend Account' : 'Reactivate Account',
                onPressed: () => AdminStateService.instance.toggleOrgStatus(org.id),
              ),
              IconButton(
                icon: Icon(Icons.open_in_new_rounded, size: 16, color: AdminColors.textSecondary),
                tooltip: 'Log In As Client (Impersonate Portal)',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Impersonating ${org.name} Portal session (Connect Code: ${org.connectCode}).'),
                      backgroundColor: AdminColors.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
