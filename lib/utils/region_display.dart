// lib/utils/region_display.dart
//
// Shared between BrowseRegionsScreen and the dashboard's quick-pick empty
// state so the two surfaces can't drift out of sync on icon/name mapping.
class RegionDisplay {
  static const Map<String, String> icons = {
    'Head_and_Neck': 'assets/body_regions/head_and_neck.png',
    'Spine': 'assets/body_regions/spine.png',
    'Chest': 'assets/body_regions/trunk.png',
    'Upper Limb': 'assets/body_regions/upper_limb.png',
    'Lower Limb': 'assets/body_regions/lower_limb.png',
  };

  // Backend names are a mix of casing/underscores ("Head_and_Neck", "brain",
  // "cranial nerves") -- normalize to Title Case for display. "Chest" shows
  // as "Trunk" to match the icon set, without renaming the backend Region.
  static String formatName(String raw) {
    if (raw == 'Chest') return 'Trunk';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
