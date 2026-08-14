import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/bordereau_colis_status.dart';
import '../../widgets/katian_scaffold.dart';
import 'convoyeur_bordereau_detail_screen.dart';

class ConvoyeurMissionsScreen extends StatefulWidget {
  const ConvoyeurMissionsScreen({super.key});

  @override
  State<ConvoyeurMissionsScreen> createState() => _ConvoyeurMissionsScreenState();
}

class _ConvoyeurMissionsScreenState extends State<ConvoyeurMissionsScreen> {
  List<BordereauExpedition> _missions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<AppProvider>().bordereaux.list(limit: 50);
      if (mounted) setState(() => _missions = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = context.read<AppProvider>().formatError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(BordereauExpedition bordereau) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConvoyeurBordereauDetailScreen(bordereauId: bordereau.id),
      ),
    );
  }

  String _statusLabel(String? status) => bordereauStatusLabel(status);

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final user = context.watch<AppProvider>().user;

    return KatianScaffold(
      title: 'Mes missions',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ext.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.assignedCarLabel != null
                            ? 'Véhicule : ${user.assignedCarLabel}'
                            : 'Aucun véhicule affecté',
                        style: TextStyle(color: ext.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bordereaux assignés',
              style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: ext.textSecondary)),
                              const SizedBox(height: 12),
                              FilledButton(onPressed: _loadMissions, child: const Text('Réessayer')),
                            ],
                          ),
                        ),
                      )
                    : _missions.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune mission pour le moment.\nUn bordereau vous sera assigné par votre gare.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ext.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            color: KatianColors.red,
                            onRefresh: _loadMissions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _missions.length,
                              itemBuilder: (context, index) {
                                final b = _missions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    onTap: () => _openDetail(b),
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: KatianColors.redLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_2_rounded,
                                        color: KatianColors.red,
                                      ),
                                    ),
                                    title: Text(
                                      b.number,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      '${b.departureLabel} · ${b.parcelCount} colis\n'
                                      '${b.departureRelayName ?? '—'} · ${_statusLabel(b.status)}',
                                    ),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
