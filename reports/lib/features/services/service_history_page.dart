import 'package:flutter/material.dart';
import '../../design/reports_design.dart';
import 'service_preview_store.dart';

import 'service_preview_page.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key, this.onStartReport});

  final VoidCallback? onStartReport;

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic>? selected;
  String query = '';
  String notice = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({String? selectedId}) async {
    if (selectedId != null) {
      setState(() {
        selected = null;
        loading = true;
      });
    }
    final loaded = await const ServicePreviewStore().load();
    if (mounted) {
      setState(() {
        records = loaded;
        selected = records
            .where((item) => item['id'] == selectedId)
            .firstOrNull;
        loading = false;
      });
    }
  }

  Future<void> remove() async {
    final item = selected;
    setState(() {
      records.remove(item);
      selected = null;
    });
    final saved = await const ServicePreviewStore().remove(
      item!['id'] as String,
    );
    if (mounted && !saved) {
      setState(
        () =>
            notice = 'Changes could not be saved. They remain in this session.',
      );
    }
  }

  Future<void> follow() async {
    final item = selected!;
    final updated = {...item, 'following': item['following'] != true};
    setState(() {
      records[records.indexOf(item)] = updated;
      selected = updated;
    });
    final saved = await const ServicePreviewStore().save(updated);
    if (mounted && !saved) {
      setState(
        () =>
            notice = 'Changes could not be saved. They remain in this session.',
      );
    }
  }

  Future<void> lookUp() async {
    final match = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => _ServiceLookupPage(records: records)),
    );
    if (mounted && match != null) setState(() => selected = match);
  }

  Iterable<Map<String, dynamic>> get matchingRecords => records.where(
    (item) => '${item['service']} ${item['id']}'.toLowerCase().contains(query),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My previews'),
      leading: selected == null
          ? null
          : BackButton(onPressed: () => setState(() => selected = null)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: selected == null
          ? [
              Text(
                'My Reports',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your drafts and completed previews stay on this device.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: ReportsStyle.muted,
                ),
              ),
              const SizedBox(height: 24),
              if (notice.isNotEmpty) Text(notice),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Find a local preview',
                ),
                onChanged: (value) =>
                    setState(() => query = value.toLowerCase()),
              ),
              const SizedBox(height: 24),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (records.isEmpty)
                const Text('No local previews yet')
              else if (matchingRecords.isEmpty)
                const Text('No local previews match your search.')
              else
                for (final record in matchingRecords)
                  Card(
                    child: ListTile(
                      title: Text(record['service'] as String),
                      subtitle: Text(
                        '${record['step'] == 5 ? 'Local receipt' : 'Draft'} · ${record['id']}',
                      ),
                      onTap: () => setState(() => selected = record),
                    ),
                  ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  OutlinedButton(
                    onPressed: loading ? null : lookUp,
                    child: const Text('Look up a request'),
                  ),
                  FilledButton(
                    onPressed: widget.onStartReport,
                    child: const Text('Start a report'),
                  ),
                ],
              ),
            ]
          : [
              Text(
                'Local record · ${selected!['id']}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                selected!['service'] as String,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    selected!['step'] == 5 ? 'Preview complete' : 'Draft',
                  ),
                ),
              ),
              Text(selected!['description'] as String? ?? ''),
              Text(selected!['address'] as String? ?? ''),
              const SizedBox(height: 16),
              Text(
                'Local preview',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Text('Saved on this device'),
              const SizedBox(height: 16),
              Text(
                'City status not available',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Text('This preview was not sent to the City.'),
              const SizedBox(height: 16),
              const Text(
                'City actions to edit or cancel are not verified. You can manage only the local preview.',
              ),
              if (notice.isNotEmpty) Text(notice),
              OutlinedButton(
                onPressed: follow,
                child: Text(
                  selected!['following'] == true
                      ? 'Unfollow locally'
                      : 'Follow locally',
                ),
              ),
              if (selected!['step'] != 5)
                FilledButton(
                  onPressed: () async {
                    final item = selected!;
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ServicePreviewPage(
                          service: {
                            'name': item['service'],
                            'group': item['group'],
                            'evidence': item['evidence'],
                          },
                          draft: item,
                        ),
                      ),
                    );
                    if (mounted) await load(selectedId: item['id'] as String);
                  },
                  child: const Text('Resume draft'),
                ),
              TextButton(
                onPressed: remove,
                child: const Text('Remove local record'),
              ),
            ],
    ),
  );
}

class _ServiceLookupPage extends StatefulWidget {
  const _ServiceLookupPage({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  State<_ServiceLookupPage> createState() => _ServiceLookupPageState();
}

class _ServiceLookupPageState extends State<_ServiceLookupPage> {
  final formKey = GlobalKey<FormState>();
  String reference = '';
  bool noMatch = false;

  void findPreview() {
    if (!formKey.currentState!.validate()) return;
    for (final record in widget.records) {
      if (record['id'] == reference) {
        Navigator.of(context).pop(record);
        return;
      }
    }
    setState(() => noMatch = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More service reports')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(bottom: 24),
                minimumSize: const Size(44, 48),
                foregroundColor: ReportsStyle.ink,
                textStyle: const TextStyle(fontSize: 16, height: 1.5),
              ),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('My Reports'),
            ),
          ),
          Text(
            'Look up a request',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'City lookup is not connected in this preview.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: ReportsStyle.muted,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Local lookup ID',
              hintText: 'Enter a local reference',
            ),
            onChanged: (value) => reference = value,
            validator: (value) => value == null || value.isEmpty
                ? 'Enter a local lookup ID.'
                : null,
            onFieldSubmitted: (_) => findPreview(),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: findPreview,
              child: const Text('Find local preview'),
            ),
          ),
          if (noMatch) ...[
            const SizedBox(height: 20),
            const Text(
              'No local preview matches that reference. City lookup is not connected.',
            ),
          ],
        ],
      ),
    ),
  );
}
