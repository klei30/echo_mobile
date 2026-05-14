import 'dart:io';

import 'package:chatmcp/echo/echo_design_system.dart';
import 'package:chatmcp/echo/echo_host_service.dart';
import 'package:chatmcp/echo/echo_offline_memory_service.dart';
import 'package:chatmcp/echo/echo_offline_queue.dart';
import 'package:chatmcp/echo/echo_product_contracts.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/local_model_download_service.dart';
import 'package:chatmcp/page/echo_tabs/remote_access_screen.dart';
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
        iconTheme: IconThemeData(color: EchoColors.textPrimary),
        title: Text(
          'Where Echo Thinks',
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
                    child: Icon(Icons.phone_android_rounded, color: EchoColors.amber, size: 25),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Choose where Echo thinks.',
                    style: GoogleFonts.lora(fontSize: 27, fontStyle: FontStyle.italic, height: 1.25, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Home Brain is strongest. This Device keeps Talk available offline. Cloud is a quick fallback when Home Brain is away.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.65, color: EchoColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  _RuntimeSection(
                    mode: runtime.mode,
                    deviceReady: deviceReady,
                    modelVersion: runtime.deviceModelVersion,
                    memoryReady: memory.hasPack,
                    memoryCount: memory.count('training_pairs') + memory.count('life_events') + memory.count('echo_threads'),
                    syncingMemory: _syncingMemory,
                    onSelect: _setRuntimeMode,
                    onSync: _syncMemoryPack,
                  ),
                  if (_error != null || serviceError != null) ...[
                    const SizedBox(height: 10),
                    Text(_error ?? serviceError!, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFFE57373))),
                  ],
                  const SizedBox(height: 22),
                  FutureBuilder<int>(
                    future: EchoOfflineQueue().pendingPairCount,
                    builder: (context, snapshot) {
                      final queued = snapshot.data ?? 0;
                      return _CapabilityMatrix(
                        capabilities: echoRuntimeCapabilities(runtime: runtime, memoryReady: memory.hasPack, queuedOutcomes: queued),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _TunnelEntryCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Download This Device model',
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
                      label: Text(deviceReady ? 'Import another offline model file' : 'Import offline model file'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EchoColors.textPrimary,
                        side: BorderSide(color: EchoColors.borderSubtle),
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
                    'Some offline models require license approval before download. If a model is gated, approve access first and import the file here.',
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

class _RuntimeSection extends StatelessWidget {
  final EchoRuntimeMode mode;
  final bool deviceReady;
  final String modelVersion;
  final bool memoryReady;
  final int memoryCount;
  final bool syncingMemory;
  final ValueChanged<EchoRuntimeMode> onSelect;
  final VoidCallback onSync;

  const _RuntimeSection({
    required this.mode,
    required this.deviceReady,
    required this.modelVersion,
    required this.memoryReady,
    required this.memoryCount,
    required this.syncingMemory,
    required this.onSelect,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_RowSpec>[
      _RowSpec(
        icon: Icons.computer_rounded,
        title: 'Home Brain',
        subtitle: 'Private desktop model, full memory, Decision Room',
        status: mode == EchoRuntimeMode.desktop ? 'Active' : 'Paired',
        statusColor: mode == EchoRuntimeMode.desktop ? EchoColors.primaryAi : EchoColors.practice,
        action: mode == EchoRuntimeMode.desktop ? null : 'Switch',
        onTap: () => onSelect(EchoRuntimeMode.desktop),
      ),
      _RowSpec(
        icon: Icons.phone_android_rounded,
        title: 'This Device',
        subtitle: deviceReady ? (modelVersion.isEmpty ? 'Offline model ready' : modelVersion) : 'Import or download a .litertlm model',
        status: mode == EchoRuntimeMode.device
            ? 'Active'
            : deviceReady
            ? 'Ready'
            : 'No model',
        statusColor: mode == EchoRuntimeMode.device
            ? EchoColors.primaryAi
            : deviceReady
            ? EchoColors.practice
            : const Color(0xFFE57373),
        action: mode == EchoRuntimeMode.device ? null : (deviceReady ? 'Switch' : null),
        onTap: deviceReady ? () => onSelect(EchoRuntimeMode.device) : null,
      ),
      _RowSpec(
        icon: Icons.cloud_rounded,
        title: 'Cloud Echo',
        subtitle: 'Fallback when Home Brain is away. Requires login & network',
        status: mode == EchoRuntimeMode.cloud ? 'Active' : 'Online',
        statusColor: mode == EchoRuntimeMode.cloud ? EchoColors.primaryAi : EchoColors.textMuted,
        action: mode == EchoRuntimeMode.cloud ? null : 'Switch',
        onTap: () => onSelect(EchoRuntimeMode.cloud),
      ),
      _RowSpec(
        icon: Icons.shield_rounded,
        title: 'Memory Pack',
        subtitle: memoryReady ? '$memoryCount items on this phone' : 'Sync before going offline',
        status: memoryReady ? 'Synced' : 'Not synced',
        statusColor: memoryReady ? EchoColors.practice : EchoColors.textMuted,
        action: syncingMemory ? null : (memoryReady ? 'Refresh' : 'Sync now'),
        isMemorySync: true,
        onTap: syncingMemory ? null : onSync,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final spec = e.value;
          return _CompactRuntimeRow(
            icon: spec.icon,
            title: spec.title,
            subtitle: spec.subtitle,
            status: spec.status,
            statusColor: spec.statusColor,
            action: spec.action,
            isActive: spec.action == null && !spec.isMemorySync,
            isLast: isLast,
            loading: spec.isMemorySync && syncingMemory,
            onTap: spec.onTap,
          );
        }).toList(),
      ),
    );
  }
}

class _RowSpec {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String? action;
  final bool isMemorySync;
  final VoidCallback? onTap;

  const _RowSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.action,
    this.isMemorySync = false,
    this.onTap,
  });
}

class _CompactRuntimeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String? action;
  final bool isActive;
  final bool isLast;
  final bool loading;
  final VoidCallback? onTap;

  const _CompactRuntimeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.action,
    this.isActive = false,
    this.isLast = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? EchoColors.primaryAi.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.only(topLeft: isActive ? Radius.zero : Radius.zero, bottomLeft: Radius.zero),
          border: isLast ? null : Border(bottom: BorderSide(color: EchoColors.borderSubtle, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? EchoColors.primaryAi.withValues(alpha: 0.14) : EchoColors.bgInput,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: isActive ? EchoColors.primaryAi : EchoColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.35, color: EchoColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                status,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 8),
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: EchoColors.primaryAi)),
            ] else if (action != null) ...[
              const SizedBox(width: 8),
              Text(
                action!,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: EchoColors.primaryAi),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapabilityMatrix extends StatelessWidget {
  final List<EchoRuntimeCapability> capabilities;

  const _CapabilityMatrix({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    return EchoPanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EchoSectionHeader(
            label: 'what works now',
            title: 'Offline & Privacy',
            body: 'See what Echo can do in this mode before you rely on it offline or away from your Home Brain.',
          ),
          const SizedBox(height: 14),
          ...capabilities.map(
            (capability) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CapabilityTile(capability: capability),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  final EchoRuntimeCapability capability;

  const _CapabilityTile({required this.capability});

  @override
  Widget build(BuildContext context) {
    final color = capability.available ? capability.color : EchoColors.textGhost;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: capability.available ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: capability.available ? 0.18 : 0.10)),
          ),
          child: Icon(capability.icon, size: 17, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(capability.title, style: EchoText.title(size: 13.2))),
                  EchoTag(
                    icon: capability.available ? Icons.check_rounded : Icons.lock_outline_rounded,
                    label: capability.available ? 'ready' : 'limited',
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(capability.body, style: EchoText.body(size: 11.6)),
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
                        Text(
                          model.size,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
                        ),
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
                valueColor: AlwaysStoppedAnimation<Color>(EchoColors.amber),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
                  ),
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
                  backgroundColor: model.recommended ? EchoColors.amber : EchoColors.bgInput,
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

class _TunnelEntryCard extends StatelessWidget {
  const _TunnelEntryCard();

  @override
  Widget build(BuildContext context) {
    final hasTunnel = EchoHostService().hasTunnel;
    final currentUrl = EchoHostService().tunnelUrl;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemoteAccessScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasTunnel ? EchoColors.amber.withValues(alpha: 0.08) : EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasTunnel ? EchoColors.amber.withValues(alpha: 0.35) : EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: EchoColors.amber.withValues(alpha: hasTunnel ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.wifi_tethering_rounded, size: 19, color: hasTunnel ? EchoColors.amber : EchoColors.textGhost),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasTunnel ? 'Home Brain connected' : 'Connect to Home Brain',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasTunnel
                        ? currentUrl.replaceFirst('https://', '').replaceFirst('http://', '')
                        : 'Paste your Cloudflare tunnel URL to reach Echo from anywhere',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.4, color: EchoColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: hasTunnel ? EchoColors.amber : EchoColors.textGhost),
          ],
        ),
      ),
    );
  }
}
