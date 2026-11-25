import 'package:flutter/material.dart';

import 'tokens.dart';

/// 把令牌装配成 Material 主题：组件只读 Theme，不读字面量。
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColor.brand,
    onPrimary: AppColor.onBrand,
    primaryContainer: AppColor.brandSoft,
    onPrimaryContainer: AppColor.brandStrong,
    secondary: AppColor.water,
    onSecondary: AppColor.onBrand,
    secondaryContainer: AppColor.surfaceMuted,
    onSecondaryContainer: AppColor.ink,
    tertiary: AppColor.heart,
    onTertiary: AppColor.onBrand,
    error: AppColor.heart,
    onError: AppColor.onBrand,
    surface: AppColor.surface,
    onSurface: AppColor.ink,
    surfaceContainerHighest: AppColor.surfaceMuted,
    onSurfaceVariant: AppColor.inkMuted,
    outline: AppColor.line,
    outlineVariant: AppColor.line,
    shadow: AppColor.shadow,
    scrim: AppColor.ink,
    inverseSurface: AppColor.ink,
    onInverseSurface: AppColor.surface,
    inversePrimary: AppColor.brandSoft,
  );

  final textTheme = TextTheme(
    displayLarge: AppType.display,
    displayMedium: AppType.display,
    displaySmall: AppType.display,
    headlineLarge: AppType.headline,
    headlineMedium: AppType.headline,
    headlineSmall: AppType.section,
    titleLarge: AppType.section,
    titleMedium: AppType.title,
    titleSmall: AppType.title,
    bodyLarge: AppType.body,
    bodyMedium: AppType.body,
    bodySmall: AppType.bodySmall,
    labelLarge: AppType.button,
    labelMedium: AppType.bodySmall,
    labelSmall: AppType.label,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColor.canvas,
    canvasColor: AppColor.canvas,
    textTheme: textTheme,
    fontFamilyFallback: AppType.fallback,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(
      color: AppColor.line,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColor.inkMuted, size: 22),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColor.brandStrong,
        foregroundColor: AppColor.onBrand,
        disabledBackgroundColor: AppColor.surfaceMuted,
        disabledForegroundColor: AppColor.inkFaint,
        minimumSize: const Size(AppLayout.tapMin, AppLayout.tapMin),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        textStyle: AppType.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColor.brandStrong,
        minimumSize: const Size(AppLayout.tapMin, AppLayout.tapMin),
        textStyle: AppType.button.copyWith(color: AppColor.brandStrong),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColor.surface
            : AppColor.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColor.brand
            : AppColor.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColor.ink,
      contentTextStyle: AppType.body.copyWith(color: AppColor.surface),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      insetPadding: const EdgeInsets.all(AppSpace.md),
    ),
    focusColor: AppColor.focus,
    // 所有交互控件保留可见焦点环（由 Pressable / 按钮自带描边实现）
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
