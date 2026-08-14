import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Polices Unicode pour PDF (accents FR) — évite Helvetica sans Unicode.
class PdfFonts {
  PdfFonts({required this.base, required this.bold});

  final pw.Font base;
  final pw.Font bold;

  pw.ThemeData get theme => pw.ThemeData.withFont(base: base, bold: bold);

  static Future<PdfFonts> load() async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    return PdfFonts(base: base, bold: bold);
  }
}
