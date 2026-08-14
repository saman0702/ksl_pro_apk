import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../models/traceability.dart';

/// Timeline verticale — alignée RelayPackages.js TrackingTimeline.
class TraceabilityTimeline extends StatelessWidget {
  const TraceabilityTimeline({
    super.key,
    required this.events,
    this.scrollController,
  });

  final List<TimelineStep> events;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: ext.textSecondary),
            const SizedBox(height: 8),
            Text(
              'Aucun événement de traçabilité',
              style: TextStyle(color: ext.textSecondary),
            ),
          ],
        ),
      );
    }

    final items = List.generate(events.length, (index) {
      final step = events[index];
      return _TimelineRow(
        step: step,
        isFirst: index == 0,
        isLast: index == events.length - 1,
        isCurrent: index == events.length - 1,
      );
    });

    if (scrollController == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final step = events[index];
        return _TimelineRow(
          step: step,
          isFirst: index == 0,
          isLast: index == events.length - 1,
          isCurrent: index == events.length - 1,
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
  });

  final TimelineStep step;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final cfg = step.config;
    final accent = cfg.accentColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.35),
                          accent,
                        ],
                      ),
                    ),
                  ),
                if (!isFirst)
                  Icon(Icons.arrow_downward_rounded, size: 16, color: accent),
                const SizedBox(height: 4),
                _StepNode(step: step, isCurrent: isCurrent),
                if (!isLast) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent,
                            step.nextAccent?.withValues(alpha: 0.5) ??
                                accent.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: isFirst ? 0 : 4),
              child: Container(
                decoration: BoxDecoration(
                  color: ext.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ext.border.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: ext.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: accent.withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            step.eventTypeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (step.location != null && step.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place_outlined, size: 15, color: accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              step.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: ext.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (step.fromToArrow != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.fromToArrow!.$1,
                              style: TextStyle(fontSize: 11, color: ext.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: accent,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step.fromToArrow!.$2,
                              style: TextStyle(fontSize: 11, color: ext.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                    ...step.details.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          d,
                          style: TextStyle(fontSize: 11, color: ext.textSecondary),
                        ),
                      ),
                    ),
                    if (step.formattedDate != null) ...[
                      const SizedBox(height: 10),
                      Divider(height: 1, color: ext.textSecondary.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: ext.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            step.formattedDate!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ext.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({required this.step, required this.isCurrent});

  final TimelineStep step;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final cfg = step.config;
    return Container(
      width: isCurrent ? 44 : 38,
      height: isCurrent ? 44 : 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? cfg.accentColor : cfg.accentColor.withValues(alpha: 0.12),
        border: Border.all(
          color: cfg.accentColor,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: cfg.accentColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        cfg.icon,
        size: isCurrent ? 22 : 18,
        color: isCurrent ? Colors.white : cfg.accentColor,
      ),
    );
  }
}

/// Parse API events → étapes chronologiques (ancien → récent).
List<TimelineStep> buildTimelineSteps(List<TraceabilityEvent> apiEvents) {
  final chronological = apiEvents.reversed.toList();
  final steps = chronological.map(TimelineStep.fromEvent).toList();
  for (var i = 0; i < steps.length - 1; i++) {
    steps[i] = steps[i].copyWith(nextAccent: steps[i + 1].config.accentColor);
  }
  return steps;
}

String? _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dt);
  } catch (_) {
    return raw;
  }
}

class TimelineStepConfig {
  const TimelineStepConfig({
    required this.icon,
    required this.accentColor,
    required this.label,
  });

  final IconData icon;
  final Color accentColor;
  final String label;

