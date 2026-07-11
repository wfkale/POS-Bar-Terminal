import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Venue logo with graceful fallback to the venue name.
class VenueBranding extends StatelessWidget {
  const VenueBranding({
    super.key,
    this.height = 72,
    this.maxWidth = 200,
    this.nameStyle,
    this.textAlign = TextAlign.center,
  });

  final double height;
  final double maxWidth;
  final TextStyle? nameStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final controller = VenueScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _VenueBrandingBody(
        config: controller.venue,
        height: height,
        maxWidth: maxWidth,
        nameStyle: nameStyle,
        textAlign: textAlign,
      ),
    );
  }
}

class _VenueBrandingBody extends StatelessWidget {
  const _VenueBrandingBody({
    required this.config,
    required this.height,
    required this.maxWidth,
    required this.nameStyle,
    required this.textAlign,
  });

  final VenueConfig config;
  final double height;
  final double maxWidth;
  final TextStyle? nameStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final defaultNameStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.accent,
        );

    final logoUrl = config.logoUrl?.trim();
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: height,
          width: maxWidth,
          child: _StableNetworkLogo(
            url: logoUrl,
            height: height,
            maxWidth: maxWidth,
            fallback: _VenueName(
              name: config.name,
              style: nameStyle ?? defaultNameStyle,
              textAlign: textAlign,
            ),
          ),
        ),
      );
    }

    return _VenueName(
      name: config.name,
      style: nameStyle ?? defaultNameStyle,
      textAlign: textAlign,
    );
  }
}

/// Keeps showing the last successful logo frame across rebuilds / PWA updates.
class _StableNetworkLogo extends StatefulWidget {
  const _StableNetworkLogo({
    required this.url,
    required this.height,
    required this.maxWidth,
    required this.fallback,
  });

  final String url;
  final double height;
  final double maxWidth;
  final Widget fallback;

  @override
  State<_StableNetworkLogo> createState() => _StableNetworkLogoState();
}

class _StableNetworkLogoState extends State<_StableNetworkLogo> {
  var _failed = false;
  var _retryToken = 0;
  var _retryScheduled = false;

  @override
  void didUpdateWidget(covariant _StableNetworkLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _failed = false;
      _retryScheduled = false;
      _retryToken++;
    }
  }

  void _scheduleRetry() {
    if (_retryScheduled || !mounted) return;
    _retryScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _failed = false;
        _retryToken++;
        _retryScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      _scheduleRetry();
      return widget.fallback;
    }

    return Image.network(
      widget.url,
      key: ValueKey('${widget.url}#$_retryToken'),
      fit: BoxFit.contain,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_failed) setState(() => _failed = true);
        });
        return widget.fallback;
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent.withOpacity(0.8),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _VenueName extends StatelessWidget {
  const _VenueName({
    required this.name,
    required this.style,
    required this.textAlign,
  });

  final String name;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(name, style: style, textAlign: textAlign);
  }
}

/// Cashier pay buttons driven by venue payment_methods settings.
class PaymentMethodButtons extends StatelessWidget {
  const PaymentMethodButtons({
    super.key,
    required this.onPay,
    this.compact = false,
  });

  final void Function(String methodCode) onPay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = VenueScope.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final methods = controller.venue.paymentMethods;
        if (methods.isEmpty) {
          return const SizedBox.shrink();
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            for (var i = 0; i < methods.length; i++)
              i == methods.length - 1
                  ? FilledButton(
                      onPressed: () => onPay(methods[i].code),
                      child: Text(methods[i].labelForLocale(locale)),
                    )
                  : OutlinedButton(
                      onPressed: () => onPay(methods[i].code),
                      child: Text(methods[i].labelForLocale(locale)),
                    ),
          ],
        );
      },
    );
  }
}
