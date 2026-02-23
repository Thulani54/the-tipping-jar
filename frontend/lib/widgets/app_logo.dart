import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The TipDrop logo icon, sized to [size] × [size].
/// Drop-in replacement for the old green circle + volunteer_activism icon.
class AppLogoIcon extends StatelessWidget {
  final double size;
  const AppLogoIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/images/logo.svg',
        width: size * 1.2,
        height: size * 1.2,
        fit: BoxFit.contain,
      );
}
