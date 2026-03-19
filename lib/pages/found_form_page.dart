import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/payment_modal.dart';
import 'login_page.dart';
import '../models/listing_model.dart';
import '../services/auth_local_storage.dart';

class FoundFormPage extends StatefulWidget {
  final String type; // 'lost' ou 'found'
  final int? listingId;
  final ListingModel? initialListing;
  final bool isEdit;
  const FoundFormPage({
    super.key,
    required this.type,
    this.listingId,
    this.initialListing,
    this.isEdit = false,
  });

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
    String cleaned = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final idx = cleaned.indexOf('uploads/');
    if (idx >= 0) cleaned = cleaned.substring(idx);
    if (cleaned.startsWith('uploads/')) {
      return '$uploadsBase$cleaned';
    }
    return '${uploadsBase}uploads/annonces/$cleaned';
  }

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

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final cats = await ApiService.instance.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        if (cats.isNotEmpty) {
          _selectedCategoryId = cats.first.id;
          _catsError = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _catsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final additions = <ApiPickedImage>[];
    for (final x in picked) {
      final Uint8List bytes = await x.readAsBytes();
      additions.add(ApiPickedImage(file: x, bytes: bytes));
    }
    setState(() => _images = [..._images, ...additions]);
  }

  void _onSubmit() {
    debugPrint('FoundFormPage onSubmit called');
    final isLoggedIn =
        currentUser.value != null || ApiService.instance.isAuthenticated;
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour publier')),
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_contactChat && !_contactWhatsApp && !_contactCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activez au moins un moyen de contact')),
      );
      return;
    }
    final phone = currentUser.value?.phone?.trim() ?? '';
    if ((_contactWhatsApp || _contactCall) && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Ajoutez un numéro dans votre profil pour WhatsApp / Appel",
          ),
        ),
      );
      return;
    }
    _createOrUpdateListing();
  }

  Future<void> _createOrUpdateListing() async {
    setState(() => _submitting = true);
    try {
      if (widget.isEdit && widget.listingId != null) {
        await ApiService.instance.updateListing(
          listingId: widget.listingId!,
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
        // Supprimer les photos marquées
        for (final pid in _removedPhotoIds) {
          await ApiService.instance.deleteListingPhoto(listingId: widget.listingId!, photoId: pid);
        }
        // Uploader les nouvelles photos ajoutées
        if (_images.isNotEmpty) {
          await ApiService.instance.uploadListingPhotos(widget.listingId!, _images);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce mise à jour avec succès')),
        );
        Navigator.of(context).pop();
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
        if (!mounted) return;
        if (_images.isNotEmpty) {
          await ApiService.instance.uploadListingPhotos(
            result.listingId,
            _images,
          );
        }
        if (!mounted) return;
        if (result.requiresPayment) {
          final priceLabel = "${result.amount ?? ''} ${result.currency ?? ''}"
              .trim();
          await PaymentModal.show(
            context,
            amount: priceLabel.isEmpty ? 'Paiement requis' : priceLabel,
            onPay: (_) async {
              await ApiService.instance.confirmPublishPayment(
                paymentId: result.paymentId ?? 0,
                listingId: result.listingId,
                provider: 'cmi',
              );
              return true;
            },
            onPaymentSuccess: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement confirmé, annonce publiée'),
                ),
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          );
          if (!mounted) return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce publiée avec succès')),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    final accent = widget.type == 'lost' ? Colors.redAccent : Colors.green;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
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
                        label: "Titre",
                        controller: _titleCtrl,
                        hint: "Ex: Téléphone trouvé au parc",
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Champ requis"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _textField(
                        label: "Description",
                        controller: _descCtrl,
                        hint:
                            "Décrivez l'objet, où et quand vous l'avez trouvé...",
                        maxLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Champ requis"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _categoryDropdown(),
                      const SizedBox(height: 16),
                      _textField(
                        label: "Ville",
                        controller: _cityCtrl,
                        hint: "Casablanca, Rabat...",
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Champ requis"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _textField(
                        label: "Lieu précis",
                        controller: _locationCtrl,
                        hint: "Quartier, rue, repère...",
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Champ requis"
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
                  ? "Modifier l'annonce"
                  : (widget.type == 'lost'
                      ? "Publier un objet perdu"
                      : "Publier un objet trouvé"),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (!widget.isEdit)
              Text(
                widget.type == 'lost'
                    ? "Paiement requis avant publication"
                    : "Publication gratuite",
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
        _label("Photos"),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.isEdit && widget.initialListing?.photoObjects.isNotEmpty == true)
              ...widget.initialListing!.photoObjects.map(
                (p) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _resolveImageUrl(p.url),
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
                            _removedPhotoIds.add(p.id);
                            widget.initialListing!.photoObjects.remove(p);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Icon(
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
          _label("Catégorie"),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Échec du chargement des catégories",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
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
          _label("Catégorie"),
          const SizedBox(height: 8),
          const Text("Aucune catégorie trouvée"),
        ],
      );
    }
    final lang = currentUser.value?.preferredLang ?? 'fr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Catégorie"),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey(_selectedCategoryId),
          initialValue: _selectedCategoryId,
          decoration: _inputDecoration(null),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.displayName(lang)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          validator: (v) => v == null ? "Choisissez une catégorie" : null,
        ),
      ],
    );
  }

  Widget _datePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Date de l'événement"),
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
                const Icon(Icons.event_outlined, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  _eventDate == null
                      ? "Sélectionner une date"
                      : "${_eventDate!.day.toString().padLeft(2, '0')}/${_eventDate!.month.toString().padLeft(2, '0')}/${_eventDate!.year}",
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
        _label("Moyens de contact"),
        const SizedBox(height: 6),
        const Text(
          "Le numéro utilisé pour WhatsApp/Appel est celui de votre profil.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Chat dans l'app"),
          value: _contactChat,
          onChanged: (v) => setState(() => _contactChat = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("WhatsApp"),
          value: _contactWhatsApp,
          onChanged: (v) => setState(() => _contactWhatsApp = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Appel téléphonique"),
          value: _contactCall,
          onChanged: (v) => setState(() => _contactCall = v),
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
          _submitting ? "Publication..." : "Publier l'annonce",
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

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    ),
  );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
