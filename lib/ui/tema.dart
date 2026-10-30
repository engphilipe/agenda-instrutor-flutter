import 'package:flutter/material.dart';

abstract final class Cores {
  static const fundo = Color(0xFF101013);
  static const cartao = Color(0xFF1B1B1F);
  static const campo = Color(0xFF1E1E22);
  static const borda = Color(0xFF2A2A2F);
  static const texto = Color(0xFFF2F2F3);
  static const textoSuave = Color(0xFF8B8B93);
  static const primaria = Color(0xFF3B82F6);
  static const botao = Color(0xFF2563EB);
  static const perigo = Color(0xFFB4483C);
  static const perigoTexto = Color(0xFFE58C83);
  static const sucesso = Color(0xFF71C995);
  static const nota = Color(0xFFF2C230);
}

ThemeData criarTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.primaria,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Cores.botao,
    onPrimary: Colors.white,
    secondary: Cores.primaria,
    surface: Cores.fundo,
    surfaceContainerLow: Cores.cartao,
    surfaceContainer: Cores.cartao,
    surfaceContainerHigh: Cores.campo,
    onSurface: Cores.texto,
    onSurfaceVariant: Cores.textoSuave,
    outline: Cores.borda,
    outlineVariant: Cores.borda,
    error: Cores.perigoTexto,
    errorContainer: Cores.perigo,
    onErrorContainer: Colors.white,
  );
  final bordaCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Cores.borda),
  );

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.fundo,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Cores.cartao,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.borda),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.campo,
      border: bordaCampo,
      enabledBorder: bordaCampo,
      focusedBorder: bordaCampo.copyWith(
        borderSide: const BorderSide(color: Cores.primaria, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Cores.cartao,
      indicatorColor: Color(0x333B82F6),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Cores.campo,
      contentTextStyle: TextStyle(color: Cores.texto),
    ),
  );
}
