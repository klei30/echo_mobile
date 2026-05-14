import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:flutter/material.dart';
import 'package:chatmcp/page/echo_settings/echo_settings_sheet.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatmcp/components/widgets/base.dart';
import 'package:chatmcp/config/pagination_config.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class SidebarPanel extends StatefulWidget {
  final VoidCallback? onToggle;
  const SidebarPanel({super.key, this.onToggle});

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _performSearch(''); // Reset search when hiding
      }
    });
  }

  void _performSearch(String keyword) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.searchChats(keyword);
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) => SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            // 顶部区域
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 8),
              child: Row(
                children: [
                  // On desktop show Echo branding; on mobile Echo manages the header
                  if (kIsDesktop) ...[
                    Image.asset('assets/echo_logo.png', width: 24, height: 24),
                    const Gap(size: 8),
                    Text(
                      'Echo',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                    ),
                  ],
                  if (kIsMobile) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Conversations',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                      ),
                    ),
                  ],
                  const Spacer(),
                  InkIcon(icon: CupertinoIcons.search, onTap: toggleSearchVisibility, tooltip: AppLocalizations.of(context)!.search),
                  if (kIsMobile) ...[
                    const Gap(size: 4),
                    InkIcon(
                      icon: CupertinoIcons.square_pencil,
                      onTap: () {
                        chatProvider.startNewChat();
                        Navigator.pop(context);
                      },
                      tooltip: 'New chat',
                    ),
                  ],
                  if (kIsDesktop) ...[
                    const Gap(size: 8),
                    InkIcon(icon: CupertinoIcons.sidebar_left, onTap: widget.onToggle, tooltip: AppLocalizations.of(context)!.toggleSidebar),
                  ],
                ],
              ),
            ),

            // 搜索框
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: EchoColors.bgInput,
                    border: Border.all(color: EchoColors.borderSubtle),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search conversations',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost),
                      suffixIcon: IconButton(
                        icon: Icon(CupertinoIcons.clear, size: 14, color: EchoColors.textGhost),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: InputBorder.none,
                      isDense: true,
                      isCollapsed: true,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textSecondary),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),

            // 中间区域 - 聊天历史列表
            Expanded(child: ChatHistoryList(chatProvider: chatProvider)),

            // 底部区域
            SidebarToolbar(chatProvider: chatProvider),
          ],
        ),
      ),
    );
  }
}

class ChatHistoryList extends StatefulWidget {
  final ChatProvider chatProvider;

  const ChatHistoryList({super.key, required this.chatProvider});

