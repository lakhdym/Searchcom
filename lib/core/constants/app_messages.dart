import '../../services/l10n_helper.dart';

class AppMessages {
  AppMessages._();

  static String genericError() => t('generic_error');
  static String unexpectedErrorTitle() => t('unexpected_error_title');
  static String unexpectedErrorMessage() => t('unexpected_error_message');
  static String pageNotFoundTitle() => t('page_not_found_title');
  static String pageNotFoundMessage() => t('page_not_found_message');
  static String navigationErrorMessage() => t('navigation_error_message');
  static String resourceNotFound() => t('resource_not_found');
  static String listingNotFound() => t('listing_not_found');
  static String conversationNotFound() => t('conversation_not_found');
  static String deletedPageMessage() => t('page_deleted_message');
  static String accessDenied() => t('access_denied_message');
  static String networkError() => t('network_error_full');
  static String serverError() => t('server_error');
  static String sessionExpired() => t('token_expired');

  static String loginSuccess() => t('login_success');
  static String accountCreatedSuccess() => t('account_created_success_clean');
  static String logoutSuccess() => t('logout_success');
  static String passwordUpdatedSuccess() => t('password_updated_success');
  static String listingPublishedSuccess() => t('listing_published_success');
  static String listingUpdatedSuccess() => t('listing_updated_success');
  static String listingDeletedSuccess() => t('listing_deleted_success');
  static String paymentConfirmedListingPublished() =>
      t('payment_confirmed_listing_published');
  static String commentAddedSuccess() => t('comment_added_success');
  static String reportSentSuccess() => t('report_sent_success');
  static String profileUpdatedSuccess() => t('profile_updated_success');
  static String languageChangedSuccess() => t('language_changed_success');
  static String preferencesSaved() => t('preferences_saved_success');
  static String codeResentSuccess() => t('verification_code_resent_success');
  static String emailVerifiedSuccess() => t('email_verified_success');
  static String phoneVerifiedSuccess() => t('phone_verified_success');

  static String listingsLoadError() => t('listings_load_error');
  static String categoriesLoadError() => t('category_load_error');
  static String loginError() => t('login_error_user');
  static String accountCreationError() => t('account_creation_error');
  static String listingPublishError() => t('listing_publish_error');
  static String listingUpdateError() => t('listing_update_error');
  static String listingDeleteError() => t('listing_delete_error');
  static String commentsLoadError() => t('comments_load_error');
  static String commentSendError() => t('comment_send_error');
  static String likesLoadError() => t('likes_load_error');
  static String likeUpdateError() => t('like_update_error');
  static String reportSendError() => t('report_send_error');
  static String profileUpdateError() => t('profile_update_error');
  static String passwordUpdateError() => t('password_update_error');
  static String conversationsLoadError() => t('conversations_load_error');
  static String messagesLoadError() => t('messages_load_error');
  static String messageSendError() => t('message_send_error');
  static String verificationError() => t('verification_error');
  static String codeResendError() => t('code_resend_error');
  static String paymentFailed() => t('payment_failed');
  static String featureComingSoon() => t('feature_coming');
  static String contactUnavailable() => t('no_contact_method');

  static String requiredField() => t('field_required');
  static String emailOrPhoneRequired() =>
      t('validation_email_or_phone_required');
  static String fullNameRequired() => t('validation_full_name_required');
  static String emailRequired() => t('validation_email_required');
  static String passwordRequired() => t('validation_password_required');
  static String categoryRequired() => t('validation_category_required');
  static String contactMethodRequired() => t('validation_contact_method');
  static String descriptionRequired() => t('validation_description_required');
  static String cityRequired() => t('validation_city_required');
  static String commentRequired() => t('validation_comment_required');
  static String validCodeRequired() => t('validation_valid_code');
  static String validEmailRequired() => t('validation_valid_email');
  static String validPhoneRequired() => t('validation_valid_phone');
  static String validEmailOrPhoneRequired() =>
      t('validation_valid_email_or_phone');
  static String passwordMinLength() => t('validation_password_min_length');
  static String passwordMismatch() => t('password_mismatch');

  static String backToHome() => t('back_to_home');
  static String tryAgain() => t('retry');
}
