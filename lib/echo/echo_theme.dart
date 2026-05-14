import 'package:flutter/material.dart';

// ── Private dark palette ──────────────────────────────────────────────────────

abstract final class _D {
  static const Color canvas = Color(0xFF0B1118);
  static const Color surface = Color(0xFF111A24);
  static const Color softSurface = Color(0xFF172333);
  static const Color deepSurface = Color(0xFF203148);
  static const Color primaryAi = Color(0xFF83BDF2);
  static const Color practice = Color(0xFF68D99D);
  static const Color proof = Color(0xFFA8C3F2);
  static const Color memory = Color(0xFFB8ABFF);
  static const Color opportunity = Color(0xFFE3BD61);
  static const Color risk = Color(0xFFEF927F);
  static const Color bgDeep = Color(0xFF070D14);
  static const Color bgInput = Color(0xFF172333);
  static const Color bgChatAI = Color(0xFF111A24);
  static const Color amberBurn = Color(0xFF122A44);
  static const Color indigoBg = Color(0xFF1A1733);
  static const Color border = Color(0xFF263646);
  static const Color borderSubtle = Color(0xFF1D2B3A);
  static const Color borderNav = Color(0xFF192634);
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFC9D5E2);
  static const Color textMuted = Color(0xFF91A1B2);
  static const Color textDim = Color(0xFF6F8194);
  static const Color textGhost = Color(0xFF56687B);
  static const Color textVeryGhost = Color(0xFF405164);
}

// ── Private light palette ─────────────────────────────────────────────────────

abstract final class _L {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFEEF4FA);
  static const Color deepSurface = Color(0xFFE3EDF7);
  static const Color primaryAi = Color(0xFF2D7DD2);
  static const Color practice = Color(0xFF1FA971);
  static const Color proof = Color(0xFF243E73);
  static const Color memory = Color(0xFF6F5DD3);
  static const Color opportunity = Color(0xFFC59A34);
  static const Color risk = Color(0xFFD96B5F);
  static const Color bgDeep = Color(0xFFE8F1FA);
  static const Color bgInput = Color(0xFFEEF4FA);
  static const Color bgChatAI = Color(0xFFF1F6FC);
  static const Color amberBurn = Color(0xFFD9EAFB);
  static const Color indigoBg = Color(0xFFF0EEF8);
  static const Color border = Color(0xFFDCE6EF);
  static const Color borderSubtle = Color(0xFFE5ECF3);
  static const Color borderNav = Color(0xFFDCE6EF);
  static const Color textPrimary = Color(0xFF101820);
  static const Color textSecondary = Color(0xFF4F5B57);
  static const Color textMuted = Color(0xFF6F7A75);
  static const Color textDim = Color(0xFF7D8A84);
  static const Color textGhost = Color(0xFF9AA7A1);
  static const Color textVeryGhost = Color(0xFFB5C2BC);
}

// ── Theme state (single mutable bool, no ChangeNotifier needed) ───────────────
//
// Updated synchronously from Consumer<SettingsProvider> in main.dart before
// MaterialApp renders. Since Consumer rebuilds the whole tree, all EchoColors
// getters see the new value on the very next frame.

class EchoThemeState {
  EchoThemeState._();
  static final EchoThemeState instance = EchoThemeState._();

  bool isDark = true;
}

// ── Public color API ──────────────────────────────────────────────────────────
//
// All fields are static getters (not const) so they react to EchoThemeState.
// Replace any `const Widget(color: EchoColors.xxx)` with non-const equivalents.

class EchoColors {
  static bool get _d => EchoThemeState.instance.isDark;

  // Core surfaces
  static Color get canvas => _d ? _D.canvas : _L.canvas;
  static Color get surface => _d ? _D.surface : _L.surface;
  static Color get softSurface => _d ? _D.softSurface : _L.softSurface;
  static Color get deepSurface => _d ? _D.deepSurface : _L.deepSurface;

  // Semantic palette
  static Color get primaryAi => _d ? _D.primaryAi : _L.primaryAi;
  static Color get practice => _d ? _D.practice : _L.practice;
  static Color get proof => _d ? _D.proof : _L.proof;
  static Color get memory => _d ? _D.memory : _L.memory;
  static Color get opportunity => _d ? _D.opportunity : _L.opportunity;
  static Color get risk => _d ? _D.risk : _L.risk;
  static Color get runtime => primaryAi;

  // Legacy amber aliases (kept for screen compatibility)
  static Color get amber => primaryAi;
  static Color get amberLight => _d ? _D.practice : _L.practice;
  static Color get amberGlow => primaryAi;
  static Color get amberDark => _d ? _D.proof : _L.proof;
  static Color get amberBurn => _d ? _D.amberBurn : _L.amberBurn;
  static Color get amberText => primaryAi;

  // Legacy indigo aliases
  static Color get indigo => memory;
  static Color get indigoLight => memory;
  static Color get indigoBg => _d ? _D.indigoBg : _L.indigoBg;

  // Surfaces
  static Color get bg => canvas;
  static Color get bgDeep => _d ? _D.bgDeep : _L.bgDeep;
  static Color get bgSurface => surface;
  static Color get bgCard => surface;
  static Color get bgInput => _d ? _D.bgInput : _L.bgInput;
  static Color get bgChatAI => _d ? _D.bgChatAI : _L.bgChatAI;
  static Color get bgChatUser => primaryAi;

  // Borders
  static Color get border => _d ? _D.border : _L.border;
  static Color get borderSubtle => _d ? _D.borderSubtle : _L.borderSubtle;
  static Color get borderCard => border;
  static Color get borderNav => _d ? _D.borderNav : _L.borderNav;

  // Text hierarchy
  static Color get textPrimary => _d ? _D.textPrimary : _L.textPrimary;
  static Color get textSecondary => _d ? _D.textSecondary : _L.textSecondary;
  static Color get textMuted => _d ? _D.textMuted : _L.textMuted;
  static Color get textDim => _d ? _D.textDim : _L.textDim;
  static Color get textGhost => _d ? _D.textGhost : _L.textGhost;
  static Color get textVeryGhost => _d ? _D.textVeryGhost : _L.textVeryGhost;
}