  @override
  State<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends State<ChatHistoryList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false; // 防止重复触发加载
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // FIX: Force reload when user changes, not just when empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = AuthService().userId;
      if (_lastUserId != currentUserId) {
        _lastUserId = currentUserId;
        widget.chatProvider.loadChats(refresh: true); // force reload on user switch
      } else if (widget.chatProvider.chats.isEmpty) {
        widget.chatProvider.loadChats();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 如果已经在加载，不重复触发
    if (_isLoadingMore) return;

    // 检查是否滚动到接近底部
    final scrollPosition = _scrollController.position;
    final isNearBottom = scrollPosition.pixels >= scrollPosition.maxScrollExtent - PaginationConfig.loadMoreTriggerDistance;

    // 只有在接近底部且有更多数据时才加载
    if (isNearBottom && widget.chatProvider.hasMoreChats && !widget.chatProvider.isLoadingChats && widget.chatProvider.chats.isNotEmpty) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.chatProvider.loadMoreChats();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Map<String, List<dynamic>> _groupChats(BuildContext context, List<dynamic> chats) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final previous7Days = today.subtract(const Duration(days: 7));
    final previous30Days = today.subtract(const Duration(days: 30));

    return {
      l10n.today: chats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isAtSameMomentAs(today);
      }).toList(),
      l10n.yesterday: chats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isAtSameMomentAs(yesterday);
      }).toList(),
      l10n.last7Days: chats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(yesterday) && chatDate.isAfter(previous7Days);
      }).toList(),
      l10n.last30Days: chats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(previous7Days) && chatDate.isAfter(previous30Days);
      }).toList(),
      l10n.earlier: chats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(previous30Days);
      }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final groupedChats = _groupChats(context, widget.chatProvider.chats);
    final hasEmptyGroups = groupedChats.values.every((group) => group.isEmpty);

    if (hasEmptyGroups && !widget.chatProvider.isLoadingChats) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Text(
            'Start a conversation with Echo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _calculateItemCount(groupedChats) + 1, // +1 for footer
            itemBuilder: (context, index) {
              final normalItemCount = _calculateItemCount(groupedChats);
              if (index == normalItemCount) {
                // This is the footer item
                return _buildFooter();
              }
              return _buildItem(context, groupedChats, index);
            },
          ),
        ),
      ],
    );
  }

  int _calculateItemCount(Map<String, List<dynamic>> groupedChats) {
    int count = 0;
    for (final entry in groupedChats.entries) {
      if (entry.value.isNotEmpty) {
        count += 1 + entry.value.length; // Header + items
      }
    }
    return count;
  }

  Widget _buildItem(BuildContext context, Map<String, List<dynamic>> groupedChats, int index) {
    int currentIndex = 0;

    for (final entry in groupedChats.entries) {
      if (entry.value.isEmpty) continue;

      // Check if this is the header
      if (currentIndex == index) {
        return _buildGroupHeader(entry.key);
      }
      currentIndex++;

      // Check if this is within the group items
      if (index < currentIndex + entry.value.length) {
        final itemIndex = index - currentIndex;
        return _buildChatItem(entry.value[itemIndex]);
      }
      currentIndex += entry.value.length;
    }

    return const SizedBox.shrink();
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).round()),
        ),
      ),
    );
  }

  Widget _buildChatItem(dynamic chat) {
    return ChatHistoryItem(chat: chat, chatProvider: widget.chatProvider);
  }

  Widget _buildFooter() {
    // Don't show footer if there are no chats at all
    if (widget.chatProvider.chats.isEmpty && !widget.chatProvider.isLoadingChats) {
      return const SizedBox.shrink();
    }

    if (widget.chatProvider.isLoadingChats) {
      // Show loading indicator when loading more
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.downloadingData,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).round())),
            ),
          ],
        ),
      );
    } else if (!widget.chatProvider.hasMoreChats && widget.chatProvider.chats.isNotEmpty) {
      // Show "no more" message only when there are chats and no more to load
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Text(
          'No more conversations',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textVeryGhost),
        ),
      );
    } else {
      // Has more but not loading, show minimal space for scroll detection
      return const SizedBox(height: 50);
    }
  }
}

class ChatHistoryItem extends StatelessWidget {
  final dynamic chat;
  final ChatProvider chatProvider;

  const ChatHistoryItem({super.key, required this.chat, required this.chatProvider});

