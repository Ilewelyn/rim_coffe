import 'package:flutter/material.dart';

/// Paleta de cafetería: espresso, café tostado, caramelo y crema.
class AppColors {
  AppColors._();

  static const Color espresso = Color(0xFF24160F);
  static const Color cafe = Color(0xFF6B4632);
  static const Color mocha = Color(0xFF8A5A3B);
  static const Color caramel = Color(0xFFC4864F);
  static const Color latte = Color(0xFFE6D3BC);
  static const Color crema = Color(0xFFF3EADF);
  static const Color foam = Color(0xFFFAF6F1);
  static const Color muted = Color(0xFF8C786A);
  static const Color line = Color(0xFFEADFD3);
  static const Color ok = Color(0xFF4C7A55);
  static const Color danger = Color(0xFFB3402F);
}

/// Colores de la marca Rim Coffee (la plataforma, no la cafetería):
/// azul marino, verde azulado y naranja del logo. Se usan en el splash y
/// en el inicio de sesión; dentro de cada negocio manda la paleta café.
class MarcaColors {
  MarcaColors._();

  static const Color marino = Color(0xFF173650);
  static const Color azulado = Color(0xFF237F86);
  static const Color naranja = Color(0xFFE8913F);
  static const Color claro = Color(0xFFD8ECEA);
}

/// Colores que cambian según la zona de la app: café dentro de cada negocio
/// y turquesa de la marca Rim Coffee en el inicio de sesión. Los widgets
/// propios (botones, campos, avisos) los leen con `RcColores.of(context)`.
class RcColores extends ThemeExtension<RcColores> {
  const RcColores({
    required this.primario,
    required this.secundario,
    required this.acento,
    required this.suave,
    required this.borde,
  });

  /// Botón principal y títulos fuertes.
  final Color primario;

  /// Botones de contorno, enlaces y selección.
  final Color secundario;

  /// Foco de los campos y botones destacados.
  final Color acento;

  /// Fondos suaves (avisos, opciones elegidas).
  final Color suave;
  final Color borde;

  static const RcColores cafe = RcColores(
    primario: AppColors.espresso,
    secundario: AppColors.cafe,
    acento: AppColors.caramel,
    suave: AppColors.crema,
    borde: AppColors.line,
  );

  static const RcColores marca = RcColores(
    primario: MarcaColors.marino,
    secundario: MarcaColors.azulado,
    acento: MarcaColors.azulado,
    suave: Color(0xFFE5F2F1),
    borde: Color(0xFFD3E5E4),
  );

  static RcColores of(BuildContext context) =>
      Theme.of(context).extension<RcColores>() ?? cafe;

  @override
  RcColores copyWith({
    Color? primario,
    Color? secundario,
    Color? acento,
    Color? suave,
    Color? borde,
  }) {
    return RcColores(
      primario: primario ?? this.primario,
      secundario: secundario ?? this.secundario,
      acento: acento ?? this.acento,
      suave: suave ?? this.suave,
      borde: borde ?? this.borde,
    );
  }

  @override
  RcColores lerp(RcColores? other, double t) {
    if (other == null) {
      return this;
    }
    return RcColores(
      primario: Color.lerp(primario, other.primario, t)!,
      secundario: Color.lerp(secundario, other.secundario, t)!,
      acento: Color.lerp(acento, other.acento, t)!,
      suave: Color.lerp(suave, other.suave, t)!,
      borde: Color.lerp(borde, other.borde, t)!,
    );
  }
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x142B1810), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A2B1810), blurRadius: 4, offset: Offset(0, 1)),
  ];
}

/// Tipografías incluidas en la app (assets/fonts):
/// - DM Serif Display para títulos (toque de carta de cafetería).
/// - Poppins para textos, botones y números.
class AppFonts {
  AppFonts._();

  static const String serif = 'DMSerifDisplay';
  static const String sans = 'Poppins';
}

class AppText {
  AppText._();

  /// Títulos grandes de portada (login, bienvenida, turno).
  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.1,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.15,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.2,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.2,
  );
  static const TextStyle title = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.espresso,
  );
  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 14,
    color: AppColors.espresso,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 12,
    color: AppColors.muted,
    height: 1.35,
  );
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.cafe,
    letterSpacing: 0.6,
  );
}

/// Tema de la marca Rim Coffee (turquesa): splash, inicio de sesión,
/// registro y recuperar contraseña.
ThemeData buildThemeMarca() => buildTheme(colores: RcColores.marca, fondo: const Color(0xFFF4F8F8));

ThemeData buildTheme({RcColores colores = RcColores.cafe, Color fondo = AppColors.foam}) {
  final scheme = ColorScheme.light(
    primary: colores.secundario,
    onPrimary: Colors.white,
    secondary: colores.acento,
    onSecondary: Colors.white,
    surface: fondo,
    onSurface: AppColors.espresso,
    error: AppColors.danger,
    onError: Colors.white,
    primaryContainer: colores.suave,
    onPrimaryContainer: AppColors.espresso,
    secondaryContainer: colores.suave,
    onSecondaryContainer: colores.secundario,
    outline: colores.borde,
    outlineVariant: colores.borde,
  );

  final redondo = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const textoBoton = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.sans,
    scaffoldBackgroundColor: fondo,
    extensions: [colores],
    appBarTheme: AppBarTheme(
      backgroundColor: fondo,
      foregroundColor: AppColors.espresso,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppText.h3,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: fondo,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: AppText.h3,
      contentTextStyle: AppText.body,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: fondo,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colores.borde,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colores.borde),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colores.secundario,
        foregroundColor: Colors.white,
        shape: redondo,
        textStyle: textoBoton,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colores.secundario,
        side: BorderSide(color: colores.secundario, width: 1.4),
        shape: redondo,
        textStyle: textoBoton,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colores.secundario,
        textStyle: textoBoton.copyWith(fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colores.primario,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: textoBoton,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.crema,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(
        fontFamily: AppFonts.sans,
        fontWeight: FontWeight.w600,
        color: AppColors.cafe,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colores.acento),
    listTileTheme: ListTileThemeData(iconColor: colores.secundario),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? colores.secundario : null,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colores.primario,
      contentTextStyle: const TextStyle(fontFamily: AppFonts.sans, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Decoración de campo de texto: fondo blanco, esquinas redondeadas y
/// borde café al enfocar.
InputDecoration rcInput({
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool enabled = true,
  bool dense = false,
  Color foco = AppColors.caramel,
}) {
  OutlineInputBorder borde(Color color, [double ancho = 1.2]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    isDense: dense,
    filled: true,
    fillColor: enabled ? Colors.white : AppColors.crema,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: borde(AppColors.line),
    enabledBorder: borde(AppColors.line),
    focusedBorder: borde(foco, 1.8),
    disabledBorder: borde(AppColors.line),
    errorBorder: borde(AppColors.danger),
    focusedErrorBorder: borde(AppColors.danger, 1.8),
    errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
  );
}
