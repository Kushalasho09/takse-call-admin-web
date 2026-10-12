import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class LeadManagementScreen extends StatefulWidget {
  const LeadManagementScreen({super.key});

  @override
  State<LeadManagementScreen> createState() => _LeadManagementScreenState();
}

class _LeadManagementScreenState extends State<LeadManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedState = 'all';
  String _selectedKyc = 'all';
  String _selectedUserType = 'all';
  int _currentPage = 0;
  static const int _pageSize = 15;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showWebhookApiDialog(BuildContext context) {
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
                color: AdminColors.primaryGlow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.webhook_rounded, color: AdminColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NodeJS Backend -> Firebase Webhook Sync',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary),
                  ),
                  Text(
                    'Share this URL & Schema with your Takse Admin backend team',
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
                Text(
                  '1. Webhook HTTP POST Endpoint:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          'https://us-central1-takse-call.cloudfunctions.net/syncLeadsWebhook',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AdminColors.accentCyan),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy Endpoint URL',
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                            text: 'https://us-central1-takse-call.cloudfunctions.net/syncLeadsWebhook',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Endpoint URL copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '2. Headers required from NodeJS Backend:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: SelectableText(
                    'Content-Type: application/json\nx-api-key: takse_sec_lead_9978_live_key',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AdminColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '3. Sample Payload (Single Lead or Array []):',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    '''{
  "name": "Debashis satpathy",
  "email": "debashissatapathy96@gmail.com",
  "mobile_number": "7609975577",
  "Reg Status": "Completed",
  "Reg Fee": "0",
  "KYC Updated": "pending",
  "Status": "TRUE",
  "referrals": 0,
  "orders": 0,
  "User Type": "TSP",
  "State": "ODISHA",
  "District": "Khurda",
  "Block": "Bhubaneswar",
  "Village": "Patia",
  "Pincode": "751024",
  "Shop Name": "Satpathy Telecom"
}''',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF38BDF8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showGoogleSheetSyncDialog(BuildContext context) {
    const sheetUrl = 'https://docs.google.com/spreadsheets/d/1m9KrQh6HOeic9s_qUmM63-lkTQLbzzQk6vDIZbvDcBM/edit?usp=sharing';
    const appsScriptCode = r'''/**
 * ⚡ Takse Call - Smart Google Sheet to Firebase Sync
 * Features:
 * 1. Checks and updates Column Q ('Sync Status') so only new/unsynced leads are processed.
 * 2. Firestore Document ID is strictly the 10-digit mobile number (Zero Duplication Guaranteed).
 */
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('⚡ Takse Sync')
    .addItem('🚀 Sync New/Unsynced Leads to Firebase', 'syncNewLeadsOnly')
    .addItem('🔄 Force Sync All Leads (With De-duplication)', 'syncAllLeads')
    .addToUi();
}

function syncNewLeadsOnly() {
  syncLeadsProcess(false);
}

function syncAllLeads() {
  syncLeadsProcess(true);
}

function syncLeadsProcess(forceAll) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  const data = sheet.getDataRange().getValues();
  
  if (data.length <= 1) {
    SpreadsheetApp.getUi().alert('No leads found in sheet.');
    return;
  }
  
  const headers = data[0].map(h => String(h).trim());
  let syncStatusColIdx = headers.indexOf('Sync Status');
  
  if (syncStatusColIdx === -1) {
    syncStatusColIdx = headers.length;
    sheet.getRange(1, syncStatusColIdx + 1).setValue('Sync Status');
    SpreadsheetApp.flush();
  }
  
  const leadsToSync = [];
  const rowIndices = [];
  
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const statusVal = String(row[syncStatusColIdx] || '').trim();
    
    if (!forceAll && statusVal === 'SYNCED') {
      continue;
    }
    
    const lead = {};
    for (let j = 0; j < Math.min(headers.length, 16); j++) {
      lead[headers[j]] = row[j];
    }
    
    const phone = String(lead['mobile_number'] || lead['phone'] || '').replace(/[^0-9]/g, '');
    if (phone.length >= 10) {
      leadsToSync.push(lead);
      rowIndices.push(i + 1);
    }
  }
  
  if (leadsToSync.length === 0) {
    SpreadsheetApp.getUi().alert('Sabhi leads already Firebase me synced hain! Koi nayi lead nahi mili.');
    return;
  }
  
  const WEBHOOK_URL = 'https://us-central1-takse-call.cloudfunctions.net/syncLeadsWebhook';
  const API_KEY = 'takse_sec_lead_9978_live_key';
  const BATCH_SIZE = 250;
  let totalSuccessful = 0;
  
  SpreadsheetApp.getActiveSpreadsheet().toast(`Syncing ${leadsToSync.length} leads to Firebase...`, 'Takse Sync', 10);
  
  for (let i = 0; i < leadsToSync.length; i += BATCH_SIZE) {
    const chunk = leadsToSync.slice(i, i + BATCH_SIZE);
    const chunkRows = rowIndices.slice(i, i + BATCH_SIZE);
    
    const options = {
      method: 'post',
      contentType: 'application/json',
      headers: { 'x-api-key': API_KEY },
      payload: JSON.stringify({ leads: chunk }),
      muteHttpExceptions: true
    };
    
    try {
      const resp = UrlFetchApp.fetch(WEBHOOK_URL, options);
      if (resp.getResponseCode() === 200) {
        totalSuccessful += chunk.length;
        for (const r of chunkRows) {
          sheet.getRange(r, syncStatusColIdx + 1).setValue('SYNCED');
        }
        SpreadsheetApp.flush();
      }
    } catch (e) {
      Logger.log('Error syncing: ' + e.toString());
    }
  }
  
  SpreadsheetApp.getUi().alert(`✅ Mubarak! ${totalSuccessful} lead(s) Firebase me successfully sync ho gayi hain! (No duplicates created)`);
}''';

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
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected Google Sheet & Zero-Duplicate Sync',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary),
                  ),
                  Text(
                    'Automatic de-duplication: Unique Key = 10-Digit Mobile Number',
                    style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Duplicate Prevention Active: Agar 100 leads pehle se hain aur 50 nayi dali jaati hain, to Firebase me duplicate create nahi honge. Sirf 50 nayi leads hi add hongi.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AdminColors.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '1. Connected Google Sheet URL:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          sheetUrl,
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF38BDF8)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy Sheet Link',
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: sheetUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sheet URL copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '2. Google Apps Script (Sheet me 1-Click Sync Button Lagane ke liye):',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Google Sheet me Extensions > Apps Script open karein aur ye code paste karke Save karein:',
                  style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      appsScriptCode,
                      style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF34D399)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: appsScriptCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Apps Script Code copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy Apps Script Code', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF34D399),
                      side: const BorderSide(color: Color(0xFF34D399)),
                    ),
                  ),
                ),
              ],
            ),
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

  void _showLeadDetailDialog(BuildContext context, AdminLead lead) {
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
                color: AdminColors.primaryGlow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_pin_rounded, color: AdminColors.primaryLight, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name.isNotEmpty ? lead.name : lead.mobileNumber,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary),
                  ),
                  Text(
                    '${lead.userType} • ${lead.shopName.isNotEmpty ? lead.shopName : "Individual Lead"}',
                    style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
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
              _buildDetailRow('Mobile Number', lead.mobileNumber, isHighlight: true),
              _buildDetailRow('Email', lead.email.isNotEmpty ? lead.email : 'N/A'),
              _buildDetailRow('Shop / Business', lead.shopName.isNotEmpty ? lead.shopName : 'N/A'),
              _buildDetailRow('User Type', lead.userType),
              _buildDetailRow('State & District', '${lead.state} ${lead.district.isNotEmpty ? "- ${lead.district}" : ""}'),
              _buildDetailRow('Block / Village', '${lead.block} ${lead.village.isNotEmpty ? "/ ${lead.village}" : ""}'),
              _buildDetailRow('Pincode', lead.pincode.isNotEmpty ? lead.pincode : 'N/A'),
              _buildDetailRow('KYC Status', lead.kycUpdated.toUpperCase()),
              _buildDetailRow('Registration Status', '${lead.regStatus} (Fee: ₹${lead.regFee})'),
              _buildDetailRow('Referrals / Orders', '${lead.referrals} referrals • ${lead.orders} orders'),
              _buildDetailRow('Account Active', lead.status),
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

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? AdminColors.primaryLight : AdminColors.textPrimary,
              ),
            ),
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
        final rawLeads = state.leads;

        final filtered = rawLeads.where((lead) {
          if (_selectedState != 'all' && lead.state.toUpperCase() != _selectedState.toUpperCase()) {
            return false;
          }
          if (_selectedKyc != 'all' && lead.kycUpdated.toLowerCase() != _selectedKyc.toLowerCase()) {
            return false;
          }
          if (_selectedUserType != 'all' && lead.userType.toUpperCase() != _selectedUserType.toUpperCase()) {
            return false;
          }
          if (query.isNotEmpty) {
            final mName = lead.name.toLowerCase().contains(query);
            final mPhone = lead.mobileNumber.toLowerCase().contains(query);
            final mEmail = lead.email.toLowerCase().contains(query);
            final mState = lead.state.toLowerCase().contains(query);
            final mDist = lead.district.toLowerCase().contains(query);
            final mShop = lead.shopName.toLowerCase().contains(query);
            if (!mName && !mPhone && !mEmail && !mState && !mDist && !mShop) {
              return false;
            }
          }
          return true;
        }).toList();

        final uniqueStates = rawLeads
            .map((l) => l.state.toUpperCase().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()..sort();

        final uniqueTypes = rawLeads
            .map((l) => l.userType.toUpperCase().trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()..sort();

        final totalPages = max(1, (filtered.length / _pageSize).ceil());
        final safePage = _currentPage.clamp(0, totalPages - 1);
        final startIndex = safePage * _pageSize;
        final pageItems = filtered.skip(startIndex).take(_pageSize).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 14,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Takse Lead Management Hub',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AdminColors.primaryGlow,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AdminColors.primary.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'LIVE SYNC READY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AdminColors.primaryLight,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Direct real-time lead ingestion stream from Takse Admin Backend & Excel Connectors.',
                          style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showGoogleSheetSyncDialog(context),
                        icon: const Icon(Icons.table_chart_rounded, size: 16),
                        label: const Text('Google Sheet Sync'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showWebhookApiDialog(context),
                        icon: const Icon(Icons.webhook_rounded, size: 16),
                        label: const Text('Webhook API Docs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await state.seedSampleLeadsFromSheet();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loaded sample leads from Google Sheets into Firestore!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('Load Sheet Sample Leads'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminColors.textPrimary,
                          side: BorderSide(color: AdminColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await state.refreshFromFirestore();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Synchronized latest leads from Firestore!'),
                                behavior: SnackBarBehavior.floating,
                              ),
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
              ),
              const SizedBox(height: 16),

              // Connected Google Sheet Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.link_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Connected Google Sheet: ',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ZERO-DUPLICATES ACTIVE',
                                      style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'https://docs.google.com/spreadsheets/d/1m9KrQh6HOeic9s_qUmM63-lkTQLbzzQk6vDIZbvDcBM',
                                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _showGoogleSheetSyncDialog(context),
                            icon: const Icon(Icons.settings_suggest_rounded, size: 15),
                            label: const Text('View Sync Settings & Apps Script'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Summary KPI Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Active Leads',
                      value: '${rawLeads.length}',
                      subtitle: 'Synced in Firestore',
                      icon: Icons.assignment_ind_rounded,
                      color: AdminColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Completed Registration',
                      value: '${rawLeads.where((l) => l.regStatus.toLowerCase() == 'completed').length}',
                      subtitle: 'Verified mobile profiles',
                      icon: Icons.verified_user_rounded,
                      color: AdminColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'KYC Pending Leads',
                      value: '${rawLeads.where((l) => l.kycUpdated.toLowerCase() == 'pending').length}',
                      subtitle: 'Action required by telecallers',
                      icon: Icons.hourglass_top_rounded,
                      color: AdminColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active States Covered',
                      value: '${uniqueStates.length}',
                      subtitle: 'National territory reach',
                      icon: Icons.map_rounded,
                      color: AdminColors.accentCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Filter Bar
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 950;
                    final stateFilterWidget = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedState,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All States')),
                            ...uniqueStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedState = v ?? 'all';
                            _currentPage = 0;
                          }),
                        ),
                      ),
                    );

                    final kycFilterWidget = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKyc,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All KYC Status')),
                            DropdownMenuItem(value: 'pending', child: Text('KYC Pending')),
                            DropdownMenuItem(value: 'completed', child: Text('KYC Completed')),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedKyc = v ?? 'all';
                            _currentPage = 0;
                          }),
                        ),
                      ),
                    );

                    final userTypeWidget = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUserType,
                          dropdownColor: AdminColors.surfaceElevated,
                          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All User Types')),
                            ...uniqueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedUserType = v ?? 'all';
                            _currentPage = 0;
                          }),
                        ),
                      ),
                    );

                    final countPillWidget = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${filtered.length} Leads',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() => _currentPage = 0),
                            style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search by lead name, phone, email, state, or shop name...',
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
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              stateFilterWidget,
                              kycFilterWidget,
                              userTypeWidget,
                              countPillWidget,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() => _currentPage = 0),
                            style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search by lead name, phone, email, state, or shop name...',
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
                        stateFilterWidget,
                        const SizedBox(width: 14),
                        kycFilterWidget,
                        const SizedBox(width: 14),
                        userTypeWidget,
                        const SizedBox(width: 14),
                        countPillWidget,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Leads Table
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_ind_outlined, size: 48, color: AdminColors.textTertiary.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'No leads found matching your criteria.',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Click "Load Sheet Sample Leads" above to populate leads from your Google Sheet or push via Webhook.',
                                style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textTertiary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => state.seedSampleLeadsFromSheet(),
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Load Sample Leads Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminColors.primary,
                                  foregroundColor: Colors.white,
                                ),
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
                                columnSpacing: 24,
                                headingRowColor: WidgetStateProperty.all(AdminColors.surfaceElevated),
                                columns: [
                                  DataColumn(label: Text('LEAD NAME & PHONE', style: _colHeaderStyle)),
                                  DataColumn(label: Text('EMAIL', style: _colHeaderStyle)),
                                  DataColumn(label: Text('USER TYPE', style: _colHeaderStyle)),
                                  DataColumn(label: Text('STATE & DISTRICT', style: _colHeaderStyle)),
                                  DataColumn(label: Text('REG STATUS', style: _colHeaderStyle)),
                                  DataColumn(label: Text('KYC UPDATED', style: _colHeaderStyle)),
                                  DataColumn(label: Text('SHOP / BUSINESS', style: _colHeaderStyle)),
                                  DataColumn(label: Text('STATS', style: _colHeaderStyle)),
                                  DataColumn(label: Text('ACTIONS', style: _colHeaderStyle)),
                                ],
                                rows: pageItems.map((lead) => _buildLeadRow(context, lead)).toList(),
                              ),
                            ),
                          ),

                          // Pagination Controls
                          if (filtered.length > _pageSize)
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
                                    'Showing ${startIndex + 1}-${min(startIndex + _pageSize, filtered.length)} of ${filtered.length} leads',
                                    style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                        onPressed: safePage > 0
                                            ? () => setState(() => _currentPage = safePage - 1)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Page ${safePage + 1} of $totalPages',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                        onPressed: safePage < totalPages - 1
                                            ? () => setState(() => _currentPage = safePage + 1)
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AdminColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildLeadRow(BuildContext context, AdminLead lead) {
    final isKycDone = lead.kycUpdated.toLowerCase() == 'completed' || lead.kycUpdated.toLowerCase() == 'verified';

    return DataRow(
      cells: [
        // Name & Phone
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lead.name.isNotEmpty ? lead.name : 'Unknown User',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, size: 12, color: AdminColors.primaryLight),
                  const SizedBox(width: 4),
                  Text(
                    lead.mobileNumber,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AdminColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Email
        DataCell(
          Text(
            lead.email.isNotEmpty ? lead.email : '—',
            style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12),
          ),
        ),

        // User Type
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AdminColors.primaryGlow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AdminColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              lead.userType,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.primaryLight),
            ),
          ),
        ),

        // Location
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lead.state.isNotEmpty ? lead.state : 'India',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: 12),
              ),
              if (lead.district.isNotEmpty)
                Text(
                  lead.district,
                  style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ),

        // Reg Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              lead.regStatus,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.success),
            ),
          ),
        ),

        // KYC Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isKycDone ? AdminColors.success.withValues(alpha: 0.12) : AdminColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              lead.kycUpdated.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isKycDone ? AdminColors.success : AdminColors.warning,
              ),
            ),
          ),
        ),

        // Shop Name
        DataCell(
          Text(
            lead.shopName.isNotEmpty ? lead.shopName : '—',
            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 12),
          ),
        ),

        // Stats (Referrals & Orders)
        DataCell(
          Text(
            '${lead.referrals} ref • ${lead.orders} ord',
            style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 11),
          ),
        ),

        // Actions
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18),
            color: AdminColors.primaryLight,
            tooltip: 'View Full Lead Details',
            onPressed: () => _showLeadDetailDialog(context, lead),
          ),
        ),
      ],
    );
  }
}