  @override
  Widget build(BuildContext context) {
    final isActive = chat.id == chatProvider.activeChat?.id;
    final backgroundColor = AppColors.getThemeColor(context, lightColor: Colors.white, darkColor: Colors.grey[800]);

    // 创建弹出菜单的内容
    Widget popupContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context); // 关闭弹窗
              _showDeleteConfirmDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(CupertinoIcons.delete, size: 18, color: EchoColors.risk),
                  const Gap(size: 8),
                  Text('Delete', style: GoogleFonts.plusJakartaSans(color: EchoColors.risk, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // 创建聊天项
    Widget chatItem = ListTile(
      dense: true,
      visualDensity: VisualDensity(vertical: -4),
      leading: chatProvider.isSelectMode
          ? Checkbox(
              value: chatProvider.selectedChats.contains(chat.id),
              onChanged: (bool? value) {
                if (value == true) {
                  chatProvider.selectChat(chat.id);
                } else {
                  chatProvider.unselectChat(chat.id);
                }
              },
            )
          : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.title.replaceAll('\n', ' '),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: EchoColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        if (chatProvider.isSelectMode) {
          chatProvider.toggleSelectChat(chat.id);
        } else {
          chatProvider.setActiveChat(chat);
          if (kIsMobile) {
            Navigator.pop(context);
          }
        }
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? EchoColors.primaryAi.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? EchoColors.primaryAi.withValues(alpha: 0.18) : Colors.transparent),
      ),
      child: kIsDesktop
          ? _buildDesktopChatItem(context, chatItem, popupContent, backgroundColor)
          : _buildMobileChatItem(context, chatItem, popupContent, backgroundColor),
    );
  }

  // 桌面端构建方法：右键触发
  Widget _buildDesktopChatItem(BuildContext context, Widget chatItem, Widget popupContent, Color? backgroundColor) {
    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) {
        _showCustomPopup(context, popupContent, backgroundColor, details.globalPosition);
      },
      child: chatItem,
    );
  }

  // 移动端构建方法：长按触发
  Widget _buildMobileChatItem(BuildContext context, Widget chatItem, Widget popupContent, Color? backgroundColor) {
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        _showCustomPopup(context, popupContent, backgroundColor, details.globalPosition);
      },
      child: chatItem,
    );
  }

  // 显示自定义弹出窗口
  void _showCustomPopup(BuildContext context, Widget content, Color? backgroundColor, Offset position) {
    // 估计弹出菜单的宽度
    const double estimatedPopupWidth = 150.0;

    // 计算屏幕宽度
    final double screenWidth = MediaQuery.of(context).size.width;

    // 计算合适的left位置，使菜单靠右显示
    double left = position.dx;

    // 确保菜单不会超出屏幕左边界
    left = left < 10 ? 10 : left;

    // 确保菜单不会超出屏幕右边界
    if (left + estimatedPopupWidth > screenWidth - 10) {
      left = screenWidth - estimatedPopupWidth - 10;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: position.dy,
              child: Material(elevation: 4.0, borderRadius: BorderRadius.circular(8.0), color: backgroundColor, child: content),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSelected),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              chatProvider.deleteChat(chat.id);
              Navigator.pop(context);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

class SidebarToolbar extends StatelessWidget {
  final ChatProvider chatProvider;

  const SidebarToolbar({super.key, required this.chatProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // On desktop show settings gear; on mobile settings is in the Echo header
          if (!kIsMobile) _buildSettingsButton(context),
          if (!kIsMobile) const Gap(size: 4),
          _buildSelectModeButton(context),
          if (chatProvider.isSelectMode) ...[const Gap(size: 4), _buildSelectAllButton(context), const Gap(size: 4), _buildDeleteButton(context)],
          const Spacer(),
          if (AuthService().isLoggedIn && !kIsMobile) _buildLogoutButton(context),
          const Gap(size: 4),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return InkIcon(icon: CupertinoIcons.settings, onTap: () => EchoSettingsSheet.show(context), tooltip: AppLocalizations.of(context)!.settings);
  }

  Widget _buildLogoutButton(BuildContext context) {
    final username = AuthService().username;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showLogoutDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (username ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            if (username != null) ...[const SizedBox(width: 4), Text(username, style: const TextStyle(fontSize: 11))],
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out'),
        content: Text('Sign out as ${AuthService().username ?? 'user'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ChatProvider().clearOnLogout();
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => AuthGate()), (_) => false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: EchoColors.risk),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectModeButton(BuildContext context) {
    return InkIcon(
      icon: chatProvider.isSelectMode ? CupertinoIcons.clear : CupertinoIcons.trash,
      onTap: () {
        if (chatProvider.isSelectMode) {
          chatProvider.exitSelectMode();
        } else {
          chatProvider.enterSelectMode();
        }
      },
      tooltip: AppLocalizations.of(context)!.deleteChat,
    );
  }

  Widget _buildSelectAllButton(BuildContext context) {
    return InkIcon(
      icon: CupertinoIcons.checkmark_square,
      onTap: () => chatProvider.toggleSelectAll(),
      tooltip: AppLocalizations.of(context)!.selectAll,
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return InkIcon(
      icon: CupertinoIcons.delete,
      onTap: chatProvider.selectedChats.isNotEmpty ? () => _showDeleteConfirmDialog(context) : null,
      tooltip: AppLocalizations.of(context)!.delete,
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSelected),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              chatProvider.deleteSelectedChats();
              Navigator.pop(context);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
