import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

/// /tip/:slug simply redirects to the combined creator page /creator/:slug
/// which has the tip form embedded. This keeps a single source of truth.
class TipScreen extends StatelessWidget {
  final String slug;
  const TipScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    // Redirect to the creator page which has the full tip form embedded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/creator/$slug');
    });
    return const Scaffold(
      backgroundColor: kDark,
      body: Center(child: CircularProgressIndicator(color: kPrimary)),
    );
  }
}
