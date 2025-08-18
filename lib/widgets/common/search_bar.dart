import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 通用搜索栏组件
class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onSearchMode;
  final VoidCallback? onExitSearchMode;
  final bool isSearchMode;
  final bool autofocus;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    this.hintText = '搜索...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onSearchMode,
    this.onExitSearchMode,
    this.isSearchMode = false,
    this.autofocus = false,
    this.leadingIcon,
    this.trailingIcon,
    this.padding,
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.5,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !widget.isSearchMode) {
        widget.onSearchMode?.call();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.cardBackground;
    final borderColor = widget.borderColor ?? 
        (widget.isSearchMode ? AppColors.accent : AppColors.divider);
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: borderColor,
            width: widget.isSearchMode ? 1.5 : widget.borderWidth,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: widget.leadingIcon ?? 
                Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
            suffixIcon: _buildSuffixIcon(),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onTap: () {
            if (!widget.isSearchMode) {
              widget.onSearchMode?.call();
            }
          },
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.trailingIcon != null) {
      return widget.trailingIcon;
    }

    if (widget.isSearchMode) {
      return IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () {
          widget.controller.clear();
          widget.onClear?.call();
          widget.onExitSearchMode?.call();
          _focusNode.unfocus();
        },
      );
    }

    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
        onPressed: () {
          widget.controller.clear();
          widget.onClear?.call();
        },
      );
    }

    return null;
  }
}

/// 搜索栏预设样式
class SearchBarPresets {
  /// 发现页面搜索栏
  static CustomSearchBar discoverySearchBar({
    Key? key,
    required TextEditingController controller,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onSearchMode,
    VoidCallback? onExitSearchMode,
    bool isSearchMode = false,
  }) {
    return CustomSearchBar(
      key: key,
      controller: controller,
      hintText: '搜索AI角色、电台、故事...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onSearchMode: onSearchMode,
      onExitSearchMode: onExitSearchMode,
      isSearchMode: isSearchMode,
      borderRadius: 20.0,
      padding: const EdgeInsets.all(16),
    );
  }

  /// 智能体市场搜索栏
  static CustomSearchBar marketplaceSearchBar({
    Key? key,
    required TextEditingController controller,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onSearchMode,
    VoidCallback? onExitSearchMode,
    bool isSearchMode = false,
  }) {
    return CustomSearchBar(
      key: key,
      controller: controller,
      hintText: '搜索智能体...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onSearchMode: onSearchMode,
      onExitSearchMode: onExitSearchMode,
      isSearchMode: isSearchMode,
      autofocus: isSearchMode,
      borderRadius: 8.0,
      padding: EdgeInsets.zero,
    );
  }

  /// 紧凑型搜索栏
  static CustomSearchBar compactSearchBar({
    Key? key,
    required TextEditingController controller,
    String hintText = '搜索...',
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return CustomSearchBar(
      key: key,
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      borderRadius: 16.0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}