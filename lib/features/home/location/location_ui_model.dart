class LocationHeaderUiModel {
  const LocationHeaderUiModel({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
}

class LocationSheetUiModel {
  const LocationSheetUiModel({
    required this.title,
    required this.subtitle,
    required this.currentLocationTitle,
    required this.currentLocationSubtitle,
    required this.writeAddressTitle,
    required this.writeAddressSubtitle,
  });

  final String title;
  final String subtitle;
  final String currentLocationTitle;
  final String currentLocationSubtitle;
  final String writeAddressTitle;
  final String writeAddressSubtitle;
}
