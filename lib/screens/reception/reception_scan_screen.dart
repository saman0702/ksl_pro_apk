import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/scan_feedback.dart';
import '../../widgets/scanner_overlay.dart';
import 'reception_wizard_screen.dart';
import 'package:provider/provider.dart';

/// Écran scan — code-barres étiquette ou QR bordereau (réception).
class ReceptionScanScreen extends StatefulWidget {
  const ReceptionScanScreen({super.key});

  @override
  State<ReceptionScanScreen> createState() => _ReceptionScanScreenState();
}

class _ReceptionScanScreenState extends State<ReceptionScanScreen>
    with WidgetsBindingObserver {
  static const _scanSize = 240.0;

  final _manualCtrl = TextEditingController();
  MobileScannerController? _controller;
  bool _busy = false;
  bool _cameraActive = true;
  bool _leavingScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    ScanFeedback.preload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualCtrl.dispose();
    unawaited(_shutdownCamera());
    super.dispose();
  }

  Future<void> _shutdownCamera() async {
    _cameraActive = false;
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      await controller.stop();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _leaveScreen([dynamic result]) async {
    if (_leavingScreen) return;
    _leavingScreen = true;
    if (mounted) setState(() => _cameraActive = false);
    await _pauseCamera();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
      case AppLifecycleState.resumed:
        if (!_busy && !_leavingScreen && _cameraActive && mounted) {
          controller.start();
        }
    }
  }

  Future<void> _pauseCamera() async {
    try {
      await _controller?.stop();
    } catch (_) {}
  }

  Future<void> _resumeCamera() async {
    if (_busy || _leavingScreen || !_cameraActive || !mounted) return;
    try {
      await _controller?.start();
    } catch (_) {}
  }

  Future<void> _resolveCode(String raw) async {
    if (_busy || _leavingScreen) return;
    final code = raw.trim().replaceAll(RegExp(r'[^\w\-]'), '');
    if (code.isEmpty) return;

    unawaited(ScanFeedback.onScanDetected());
    setState(() => _busy = true);
    await _pauseCamera();
    var leftForConfirm = false;
    try {
      final app = context.read<AppProvider>();

      try {
        final b = await app.bordereaux.byNumber(code);
        final eligible = b.eligibleCount ?? b.colis.where((c) => c.canReceive).length;
        if (eligible == 0) {
          _snack('Aucun colis à réceptionner sur ce bordereau.');
          return;
        }
        if (!mounted) return;
        leftForConfirm = true;
        await _goToConfirm(bordereau: b, target: ReceptionScanTarget.bordereau);
        return;
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          _snack(_errorMessage(e));
          return;
        }
      }

      final list = await app.expeditions.receptionables(search: code);
      if (list.isEmpty) {
        _snack('Colis introuvable ou non réceptionnable.');
        return;
      }

      KatianExpedition? match;
      for (final p in list) {
        if (p.displayNumber.toLowerCase() == code.toLowerCase()) {
          match = p;
          break;
        }
      }
      match ??= list.first;

      if (!match.canReceive) {
        _snack('Colis pas encore expédié — réception impossible.');
        return;
      }

      if (!mounted) return;
      leftForConfirm = true;
      await _goToConfirm(parcel: match, target: ReceptionScanTarget.parcel);
    } finally {
      if (mounted && !leftForConfirm && !_leavingScreen) {
        setState(() => _busy = false);
        await _resumeCamera();
      }
    }
  }

  Future<void> _goToConfirm({
    KatianExpedition? parcel,
    BordereauExpedition? bordereau,
    required ReceptionScanTarget target,
  }) async {
    await _pauseCamera();
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceptionWizardScreen(
          initialStep: ReceptionWizardStep.detail,
          initialParcel: parcel,
          initialBordereau: bordereau,
          initialTarget: target,
        ),
      ),
    );
    if (refreshed == true && mounted) {
      await _leaveScreen(true);
      return;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _cameraActive = true;
      });
    }
    await _resumeCamera();
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    return e.message ?? 'Erreur réseau';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _leavingScreen) return;
        await _leaveScreen();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner'),
        backgroundColor: KatianColors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveScreen(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _cameraActive)
                  MobileScanner(
                    controller: _controller!,
                    onDetect: (capture) {
                      if (_busy) return;
                      final raw = capture.barcodes.firstOrNull?.rawValue;
                      if (raw != null && raw.isNotEmpty) _resolveCode(raw);
                    },
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Caméra indisponible : ${error.errorCode.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    },
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ScannerOverlay(
                      scanSize: _scanSize,
                      active: !_busy,
                    ),
                  ),
                ),
                if (_busy)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: KatianColors.red),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: ext.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Text(
              'Code-barres étiquette ou QR bordereau',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ext.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scannez le code-barres sous le n° d\'expédition sur l\'étiquette',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: ext.textSecondary),
            ),
                const SizedBox(height: 12),
                TextField(
                  controller: _manualCtrl,
                  decoration: InputDecoration(
                    hintText: 'N° expédition ou bordereau',
                    filled: true,
                    fillColor: ext.background,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: KatianColors.red),
                      onPressed: () => _resolveCode(_manualCtrl.text),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _resolveCode,
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

enum ReceptionScanTarget { parcel, bordereau }

enum ReceptionWizardStep { list, detail, confirm, success }
