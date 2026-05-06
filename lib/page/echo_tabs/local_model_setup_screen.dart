import 'dart:io';

import 'package:chatmcp/echo/echo_offline_memory_service.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/local_model_download_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class LocalModelSetupScreen extends StatefulWidget {
  final bool onboarding;

  const LocalModelSetupScreen({super.key, this.onboarding = false});

  @override
  State<LocalModelSetupScreen> createState() => _LocalModelSetupScreenState();
}

class _LocalModelSetupScreenState extends State<LocalModelSetupScreen> {
  bool _busy = false;
  bool _syncingMemory = false;
  String? _error;

  Future<String> _copyModelIntoAppStorage(String sourcePath, String fileName) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${baseDir.path}${Platform.pathSeparator}echo_models');
    if (!await modelDir.exists()) await modelDir.create(recursive: true);
    final safeName = fileName.trim().isEmpty ? 'gemma-on-device.litertlm' : fileName;
    final destination = File('${modelDir.path}${Platform.pathSeparator}$safeName');
    if (destination.path == sourcePath) return destination.path;
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  Future<void> _pickModel() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      final file = result?.files.single;
      final path = file?.path;
      if (path == null || path.trim().isEmpty) {
        setState(() {
          _busy = false;
          _error = 'Android did not return a readable file path. Try choosing the model from Downloads or device storage.';
        });
        return;
      }
      final fileName = file?.name.toLowerCase() ?? path.toLowerCase();
      if (!fileName.endsWith('.litertlm') && !path.toLowerCase().endsWith('.litertlm')) {
        setState(() {
          _busy = false;
          _error = 'Choose a .litertlm model file.';
        });
        return;
      }

      if (path.trim().isEmpty) {
        setState(() => _busy = false);
        return;
      }

