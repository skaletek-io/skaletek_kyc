import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skaletek_kyc/src/ui/shared/app_color.dart';

class StyledText extends StatelessWidget {
  const StyledText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        textStyle: Theme.of(context).textTheme.bodyMedium,
        fontSize: 12,
        color: AppColor.textLight,
      ).merge(style),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

class StyledTitle extends StatelessWidget {
  const StyledTitle(
    this.text, {
    super.key,
    this.style,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        textStyle: Theme.of(context).textTheme.titleMedium,
        fontSize: 14,
        color: AppColor.text,
      ).merge(style),
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        textStyle: Theme.of(context).textTheme.headlineMedium,
        fontSize: 18,
        color: AppColor.text,
        fontWeight: FontWeight.w600,
      ).merge(style),
    );
  }
}
