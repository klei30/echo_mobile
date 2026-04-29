import 'dart:async';
import 'package:chatmcp/page/layout/widgets/mcp_tools.dart';
import 'package:chatmcp/page/echo_tabs/voice_session_screen.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chatmcp/widgets/upload_menu.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/page/layout/widgets/conv_setting.dart';
import 'package:chatmcp/voice/voice_service.dart';

class SubmitData {
  final String text;
  final List<PlatformFile> files;

  SubmitData(this.text, this.files);

  @override
  String toString() {
    return 'SubmitData(text: $text, files: $files)';
  }
}

class InputArea extends StatefulWidget {
  final bool isComposing;
  final bool disabled;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<SubmitData> onSubmitted;
  final VoidCallback? onCancel;
  final ValueChanged<List<PlatformFile>>? onFilesSelected;
  final bool autoFocus;

  const InputArea({
    super.key,
    required this.isComposing,
    required this.disabled,
    required this.onTextChanged,
    required this.onSubmitted,
    this.onFilesSelected,
    this.onCancel,
    this.autoFocus = false,
  });

  @override
  State<InputArea> createState() => InputAreaState();
}

class InputAreaState extends State<InputArea> {
  List<PlatformFile> _selectedFiles = [];
  final TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isImeComposing = false;

  @override
  void initState() {
    super.initState();
    // Auto focus on desktop when autoFocus is true
    if (!kIsMobile && widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(InputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto focus on desktop when autoFocus changes to true
    if (!kIsMobile && widget.autoFocus && !oldWidget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void requestFocus() {
    if (!kIsMobile && mounted) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = [..._selectedFiles, ...result.files];
        });
        widget.onFilesSelected?.call(_selectedFiles);
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = [..._selectedFiles, ...result.files];
        });
        widget.onFilesSelected?.call(_selectedFiles);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected?.call(_selectedFiles);
  }

  void _afterSubmitted() {
    textController.clear();
    _selectedFiles.clear();
  }

  String _truncateFileName(String fileName) {
    const int maxLength = 20;
    if (fileName.length <= maxLength) return fileName;

    final extension = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
    final nameWithoutExt = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;

    if (nameWithoutExt.length <= maxLength - extension.length - 3) {
      return fileName;
    }

    final truncatedLength = (maxLength - extension.length - 3) ~/ 2;
    return '${nameWithoutExt.substring(0, truncatedLength)}'
        '...'
        '${nameWithoutExt.substring(nameWithoutExt.length - truncatedLength)}'
        '$extension';
  }

  // ── Echo mobile input bar ────────────────────────────────────────────────
  Widget _buildEchoMobileInput(BuildContext context) {
    return _buildEchoInputRow(context);
  }

