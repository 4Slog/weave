import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/optimized_asset_loader.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';

/// A widget that displays an image with optimized loading and caching
class OptimizedImage extends StatefulWidget {
  /// The image path or URL
  final String imagePath;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Fit of the image
  final BoxFit fit;

  /// Whether to use downsampling for memory efficiency
  final bool useDownsampling;

  /// Target width for downsampling (required if useDownsampling is true)
  final int? targetWidth;

  /// Target height for downsampling (required if useDownsampling is true)
  final int? targetHeight;

  /// Placeholder widget to show while loading
  final Widget? placeholder;

  /// Error widget to show on error
  final Widget? errorWidget;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Whether to preload related assets
  final bool preload;

  /// Feature context for preloading related assets
  final String? featureContext;

  /// Create a new optimized image widget
  const OptimizedImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useDownsampling = false,
    this.targetWidth,
    this.targetHeight,
    this.placeholder,
    this.errorWidget,
    this.semanticLabel,
    this.preload = false,
    this.featureContext,
  }) : assert(!useDownsampling || (targetWidth != null && targetHeight != null),
            'targetWidth and targetHeight must be provided when useDownsampling is true');

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  // Asset loader
  late final OptimizedAssetLoader _assetLoader;

  // Image loading state
  bool _isLoading = true;
  bool _hasError = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();

    // Get asset loader
    _assetLoader = ServiceProvider.get<OptimizedAssetLoader>();

    // Preload related assets if requested
    if (widget.preload && widget.featureContext != null) {
      _assetLoader.preloadAssetsForFeature(widget.featureContext!);
    }

    // Load image
    _loadImage();
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload image if path changed
    if (widget.imagePath != oldWidget.imagePath ||
        widget.useDownsampling != oldWidget.useDownsampling ||
        widget.targetWidth != oldWidget.targetWidth ||
        widget.targetHeight != oldWidget.targetHeight) {
      _loadImage();
    }
  }

  /// Load the image
  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageProvider = null;
    });

    try {
      if (widget.useDownsampling) {
        // Load with downsampling
        final image = await _assetLoader.loadDownsampledImage(
          widget.imagePath,
          targetWidth: widget.targetWidth!,
          targetHeight: widget.targetHeight!,
        );

        if (!mounted) return;

        // Convert image to bytes outside of setState
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        if (!mounted) return;

        setState(() {
          _imageProvider = MemoryImage(bytes);
          _isLoading = false;
        });
      } else {
        // Load normally
        if (widget.imagePath.startsWith('http')) {
          // Network image
          setState(() {
            _imageProvider = NetworkImage(widget.imagePath);
            _isLoading = false;
          });
        } else {
          // Asset image
          setState(() {
            _imageProvider = AssetImage(widget.imagePath);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });

      debugPrint('Error loading image ${widget.imagePath}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder while loading
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder ?? const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error widget on error
    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ?? const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    }

    // Show image
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: Image(
        image: _imageProvider!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}
