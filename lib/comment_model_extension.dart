import 'services/api_service.dart';

extension CommentModelExtension on ApiListingComment {
  bool get isDeleted => (status ?? '').toLowerCase() == 'deleted';
  bool get isEdited => (status ?? '').toLowerCase() == 'edited';
}
