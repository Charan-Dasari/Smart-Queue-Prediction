import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/smart_search_bar.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final String? initialCategory;
  const ServiceSelectionScreen({super.key, this.initialCategory});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedCategory = 'All';
  String? _selectedState;
  String? _selectedCity;

  List<dynamic> _places = [];
  List<String> _states = [];
  List<String> _cities = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';

  final ScrollController _scrollController = ScrollController();

  // Category definitions for the "Other" (All) view
  static final List<Map<String, dynamic>> _categoryOptions = [
    {'label': 'Hospitals', 'route': '/hospital', 'icon': Icons.local_hospital, 'color': AppTheme.hospitalColor},
    {'label': 'Banks', 'route': '/bank', 'icon': Icons.account_balance, 'color': AppTheme.bankColor},
    {'label': 'Restaurants', 'route': '/restaurant', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'label': 'Colleges', 'route': '/college', 'icon': Icons.school, 'color': AppTheme.collegeColor},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    _scrollController.addListener(_onScroll);
    _fetchStates();
    _fetchPlaces();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePlaces();
    }
  }

  Future<void> _fetchStates() async {
    try {
      final states = await ApiService.getPlaceStates();
      if (mounted) {
        setState(() {
          _states = ['All', ...states];
        });
      }
    } catch (e) {
      debugPrint('Error fetching states: $e');
    }
  }

  Future<void> _fetchCities() async {
    if (_selectedState == null || _selectedState == 'All') return;
    try {
      final cities = await ApiService.getPlaceCities(state: _selectedState!);
      if (mounted) {
        setState(() {
          _cities = ['All', ...cities];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPlaces({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _places = [];
        _error = '';
      });
    }

    try {
      final category = _selectedCategory != 'All' ? _selectedCategory : null;
      final query = _searchController.text.isNotEmpty ? _searchController.text : null;
      final stateParam = (_selectedState != null && _selectedState != 'All') ? _selectedState : null;
      final cityParam = (_selectedCity != null && _selectedCity != 'All') ? _selectedCity : null;

      final data = await ApiService.getPlaces(
        category: category,
        state: stateParam,
        city: cityParam,
        query: query,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _places = data['places'] ?? [];
          } else {
            _places.addAll(data['places'] ?? []);
          }
          _totalCount = data['totalCount'] ?? 0;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load places: $e';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMorePlaces() async {
    if (_isLoadingMore) return;
    if (_places.length >= _totalCount) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchPlaces(reset: false);
  }

  String _getScreenTitle() {
    if (_selectedCategory == 'All') return 'All Services';
    if (_selectedCategory == 'GovtOffice') return 'Government Offices';
    return '${_selectedCategory}s';
  }

  @override
  Widget build(BuildContext context) {
    // If category is "All", show category selection tiles first
    final bool showCategoryPicker = _selectedCategory == 'All';

    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: Text(_getScreenTitle()),
        ),
        body: showCategoryPicker
            ? _buildCategoryPickerView(context)
            : _buildPlacesListView(context),
      ),
    );
  }

  /// View shown when user taps "Other" — displays all service categories to choose from.
  Widget _buildCategoryPickerView(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Service Category',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore queues & book smart slots across sectors',
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 24),
          ..._categoryOptions.map((cat) => _buildCategoryTile(
            context,
            icon: cat['icon'] as IconData,
            title: cat['label'] as String,
            color: cat['color'] as Color,
            route: cat['route'] as String,
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, {required IconData icon, required String title, required Color color, required String route}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(route),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
                ),
                Icon(Icons.chevron_right_rounded, size: 22, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// View shown when a specific category is selected — displays places from the dataset.
  Widget _buildPlacesListView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 480;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMutedColor)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _fetchPlaces(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Search & Filters ──
        Padding(
          padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 20, isNarrow ? 12 : 16, isNarrow ? 16 : 20, 0),
          child: Column(
            children: [
              // Smart Search Bar
              SmartSearchBar(
                onPlaceSelected: (place) {
                  final placeId = place['id'];
                  if (placeId != null) context.push('/booking/$placeId');
                },
                onQuerySubmitted: (query) {
                  _searchController.text = query;
                  _fetchPlaces();
                },
              ),
              SizedBox(height: isNarrow ? 8 : 12),
              // State & City Filters — stack on narrow screens
              if (isNarrow)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSearchableDropdown(
                            hint: 'State',
                            controller: _stateController,
                            value: _selectedState,
                            items: _states,
                            onChanged: (val) {
                              setState(() {
                                _selectedState = val;
                                _selectedCity = null;
                                _cityController.clear();
                                _cities = [];
                              });
                              if (val != null && val != 'All') _fetchCities();
                              _fetchPlaces();
                            },
                          ),
                        ),
                        if (_selectedState != null || _selectedCity != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppTheme.textMutedColor),
                            padding: const EdgeInsets.only(left: 4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedState = null;
                                _stateController.clear();
                                _selectedCity = null;
                                _cityController.clear();
                                _cities = [];
                              });
                              _fetchPlaces();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSearchableDropdown(
                      hint: 'City',
                      controller: _cityController,
                      value: _selectedCity,
                      items: _cities,
                      onChanged: (val) {
                        setState(() => _selectedCity = val);
                        _fetchPlaces();
                      },
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchableDropdown(
                        hint: 'State',
                        controller: _stateController,
                        value: _selectedState,
                        items: _states,
                        onChanged: (val) {
                          setState(() {
                            _selectedState = val;
                            _selectedCity = null;
                            _cityController.clear();
                            _cities = [];
                          });
                          if (val != null && val != 'All') _fetchCities();
                          _fetchPlaces();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSearchableDropdown(
                        hint: 'City',
                        controller: _cityController,
                        value: _selectedCity,
                        items: _cities,
                        onChanged: (val) {
                          setState(() => _selectedCity = val);
                          _fetchPlaces();
                        },
                      ),
                    ),
                    if (_selectedState != null || _selectedCity != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20, color: AppTheme.textMutedColor),
                        onPressed: () {
                          setState(() {
                            _selectedState = null;
                            _stateController.clear();
                            _selectedCity = null;
                            _cityController.clear();
                            _cities = [];
                          });
                          _fetchPlaces();
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              // Results count
              if (_searchController.text.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$_totalCount results found',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Places List ──
        Expanded(
          child: _places.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: AppTheme.textLightColor),
                      SizedBox(height: 12),
                      Text('No places found', style: TextStyle(color: AppTheme.textMutedColor, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Try adjusting your filters', style: TextStyle(color: AppTheme.textLightColor, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 20),
                  itemCount: _places.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _places.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final place = _places[index];
                    return _buildPlaceCard(context, place);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String hint, 
    required TextEditingController controller,
    required String? value, 
    required List<String> items, 
    required ValueChanged<String?> onChanged
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          controller: controller,
          initialSelection: value,
          hintText: hint,
          enableSearch: true,
          enableFilter: true,
          textStyle: const TextStyle(fontSize: 13),
          menuStyle: MenuStyle(
            backgroundColor: MaterialStateProperty.all(Theme.of(context).cardColor),
            maximumSize: MaterialStateProperty.all(const Size.fromHeight(300)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
            ),
          ),
          dropdownMenuEntries: items.map((item) {
            return DropdownMenuEntry<String>(
              value: item,
              label: item,
              style: MenuItemButton.styleFrom(
                textStyle: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onSelected: onChanged,
        );
      }
    );
  }

  Widget _buildPlaceCard(BuildContext context, dynamic place) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 480;
    final name = place['name'] ?? '';
    final category = place['category'] ?? '';
    final state = place['state'] ?? '';
    final city = place['city'] ?? '';
    final address = place['address'] ?? '';
    final rating = (place['rating'] ?? 0.0).toDouble();
    final placeId = place['id'] ?? '';

    Color categoryColor = AppTheme.primaryColor;
    IconData categoryIcon = Icons.place;

    switch (category) {
      case 'Hospital':
        categoryColor = AppTheme.hospitalColor;
        categoryIcon = Icons.local_hospital;
        break;
      case 'Bank':
        categoryColor = AppTheme.bankColor;
        categoryIcon = Icons.account_balance;
        break;
      case 'Restaurant':
        categoryColor = AppTheme.restaurantColor;
        categoryIcon = Icons.restaurant;
        break;
      case 'College':
        categoryColor = AppTheme.collegeColor;
        categoryIcon = Icons.school;
        break;
      case 'GovtOffice':
        categoryColor = AppTheme.govtColor;
        categoryIcon = Icons.account_balance_outlined;
        break;
      case 'Hotel':
        categoryColor = Colors.indigo;
        categoryIcon = Icons.hotel;
        break;
    }

    final locationParts = [city, state].where((s) => s.isNotEmpty).toList();
    final location = locationParts.join(', ');

    return GestureDetector(
      onTap: () => context.push('/booking/$placeId'),
      child: Container(
        margin: EdgeInsets.only(bottom: isNarrow ? 10 : 12),
        padding: EdgeInsets.all(isNarrow ? 12 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(isNarrow ? 14 : 16),
          border: Border.all(color: AppTheme.getBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isNarrow ? 8 : 10),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isNarrow ? 10 : 12),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: isNarrow ? 18 : 22),
                ),
                SizedBox(width: isNarrow ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: isNarrow ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: AppTheme.textMutedColor, size: isNarrow ? 12 : 14),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(fontSize: isNarrow ? 11 : 12, color: AppTheme.textMutedColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 10 : 14),
            Row(
              children: [
                if (rating > 0) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 8, vertical: isNarrow ? 3 : 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: isNarrow ? 12 : 14),
                        SizedBox(width: isNarrow ? 2 : 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: isNarrow ? 11 : 12, fontWeight: FontWeight.w700, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isNarrow ? 6 : 8),
                ],
                Container(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 8, vertical: isNarrow ? 3 : 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category == 'GovtOffice' ? 'Govt' : category,
                      style: TextStyle(fontSize: isNarrow ? 10 : 11, fontWeight: FontWeight.w700, color: categoryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 12, vertical: isNarrow ? 5 : 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNarrow ? 'Book' : 'Book Queue',
                        style: TextStyle(fontSize: isNarrow ? 10 : 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      SizedBox(width: isNarrow ? 2 : 4),
                      Icon(Icons.arrow_forward_ios, size: isNarrow ? 8 : 10, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