  Widget _buildEchoInputRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0D0B),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF1E1B17)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: !widget.disabled,
                      controller: textController,
                      focusNode: _focusNode,
                      onChanged: widget.onTextChanged,
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFEAE6E0)),
                      decoration: InputDecoration(
                        hintText: 'Keep talking...',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF3A3530)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                      cursorColor: const Color(0xFFC4783A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mic button
                  if (!widget.disabled)
                    StreamBuilder<VoiceState>(
                      stream: VoiceService().stateStream,
                      initialData: VoiceService().state,
                      builder: (ctx, snap) {
                        final vs = snap.data ?? VoiceState.idle;
                        final isActive = vs == VoiceState.listening || vs == VoiceState.speaking;
                        final isConnecting = vs == VoiceState.connecting || vs == VoiceState.disconnecting;
                        return GestureDetector(
                          onTap: isConnecting ? null : () async {
                            if (vs == VoiceState.idle) {
                              // Open dedicated voice session screen
                              await Navigator.of(ctx).push(PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const VoiceSessionScreen(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOut)),
                                      child: child,
                                    ),
                                transitionDuration:
                                    const Duration(milliseconds: 350),
                                fullscreenDialog: true,
                              ));
                            } else {
                              await VoiceService().disconnect();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: isConnecting
                                ? const SizedBox(
                                    width: 17, height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Color(0xFF3A3530)),
                                    ),
                                  )
                                : Icon(
                                    isActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                                    size: 17,
                                    color: isActive ? const Color(0xFFC4783A) : const Color(0xFF3A3530),
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send / Cancel button
          GestureDetector(
            onTap: widget.disabled
                ? (widget.onCancel != null ? () => widget.onCancel!() : null)
                : () {
                    if (textController.text.trim().isEmpty) return;
                    widget.onSubmitted(SubmitData(textController.text, _selectedFiles));
                    _afterSubmitted();
                  },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.disabled
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFB86A28), Color(0xFFE8AE60)],
                      ),
                color: widget.disabled ? const Color(0xFF1A1815) : null,
              ),
              child: Icon(
                widget.disabled ? Icons.stop_rounded : Icons.arrow_forward_rounded,
                size: 15,
                color: widget.disabled ? const Color(0xFF5A5550) : const Color(0xFF060504),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mobile Echo: use slim pill input
    if (kIsMobile) return _buildEchoMobileInput(context);

    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputAreaBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getInputAreaBorderColor(context), width: 1),
      ),
      margin: const EdgeInsets.only(left: 12.0, right: 12.0, top: 2.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0),
              constraints: const BoxConstraints(maxHeight: 65),
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _selectedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    final isImage =
                        file.extension?.toLowerCase() == 'jpg' ||
                        file.extension?.toLowerCase() == 'jpeg' ||
                        file.extension?.toLowerCase() == 'png' ||
                        file.extension?.toLowerCase() == 'gif';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.getInputAreaFileItemBackgroundColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.getInputAreaBorderColor(context), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isImage ? Icons.image : Icons.insert_drive_file,
                                    size: 16,
                                    color: AppColors.getInputAreaFileIconColor(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _truncateFileName(file.name),
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _removeFile(index),
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                                  child: Icon(Icons.close, size: 14, color: AppColors.getInputAreaIconColor(context)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Container(
              decoration: BoxDecoration(color: AppColors.getInputAreaBackgroundColor(context)),
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      return KeyEventResult.ignored;
                    }

                    if (_isImeComposing) {
                      return KeyEventResult.ignored;
                    }

                    if (widget.isComposing && textController.text.trim().isNotEmpty) {
                      widget.onSubmitted(SubmitData(textController.text, _selectedFiles));
                      _afterSubmitted();
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  enabled: !widget.disabled,
                  controller: textController,
                  focusNode: _focusNode,
                  onChanged: widget.onTextChanged,
                  maxLines: 5,
                  minLines: 1,
                  onAppPrivateCommand: (value, map) {
                    debugPrint('onAppPrivateCommand: $value');
                  },
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return null;
                  },
                  textInputAction: kIsMobile ? TextInputAction.newline : TextInputAction.done,
                  onSubmitted: null,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      _isImeComposing = newValue.composing != TextRange.empty;
                      return newValue;
                    }),
                  ],
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 14.0, color: AppColors.getInputAreaTextColor(context)),
                  scrollPhysics: const BouncingScrollPhysics(),
                  decoration: InputDecoration(
                    hintText: l10n.askMeAnything,
                    hintStyle: TextStyle(fontSize: 14.0, color: AppColors.getInputAreaHintTextColor(context)),
                    filled: true,
                    fillColor: AppColors.getInputAreaBackgroundColor(context),
                    hoverColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    isDense: true,
                  ),
                  cursorColor: AppColors.getInputAreaCursorColor(context),
                  mouseCursor: WidgetStateMouseCursor.textable,
                ),
              ),
            ),
          ),
Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.disabled) ...[
                  Row(
                    children: [
                      FutureBuilder<int>(
                        future: ProviderManager.mcpServerProvider.installedServersCount,
                        builder: (context, snapshot) {
                          return const McpTools();
                        },
                      ),
                      const SizedBox(width: 10),
                      if (kIsMobile) ...[
                        UploadMenu(disabled: widget.disabled, onPickImages: _pickImages, onPickFiles: _pickFiles),
                      ] else ...[
                        InkIcon(
                          icon: CupertinoIcons.plus_app,
                          onTap: () {
                            if (widget.disabled) return;
                            _pickFiles();
                          },
                          disabled: widget.disabled,
                          hoverColor: Theme.of(context).hoverColor,
                          tooltip: AppLocalizations.of(context)!.uploadFile,
                        ),
                      ],
                      const SizedBox(width: 10),
                      const ConvSetting(),
                      const SizedBox(width: 10),
                      VoiceButton(),
                    ],
                  ),
                ],
                if (!widget.disabled) ...[
                  const Spacer(),
                  InkIcon(
                    icon: CupertinoIcons.arrow_up_circle,
                    onTap: () {
                      if (widget.disabled || textController.text.trim().isEmpty) {
                        return;
                      }
                      widget.onSubmitted(SubmitData(textController.text, _selectedFiles));
                      _afterSubmitted();
                    },
                    tooltip: AppLocalizations.of(context)!.send,
                  ),
                ] else ...[
                  const Spacer(),
                  InkIcon(
                    icon: CupertinoIcons.stop,
                    onTap: widget.onCancel != null
                        ? () {
                            widget.onCancel!();
                          }
                        : null,
                    tooltip: AppLocalizations.of(context)!.cancel,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voice status banner ───────────────────────────────────────────────────

class _VoiceStatusBanner extends StatefulWidget {
  const _VoiceStatusBanner();

  @override
  State<_VoiceStatusBanner> createState() => _VoiceStatusBannerState();
}

class _VoiceStatusBannerState extends State<_VoiceStatusBanner> {
  String _lastTranscript = '';
  late final StreamSubscription<({String role, String text})> _transcriptSub;
  late final StreamSubscription<VoiceState> _stateSub;

  @override
  void initState() {
    super.initState();
    _transcriptSub = VoiceService().transcriptStream.listen((t) {
      if (mounted && t.role == 'user' && t.text.isNotEmpty) {
        setState(() => _lastTranscript = t.text);
      }
    });
    _stateSub = VoiceService().stateStream.listen((s) {
      if (mounted && s == VoiceState.idle) {
        setState(() => _lastTranscript = '');
      }
    });
  }

  @override
  void dispose() {
    _transcriptSub.cancel();
    _stateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VoiceState>(
      stream: VoiceService().stateStream,
      initialData: VoiceService().state,
      builder: (context, snap) {
        final state = snap.data ?? VoiceState.idle;
        if (state == VoiceState.idle) return const SizedBox.shrink();

        final (label, icon, color) = switch (state) {
          VoiceState.connecting    => ('Connecting...', Icons.wifi_tethering_rounded, const Color(0xFF5A5550)),
          VoiceState.listening     => (_lastTranscript.isNotEmpty ? '"$_lastTranscript"' : 'Echo is listening...', Icons.hearing_rounded, const Color(0xFFC4783A)),
          VoiceState.speaking      => ('Echo is speaking', Icons.volume_up_rounded, const Color(0xFF4A9EDB)),
          VoiceState.disconnecting => ('Ending session...', Icons.wifi_tethering_off_rounded, const Color(0xFF5A5550)),
          _                        => ('Voice active', Icons.mic_rounded, const Color(0xFFC4783A)),
        };

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
