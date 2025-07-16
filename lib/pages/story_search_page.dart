import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';
import '../widgets/story_card.dart';

/// 故事搜索页面
/// 提供搜索建议、搜索历史、结果分类、实时搜索等功能
class StorySearchPage extends StatefulWidget {
  const StorySearchPage({super.key});

  @override
  State<StorySearchPage> createState() => _StorySearchPageState();
}

class _StorySearchPageState extends State<StorySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 搜索状态
  bool _isSearching = false;
  String _searchQuery = '';

  // 搜索历史
  List<String> _searchHistory = [
    '科幻小说',
    '爱情故事',
    '悬疑推理',
    '奇幻冒险',
    '都市言情',
  ];

  // 搜索建议
  List<String> _suggestions = [
    '科幻小说',
    '爱情故事',
    '悬疑推理',
    '奇幻冒险',
    '都市言情',
    '历史传记',
    '惊悚恐怖',
    '武侠小说',
  ];

  // 搜索结果
  List<Story> _searchResults = [];

  // 热门搜索
  List<String> _hotSearches = [
    '星际战争',
    '时空穿越',
    '末日生存',
    '机器人觉醒',
    '虚拟现实',
    '基因改造',
    '人工智能',
    '太空探索',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 搜索内容变化监听
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });

    // 实时搜索
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  /// 焦点变化监听
  void _onFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _buildSearchBar(),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textSecondary),
            onPressed: _clearSearch,
          ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: '搜索故事、作者或标签',
          hintStyle: AppTextStyles.body2,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
        ),
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isSearching && _searchResults.isNotEmpty) {
      return _buildSearchResults();
    } else if (_isSearching && _searchResults.isEmpty) {
      return _buildEmptyResults();
    } else if (_focusNode.hasFocus || _searchController.text.isNotEmpty) {
      return _buildSearchSuggestions();
    } else {
      return _buildSearchHome();
    }
  }

  /// 构建搜索主页
  Widget _buildSearchHome() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        _buildSectionTitle('搜索历史'),
        _buildSearchHistory(),
        const SizedBox(height: AppDimensions.paddingL),
        _buildSectionTitle('热门搜索'),
        _buildHotSearches(),
      ],
    );
  }

  /// 构建搜索建议
  Widget _buildSearchSuggestions() {
    List<String> filteredSuggestions = _suggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return _buildSuggestionItem(suggestion);
      },
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final story = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: StoryCard(story: story),
        );
      },
    );
  }

  /// 构建空结果页面
  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '未找到相关内容',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            '尝试使用其他关键词搜索',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
          if (title == '搜索历史' && _searchHistory.isNotEmpty)
            TextButton(
              onPressed: _clearSearchHistory,
              child: Text(
                '清除',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建搜索历史
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Text(
        '暂无搜索历史',
        style: AppTextStyles.body2,
      );
    }

    return Wrap(
      spacing: AppDimensions.paddingS,
      runSpacing: AppDimensions.paddingS,
      children: _searchHistory.map((history) {
        return _buildHistoryChip(history);
      }).toList(),
    );
  }

  /// 构建热门搜索
  Widget _buildHotSearches() {
    return Wrap(
      spacing: AppDimensions.paddingS,
      runSpacing: AppDimensions.paddingS,
      children: _hotSearches.asMap().entries.map((entry) {
        final index = entry.key;
        final search = entry.value;
        return _buildHotSearchChip(search, index);
      }).toList(),
    );
  }

  /// 构建历史搜索标签
  Widget _buildHistoryChip(String history) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _searchFromHistory(history),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                history,
                style: AppTextStyles.body2,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              GestureDetector(
                onTap: () => _removeFromHistory(history),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建热门搜索标签
  Widget _buildHotSearchChip(String search, int index) {
    Color chipColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;

    // 前三个热门搜索使用特殊颜色
    if (index < 3) {
      chipColor = AppColors.accent.withOpacity(0.1);
      textColor = AppColors.accent;
    }

    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _searchFromHistory(search),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index < 3) ...[
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: AppDimensions.paddingS),
              ],
              Text(
                search,
                style: AppTextStyles.body2.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建搜索建议项
  Widget _buildSuggestionItem(String suggestion) {
    return ListTile(
      leading: const Icon(Icons.search, color: AppColors.textSecondary),
      title: Text(
        suggestion,
        style: AppTextStyles.body1,
      ),
      trailing: const Icon(Icons.arrow_outward, color: AppColors.textSecondary),
      onTap: () => _searchFromHistory(suggestion),
    );
  }

  /// 清除搜索
  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchResults.clear();
    });
  }

  /// 清除搜索历史
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  /// 从历史记录中移除
  void _removeFromHistory(String history) {
    setState(() {
      _searchHistory.remove(history);
    });
  }

  /// 从历史记录搜索
  void _searchFromHistory(String query) {
    _searchController.text = query;
    _focusNode.unfocus();
    _onSearchSubmitted(query);
  }

  /// 搜索提交
  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      // 添加到搜索历史
      if (!_searchHistory.contains(query)) {
        setState(() {
          _searchHistory.insert(0, query);
          // 限制历史记录数量
          if (_searchHistory.length > 10) {
            _searchHistory = _searchHistory.take(10).toList();
          }
        });
      }

      // 执行搜索
      _performSearch(query);
    }
  }

  /// 执行搜索
  void _performSearch(String query) {
    // TODO: 实现真实的搜索逻辑
    setState(() {
      _isSearching = true;
      _searchResults = _getMockSearchResults(query);
    });
  }

  /// 获取模拟搜索结果
  List<Story> _getMockSearchResults(String query) {
    // 模拟搜索结果
    List<Story> mockResults = [
      Story(
        id: '1',
        title: '星际探索：${query}的奇幻冒险',
        content: '在遥远的未来，人类已经踏出了地球，开始了伟大的星际探索之旅...',
        user: const User(id: '1', nickname: '科幻作家', isFollowed: false),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likeCount: 128,
        commentCount: 23,
        isLiked: false,
        views: 1520,
        tags: ['科幻', '冒险', query],
        imageUrl: null,
      ),
      Story(
        id: '2',
        title: '${query}传说：古老的秘密',
        content: '在一个充满魔法和神秘的世界里，年轻的冒险者发现了一个古老的秘密...',
        user: const User(id: '2', nickname: '奇幻作家', isFollowed: false),
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likeCount: 89,
        commentCount: 15,
        isLiked: false,
        views: 892,
        tags: ['奇幻', '传说', query],
        imageUrl: null,
      ),
      Story(
        id: '3',
        title: '都市${query}：现代爱情故事',
        content: '在繁华的都市中，两个年轻人因为一次偶然的相遇，开始了一段美好的爱情...',
        user: const User(id: '3', nickname: '都市作家', isFollowed: false),
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        likeCount: 256,
        commentCount: 42,
        isLiked: false,
        views: 2341,
        tags: ['都市', '爱情', query],
        imageUrl: null,
      ),
    ];

    return mockResults;
  }
}
