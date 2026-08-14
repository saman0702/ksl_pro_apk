import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/config.dart';
import '../models/models.dart';
import '../utils/shipment_document_data.dart';
import 'pdf_fonts.dart';

class DocumentService {
  DocumentService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  PdfFonts? _fonts;

  Future<PdfFonts> _fontsOrLoad() async {
    _fonts ??= await PdfFonts.load();
    return _fonts!;
  }

  Future<void> generateInvoice(
    KatianExpedition parcel,
    KatianUser? user,
  ) async {
    final fonts = await _fontsOrLoad();
    final data = ShipmentDocumentData.fromParcel(parcel, user);
    final logo = await _loadLogo(data.logoUrl, data.gerantId);
    final pdf = pw.Document(theme: fonts.theme);
    final dateStr = _formatDate(data.createdAt);
    final amount = data.amount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('DATE: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    'FACTURE N°: ${data.trackingNumber}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              _logoWidget(logo, data.companyName),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _partyBlock(
                  'ÉMETTEUR',
                  data.senderName ?? data.companyName ?? 'KATIAN LOGISTIQUE',
                  data.senderAddress ?? "Abidjan, Côte d'Ivoire",
                  data.senderPhone ?? '',
                  data.senderEmail,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _partyBlock(
                  'DESTINATAIRE',
                  '${data.recipientName ?? ''} ${data.recipientPrenom ?? ''}'.trim(),
                  data.destinationRelayName ?? 'Non spécifié',
                  data.recipientPhone ?? '',
                  null,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          _invoiceTable(amount, data.packageContent ?? "Service d'expédition"),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              "Merci d'avoir choisi KATIAN SERVICE LOGISTIQUE",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              '© Katian Service Logistique - Tous droits réservés',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    await _saveAndOpen(
      await pdf.save(),
      'Facture_${_safeName(data.trackingNumber)}.pdf',
    );
  }

  Future<void> generateCashReceipt(
    KatianExpedition parcel,
    KatianUser? user,
  ) async {
    final fonts = await _fontsOrLoad();
    final data = ShipmentDocumentData.fromParcel(parcel, user);
    final logo = await _loadLogo(data.logoUrl, data.gerantId);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy', 'fr_FR').format(now);
    final timeStr = DateFormat('HH:mm', 'fr_FR').format(now);
    final relayHeader =
        data.relayEmissionName ?? data.originRelayName ?? 'Point Relais';

    const receiptFormat = PdfPageFormat(
      97 * PdfPageFormat.mm,
      230 * PdfPageFormat.mm,
    );

    final pdf = pw.Document(theme: fonts.theme);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: receiptFormat,
        margin: const pw.EdgeInsets.all(8 * PdfPageFormat.mm),
        build: (context) => [
          pw.Center(child: _logoWidget(logo, data.companyName, compact: true)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
            child: pw.Center(
              child: pw.Text(
                relayHeader,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text('Date: $dateStr', style: _sBold(10))),
          pw.Center(child: pw.Text('Heure: $timeStr', style: _sBold(10))),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Tel Agence: ${data.relayTel ?? 'N/A'}',
              textAlign: pw.TextAlign.center,
              style: _sBold(9),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Numéro: ${data.trackingNumber}',
              textAlign: pw.TextAlign.center,
              style: _sBold(9),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Code Retrait: ${data.pickupCode ?? 'N/A'}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColor.fromHex('#D32F2F'),
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          _divider(),
          _sectionTitle('Expéditeur'),
          pw.Text(
            'Nom et Prenom: ${data.expediteurName ?? ''} ${data.expediteurPrenom ?? ''}'.trim(),
            style: _sBold(9),
          ),
          pw.Text('Tel: ${data.expediteurPhone ?? 'N/A'}', style: _sBold(9)),
          pw.SizedBox(height: 6),
          _divider(),
          _sectionTitle('Destinataire'),
          pw.Text(
            'Nom et Prenom: ${data.recipientName ?? ''} ${data.recipientPrenom ?? ''}'.trim(),
            style: _sBold(9),
          ),
          pw.Text('Tel: ${data.recipientPhone ?? 'N/A'}', style: _sBold(9)),
          pw.Text(
            'Agence de retrait: ${data.relayReceptionName ?? 'N/A'}',
            style: _sBold(9),
          ),
          pw.SizedBox(height: 6),
          _divider(),
          pw.Center(
            child: pw.Text(
              'Détails du Colis',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 4),
          _receiptTable([
            (label: 'N° suivi', value: data.trackingNumber, bold: false),
            (label: 'Type de colis', value: data.packageTypeLabel, bold: false),
            if (data.descriptionColis != null && data.descriptionColis!.isNotEmpty)
              (label: 'Description', value: data.descriptionColis!, bold: false),
            (label: 'Contenu', value: data.packageContent ?? 'Non spécifié', bold: false),
            if ((data.valeurDeclaree ?? 0) > 0)
              (
                label: 'Valeur déclarée',
                value: _formatCurrency(data.valeurDeclaree!),
                bold: false,
              ),
            if (data.pourcentageApplique != null)
              (
                label: 'Taux appliqué',
                value: '${data.pourcentageApplique!.toStringAsFixed(0)}%',
                bold: false,
              ),
            if (data.hasInsurance)
              (
                label: 'Assurance',
                value: 'Oui (${_formatCurrency(data.insuranceAmount!)})',
                bold: false,
              ),
          ]),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Détails des Coûts',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 4),
          _receiptTable([
            (
              label: data.modeExpedition?.toLowerCase().contains('relais') == true
                  ? "Frais d'envoi"
                  : 'Frais envoi',
              value: _formatCurrency(data.amount),
              bold: false,
            ),
            if (data.hasInsurance)
              (
                label: 'Assurance',
                value: _formatCurrency(data.insuranceAmount!),
                bold: false,
              ),
            if ((data.montantPal ?? 0) > 0)
              (
                label: 'Montant PAL',
                value: _formatCurrency(data.montantPal!),
                bold: false,
              ),
            (
              label: 'TOTAL',
              value: _formatCurrency(data.totalPaid),
              bold: true,
            ),
          ]),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Paiement: ${data.paymentMethod ?? 'Espèces'}',
              style: _sBold(9),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Reçu par: ${data.receivedByShort ?? data.receivedBy ?? 'N/A'}',
              style: _sBold(9),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Suivez votre colis sur: ${data.trackingUrl}',
              textAlign: pw.TextAlign.center,
              style: _sBold(9),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              '${data.disclaimerCompany} toute responsabilité en cas de contenu non déclaré, '
              'interdit ou mal emballé. Conservez ce reçu pour toute réclamation. '
              'La valeur déclarée est la valeur remboursée en cas de perte.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text('© KSL', style: _sBold(10)),
          ),
        ],
      ),
    );

    await _saveAndOpen(
      await pdf.save(),
      'recu_caisse_${_safeName(data.trackingNumber)}.pdf',
    );
  }

  Future<void> generateShippingLabel(
    KatianExpedition parcel,
    KatianUser? user, {
    int count = 1,
  }) async {
    final fonts = await _fontsOrLoad();
    final data = ShipmentDocumentData.fromParcel(parcel, user);
    final logo = await _loadLogo(data.logoUrl, data.gerantId);
    final pdf = pw.Document(theme: fonts.theme);
    final items = _parcelItems(parcel);
    final totalWeight = items.fold<double>(0, (sum, item) {
      final w = item['weight'] ?? item['poids'];
      return sum + (double.tryParse('$w') ?? 0);
    });

    for (var i = 0; i < count; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(14),
          build: (context) => _buildShippingLabelPage(
            data: data,
            parcel: parcel,
            logo: logo,
            items: items,
            totalWeight: totalWeight,
            labelNumber: i + 1,
            totalLabels: count,
          ),
        ),
      );
    }

    await _saveAndOpen(
      await pdf.save(),
      'Etiquette_${_safeName(data.trackingNumber)}.pdf',
    );
  }

  /// Structure alignée sur [printService.js] `generateLabelContentInGrid`.
  pw.Widget _buildShippingLabelPage({
    required ShipmentDocumentData data,
    required KatianExpedition parcel,
    required pw.MemoryImage? logo,
    required List<Map<String, dynamic>> items,
    required double totalWeight,
    required int labelNumber,
    required int totalLabels,
  }) {
    final raw = parcel.raw;
    final tracking = data.trackingNumber;
    final qrContent = _labelItemsQrContent(parcel);
    final serviceLabel = _serviceTypeLabel(
      raw['type_service']?.toString() ?? raw['serviceType']?.toString(),
    );
    final dateStr = _formatDate(data.createdAt);
    final mode = (data.modeExpedition ?? '').toLowerCase();
    final isHomeDelivery = mode.contains('domicile');
    final companyTitle =
        (data.companyName ?? 'KSL TRANSPORTEUR').trim().toUpperCase();
    final expediteurLine =
        '${data.expediteurName ?? ''} ${data.expediteurPrenom ?? ''}'.trim();
    final recipientLine =
        '${data.recipientName ?? ''} ${data.recipientPrenom ?? ''}'.trim();
    final relayName = (data.destinationRelayName ?? '—').toUpperCase();
    final senderAgency = data.relayEmissionName ??
        data.originRelayName ??
        data.senderName ??
        '—';
    final senderTel = data.relayTel ?? data.senderPhone ?? '';
    final footerCity =
        (data.destinationRelayName ?? data.originRelayName ?? '').toUpperCase();
    final orderNote = raw['order_note']?.toString().trim();
    final orderNumber = raw['order_number']?.toString().trim();
    final dest = raw['adresse_destinataire'];
    final deliveryAddress = _deliveryAddressFromRaw(dest, raw);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // --- En-tête société ---
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              companyTitle,
              textAlign: pw.TextAlign.center,
              style: _sBold(18),
            ),
          ),
          pw.SizedBox(height: 14),
          // --- Tracking + codes ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(tracking, style: _sBold(20)),
                    pw.SizedBox(height: 6),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: tracking,
                      width: 200,
                      height: 52,
                      drawText: false,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(serviceLabel, style: _sBold(16)),
                    if (dateStr.isNotEmpty)
                      pw.Text(dateStr, style: _sBold(13)),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrContent,
                width: 68,
                height: 68,
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          // --- Expéditeur ---
          pw.Text('Expéditeur :', style: _sBold(14)),
          pw.SizedBox(height: 2),
          if (expediteurLine.isNotEmpty)
            pw.Text(expediteurLine, style: _sBold(13)),
          if ((data.expediteurPhone ?? '').isNotEmpty)
            pw.Text(data.expediteurPhone!, style: _sBold(12)),
          pw.SizedBox(height: 12),
          // --- Destinataire + agence / adresse ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Livré à :', style: _sBold(14)),
                    pw.SizedBox(height: 2),
                    if (recipientLine.isNotEmpty)
                      pw.Text(recipientLine, style: _sBold(14)),
                    if ((data.recipientPhone ?? '').isNotEmpty)
                      pw.Text(
                        'Tel: ${data.recipientPhone}',
                        style: _sBold(12),
                      ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      isHomeDelivery ? 'Adresse de livraison' : 'Agence de retrait',
                      style: _sBold(12),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      isHomeDelivery ? deliveryAddress : relayName,
                      style: _sBold(12),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.black, thickness: 0.6),
          pw.SizedBox(height: 8),
          // --- Commande / ref ---
          if (orderNote != null && orderNote.isNotEmpty) ...[
            pw.Text('N° Commande : $orderNote', style: _sBold(12)),
            pw.SizedBox(height: 4),
          ],
          if (orderNumber != null && orderNumber.isNotEmpty) ...[
            pw.Text('Ref: $orderNumber', style: _sBold(12)),
            pw.SizedBox(height: 4),
          ],
          // --- Poids + items ---
          if (totalWeight > 0)
            pw.Text(
              'Poids total : ${totalWeight.toStringAsFixed(2)} kg',
              style: _sBold(13),
            ),
          pw.SizedBox(height: 6),
          pw.Text('Colis / Items :', style: _sBold(13)),
          pw.SizedBox(height: 4),
          ..._buildLabelItemRows(items),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.black, thickness: 0.6),
          pw.SizedBox(height: 10),
          // --- Agence expéditeur ---
          pw.Text('Agence Expéditeur :', style: _sBold(13)),
          pw.SizedBox(height: 2),
          pw.Text(senderAgency, style: _sBold(13)),
          if (senderTel.isNotEmpty)
            pw.Text('Tel: $senderTel', style: _sBold(12)),
          pw.Spacer(),
          // --- Pied de page ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                children: [
                  _logoWidget(logo, data.companyName, compact: true),
                  pw.SizedBox(width: 6),
                  pw.Text('$labelNumber/$totalLabels', style: _sBold(10)),
                ],
              ),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text('© KSL', style: _sBold(10)),
                ),
              ),
              if (footerCity.isNotEmpty)
                pw.Text(footerCity, style: _sBold(11)),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildLabelItemRows(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return [
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8),
          child: pw.Text('Aucun détail colis', style: _sBold(11)),
        ),
      ];
    }

    final widgets = <pw.Widget>[];
    final shown = items.take(3).toList();
    for (var i = 0; i < shown.length; i++) {
      final item = shown[i];
      var category =
          (item['category'] ?? item['categorie'] ?? item['name'] ?? 'Colis')
              .toString()
              .trim();
      if (category.length > 22) {
        category = '${category.substring(0, 19)}...';
      }
      final qty = item['quantity'] ?? 1;
      final weight = item['weight'] ?? item['poids'];
      final weightPart =
          weight != null && '$weight'.isNotEmpty ? '  ${weight}kg' : '';
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
          child: pw.Text(
            '${i + 1}. $category  x$qty$weightPart',
            style: _sBold(11),
          ),
        ),
      );
      if (i < shown.length - 1) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 8, right: 8, bottom: 2),
            height: 0.4,
            color: PdfColors.black,
          ),
        );
      }
    }
    if (items.length > 3) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, top: 2),
          child: pw.Text('...et ${items.length - 3} autres', style: _sBold(10)),
        ),
      );
    }
    return widgets;
  }

  String _serviceTypeLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'interurbaine':
        return 'INTERURBAINE';
      case 'sous_regionale':
        return 'SOUS-RÉGIONALE';
      case 'express':
        return 'EXPRESS';
      case 'economique':
        return 'ÉCONOMIQUE';
      case 'flash':
        return 'CHRONO';
      default:
        return (raw ?? 'STANDARD').toUpperCase();
    }
  }

  String _labelItemsQrContent(KatianExpedition parcel) {
    final items = _parcelItems(parcel);
    if (items.isEmpty) return 'Items:\nAucun item renseigné';
    final lines = items.take(5).toList().asMap().entries.map((e) {
      final item = e.value;
      final name = (item['name'] ?? item['nom'] ?? 'Colis').toString().trim();
      final category =
          (item['category'] ?? item['categorie'] ?? '—').toString().trim();
      final weight = item['weight'] ?? item['poids'];
      final weightStr =
          weight != null && weight.toString().isNotEmpty ? '${weight}kg' : '—';
      return '${e.key + 1}) Nom: $name | Catégorie: $category | Poids: $weightStr';
    });
    return 'Items:\n${lines.join('\n')}';
  }

  List<Map<String, dynamic>> _parcelItems(KatianExpedition parcel) {
    final fromInfocolis = _parseItemList(parcel.raw['infocolis']);
    if (fromInfocolis.isNotEmpty) return fromInfocolis;

    final package = parcel.raw['package'];
    if (package is Map) {
      final items = package['items'];
      return _parseItemList(items);
    }
    return const [];
  }

  List<Map<String, dynamic>> _parseItemList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  pw.Widget _partyBlock(
    String title,
    String name,
    String address,
    String phone,
    String? email,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (address.isNotEmpty)
          pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text('Tél: $phone', style: const pw.TextStyle(fontSize: 10)),
        if (email != null && email.isNotEmpty)
          pw.Text('Email: $email', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _invoiceTable(double amount, String description) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.black),
          children: [
            _tableHeaderCell('DESCRIPTION'),
            _tableHeaderCell('PRIX', align: pw.TextAlign.right),
            _tableHeaderCell('QTÉ', align: pw.TextAlign.center),
            _tableHeaderCell('TOTAL', align: pw.TextAlign.right),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell(description),
            _tableCell(_formatCurrency(amount), align: pw.TextAlign.right),
            _tableCell('1', align: pw.TextAlign.center),
            _tableCell(_formatCurrency(amount), align: pw.TextAlign.right),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'TOTAL TTC',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                _formatCurrency(amount),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _receiptTable(List<({String label, String value, bool bold})> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FlexColumnWidth(4.5),
        1: const pw.FlexColumnWidth(5.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableCell('Détail', bold: true),
            _tableCell('Valeur', bold: true),
          ],
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: [
              _tableCell(row.label, bold: row.bold),
              _tableCell(row.value, bold: row.bold),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  pw.Widget _divider() => pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        height: 0.5,
        color: PdfColors.grey400,
      );

  pw.Widget _logoWidget(
    pw.MemoryImage? logo,
    String? companyName, {
    bool compact = false,
  }) {
    if (logo != null) {
      return pw.Image(logo, width: compact ? 56 : 72, height: compact ? 28 : 36);
    }
    return pw.Container(
      width: compact ? 28 : 36,
      height: compact ? 28 : 36,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E30613'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        (companyName ?? 'K').substring(0, 1).toUpperCase(),
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: compact ? 14 : 18,
        ),
      ),
    );
  }

  Future<pw.MemoryImage?> _loadLogo(String? url, int? gerantId) async {
    final resolved = AppConfig.resolveMediaUrl(url);
    if (resolved != null) {
      final img = await _fetchImage(resolved);
      if (img != null) return img;
    }
    try {
      final bytes = await rootBundle.load('assets/images/katian-logo.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentService] logo asset fallback failed: $e');
      }
    }
    return null;
  }

  Future<pw.MemoryImage?> _fetchImage(String url) async {
    try {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;
      return pw.MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAndOpen(Uint8List bytes, String filename) async {
    if (bytes.length < 4 || String.fromCharCodes(bytes.take(4)) != '%PDF') {
      throw Exception('PDF invalide généré');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type == ResultType.done) return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentService] open file failed: $e');
      }
    }

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  String _formatCurrency(num amount) {
    final formatted = NumberFormat('#,##0', 'fr_FR').format(amount.round());
    return '$formatted FCFA'.replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.now());
    }
    try {
      return DateFormat('dd/MM/yyyy', 'fr_FR')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  Future<void> generateBordereau(BordereauExpedition bordereau) async {
    final fonts = await _fontsOrLoad();
    final logo = await _loadLogo(null, null);
    final pdf = pw.Document(theme: fonts.theme);
    final dateStr = _formatBordereauDate(bordereau.departureDate);
    final timeStr = bordereau.departureTime ?? '—';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _logoWidget(logo, 'KATIAN', compact: true),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'BORDEREAU D\'EXPÉDITION',
                        style: _sBold(18),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('N° ${bordereau.number}', style: _sBold(12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Heure: $timeStr', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _infoLine('Car', bordereau.carNumber ?? '—'),
                  ),
                  pw.Expanded(
                    child: _infoLine('Conducteur', bordereau.driverName ?? '—'),
                  ),
                  pw.Expanded(
                    child: _infoLine('Téléphone', bordereau.driverPhone ?? '—'),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              _infoLine('Gare de départ', bordereau.departureRelayName ?? '—'),
              if (bordereau.comment != null && bordereau.comment!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _infoLine('Commentaire', bordereau.comment!),
              ],
              pw.SizedBox(height: 10),
              pw.Text(
                'Nombre de colis : ${bordereau.parcelCount}',
                style: _sBold(11),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['N° Expédition', 'Destinataire', 'Destination finale'],
                data: bordereau.colis
                    .map((c) => [
                          c.expeditionNumber ?? '—',
                          c.recipientName ?? '—',
                          c.destination ?? '—',
                        ])
                    .toList(),
                headerStyle: _sBold(9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: bordereau.number,
                  width: 80,
                  height: 80,
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await _saveAndOpen(bytes, 'bordereau_${_safeName(bordereau.number)}.pdf');
  }

  pw.Widget _infoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label : ', style: _sBold(10)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  String _formatBordereauDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.now());
    }
    try {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _safeName(String input) =>
      input.replaceAll(RegExp(r'[^\w\-]'), '_');

  String _deliveryAddressFromRaw(dynamic destRaw, Map<String, dynamic> raw) {
    if (destRaw is Map) {
      final dest = Map<String, dynamic>.from(destRaw);
      final parts = [
        dest['address'],
        dest['adresse'],
        dest['city'],
        dest['commune'],
        dest['ville'],
      ]
          .map((v) => v?.toString().trim())
          .whereType<String>()
          .where((v) => v.isNotEmpty);
      final joined = parts.join(', ');
      if (joined.isNotEmpty) return joined;
    }
    final fallback = raw['destination'] ?? raw['to_address'];
    return fallback?.toString().trim() ?? '—';
  }

  pw.TextStyle _sBold(double size) =>
      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: size);
}
