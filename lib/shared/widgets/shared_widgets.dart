import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../app/theme.dart';
import '../../core/services/locale_service.dart';
import '../../core/constants/app_strings.dart';

// ============ VAKIL BUTTON ============
class VakilButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final IconData? icon;

  const VakilButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final btn = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(width ?? double.infinity, 52),
            ),
            child: _buildChild(),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.primary,
              foregroundColor: textColor ?? Colors.white,
              minimumSize: Size(width ?? double.infinity, 52),
            ),
            child: _buildChild(),
          );
    return btn;
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    return Text(text);
  }
}

// ============ VAKIL CARD ============
class VakilCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;

  const VakilCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}

// ============ LANGUAGE TOGGLE ============
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lang == 'hi' ? 'भाषा चुनें / Choose Language' : 'Choose Language / भाषा चुनें',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOption(context, ref, 'en', 'English', lang == 'en'),
            const SizedBox(width: 12),
            _buildOption(context, ref, 'hi', 'हिंदी', lang == 'hi'),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, String code, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLocale(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ============ SUBSCRIPTION BADGE ============
class SubscriptionBadge extends StatelessWidget {
  final String plan;
  const SubscriptionBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (plan.toLowerCase()) {
      case 'saathi':
        bgColor = AppColors.primary.withOpacity(0.15);
        textColor = AppColors.primary;
        label = 'Saathi ✦';
        break;
      case 'vakil':
        bgColor = const Color(0xFF8B4513).withOpacity(0.15);
        textColor = const Color(0xFF8B4513);
        label = 'Vakil ⚖️';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey[700]!;
        label = 'Free';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============ LOADING OVERLAY ============
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============ RISK LEVEL BADGE ============
class RiskLevelBadge extends StatelessWidget {
  final String level;
  const RiskLevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (level.toUpperCase()) {
      case 'LOW':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'HIGH':
        color = AppColors.error;
        icon = Icons.error;
        break;
      case 'CRITICAL':
        color = const Color(0xFF7B1FA2);
        icon = Icons.dangerous;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            level,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============ SECTION HEADER ============
class SectionHeader extends ConsumerWidget {
  final String titleHi;
  final String titleEn;
  final String? actionLabelHi;
  final String? actionLabelEn;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.titleHi,
    required this.titleEn,
    this.actionLabelHi,
    this.actionLabelEn,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lang == 'hi' ? titleHi : titleEn,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              lang == 'hi' ? (actionLabelHi ?? 'सभी देखें') : (actionLabelEn ?? 'See all'),
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

// ============ VAKIL TEXT FIELD ============
class VakilTextField extends StatelessWidget {
  final String labelHi;
  final String labelEn;
  final String? hintHi;
  final String? hintEn;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final bool obscureText;
  final bool autofocus;
  final String lang;
  final ValueChanged<String>? onChanged;

  const VakilTextField({
    super.key,
    required this.labelHi,
    required this.labelEn,
    this.hintHi,
    this.hintEn,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixWidget,
    this.suffixWidget,
    this.obscureText = false,
    this.autofocus = false,
    required this.lang,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: lang == 'hi' ? labelHi : labelEn,
        hintText: lang == 'hi' ? hintHi : hintEn,
        prefix: prefixWidget,
        suffix: suffixWidget,
      ),
    );
  }
}

// ============ UPGRADE PROMPT CARD ============
class UpgradePromptCard extends ConsumerWidget {
  final VoidCallback onUpgrade;
  const UpgradePromptCard({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'hi' ? '🔒 Saathi Plan की ज़रूरत है' : '🔒 Saathi Plan Required',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'hi'
                ? 'असीमित AI प्रश्न, नोटिस विश्लेषण और बहुत कुछ के लिए अपग्रेड करें'
                : 'Upgrade for unlimited AI questions, notice analysis and more',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              lang == 'hi' ? '₹999/महीना - अभी अपग्रेड करें' : '₹999/month - Upgrade Now',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ COMPLIANCE STATUS CHIP ============
class ComplianceStatusChip extends StatelessWidget {
  final String status;
  final int? daysLeft;
  final String lang;

  const ComplianceStatusChip({
    super.key,
    required this.status,
    this.daysLeft,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (status == 'completed') {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      label = lang == 'hi' ? 'पूरा हुआ ✓' : 'Done ✓';
    } else if (status == 'overdue' || (daysLeft != null && daysLeft! < 0)) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      label = lang == 'hi' ? 'देर हो गई' : 'Overdue';
    } else if (daysLeft != null && daysLeft! <= 7) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      label = lang == 'hi' ? '$daysLeft दिन बचे' : '$daysLeft days left';
    } else if (daysLeft != null && daysLeft! <= 14) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      label = lang == 'hi' ? '$daysLeft दिन बचे' : '$daysLeft days left';
    } else {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      label = daysLeft != null
          ? (lang == 'hi' ? '$daysLeft दिन बचे' : '$daysLeft days left')
          : (lang == 'hi' ? 'बाकी है' : 'Pending');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
