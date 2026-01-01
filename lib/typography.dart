import 'package:shadcn_flutter/shadcn_flutter.dart';

class _BaseWeights {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight normal = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

class _BaseSizes {
  static const double xSmall = 10.0;
  static const double small = 12.0;
  static const double base = 14.0;
  static const double large = 16.0;
  static const double xLarge = 18.0;
  static const double x2Large = 20.0;
  static const double x3Large = 24.0;
  static const double x4Large = 28.0;
  static const double x5Large = 32.0;
  static const double x6Large = 36.0;
  static const double x7Large = 42.0;
  static const double x8Large = 48.0;
  static const double x9Large = 56.0;
}

const Typography appTypography = Typography(
  // Base & font families
  sans: TextStyle(fontFamily: 'Inter'),
  mono: TextStyle(
    fontFamily: 'JetBrainsMono',
    fontWeight: _BaseWeights.normal,
    fontFeatures: [FontFeature.tabularFigures()],
  ),

  // Sizes - smaller for dense UI but still readable on desktop
  xSmall: TextStyle(fontSize: _BaseSizes.xSmall),
  small: TextStyle(fontSize: _BaseSizes.small),
  base: TextStyle(fontSize: _BaseSizes.base),
  large: TextStyle(fontSize: _BaseSizes.large),
  xLarge: TextStyle(fontSize: _BaseSizes.xLarge),
  x2Large: TextStyle(fontSize: _BaseSizes.x2Large),
  x3Large: TextStyle(fontSize: _BaseSizes.x3Large),
  x4Large: TextStyle(fontSize: _BaseSizes.x4Large),
  x5Large: TextStyle(fontSize: _BaseSizes.x5Large),
  x6Large: TextStyle(fontSize: _BaseSizes.x6Large),
  x7Large: TextStyle(fontSize: _BaseSizes.x7Large),
  x8Large: TextStyle(fontSize: _BaseSizes.x8Large),
  x9Large: TextStyle(fontSize: _BaseSizes.x9Large),

  // Weights
  thin: TextStyle(fontWeight: _BaseWeights.thin),
  extraLight: TextStyle(fontWeight: _BaseWeights.extraLight),
  light: TextStyle(fontWeight: _BaseWeights.light),
  normal: TextStyle(fontWeight: _BaseWeights.normal),
  medium: TextStyle(fontWeight: _BaseWeights.medium),
  semiBold: TextStyle(fontWeight: _BaseWeights.semiBold),
  bold: TextStyle(fontWeight: _BaseWeights.bold),
  extraBold: TextStyle(fontWeight: _BaseWeights.extraBold),
  black: TextStyle(fontWeight: _BaseWeights.black),

  // Semantic styles
  italic: TextStyle(fontStyle: FontStyle.italic),

  // Headings
  h1: TextStyle(fontSize: _BaseSizes.x4Large, fontWeight: FontWeight.w700),
  h2: TextStyle(fontSize: _BaseSizes.x3Large, fontWeight: FontWeight.w600),
  h3: TextStyle(fontSize: _BaseSizes.x2Large, fontWeight: FontWeight.w600),
  h4: TextStyle(fontSize: _BaseSizes.xLarge, fontWeight: FontWeight.w600),

  // Paragraph & content labels
  p: TextStyle(fontSize: _BaseSizes.base, fontWeight: _BaseWeights.normal),
  lead: TextStyle(fontSize: _BaseSizes.xLarge, fontWeight: _BaseWeights.medium),
  textLarge:
      TextStyle(fontSize: _BaseSizes.large, fontWeight: _BaseWeights.medium),
  textSmall:
      TextStyle(fontSize: _BaseSizes.small, fontWeight: _BaseWeights.medium),
  textMuted:
      TextStyle(fontSize: _BaseSizes.small, fontWeight: _BaseWeights.normal),

  // Code / quote styles
  blockQuote: TextStyle(fontSize: _BaseSizes.base, fontStyle: FontStyle.italic),
  inlineCode: TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: _BaseSizes.small,
      fontWeight: _BaseWeights.medium),
);
