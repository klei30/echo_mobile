import 'package:chatmcp/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/connected_apps_screen.dart';
import 'llm_setting.dart';
import 'general_setting.dart';
import 'package:flutter/cupertino.dart';
import 'network_sync_setting.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  List<SettingTab> _getTabs(BuildContext context) {
    return [
      SettingTab(title: 'Basics', icon: CupertinoIcons.settings, content: GeneralSettings()),
      SettingTab(title: 'Model Keys', icon: CupertinoIcons.cube, content: KeysSettings()),
      SettingTab(title: 'Actions', icon: CupertinoIcons.link, content: ConnectedAppsScreen()),
      if (!kIsBrowser) SettingTab(title: 'Home Brain', icon: CupertinoIcons.cloud_download, content: NetworkSyncSetting()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs(context);

    final canPop = Navigator.of(context).canPop();
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: EchoColors.bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: canPop ? kToolbarHeight : 0,
          leading: canPop
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: EchoColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          title: canPop
              ? Text(
                  'Settings',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
                )
              : null,
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            indicatorColor: EchoColors.amber,
            labelColor: EchoColors.textPrimary,
            unselectedLabelColor: EchoColors.textMuted,
            labelStyle: GoogleFonts.plusJakartaSans(fontSize: kIsMobile ? 10 : 13, fontWeight: FontWeight.w700),
            tabs: tabs.map((tab) => Tab(icon: Icon(tab.icon), text: tab.title)).toList(),
            onTap: (index) {
              setState(() {});
            },
          ),
        ),
        body: TabBarView(children: tabs.map((tab) => tab.content).toList()),
      ),
    );
  }
}

// é€‰é¡¹å¡æ•°æ®æ¨¡åž‹
class SettingTab {
  final String title;
  final IconData icon;
  final Widget content;

  SettingTab({required this.title, required this.icon, required this.content});
}
