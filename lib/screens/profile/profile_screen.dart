import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../widgets/katian_avatar.dart';
import '../../widgets/katian_scaffold.dart';
import '../../widgets/theme_switcher.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final _currency = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadFinanceSummary();
    });
  }

  String _formatMoney(double value) => '${_currency.format(value)} FCFA';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.user;
    final finance = app.financeSummary;
    final ext = context.katian;
    final relay = user?.relayPoint;

    return KatianScaffold(
      title: 'Profil',
      body: RefreshIndicator(
        color: KatianColors.red,
        onRefresh: () async {
          await app.loadFinanceSummary();
          await app.loadDashboardStats();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _UserHeaderCard(user: user, ext: ext),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Point relais',
              icon: Icons.storefront_outlined,
              child: _RelayDetails(relay: relay, user: user, ext: ext),
            ),
            if (!user.isAgent) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Finances',
                icon: Icons.account_balance_wallet_outlined,
                child: app.financeLoading && finance == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: KatianColors.red),
                        ),
                      )
                    : finance == null
                        ? Text(
                            'Impossible de charger les données financières.',
                            style: TextStyle(color: ext.textSecondary),
                          )
                        : _FinanceDetails(
                            finance: finance,
                            ext: ext,
                            formatMoney: _formatMoney,
                          ),
              ),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Compte',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '—',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: user?.phone ?? '—',
                  ),
                  if (user?.address?.trim().isNotEmpty == true) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Adresse',
                      value: user!.address!,
                    ),
                  ],
                  if (user?.isCredit == true) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.credit_card_outlined,
                      label: 'Compte',
                      value: 'Crédit activé',
                      valueColor: KatianColors.orange,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: const ThemeSwitcher(),
              ),
            ),
            const SizedBox(height: 24),
            KatianActionButtons.elevated(
              onPressed: () async {
                await app.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              label: 'Se déconnecter',
              icon: Icons.logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: ext.surface,
                foregroundColor: KatianColors.red,
                side: const BorderSide(color: KatianColors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeaderCard extends StatelessWidget {
  const _UserHeaderCard({required this.user, required this.ext});

  final KatianUser? user;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            KatianAvatar(
              size: 64,
              imageUrl: user?.displayLogo,
              initial: user?.avatarInitial ?? 'K',
              backgroundColor: KatianColors.redLight,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: ext.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.roleLabel ?? '', style: TextStyle(color: ext.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    user?.displayRelayName ?? '',
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: KatianColors.red),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ext.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _RelayDetails extends StatelessWidget {
  const _RelayDetails({
    required this.relay,
    required this.user,
    required this.ext,
  });

  final RelayPointInfo? relay;
  final KatianUser? user;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    if (relay == null) {
      return Text(
        'Aucun point relais associé à ce compte.',
        style: TextStyle(color: ext.textSecondary),
      );
    }

    return Column(
      children: [
        _DetailRow(
          icon: Icons.badge_outlined,
          label: 'Nom de la gare',
          value: relay!.name ?? user?.displayRelayName ?? '—',
        ),
        if (relay!.locationLine.isNotEmpty) ...[
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.map_outlined,
            label: 'Localisation',
            value: relay!.locationLine,
          ),
        ],
        if (relay!.address?.trim().isNotEmpty == true) ...[
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.place_outlined,
            label: 'Adresse',
            value: relay!.address!,
          ),
        ],
        if (relay!.businessNumber?.trim().isNotEmpty == true) ...[
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.numbers_outlined,
            label: 'N° entreprise',
            value: relay!.businessNumber!,
          ),
        ],
        const Divider(height: 20),
        _DetailRow(
          icon: Icons.toggle_on_outlined,
          label: 'Statut',
          value: relay!.available == false ? 'Indisponible' : 'Opérationnel',
          valueColor: relay!.available == false ? KatianColors.orange : KatianColors.green,
          leadingDotColor: relay!.available == false ? KatianColors.orange : KatianColors.green,
        ),
        if (user?.gerantName != null) ...[
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.supervisor_account_outlined,
            label: 'Gérant',
            value: user!.gerantName!,
          ),
        ],
        if (user?.gerantPhone != null) ...[
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.call_outlined,
            label: 'Tél. gérant',
            value: user!.gerantPhone!,
          ),
        ],
        if (_hasCommissionRates(relay!)) ...[
          const SizedBox(height: 16),
          Text(
            'Taux de commission',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (relay!.commissionRateRecep != null)
                _RateChip(label: 'Réception', value: relay!.commissionRateRecep!),
              if (relay!.commissionRateExp != null)
                _RateChip(label: 'Expédition', value: relay!.commissionRateExp!),
              if (relay!.commissionRatePal != null)
                _RateChip(label: 'PAL', value: relay!.commissionRatePal!),
            ],
          ),
        ],
      ],
    );
  }

  bool _hasCommissionRates(RelayPointInfo relay) {
    return relay.commissionRateRecep != null ||
        relay.commissionRateExp != null ||
        relay.commissionRatePal != null;
  }
}

