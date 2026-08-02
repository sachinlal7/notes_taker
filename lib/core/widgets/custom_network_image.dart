import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';

class CustomNetworkImage extends StatelessWidget {
  const CustomNetworkImage({
    required this.imageUrl,
    required this.height,
    this.width = 50,
    this.fit = BoxFit.cover,
    this.color,
    this.errorWidget,
    this.borderRadius = 0,
    this.semanticLabel,
    super.key,
  });

  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final Color? color;
  final Widget? errorWidget;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();
    final child = trimmedUrl.isEmpty
        ? _ImageFallback(
            height: height,
            width: width,
            borderRadius: borderRadius,
            child: errorWidget,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: CachedNetworkImage(
              imageUrl: trimmedUrl,
              height: height,
              width: width,
              fit: fit,
              color: color,
              progressIndicatorBuilder: (_, _, _) => _ImagePlaceholder(
                height: height,
                width: width,
                borderRadius: borderRadius,
              ),
              errorWidget: (_, _, _) => _ImageFallback(
                height: height,
                width: width,
                borderRadius: borderRadius,
                child: errorWidget,
              ),
            ),
          );

    if (semanticLabel == null) return child;

    return Semantics(image: true, label: semanticLabel, child: child);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.height,
    required this.width,
    required this.borderRadius,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return _ImageContainer(
      height: height,
      width: width,
      borderRadius: borderRadius,
      child: const BreathingIcon(
        icon: CupertinoIcons.photo,
        color: AppColors.shimmerHighlight,
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({
    required this.height,
    required this.width,
    required this.borderRadius,
    this.child,
  });

  final double height;
  final double width;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _ImageContainer(
      height: height,
      width: width,
      borderRadius: borderRadius,
      child:
          child ??
          const Icon(CupertinoIcons.photo, color: AppColors.shimmerHighlight),
    );
  }
}

class _ImageContainer extends StatelessWidget {
  const _ImageContainer({
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.child,
  });

  final double height;
  final double width;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class BreathingIcon extends StatefulWidget {
  const BreathingIcon({
    required this.icon,
    required this.color,
    this.size = 24,
    this.duration = const Duration(milliseconds: 1000),
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;

  @override
  State<BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<BreathingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(curve);
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(widget.icon, color: widget.color, size: widget.size),
          ),
        );
      },
    );
  }
}
