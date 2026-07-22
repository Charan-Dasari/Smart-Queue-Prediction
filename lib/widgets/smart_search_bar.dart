import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

/// A fully-featured smart search bar that provides:
/// - Real-time, debounced suggestions from the Places API (320 ms)
/// - Recent searches (persisted via SharedPreferences, up to 6)
/// - Trending/popular keywords shown when the field is empty & focused
/// - Highlighted matching text in suggestions
/// - Category quick-filter chips above the suggestion list
class SmartSearchBar extends StatefulWidget {
  /// Called when the user selects a place suggestion from the dropdown.
  final void Function(Map<String, dynamic> place) onPlaceSelected;

  /// Called when the user submits the query (keyboard search / trending tap).
  final void Function(String query)? onQuerySubmitted;

  const SmartSearchBar({
    super.key,
    required this.onPlaceSelected,
    this.onQuerySubmitted,
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar>
    with SingleTickerProviderStateMixin {
  // ── Controllers & Focus ─────────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  // ── State ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _isOverlayVisible = false;
  String _selectedCategory = 'All';

  // ── Debounce ─────────────────────────────────────────────────────────────
  Timer? _debounce;

  // ── Overlay ──────────────────────────────────────────────────────────────
  OverlayEntry? _overlayEntry;

  // ── Animation ────────────────────────────────────────────────────────────
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Trending / Popular keywords ──────────────────────────────────────────
  static const List<Map<String, dynamic>> _trendingItems = [
    {'label': 'Apollo Hospital', 'category': 'Hospital', 'icon': Icons.local_hospital},
    {'label': 'SBI Bank', 'category': 'Bank', 'icon': Icons.account_balance},
    {'label': 'AIIMS', 'category': 'Hospital', 'icon': Icons.local_hospital},
    {'label': 'HDFC Bank', 'category': 'Bank', 'icon': Icons.account_balance},
    {'label': 'IIT Delhi', 'category': 'College', 'icon': Icons.school},
    {'label': 'Government Office', 'category': 'GovtOffice', 'icon': Icons.account_balance_outlined},
  ];

  // ── Category Chips ────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.apps_rounded, 'color': AppTheme.primaryColor},
    {'label': 'Hospital', 'icon': Icons.local_hospital, 'color': AppTheme.hospitalColor},
    {'label': 'Bank', 'icon': Icons.account_balance, 'color': AppTheme.bankColor},
    {'label': 'College', 'icon': Icons.school, 'color': AppTheme.collegeColor},
    {'label': 'Restaurant', 'icon': Icons.restaurant, 'color': AppTheme.restaurantColor},
    {'label': 'GovtOffice', 'icon': Icons.account_balance_outlined, 'color': AppTheme.govtColor},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _animController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('smart_search_recent') ?? [];
      if (mounted) setState(() => _recentSearches = saved);
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated =
          [query, ..._recentSearches.where((r) => r != query)].take(6).toList();
      await prefs.setStringList('smart_search_recent', updated);
      if (mounted) setState(() => _recentSearches = updated);
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = _recentSearches.where((r) => r != query).toList();
      await prefs.setStringList('smart_search_recent', updated);
      if (mounted) {
        setState(() => _recentSearches = updated);
        _rebuildOverlay();
      }
    } catch (_) {}
  }

  Future<void> _clearAllRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('smart_search_recent');
      if (mounted) {
        setState(() => _recentSearches = []);
        _rebuildOverlay();
      }
    } catch (_) {}
  }

  // ── Focus & Text Changes ──────────────────────────────────────────────────

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {}); // Rebuild border color
      _showOverlay();
    } else {
      setState(() {}); // Rebuild border color
      _hideOverlay();
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    _debounce?.cancel();

    if (query.isEmpty) {
      if (mounted) setState(() { _suggestions = []; _isLoading = false; });
      _rebuildOverlay();
      return;
    }

    setState(() => _isLoading = true);
    _rebuildOverlay();
    _debounce = Timer(const Duration(milliseconds: 320), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted || query.isEmpty) return;
    try {
      final category = _selectedCategory != 'All' ? _selectedCategory : null;
      final data = await ApiService.getPlaces(query: query, category: category, pageSize: 7);
      final places = (data['places'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() { _suggestions = places; _isLoading = false; });
        _rebuildOverlay();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _rebuildOverlay();
      }
    }
  }

  // ── Category filter ────────────────────────────────────────────────────────

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    if (_controller.text.isNotEmpty) {
      setState(() => _isLoading = true);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 150), () => _fetchSuggestions(_controller.text));
    }
    _rebuildOverlay();
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void _onSuggestionTap(Map<String, dynamic> place) {
    final name = place['name']?.toString() ?? '';
    _controller.text = name;
    _saveRecentSearch(name);
    _focusNode.unfocus();
    widget.onPlaceSelected(place);
  }

  void _onTrendingTap(String label) {
    _controller.text = label;
    _saveRecentSearch(label);
    _focusNode.unfocus();
    widget.onQuerySubmitted?.call(label);
  }

  void _onSubmit(String value) {
    if (value.trim().isEmpty) return;
    _saveRecentSearch(value.trim());
    _focusNode.unfocus();
    widget.onQuerySubmitted?.call(value.trim());
  }

  // ── Overlay management ─────────────────────────────────────────────────────

  void _showOverlay() {
    _isOverlayVisible = true;
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  void _hideOverlay() {
    _isOverlayVisible = false;
    _animController.reverse().then((_) => _removeOverlay());
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _rebuildOverlay() {
    if (!_isOverlayVisible) return;
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 6),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Material(color: Colors.transparent, child: _buildDropdown(ctx)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dropdown Panel ─────────────────────────────────────────────────────────

  Widget _buildDropdown(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : AppTheme.borderColor;
    final hasQuery = _controller.text.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryChips(ctx, isDark),
              if (_isLoading && hasQuery)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    ),
                  ),
                )
              else if (hasQuery && _suggestions.isNotEmpty)
                _buildSuggestionsList(ctx, isDark, _controller.text)
              else if (hasQuery && !_isLoading)
                _buildNoResults(ctx)
              else ...[
                if (_recentSearches.isNotEmpty) _buildRecentSearches(ctx, isDark),
                _buildTrending(ctx, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext ctx, bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final color = cat['color'] as Color;
          final isSelected = _selectedCategory == label;

          return GestureDetector(
            onTap: () => _onCategoryChanged(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : (isDark ? const Color(0xFF334155) : AppTheme.borderColor),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: isSelected ? color : AppTheme.textMutedColor),
                  const SizedBox(width: 4),
                  Text(
                    label == 'GovtOffice' ? 'Govt' : label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext ctx, bool isDark, String query) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1),
        ...List.generate(
          _suggestions.length,
          (i) => _buildSuggestionTile(ctx, isDark, _suggestions[i], query),
        ),
      ],
    );
  }

  Widget _buildSuggestionTile(
    BuildContext ctx, bool isDark, Map<String, dynamic> place, String query) {
    final name = place['name']?.toString() ?? '';
    final category = place['category']?.toString() ?? '';
    final city = place['city']?.toString() ?? '';
    final state = place['state']?.toString() ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

    Color iconColor = AppTheme.primaryColor;
    IconData icon = Icons.place_outlined;
    switch (category) {
      case 'Hospital': icon = Icons.local_hospital; iconColor = AppTheme.hospitalColor; break;
      case 'Bank': icon = Icons.account_balance; iconColor = AppTheme.bankColor; break;
      case 'Restaurant': icon = Icons.restaurant; iconColor = AppTheme.restaurantColor; break;
      case 'College': icon = Icons.school; iconColor = AppTheme.collegeColor; break;
      case 'GovtOffice': icon = Icons.account_balance_outlined; iconColor = AppTheme.govtColor; break;
      case 'Hotel': icon = Icons.hotel; iconColor = Colors.indigo; break;
    }

    return InkWell(
      onTap: () => _onSuggestionTap(place),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(name, query, isDark),
                  if (location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: AppTheme.textLightColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(location,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textLightColor),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category == 'GovtOffice' ? 'Govt' : category,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders [text] with the matched [query] portion highlighted in bold + teal.
  Widget _buildHighlightedText(String text, String query, bool isDark) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final idx = lowerText.indexOf(lowerQuery);

    final baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : AppTheme.textDarkColor,
    );

    if (idx == -1) return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        if (idx > 0) TextSpan(text: text.substring(0, idx), style: baseStyle),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: baseStyle.copyWith(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.w700,
            backgroundColor: AppTheme.accentColor.withOpacity(0.08),
          ),
        ),
        if (idx + query.length < text.length)
          TextSpan(text: text.substring(idx + query.length), style: baseStyle),
      ]),
    );
  }

  Widget _buildNoResults(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textLightColor.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            'No results for "${_controller.text}"',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different keyword or category',
            style: TextStyle(fontSize: 12, color: AppTheme.textLightColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext ctx, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: 6),
              const Text('Recent Searches',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor)),
              const Spacer(),
              GestureDetector(
                onTap: _clearAllRecent,
                child: const Text('Clear all',
                    style: TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        ..._recentSearches.map((r) => _buildRecentTile(isDark, r)),
      ],
    );
  }

  Widget _buildRecentTile(bool isDark, String recent) {
    return InkWell(
      onTap: () {
        _controller.text = recent;
        // Rebuild overlay after text set (listener fires automatically)
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, size: 16, color: AppTheme.textMutedColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(recent,
                  style: TextStyle(fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.textDarkColor)),
            ),
            GestureDetector(
              onTap: () => _removeRecentSearch(recent),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close_rounded, size: 15, color: AppTheme.textLightColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrending(BuildContext ctx, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text('Trending Searches',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor)),
            ],
          ),
        ),
        ..._trendingItems.map((item) => _buildTrendingTile(isDark, item)),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildTrendingTile(bool isDark, Map<String, dynamic> item) {
    final label = item['label'] as String;
    final icon = item['icon'] as IconData;
    final category = item['category'] as String;

    Color iconColor = AppTheme.primaryColor;
    switch (category) {
      case 'Hospital': iconColor = AppTheme.hospitalColor; break;
      case 'Bank': iconColor = AppTheme.bankColor; break;
      case 'College': iconColor = AppTheme.collegeColor; break;
      case 'GovtOffice': iconColor = AppTheme.govtColor; break;
    }

    return InkWell(
      onTap: () => _onTrendingTap(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.textDarkColor)),
            ),
            const Icon(Icons.north_west_rounded, size: 14, color: AppTheme.textLightColor),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? AppTheme.primaryColor.withOpacity(0.5)
                : AppTheme.borderColor,
            width: isFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isFocused
                  ? AppTheme.primaryColor.withOpacity(0.07)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSubmit,
          decoration: InputDecoration(
            hintText: 'Search Hospital, Bank, College...',
            hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textLightColor),
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading
                  ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                      ),
                    )
                  : const Icon(key: ValueKey('search'), Icons.search_rounded,
                      color: AppTheme.textMutedColor, size: 22),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textLightColor),
                    onPressed: () {
                      _controller.clear();
                      setState(() { _suggestions = []; _isLoading = false; });
                      _rebuildOverlay();
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.tune_rounded, color: AppTheme.textLightColor, size: 18),
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
