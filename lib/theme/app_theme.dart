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
    // 所有输入框一套外观：圆角描边 + 淡底 + 统一内边距。
    // 只在这里定义一次，字段那边只写 label / hint / suffix。
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColor.canvas,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      hintStyle: AppType.body.copyWith(color: AppColor.inkFaint),
      labelStyle: AppType.bodySmall.copyWith(color: AppColor.inkMuted),
      suffixStyle: AppType.body.copyWith(color: AppColor.inkMuted),
      border: appFieldBorder(AppColor.line, 1),
      enabledBorder: appFieldBorder(AppColor.line, 1),
      disabledBorder: appFieldBorder(AppColor.line, 1),
      focusedBorder: appFieldBorder(AppColor.brand, 2),
      errorBorder: appFieldBorder(AppColor.heart, 1),
      focusedErrorBorder: appFieldBorder(AppColor.heart, 2),
    ),
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
    // 对话框：形状、留白、字号都在这里定，两个业务对话框不再各写一套。
    dialogTheme: DialogThemeData(
      backgroundColor: AppColor.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      titleTextStyle: AppType.headline,
      contentTextStyle: AppType.body,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppLayout.dialogInset,
        vertical: AppSpace.lg,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        AppSpace.md,
      ),
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

/// 输入框描边：圆角沿用 AppRadius.smAll，粗细区分「常态 / 聚焦」。
///
/// 公开给输入框控件用：出错时控件自己把描边换成红色，而不是让 decoration
/// 画一行错误文字（那一行会把输入框撑高）。
OutlineInputBorder appFieldBorder(Color color, double width) =>
    OutlineInputBorder(
  borderRadius: AppRadius.smAll,
  borderSide: BorderSide(color: color, width: width),
);