      final persistedPath = await _copyModelIntoAppStorage(path, file?.name ?? 'gemma-on-device.litertlm');
      await EchoRuntimeService().setDeviceModel(path: persistedPath, version: file?.name ?? 'Gemma on device');
      await EchoRuntimeService().setMode(EchoRuntimeMode.device);
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      await EchoRuntimeService().markDeviceModelError();
      setState(() {
        _busy = false;
        _error = 'Could not import this model file.';
      });
    }
  }

  Future<void> _continue() async {
    await EchoRuntimeService().setMode(EchoRuntimeMode.device);
    if (!mounted) return;
    Navigator.of(context).pop(EchoRuntimeService().isDeviceReady);
  }

  Future<void> _setRuntimeMode(EchoRuntimeMode mode) async {
    if (mode == EchoRuntimeMode.device) {
      final runtime = EchoRuntimeService();
      final hasModel = runtime.deviceModelStatus == DeviceModelStatus.ready && runtime.deviceModelPath.isNotEmpty;
      if (!hasModel) {
        setState(() => _error = 'Import or download a .litertlm model before using This Device.');
        return;
      }
    }
    await EchoRuntimeService().setMode(mode);
    if (!mounted) return;
    setState(() => _error = null);
  }

  Future<void> _syncMemoryPack() async {
    setState(() {
      _syncingMemory = true;
      _error = null;
    });
    final ok = await EchoOfflineMemoryService().syncFromEcho();
    if (!mounted) return;
    setState(() {
      _syncingMemory = false;
      _error = ok ? null : 'Could not sync Echo memory. Connect to Home Brain or Cloud Echo, then try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final runtime = EchoRuntimeService();
    final downloads = LocalModelDownloadService();
    final deviceReady = runtime.deviceModelStatus == DeviceModelStatus.ready && runtime.deviceModelPath.isNotEmpty;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: AppBar(
        backgroundColor: EchoColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: EchoColors.textPrimary),
        title: Text(
          'Runtime',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([runtime, downloads]),
          builder: (context, _) {
            final serviceError = downloads.error;
            final memory = EchoOfflineMemoryService();
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: EchoColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EchoColors.amber.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.phone_android_rounded, color: EchoColors.amber, size: 25),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Choose where Echo thinks from.',
                    style: GoogleFonts.lora(fontSize: 27, fontStyle: FontStyle.italic, height: 1.25, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Home Brain is strongest. This Device keeps Coach available offline. Cloud is the fallback when Home Brain is away.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.65, color: EchoColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  _RuntimePanel(
                    mode: runtime.mode,
                    deviceReady: deviceReady,
                    memoryReady: memory.hasPack,
                    onSelect: _setRuntimeMode,
                  ),
                  const SizedBox(height: 14),
                  _StatusPanel(
                    ready: deviceReady,
                    modelPath: runtime.deviceModelPath,
                    modelVersion: runtime.deviceModelVersion,
                    memoryReady: memory.hasPack,
                    memoryExportedAt: memory.exportedAt,
                    memoryCount: memory.count('training_pairs') + memory.count('life_events') + memory.count('echo_threads'),
                  ),
                  if (_error != null || serviceError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error ?? serviceError!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFFE57373)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _CapabilityRow(icon: Icons.chat_bubble_outline_rounded, title: 'Offline Coach', body: 'Uses on-device Gemma with cached Echo context.'),
                  _CapabilityRow(icon: Icons.psychology_alt_outlined, title: 'Cached Echo memory', body: 'Memories, rules, Current Read, and Today stay available.'),
                  _CapabilityRow(icon: Icons.sync_rounded, title: 'Sync later', body: 'New signals and feedback are saved for Home Brain or Cloud training.'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _syncingMemory ? null : _syncMemoryPack,
                      icon: _syncingMemory
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_sync_rounded, size: 18),
                      label: Text(memory.hasPack ? 'Refresh Echo memory on this phone' : 'Sync Echo memory to this phone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EchoColors.amber,
                        foregroundColor: EchoColors.bg,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Download a model',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  ...echoModelCatalog.map(
                    (model) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ModelDownloadCard(
                        model: model,
                        busy: _busy || downloads.downloading,
                        downloading: downloads.activeModelId == model.id,
                        progress: downloads.activeModelId == model.id ? downloads.progress : null,
                        onDownload: () {
                          setState(() => _error = null);
                          downloads.clearError();
                          downloads.download(model);
                        },
                        onCancel: downloads.stop,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _pickModel,
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(deviceReady ? 'Import another .litertlm file' : 'Import .litertlm file'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EchoColors.textPrimary,
                        side: const BorderSide(color: EchoColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: deviceReady ? _continue : null,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Use this device'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: deviceReady ? EchoColors.textPrimary : EchoColors.textGhost,
                        side: BorderSide(color: deviceReady ? EchoColors.borderSubtle : EchoColors.borderSubtle.withValues(alpha: 0.45)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gemma 3 and Function Gemma models are available too, but many are gated by the Gemma license on Hugging Face. Use import for those after accepting access.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.55, color: EchoColors.textGhost),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RuntimePanel extends StatelessWidget {
  final EchoRuntimeMode mode;
  final bool deviceReady;
  final bool memoryReady;
  final ValueChanged<EchoRuntimeMode> onSelect;

  const _RuntimePanel({
    required this.mode,
    required this.deviceReady,
    required this.memoryReady,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Runtime',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _RuntimeCard(
          icon: Icons.computer_rounded,
          title: 'Home Brain',
          badge: 'Personalized',
          body: 'Uses your private desktop Gemma 4 adapter, full memory, Decision Room, tools, voice, and training.',
          action: 'Use Home Brain',
          selected: mode == EchoRuntimeMode.desktop,
          status: 'Best when your computer is running Echo and paired by Wi-Fi or tunnel',
          enabled: true,
          onTap: () => onSelect(EchoRuntimeMode.desktop),
        ),
        const SizedBox(height: 10),
        _RuntimeCard(
          icon: Icons.cloud_rounded,
          title: 'Cloud Echo',
          badge: 'Connected',
          body: 'Uses Echo backend routing when Home Brain is not available. Good for online fallback.',
          action: 'Use Cloud',
          selected: mode == EchoRuntimeMode.cloud,
          status: 'Requires login and network',
          enabled: true,
          onTap: () => onSelect(EchoRuntimeMode.cloud),
        ),
        const SizedBox(height: 10),
        _RuntimeCard(
          icon: Icons.phone_android_rounded,
          title: 'This Device',
          badge: 'Offline',
          body: 'Uses LiteRT-LM Gemma on this phone with synced Echo memory. No tools or training.',
          action: 'Use This Device',
          selected: mode == EchoRuntimeMode.device,
          status: deviceReady
              ? memoryReady
                  ? 'Ready offline'
                  : 'Model ready, memory not synced'
              : 'Needs a .litertlm model',
          enabled: deviceReady,
          onTap: () => onSelect(EchoRuntimeMode.device),
        ),
      ],
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final String body;
  final String action;
  final String status;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _RuntimeCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.body,
    required this.action,
    required this.status,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? EchoColors.amber.withValues(alpha: 0.55) : EchoColors.borderSubtle;
    final bg = selected ? EchoColors.amber.withValues(alpha: 0.08) : EchoColors.bgSurface;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: EchoColors.amber.withValues(alpha: selected ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: selected ? EchoColors.amber : EchoColors.textGhost),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? EchoColors.amber.withValues(alpha: 0.18) : const Color(0xFF1E1B17),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              selected ? 'Active' : badge,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: selected ? EchoColors.amber : EchoColors.textGhost,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 11.7, height: 1.45, color: EchoColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 16, color: selected ? EchoColors.amber : EchoColors.textGhost),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 11.2, color: enabled ? EchoColors.textGhost : const Color(0xFFE57373))),
                ),
                Text(
                  action,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: enabled ? EchoColors.amber : EchoColors.textGhost,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final bool ready;
  final String modelPath;
  final String modelVersion;
  final bool memoryReady;
  final String memoryExportedAt;
  final int memoryCount;

  const _StatusPanel({
    required this.ready,
    required this.modelPath,
    required this.modelVersion,
    required this.memoryReady,
    required this.memoryExportedAt,
    required this.memoryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ready ? EchoColors.amber.withValues(alpha: 0.08) : EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ready ? EchoColors.amber.withValues(alpha: 0.25) : EchoColors.borderSubtle),
      ),
      child: Column(
        children: [
          _StatusLine(
            icon: ready ? Icons.offline_bolt_rounded : Icons.download_for_offline_outlined,
            iconColor: ready ? EchoColors.amber : EchoColors.textGhost,
            title: ready ? 'Gemma ready offline' : 'Model not installed',
            body: ready ? '${modelVersion.isEmpty ? 'Gemma on device' : modelVersion}\n$modelPath' : 'Import a .litertlm model before using device mode.',
          ),
          const SizedBox(height: 14),
          _StatusLine(
            icon: memoryReady ? Icons.verified_user_rounded : Icons.cloud_sync_outlined,
            iconColor: memoryReady ? EchoColors.amber : EchoColors.textGhost,
            title: memoryReady ? 'Echo memory synced' : 'Echo memory not on this phone',
            body: memoryReady
                ? '$memoryCount local signals cached${memoryExportedAt.isEmpty ? '' : '\nSynced $memoryExportedAt'}'
                : 'Sync before going offline so Gemma can use your memories, rules, Current Read, and Today state.',
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _StatusLine({required this.icon, required this.iconColor, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary)),
              const SizedBox(height: 5),
              Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.45, color: EchoColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelDownloadCard extends StatelessWidget {
  final EchoModelOption model;
  final bool busy;
  final bool downloading;
  final double? progress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const _ModelDownloadCard({
    required this.model,
    required this.busy,
    required this.downloading,
    required this.progress,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = progress == null ? null : (progress!.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: model.recommended ? EchoColors.amber.withValues(alpha: 0.30) : EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: EchoColors.amber.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
                child: Icon(model.recommended ? Icons.speed_rounded : Icons.memory_rounded, color: EchoColors.amber, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            model.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                          ),
                        ),
                        Text(model.size, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(model.subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.45, color: EchoColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: EchoColors.borderSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(EchoColors.amber),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  pct == null ? 'Downloading...' : 'Downloading $pct%',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: EchoColors.amber),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCancel,
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: EchoColors.textGhost)),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onDownload,
                icon: const Icon(Icons.download_rounded, size: 17),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: model.recommended ? EchoColors.amber : const Color(0xFF1E1B17),
                  foregroundColor: model.recommended ? EchoColors.bg : EchoColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CapabilityRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: EchoColors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EchoColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.45, color: EchoColors.textGhost)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
