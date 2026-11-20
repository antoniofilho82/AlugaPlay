import 'package:material_ui/material_ui.dart';

/// Centraliza o tema escuro grafite e o tema claro pastel do AlugaPlay.
class AppTheme {
  AppTheme._();

  /// Notificador reativo observado pelo app para reconstruir o tema em runtime.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Verde de referência para componentes e estados destacados.
  static const Color emerald = Color(0xFF16A34A);

  /// Tons secundários de esmeralda usados em acentos e estados sutis.
  static const Color emeraldAccent = Color(0xFF22C55E);
  static const Color emeraldDeep = Color(0xFF059669);

  /// Degradê principal compartilhado por ações e estados selecionados.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Fundo do destaque da semana, ajustado ao contraste de cada tema.
  static LinearGradient heroBannerGradient(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [Color(0xFF123521), Color(0xFF10291E), Color(0xFF181B20)]
          : const [Color(0xFFD7E7DD), Color(0xFFE5EFE8), Color(0xFFEEF4F0)],
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
              emeraldAccent.withValues(alpha: 0.2),
              emeraldDeep.withValues(alpha: 0.08),
              Colors.transparent,
            ]
          : [
              const Color(0xFF389E68).withValues(alpha: 0.14),
              const Color(0xFF2E8B57).withValues(alpha: 0.05),
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

  /// Monta o esquema escuro com superfícies grafite e acentos esmeralda.
  static ThemeData _buildDarkTheme() => _buildTheme(
    brightness: Brightness.dark,
    background: const Color(0xFF0F1115),
    surface: const Color(0xFF181B20),
    surfaceContainer: const Color(0xFF22262E),
    outline: const Color(0xFF2E3440),
    foreground: const Color(0xFFF8FAFC),
    foregroundVariant: const Color(0xFF94A3B8),
  );

  /// Usa superfícies verde-acinzentadas e acentos esmeralda de menor brilho.
  static ThemeData _buildLightTheme() => _buildTheme(
    brightness: Brightness.light,
    background: const Color(0xFFE3ECE6),
    surface: const Color(0xFFE3ECE6),
    surfaceContainer: const Color(0xFFEEF4F0),
    outline: const Color(0xFFC8D8CE),
    foreground: const Color(0xFF233029),
    foregroundVariant: const Color(0xFF52645A),
    primary: const Color(0xFF2E8B57),
    secondary: const Color(0xFF389E68),
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
    final primaryColor = primary ?? emerald;
    final secondaryColor = secondary ?? (isDark ? emeraldAccent : emeraldDeep);
    final colorScheme =
        (isDark
                ? ColorScheme.dark(
                    primary: primaryColor,
                    onPrimary: const Color(0xFFFFFFFF),
                    secondary: secondaryColor,
                    onSecondary: const Color(0xFF052E1B),
                    surface: surface,
                    onSurface: foreground,
                    error: const Color(0xFFDC2626),
                    onError: const Color(0xFFFFFFFF),
                  )
                : ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: const Color(0xFFFFFFFF),
                    secondary: secondaryColor,
                    onSecondary: const Color(0xFFFFFFFF),
                    surface: surface,
                    onSurface: foreground,
                    error: const Color(0xFFB91C1C),
                    onError: const Color(0xFFFFFFFF),
                  ))
            .copyWith(
              primaryContainer: isDark
                  ? const Color(0xFF123521)
                  : const Color(0xFFD7E7DD),
              onPrimaryContainer: isDark ? const Color(0xFFD1FAE5) : foreground,
              secondaryContainer: surfaceContainer,
              onSecondaryContainer: foreground,
              tertiary: isDark ? emeraldDeep : secondaryColor,
              onTertiary: const Color(0xFFFFFFFF),
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
              inversePrimary: emeraldAccent,
              surfaceTint: emerald,
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
            color: isDark ? emeraldAccent : colorScheme.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: outline),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? surface : surfaceContainer,
        surfaceTintColor: isDark ? surface : surfaceContainer,
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
        indicatorColor: isDark
            ? const Color(0xFF123521)
            : const Color(0xFFD7E7DD),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : foregroundVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
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