  static TimelineStepConfig forEventType(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'CREATION':
        return const TimelineStepConfig(
          icon: Icons.inventory_2_outlined,
          accentColor: KatianColors.blue,
          label: 'Création',
        );
      case 'DEPART':
      case 'RETURN_DEPART':
        return const TimelineStepConfig(
          icon: Icons.local_shipping_outlined,
          accentColor: KatianColors.orange,
          label: 'Expédition',
        );
      case 'RECEPTION':
      case 'RETURN_RECEPTION':
        return const TimelineStepConfig(
          icon: Icons.download_done_outlined,
          accentColor: Colors.deepPurple,
          label: 'Réception',
        );
      case 'ARRIVEE_DESTINATION':
        return const TimelineStepConfig(
          icon: Icons.flag_outlined,
          accentColor: Colors.green,
          label: 'Arrivée destination',
        );
      case 'RETRAIT':
      case 'COLIS_LIVRE_AU_DESTINATAIRE':
        return const TimelineStepConfig(
          icon: Icons.check_circle_outline,
          accentColor: Colors.green,
          label: 'Retrait / Livré',
        );
      case 'RETOUR':
      case 'RETOURNE':
      case 'RETURN_ARRIVEE':
      case 'RETURN_REQUEST':
        return const TimelineStepConfig(
          icon: Icons.rotate_left,
          accentColor: KatianColors.red,
          label: 'Retour',
        );
      case 'PERTE':
      case 'PERDUE':
      case 'ECHEC_DE_LIVRAISON':
        return const TimelineStepConfig(
          icon: Icons.warning_amber_outlined,
          accentColor: KatianColors.red,
          label: 'Incident',
        );
      case 'ANNULATION':
        return const TimelineStepConfig(
          icon: Icons.cancel_outlined,
          accentColor: Colors.grey,
          label: 'Annulation',
        );
      case 'RETROUVE':
        return const TimelineStepConfig(
          icon: Icons.restore_outlined,
          accentColor: Colors.teal,
          label: 'Retrouvé',
        );
      case 'EN_LIVRAISON':
        return const TimelineStepConfig(
          icon: Icons.delivery_dining_outlined,
          accentColor: KatianColors.blue,
          label: 'En livraison',
        );
      default:
        return const TimelineStepConfig(
          icon: Icons.circle_outlined,
          accentColor: KatianColors.red,
          label: 'Événement',
        );
    }
  }
}

class TimelineStep {
  const TimelineStep({
    required this.id,
    required this.title,
    required this.eventTypeLabel,
    required this.config,
    this.location,
    this.fromToArrow,
    this.details = const [],
    this.formattedDate,
    this.nextAccent,
  });

  final int? id;
  final String title;
  final String eventTypeLabel;
  final TimelineStepConfig config;
  final String? location;
  final (String, String)? fromToArrow;
  final List<String> details;
  final String? formattedDate;
  final Color? nextAccent;

  TimelineStep copyWith({Color? nextAccent}) => TimelineStep(
        id: id,
        title: title,
        eventTypeLabel: eventTypeLabel,
        config: config,
        location: location,
        fromToArrow: fromToArrow,
        details: details,
        formattedDate: formattedDate,
        nextAccent: nextAccent ?? this.nextAccent,
      );

  factory TimelineStep.fromEvent(TraceabilityEvent event) {
    final cfg = TimelineStepConfig.forEventType(event.eventType);
    final typeLabels = {
      'DEPART': 'Colis expédié',
      'RECEPTION': 'Colis en transit',
    };

    String? location;
    (String, String)? fromToArrow;

    if (event.fromRelayName != null && event.toRelayName != null) {
      fromToArrow = (event.fromRelayName!, event.toRelayName!);
      location = 'De ${event.fromRelayName} vers ${event.toRelayName}';
    } else if (event.relayName != null) {
      location = event.relayName;
    } else if (event.fromRelayName != null) {
      location = 'Depuis ${event.fromRelayName}';
    } else if (event.toRelayName != null) {
      location = 'Vers ${event.toRelayName}';
    }

    final details = <String>[];
    if (event.bordereauNumber != null && event.bordereauNumber!.isNotEmpty) {
      details.add('Bordereau : ${event.bordereauNumber}');
    }
    if (event.driverName != null && event.driverName!.isNotEmpty) {
      details.add('Chauffeur : ${event.driverName}');
    }
    if (event.recipientName != null && event.recipientName!.isNotEmpty) {
      details.add('Destinataire : ${event.recipientName}');
    }
    if (event.actorType != null && event.actorType!.isNotEmpty) {
      details.add('Par : ${event.actorType}');
    }

    final eventType = (event.eventType ?? '').toUpperCase();
    final label = typeLabels[eventType] ??
        event.eventTypeDisplay ??
        eventType.replaceAll('_', ' ');

    return TimelineStep(
      id: event.id,
      title: event.description ?? label,
      eventTypeLabel: label,
      config: cfg,
      location: fromToArrow == null ? location : null,
      fromToArrow: fromToArrow,
      details: details,
      formattedDate: _formatDate(event.createdAt),
    );
  }
}