class _FinanceDetails extends StatelessWidget {
  const _FinanceDetails({
    required this.finance,
    required this.ext,
    required this.formatMoney,
  });

  final RelayFinanceSummary finance;
  final KatianThemeExtension ext;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final unpaid = finance.unpaidInvoices.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [KatianColors.red, KatianColors.redDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Redevance à verser',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                formatMoney(finance.redevanceDue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${finance.unpaidInvoicesCount} facture(s) en attente',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _MoneyTile(
              label: 'Revenu total',
              value: formatMoney(finance.totalRevenue),
              icon: Icons.trending_up,
              color: KatianColors.green,
              ext: ext,
            ),
            _MoneyTile(
              label: 'Redevance réglée',
              value: formatMoney(finance.redevancePaid),
              icon: Icons.check_circle_outline,
              color: KatianColors.teal,
              ext: ext,
            ),
            _MoneyTile(
              label: 'Montant à régler',
              value: formatMoney(finance.amountToSettle),
              icon: Icons.pending_actions_outlined,
              color: KatianColors.orange,
              ext: ext,
            ),
            _MoneyTile(
              label: 'Factures réglées',
              value: formatMoney(finance.amountSettled),
              icon: Icons.receipt_long_outlined,
              color: KatianColors.blue,
              ext: ext,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Colis traités',
                value: '${finance.parcelCount}',
                ext: ext,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Colis crédit',
                value: '${finance.creditParcelsCount}',
                ext: ext,
              ),
            ),
          ],
        ),
        if (unpaid.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Factures en attente',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...unpaid.map(
            (invoice) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InvoiceRow(invoice: invoice, formatMoney: formatMoney, ext: ext),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.leadingDotColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? leadingDotColor;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ext.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ext.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (leadingDotColor != null)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: leadingDotColor, shape: BoxShape.circle),
          ),
      ],
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KatianColors.redLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KatianColors.red.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: ext.textSecondary)),
          Text(
            '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} %',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: KatianColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.ext,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 11, color: ext.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ext.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.ext,
  });

  final String label;
  final String value;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ext.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: ext.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ext.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.invoice,
    required this.formatMoney,
    required this.ext,
  });

  final FinanceInvoicePreview invoice;
  final String Function(double) formatMoney;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    final amount = invoice.amount ?? 0;
    final status = invoice.isPaid ? 'Payée' : 'Non payée';
    final statusColor = invoice.isPaid ? KatianColors.green : KatianColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: ext.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceType?.replaceAll('_', ' ') ?? 'Facture #${invoice.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ext.textPrimary,
                  ),
                ),
                if (invoice.issueDate != null)
                  Text(
                    invoice.issueDate!,
                    style: TextStyle(fontSize: 11, color: ext.textSecondary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ext.textPrimary,
                  fontSize: 13,
                ),
              ),
              Text(
                status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on KatianUser? {
  bool get isAgent => this?.isAgent ?? false;
}
