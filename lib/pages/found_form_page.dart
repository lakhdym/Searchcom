import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_messages.dart';
import '../core/errors/app_error_mapper.dart';
import '../core/feedback/app_feedback.dart';
import '../models/listing_model.dart';
import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_modal.dart';
import '../widgets/top_nav_bar.dart';
import 'login_page.dart';
import 'main_app_shell.dart';

class FoundFormPage extends StatefulWidget {
  const FoundFormPage({
    super.key,
    required this.type,
    this.listingId,
    this.initialListing,
    this.isEdit = false,
  });

  final String type;
  final int? listingId;
  final ListingModel? initialListing;
  final bool isEdit;

  @override
  State<FoundFormPage> createState() => _FoundFormPageState();
}

class _FoundFormPageState extends State<FoundFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  DateTime? _eventDate;
  bool _contactChat = true;
  bool _contactWhatsApp = true;
  bool _contactCall = true;

  final ImagePicker _picker = ImagePicker();
  List<ApiPickedImage> _images = [];
  final List<int> _removedPhotoIds = [];

  List<ApiCategory> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCats = true;
  String? _catsError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    AuthLocalStorage.instance.getToken().then((token) {
      if (token != null && token.isNotEmpty) {
        ApiService.instance.setToken(token);
      }
    });
    _loadCategories();
    if (widget.isEdit && widget.initialListing != null) {
      _prefill(widget.initialListing!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _prefill(ListingModel listing) {
    _titleCtrl.text = listing.title;
    _descCtrl.text = listing.description;
    _cityCtrl.text = listing.city ?? '';
    _locationCtrl.text = listing.locationText ?? '';
    _eventDate = listing.eventDate != null && listing.eventDate!.isNotEmpty
        ? DateTime.tryParse(listing.eventDate!)
        : null;
    _contactChat = listing.contactChat;
    _contactWhatsApp = listing.contactWhatsApp;
    _contactCall = listing.contactCall;
    _selectedCategoryId = listing.categoryId;
  }

  String _resolveImageUrl(String? raw) {
    const uploadsBase = 'https://italents.ma/app/';
    const placeholder = 'https://via.placeholder.com/600x400?text=Annonce';
    if (raw == null) return placeholder;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return placeholder;
    if (trimmed.startsWith('http')) return trimmed;
    var cleaned = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final idx = cleaned.indexOf('uploads/');
    if (idx >= 0) cleaned = cleaned.substring(idx);
    if (cleaned.startsWith('uploads/')) {
      return '$uploadsBase$cleaned';
    }
    return '${uploadsBase}uploads/annonces/$cleaned';
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final categories = await ApiService.instance.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId ??= categories.first.id;
          _catsError = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catsError = AppErrorMapper.message(
          e,
          fallbackMessage: AppMessages.categoriesLoadError(),
        );
      });
    } finally {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final additions = <ApiPickedImage>[];
    for (final image in picked) {
      final bytes = await image.readAsBytes();
      additions.add(ApiPickedImage(file: image, bytes: bytes));
    }
    setState(() => _images = [..._images, ...additions]);
  }

  void _onSubmit() {
    final isLoggedIn =
        currentUser.value != null || ApiService.instance.isAuthenticated;
    if (!isLoggedIn) {
      AppFeedback.showInfoSnackBar(context, t('sign_in_to_publish'));
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_contactChat && !_contactWhatsApp && !_contactCall) {
      AppFeedback.showErrorSnackBar(
        context,
        AppMessages.contactMethodRequired(),
      );
      return;
    }
    final phone = currentUser.value?.phone?.trim() ?? '';
    if ((_contactWhatsApp || _contactCall) && phone.isEmpty) {
      AppFeedback.showErrorSnackBar(context, t('add_phone_number'));
      return;
    }
    _createOrUpdateListing();
  }

  Future<void> _createOrUpdateListing() async {
    setState(() => _submitting = true);
    try {
      final isEdit = widget.isEdit && widget.listingId != null;
      int listingId;

      if (isEdit) {
        listingId = widget.listingId!;
        await ApiService.instance.updateListing(
          listingId: listingId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          categoryId: _selectedCategoryId,
          city: _cityCtrl.text.trim(),
          locationText: _locationCtrl.text.trim(),
          eventDate: _eventDate,
          contactChat: _contactChat,
          contactWhatsApp: _contactWhatsApp,
          contactCall: _contactCall,
        );
      } else {
        final result = await ApiService.instance.createListing(
          type: widget.type,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          categoryId: _selectedCategoryId,
          city: _cityCtrl.text.trim(),
          locationText: _locationCtrl.text.trim(),
          eventDate: _eventDate,
          contactChat: _contactChat,
          contactWhatsApp: _contactWhatsApp,
          contactCall: _contactCall,
        );
        listingId = result.listingId;

        if (!mounted) return;

        if (result.requiresPayment) {
          var paymentConfirmed = false;
          final priceLabel = '${result.amount ?? ''} ${result.currency ?? ''}'
              .trim();
          await PaymentModal.show(
            context,
            amount: priceLabel.isEmpty ? t('payment_required') : priceLabel,
            onPay: (_) async {
              await ApiService.instance.confirmPublishPayment(
                paymentId: result.paymentId ?? 0,
                listingId: result.listingId,
                provider: 'cmi',
              );
              return true;
            },
            onPaymentSuccess: () {
              paymentConfirmed = true;
            },
          );
          if (!mounted) return;
          if (!paymentConfirmed) return;
        }
      }

      if (!mounted) return;
      if (_images.isNotEmpty) {
        await ApiService.instance.uploadListingPhotos(listingId, _images);
      }

      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(
        context,
        isEdit
            ? AppMessages.listingUpdatedSuccess()
            : AppMessages.listingPublishedSuccess(),
      );
      if (isEdit) {
        Navigator.of(context).pop(true);
        return;
      }
      openAuthenticatedSection(context, index: mainAppShellHomeIndex);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showErrorSnackBar(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: widget.isEdit
              ? AppMessages.listingUpdateError()
              : AppMessages.listingPublishError(),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final isMobile = MediaQuery.of(context).size.width < 640;
    final accent = widget.type == 'lost' ? Colors.redAccent : Colors.green;

    return AuthenticatedScaffold(
      currentIndex: mainAppShellCreateIndex,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: TopNavBar(
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(context, accent),
                      const SizedBox(height: 20),
                      _photosSection(),
                      const SizedBox(height: 20),
                      _textField(
                        label: t('title'),
                        controller: _titleCtrl,
                        hint: t('listing_title_hint'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? AppMessages.requiredField()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _textField(
                        label: t('description'),
                        controller: _descCtrl,
                        hint: t('listing_description_hint'),
                        maxLines: 4,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? AppMessages.requiredField()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _categoryDropdown(),
                      const SizedBox(height: 16),
                      _textField(
                        label: t('city_label'),
                        controller: _cityCtrl,
                        hint: t('city_hint'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? AppMessages.requiredField()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _textField(
                        label: t('precise_location'),
                        controller: _locationCtrl,
                        hint: t('precise_location_hint'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? AppMessages.requiredField()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _datePicker(context),
                      const SizedBox(height: 16),
                      _contactToggles(),
                      const SizedBox(height: 24),
                      _submitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.edit_outlined, color: accent),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit
                  ? t('edit_listing')
                  : (widget.type == 'lost'
                        ? t('publish_lost_listing')
                        : t('publish_found_listing')),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (!widget.isEdit)
              Text(
                widget.type == 'lost'
                    ? t('payment_required_before_publish')
                    : t('free_publication'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
          ],
        ),
      ],
    );
  }

  Widget _photosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t('images')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.isEdit &&
                widget.initialListing?.photoObjects.isNotEmpty == true)
              ...widget.initialListing!.photoObjects.map(
                (photo) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _resolveImageUrl(photo.url),
                        width: 95,
                        height: 95,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _removedPhotoIds.add(photo.id);
                            widget.initialListing!.photoObjects.remove(photo);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ..._images.map(
              (img) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      img.bytes,
                      width: 95,
                      height: 95,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.remove(img)),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 95,
                height: 95,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryDropdown() {
    if (_loadingCats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }
    if (_catsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(t('category')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _catsError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              TextButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: Text(t('retry')),
              ),
            ],
          ),
        ],
      );
    }
    if (_categories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(t('category')),
          const SizedBox(height: 8),
          Text(t('no_categories_found')),
        ],
      );
    }

    final lang = LanguageService.instance.currentLanguageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t('category')),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey(_selectedCategoryId),
          initialValue: _selectedCategoryId,
          decoration: _inputDecoration(null),
          items: _categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.displayName(lang)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
          validator: (value) =>
              value == null ? AppMessages.categoryRequired() : null,
        ),
      ],
    );
  }

  Widget _datePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t('event_date')),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _eventDate ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 1),
            );
            if (picked != null) setState(() => _eventDate = picked);
          },
          child: InputDecorator(
            decoration: _inputDecoration(null),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  _eventDate == null
                      ? t('select_date')
                      : '${_eventDate!.day.toString().padLeft(2, '0')}/${_eventDate!.month.toString().padLeft(2, '0')}/${_eventDate!.year}',
                  style: TextStyle(
                    color: _eventDate == null
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t('contact_methods')),
        const SizedBox(height: 6),
        Text(
          t('profile_phone_used_for_contact'),
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('chat_in_app')),
          value: _contactChat,
          onChanged: (value) => setState(() => _contactChat = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('WhatsApp'),
          value: _contactWhatsApp,
          onChanged: (value) => setState(() => _contactWhatsApp = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('phone_call')),
          value: _contactCall,
          onChanged: (value) => setState(() => _contactCall = value),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _onSubmit,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload_outlined),
        label: Text(
          _submitting
              ? t('publishing')
              : (widget.isEdit ? t('save_changes') : t('publish_listing')),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppTheme.primaryViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
