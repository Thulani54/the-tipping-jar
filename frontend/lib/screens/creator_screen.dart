import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/creator.dart';
import '../models/tip.dart';
import '../services/api_service.dart';

class CreatorScreen extends StatefulWidget {
  final String slug;
  const CreatorScreen({super.key, required this.slug});

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  late Future<Creator> _creatorFuture;
  late Future<List<Tip>> _tipsFuture;

  @override
  void initState() {
    super.initState();
    _creatorFuture = ApiService().getCreator(widget.slug);
    _tipsFuture = ApiService().getCreatorTips(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      body: FutureBuilder<Creator>(
        future: _creatorFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final creator = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(creator.displayName),
                  background: creator.coverImage != null
                      ? Image.network(creator.coverImage!, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (creator.tagline.isNotEmpty)
                        Text(creator.tagline,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _statCard('Total tips',
                              currency.format(creator.totalTips)),
                          const SizedBox(width: 12),
                          if (creator.tipGoal != null)
                            _statCard('Monthly goal',
                                currency.format(creator.tipGoal)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/tip/${creator.slug}'),
                          icon: const Icon(Icons.volunteer_activism),
                          label: const Text('Send a tip'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Recent tips',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<Tip>>(
                future: _tipsFuture,
                builder: (context, tipSnap) {
                  if (!tipSnap.hasData) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final tips = tipSnap.data!;
                  if (tips.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No tips yet — be the first!',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final tip = tips[i];
                        return ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.favorite, size: 16)),
                          title: Text(
                              '${tip.tipperName}  ·  ${currency.format(tip.amount)}'),
                          subtitle: tip.message.isNotEmpty
                              ? Text(tip.message)
                              : null,
                          trailing: Text(
                            DateFormat('MMM d').format(tip.createdAt),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        );
                      },
                      childCount: tips.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
