class FinanceInvoicePreview {
  const FinanceInvoicePreview({
    required this.id,
    this.amount,
    this.status,
    this.issueDate,
    this.invoiceType,
  });

  final int id;
  final double? amount;
  final String? status;
  final String? issueDate;
  final String? invoiceType;

  bool get isPaid {
    final s = (status ?? '').toLowerCase();
    return s == 'payé' || s == 'paye' || s == 'paid';
  }

  factory FinanceInvoicePreview.fromJson(Map<String, dynamic> json) {
    return FinanceInvoicePreview(
      id: json['id'] as int? ?? 0,
      amount: (json['montant_total'] is num)
          ? (json['montant_total'] as num).toDouble()
          : double.tryParse('${json['montant_total']}'),
      status: json['statut']?.toString(),
      issueDate: json['date_emission']?.toString(),
      invoiceType: json['type_facture']?.toString(),
    );
  }
}

class RelayFinanceSummary {
  const RelayFinanceSummary({
    this.totalRevenue = 0,
    this.redevanceDue = 0,
    this.redevancePaid = 0,
    this.parcelCount = 0,
    this.amountToSettle = 0,
    this.amountSettled = 0,
    this.paidInvoicesCount = 0,
    this.unpaidInvoicesCount = 0,
    this.creditParcelsCount = 0,
    this.invoices = const [],
  });

  final double totalRevenue;
  final double redevanceDue;
  final double redevancePaid;
  final int parcelCount;
  final double amountToSettle;
  final double amountSettled;
  final int paidInvoicesCount;
  final int unpaidInvoicesCount;
  final int creditParcelsCount;
  final List<FinanceInvoicePreview> invoices;

  List<FinanceInvoicePreview> get unpaidInvoices =>
      invoices.where((i) => !i.isPaid).toList();

  factory RelayFinanceSummary.fromJson(Map<String, dynamic> json) {
    double amount(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    final rawInvoices = json['facture_liste'];
    final invoices = rawInvoices is List
        ? rawInvoices
            .whereType<Map>()
            .map((e) => FinanceInvoicePreview.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <FinanceInvoicePreview>[];

    return RelayFinanceSummary(
      totalRevenue: amount(json['totalRevenue']),
      redevanceDue: amount(json['Redevence']),
      redevancePaid: amount(json['totalRedevenceRegle']),
      parcelCount: json['nbrcolisT'] is int
          ? json['nbrcolisT'] as int
          : int.tryParse('${json['nbrcolisT']}') ?? 0,
      amountToSettle: amount(json['montant_total_a_regler']),
      amountSettled: amount(json['montant_factures_reglees']),
      paidInvoicesCount: json['nombre_factures_payees'] is int
          ? json['nombre_factures_payees'] as int
          : int.tryParse('${json['nombre_factures_payees']}') ?? 0,
      unpaidInvoicesCount: json['nombre_factures_non_payees'] is int
          ? json['nombre_factures_non_payees'] as int
          : int.tryParse('${json['nombre_factures_non_payees']}') ?? 0,
      creditParcelsCount: json['nbr_colis_credit'] is int
          ? json['nbr_colis_credit'] as int
          : int.tryParse('${json['nbr_colis_credit']}') ?? 0,
      invoices: invoices,
    );
  }
}
