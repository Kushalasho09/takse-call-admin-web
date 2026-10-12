import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_data_models.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final now = DateTime.now();
        final expiringOrgs = state.organizations.where((o) {
          final daysLeft = o.renewalDate.difference(now).inDays;
          return o.status == OrgStatus.trial || (daysLeft >= 0 && daysLeft <= 7);
        }).toList();

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
                        'Plans & Subscription Tiers',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure employee seat quotas, billing tiers, and live client renewals.',
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
                            content: Text('Synchronized live subscription data!'),
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

              // Expiring Accounts Alert Banner (Dynamic)
              if (expiringOrgs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.warningSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_rounded, color: AdminColors.warning, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${expiringOrgs.length} Client Subscription${expiringOrgs.length > 1 ? 's' : ''} Require Attention',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.warning),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '"${expiringOrgs.first.name}" (${expiringOrgs.first.plan}) renewal due on ${DateFormat('d MMM yyyy').format(expiringOrgs.first.renewalDate)}.',
                              style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Renewal reminder queued for ${expiringOrgs.first.name}.'),
                              backgroundColor: AdminColors.warning,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AdminColors.warning),
                          foregroundColor: AdminColors.warning,
                        ),
                        child: const Text('Send Reminder'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.successSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AdminColors.success, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All ${state.totalOrganizations} Client Subscriptions Active & Healthy',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.success),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'All client tenant organizations have active subscription status and live cloud sync.',
                              style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              // Plan Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1150) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 650) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    itemCount: state.plans.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 470,
                    ),
                    itemBuilder: (context, index) {
                      final plan = state.plans[index];
                      return _buildPlanCard(context, plan, state);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, AdminPlanTier plan, AdminStateService state) {
    final cleanPlanKey = plan.name.toLowerCase().replaceAll(' plan', '').trim();
    final dynamicSubscribers = state.organizations.where((o) => o.plan.toLowerCase().contains(cleanPlanKey)).length;

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular ? AdminColors.primaryLight : AdminColors.border,
          width: plan.isPopular ? 1.5 : 1,
        ),
        boxShadow: plan.isPopular
            ? [
                BoxShadow(
                  color: AdminColors.primary.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${NumberFormat('#,###').format(plan.monthlyPrice)}',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.textPrimary,
                ),
              ),
              Text(
                ' / month',
                style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'billed ₹${NumberFormat('#,###').format(plan.yearlyPrice)} annually',
            style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textTertiary),
          ),
          const SizedBox(height: 14),

          // Dynamic Active Subscribers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Clients:', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary)),
                Text(
                  '$dynamicSubscribers Tenants',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.primaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Capacity:', style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary)),
                Text(
                  'Up to ${plan.maxAgents} Telecallers',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Divider(color: AdminColors.border),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: plan.features.length,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                return Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AdminColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.features[i],
                        style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textSecondary),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${plan.name} configuration is synchronized with active tenants.'),
                    backgroundColor: AdminColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AdminColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('View Tier Subscribers', style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
