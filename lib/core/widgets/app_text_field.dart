import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixSvgPath;
  final String? suffixSvgPath;
  final double? prefixSvgSize;
  final double? suffixSvgSize;
  final Color? prefixSvgColor;
  final Color? suffixSvgColor;
  final VoidCallback? onSuffixTap;
  final VoidCallback? onPrefixTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixSvgPath,
    this.suffixSvgPath,
    this.prefixSvgSize = 20,
    this.suffixSvgSize = 20,
    this.prefixSvgColor,
    this.suffixSvgColor,
    this.onSuffixTap,
    this.onPrefixTap,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textInputAction,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget? buildPrefixIcon() {
      if (prefixIcon != null) return prefixIcon;
      if (prefixSvgPath != null) {
        return GestureDetector(
          onTap: onPrefixTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              prefixSvgPath!,
              width: prefixSvgSize,
              height: prefixSvgSize,
              colorFilter: prefixSvgColor != null
                  ? ColorFilter.mode(prefixSvgColor!, BlendMode.srcIn)
                  : ColorFilter.mode(
                      colorScheme.onSurface.withValues(alpha: 0.6),
                      BlendMode.srcIn,
                    ),
            ),
          ),
        );
      }
      return null;
    }

    Widget? buildSuffixIcon() {
      if (suffixIcon != null) return suffixIcon;
      if (suffixSvgPath != null) {
        return GestureDetector(
          onTap: onSuffixTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              suffixSvgPath!,
              width: suffixSvgSize,
              height: suffixSvgSize,
              colorFilter: suffixSvgColor != null
                  ? ColorFilter.mode(suffixSvgColor!, BlendMode.srcIn)
                  : ColorFilter.mode(
                      colorScheme.onSurface.withValues(alpha: 0.6),
                      BlendMode.srcIn,
                    ),
            ),
          ),
        );
      }
      return null;
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      focusNode: focusNode,
      textInputAction: textInputAction,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        // Allow theme to handle styling
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: buildPrefixIcon(),
        suffixIcon: buildSuffixIcon(),
      ),
    );
  }
}
