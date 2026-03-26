import '../../services/l10n_helper.dart';

const List<String> _englishShortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatPublicationEventDate(String? rawDate, {String? languageCode}) {
  final normalized = rawDate?.trim() ?? '';
  if (normalized.isEmpty) return '';

  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return normalized;

  final lang = _normalizeLanguageCode(languageCode ?? getCurrentLanguageCode());
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');

  if (lang == 'en') {
    return '$day ${_englishShortMonths[parsed.month - 1]} ${parsed.year}';
  }

  return '$day/$month/${parsed.year}';
}

String _normalizeLanguageCode(String languageCode) {
  final normalized = languageCode.trim().toLowerCase();
  if (normalized.startsWith('en')) return 'en';
  if (normalized.startsWith('ar')) return 'ar';
  return 'fr';
}
