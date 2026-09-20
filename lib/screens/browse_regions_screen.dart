// lib/screens/browse_regions_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/region_display.dart';
import 'browse_exercise_list_screen.dart';

/// Entry point for a patient exploring the exercise library themselves,
/// independent of what a physio has actually prescribed. Read-only --
/// no mark-done/feedback here, see patient_api_browse_exercises's
/// docstring on the backend for why.
class BrowseRegionsScreen extends StatefulWidget {
  // Opens with this region already expanded, e.g. when a patient taps a
  // specific body-region icon on the dashboard rather than the generic
  // "Browse Library" link.
  final int? initialExpandedRegionId;

  const BrowseRegionsScreen({super.key, this.initialExpandedRegionId});

  @override
  State<BrowseRegionsScreen> createState() => _BrowseRegionsScreenState();
}

class _BrowseRegionsScreenState extends State<BrowseRegionsScreen> {
  List<Map<String, dynamic>> _regions = [];
  bool _loading = true;
  int? _expandedRegionId;

  @override
  void initState() {
    super.initState();
    _expandedRegionId = widget.initialExpandedRegionId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final regions = await ApiService().getBrowseRegions();
      setState(() {
        _regions = regions;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Exercise Library', style: TextStyle(color: Colors.black87, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _regions.isEmpty
              ? Center(child: Text('No exercises available right now', style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _regions.length,
                  itemBuilder: (_, i) => _regionCard(_regions[i]),
                ),
    );
  }

  Widget _regionCard(Map<String, dynamic> region) {
    // Only sub-regions with content -- roughly half are still empty
    // placeholders on the backend, no point listing a dead end.
    final subregions = List<Map<String, dynamic>>.from(region['subregions'] ?? [])
        .where((sr) => (sr['exercise_count'] as int? ?? 0) > 0)
        .toList();
    if (subregions.isEmpty) return const SizedBox.shrink();

    final expanded = _expandedRegionId == region['id'];
    final totalCount = subregions.fold<int>(0, (sum, sr) => sum + (sr['exercise_count'] as int));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expandedRegionId = expanded ? null : region['id'] as int),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _regionIcon(region['region_name'] as String? ?? ''),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatRegionName(region['region_name'] ?? ''),
                          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text('$totalCount exercises', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
              child: Column(
                children: [
                  for (final sr in subregions) _subregionRow(sr),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _subregionRow(Map<String, dynamic> subregion) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BrowseExerciseListScreen(
            subregionId: subregion['id'] as int,
            subregionName: _formatRegionName(subregion['sub_region_name'] ?? ''),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.chevron_right, size: 18, color: const Color(0xFF0A6EBD)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _formatRegionName(subregion['sub_region_name'] ?? ''),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ),
            Text('${subregion['exercise_count']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _regionIcon(String regionName) {
    final asset = RegionDisplay.icons[regionName];
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: asset != null
          ? Image.asset(asset, width: 48, height: 48, fit: BoxFit.cover)
          : Container(width: 48, height: 48, color: Colors.grey[100]),
    );
  }

  String _formatRegionName(String raw) => RegionDisplay.formatName(raw);
}
