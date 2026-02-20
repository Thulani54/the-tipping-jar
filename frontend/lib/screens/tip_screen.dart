import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class TipScreen extends StatefulWidget {
  final String slug;
  const TipScreen({super.key, required this.slug});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Anonymous');
  final _messageCtrl = TextEditingController();
  double _amount = 5;
  bool _loading = false;
  String? _error;
  bool _success = false;

  final _quickAmounts = [1.0, 5.0, 10.0, 25.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send a tip')),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose an amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _quickAmounts.map((a) {
                return ChoiceChip(
                  label: Text('\$${a.toInt()}'),
                  selected: _amount == a,
                  onSelected: (_) => setState(() => _amount = a),
                  selectedColor: const Color(0xFFFF6B35),
                  labelStyle: TextStyle(
                      color: _amount == a ? Colors.white : null,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _amount.toString(),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Custom amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  setState(() => _amount = double.tryParse(v) ?? _amount),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 1) return 'Minimum tip is \$1';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Leave a message (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(color: Colors.white))
                    : Text('Tip \$${_amount.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: Color(0xFFFF6B35), size: 80),
          const SizedBox(height: 16),
          const Text('Your tip is on its way!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('\$${_amount.toStringAsFixed(2)} sent',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/creator/${widget.slug}'),
            child: const Text('Back to creator page'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService().initiateTip(
        creatorSlug: widget.slug,
        amount: _amount,
        tipperName: _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      setState(() => _success = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }
}
