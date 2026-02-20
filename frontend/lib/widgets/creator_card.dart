import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/creator.dart';

class CreatorCard extends StatelessWidget {
  final Creator creator;
  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/creator/${creator.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 100,
              color: const Color(0xFFFF6B35).withOpacity(0.2),
              child: creator.coverImage != null
                  ? Image.network(creator.coverImage!,
                      width: double.infinity, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.photo, size: 40, color: Colors.white54)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(creator.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (creator.tagline.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(creator.tagline,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/tip/${creator.slug}'),
                    icon: const Icon(Icons.volunteer_activism, size: 16),
                    label: const Text('Send a tip'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
