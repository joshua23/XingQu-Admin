import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 智能体搜索栏组件
/// 提供搜索、筛选和排序功能
class AgentSearchBar extends StatefulWidget {
  final String? initialQuery;
  final String? selectedCategory;
  final String? sortBy;
  final List<String> categories;
  final List<String> sortOptions;
  final Function(String) onSearchChanged;
  final Function(String?) onCategoryChanged;
  final Function(String?) onSortChanged;
  final VoidCallback? onFilterTap;
  final bool showFilters;

  const AgentSearchBar({
    super.key,
    this.initialQuery,
    this.selectedCategory,
    this.sortBy,
    this.categories = const [],
    this.sortOptions = const [],
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    this.onFilterTap,
    this.showFilters = true,
  });

  @override
  State<AgentSearchBar> createState() => _AgentSearchBarState();
}

class _AgentSearchBarState extends State<AgentSearchBar>
    with SingleTickerProviderStateMixin {
  
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isSearchFocused = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 搜索框和按钮行
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 12),
              _buildFilterButton(),
            ],
          ),
          
          // 筛选器区域
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters ? _buildFiltersSection() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索输入框
  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(_isSearchFocused ? 12 : 24),
        border: Border.all(
          color: _isSearchFocused ? AppColors.accent : AppColors.border,
          width: _isSearchFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.onSearchChanged,
        onTap: () => setState(() => _isSearchFocused = true),
        onSubmitted: (_) => setState(() => _isSearchFocused = false),
        style: AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: '搜索智能体...',
          hintStyle: AppTextStyles.body1.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSearchFocused ? Icons.search : Icons.search_outlined,
              key: ValueKey(_isSearchFocused),
              color: _isSearchFocused ? AppColors.accent : AppColors.textSecondary,
              size: 20,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                  },
                  child: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _toggleFilters,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _showFilters ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showFilters ? AppColors.accent : AppColors.border,
            width: 1,
          ),
          boxShadow: _showFilters
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedRotation(
            turns: _showFilters ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.filter_list,
              color: _showFilters ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建筛选器区域
  Widget _buildFiltersSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类筛选
            if (widget.categories.isNotEmpty) ...[
              const Text(
                '分类',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryChips(),
              const SizedBox(height: 16),
            ],
            
            // 排序选项
            if (widget.sortOptions.isNotEmpty) ...[
              const Text(
                '排序',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOptions(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建分类芯片
  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "全部" 选项
        _buildFilterChip(
          label: '全部',
          isSelected: widget.selectedCategory == null || widget.selectedCategory == '全部',
          onTap: () => widget.onCategoryChanged(null),
        ),
        
        // 其他分类选项
        ...widget.categories.where((cat) => cat != '全部').map(
          (category) => _buildFilterChip(
            label: category,
            isSelected: widget.selectedCategory == category,
            onTap: () => widget.onCategoryChanged(category),
          ),
        ),
      ],
    );
  }

  /// 构建排序选项
  Widget _buildSortOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.sortOptions.map(
        (sortOption) => _buildFilterChip(
          label: _getSortDisplayName(sortOption),
          isSelected: widget.sortBy == sortOption,
          onTap: () => widget.onSortChanged(sortOption),
          icon: _getSortIcon(sortOption),
        ),
      ).toList(),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换筛选器显示
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    
    widget.onFilterTap?.call();
  }

  /// 获取排序选项显示名称
  String _getSortDisplayName(String sortOption) {
    switch (sortOption) {
      case 'popular':
        return '热门度';
      case 'rating':
        return '评分';
      case 'recent':
        return '最新';
      case 'name':
        return '名称';
      default:
        return sortOption;
    }
  }

  /// 获取排序选项图标
  IconData _getSortIcon(String sortOption) {
    switch (sortOption) {
      case 'popular':
        return Icons.trending_up;
      case 'rating':
        return Icons.star;
      case 'recent':
        return Icons.schedule;
      case 'name':
        return Icons.sort_by_alpha;
      default:
        return Icons.sort;
    }
  }
}