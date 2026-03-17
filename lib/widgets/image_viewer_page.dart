import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0, 'images must not be empty');

  final List<String> images;
  final int initialIndex;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double? _progressValue(ImageChunkEvent? event) {
    final expected = event?.expectedTotalBytes;
    if (event == null || expected == null || expected == 0) {
      return null;
    }
    return event.cumulativeBytesLoaded / expected;
  }

  PhotoViewScaleState _scaleStateCycle(PhotoViewScaleState actual) {
    switch (actual) {
      case PhotoViewScaleState.initial:
        return PhotoViewScaleState.covering;
      case PhotoViewScaleState.covering:
        return PhotoViewScaleState.originalSize;
      case PhotoViewScaleState.originalSize:
      case PhotoViewScaleState.zoomedIn:
      case PhotoViewScaleState.zoomedOut:
        return PhotoViewScaleState.initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: totalImages,
            pageController: _pageController,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentIndex = index);
            },
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                  value: _progressValue(event),
                ),
              ),
            ),
            builder: (context, index) {
              final imageUrl = widget.images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                initialScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                scaleStateCycle: _scaleStateCycle,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 44,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Impossible de charger l'image",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  _ViewerButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $totalImages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
