import 'package:material_ui/material_ui.dart';

/// Centraliza os temas azul-noturno e azul-claro suave do AlugaPlay.
class AppTheme {
  AppTheme._();

  /// Notificador reativo observado pelo app para reconstruir o tema em runtime.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Azul principal e tons de apoio da identidade visual.
  static const Color blue = Color(0xFF2563EB);
  static const Color blueAccent = Color(0xFF38BDF8);
  static const Color blueDeep = Color(0xFF1D4ED8);

  /// Amarelo de destaque usado em detalhes sem comprometer a leitura.
  static const Color gold = Color(0xFFFACC15);
  static const Color goldAmber = Color(0xFFA16207);

  /// Degradê principal compartilhado por ações e estados selecionados.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Fundo do destaque da semana, ajustado ao contraste de cada tema.
  static LinearGradient heroBannerGradient(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [Color(0xFF16264A), Color(0xFF0A1224), Color(0xFF101B36)]
          : const [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Halo suave para a área superior sem competir com o conteúdo.
  static RadialGradient topAmbientGradient(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return RadialGradient(
      center: Alignment.topCenter,
      radius: 1.15,
      colors: isDark
          ? [
              blueAccent.withValues(alpha: 0.2),
              blueDeep.withValues(alpha: 0.08),
              Colors.transparent,
            ]
          : [
              const Color(0xFF38BDF8).withValues(alpha: 0.1),
              const Color(0xFF2563EB).withValues(alpha: 0.035),
              Colors.transparent,
            ],
      stops: const [0, 0.48, 1],
    );
  }

  /// Raios compartilhados para manter consistência entre componentes.
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  /// Alterna o modo ativo; a mudança notifica os ouvintes de [themeModeNotifier].
  static void toggleTheme(Brightness currentBrightness) {
    themeModeNotifier.value = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  /// Temas construídos uma vez e reutilizados em cada alternância de aparência.
  static final ThemeData darkTheme = _buildDarkTheme();
  static final ThemeData lightTheme = _buildLightTheme();

  /// Monta o esquema escuro com superfícies azul-noturno.
  static ThemeData _buildDarkTheme() => _buildTheme(
    brightness: Brightness.dark,
    background: const Color(0xFF050811),
    surface: const Color(0xFF0A1224),
    surfaceContainer: const Color(0xFF101B36),
    outline: const Color(0xFF263654),
    foreground: const Color(0xFFF8FAFC),
    foregroundVariant: const Color(0xFFAAB8CE),
  );

  /// Usa superfícies azuladas suaves e texto escuro de alto contraste.
  static ThemeData _buildLightTheme() => _buildTheme(
    brightness: Brightness.light,
    background: const Color(0xFFF8FAFC),
    surface: const Color(0xFFFFFFFF),
    surfaceContainer: const Color(0xFFEFF6FF),
    outline: const Color(0xFFCBD5E1),
    foreground: const Color(0xFF0F172A),
    foregroundVariant: const Color(0xFF334155),
    primary: blueDeep,
    secondary: blueDeep,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceContainer,
    required Color outline,
    required Color foreground,
    required Color foregroundVariant,
    Color? primary,
    Color? secondary,
  }) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = primary ?? blue;
    final secondaryColor = secondary ?? (isDark ? gold : goldAmber);
    final colorScheme =
        (isDark
                ? ColorScheme.dark(
                    primary: primaryColor,
                    onPrimary: const Color(0xFFFFFFFF),
                    secondary: secondaryColor,
                    onSecondary: const Color(0xFF050811),
                    surface: surface,
                    onSurface: foreground,
                    error: const Color(0xFFDC2626),
                    onError: const Color(0xFFFFFFFF),
                  )
                : ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: const Color(0xFFFFFFFF),
                    secondary: secondaryColor,
                    onSecondary: const Color(0xFF050811),
                    surface: surface,
                    onSurface: foreground,
                    error: const Color(0xFFB91C1C),
                    onError: const Color(0xFFFFFFFF),
                  ))
            .copyWith(
              primaryContainer: isDark
                  ? const Color(0xFF101B36)
                  : const Color(0xFFEFF6FF),
              onPrimaryContainer: foreground,
              secondaryContainer: isDark
                  ? const Color(0xFF332B10)
                  : const Color(0xFFDBEAFE),
              onSecondaryContainer: isDark
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFF1E3A8A),
              tertiary: secondaryColor,
              onTertiary: const Color(0xFF0A1224),
              surfaceDim: background,
              surfaceBright: surface,
              surfaceContainerLowest: background,
              surfaceContainerLow: surface,
              surfaceContainer: surfaceContainer,
              surfaceContainerHigh: surfaceContainer,
              surfaceContainerHighest: surfaceContainer,
              onSurfaceVariant: foregroundVariant,
              outline: outline,
              outlineVariant: outline,
              shadow: const Color(0xFF000000),
              scrim: const Color(0xFF000000),
              inverseSurface: foreground,
              onInverseSurface: background,
              inversePrimary: blueAccent,
              surfaceTint: blue,
            );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: foreground,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: foreground,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: foreground, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: colorScheme.secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: foregroundVariant),
        floatingLabelStyle: TextStyle(color: colorScheme.secondary),
        hintStyle: TextStyle(color: foregroundVariant),
        iconColor: colorScheme.secondary,
        prefixIconColor: colorScheme.secondary,
        suffixIconColor: colorScheme.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: isDark ? blueAccent : colorScheme.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: outline),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: surface,
        shadowColor: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: outline),
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.secondary),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: colorScheme.primary,
        checkmarkColor: const Color(0xFFFFFFFF),
        labelStyle: TextStyle(color: foreground),
        secondaryLabelStyle: TextStyle(color: foreground),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: foreground),
        actionsIconTheme: IconThemeData(color: foreground),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (states) => IconThemeData(
            color: isDark || states.contains(WidgetState.selected)
                ? colorScheme.secondary
                : foregroundVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => TextStyle(
            color: isDark
                ? colorScheme.secondary
                : states.contains(WidgetState.selected)
                ? colorScheme.primary
                : foregroundVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceContainer,
        contentTextStyle: TextStyle(color: foreground),
        actionTextColor: colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        titleTextStyle: TextStyle(color: foreground),
        contentTextStyle: TextStyle(color: foregroundVariant),
      ),
    );
  }
}
