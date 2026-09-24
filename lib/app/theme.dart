import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Legacy export layer to maintain backwards compatibility.
class OpenAskTheme {
  OpenAskTheme._();

  static ThemeData get lightTheme => AppTheme.lightTheme;
  static ThemeData get darkTheme => AppTheme.darkTheme;
}
