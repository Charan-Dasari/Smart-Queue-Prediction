import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(_getScreenTitle()),
      ),
      body: showCategoryPicker
          ? _buildCategoryPickerView(context)
          : _buildPlacesListView(context),
    );
  }

  /// View shown when user taps "Other" — displays all service categories to choose from.
  Widget _buildCategoryPickerView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Service Type',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose from the available services below',
            style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
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
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLightColor),
          ],
        ),
      ),
    );
  }

  /// View shown when a specific category is selected — displays places from the dataset.
  Widget _buildPlacesListView(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchPlaces(),
                  decoration: InputDecoration(
                    hintText: 'Search by name, city, or state...',
                    hintStyle: TextStyle(color: AppTheme.textMutedColor.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMutedColor, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchPlaces();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // State & City Filters
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
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
        categoryColor = Colors.orange;
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (rating > 0) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.location_on_outlined, color: AppTheme.textMutedColor, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                address,
                style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
