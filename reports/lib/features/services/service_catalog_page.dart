import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/reports_design.dart';
import '../report/domain/report.dart';
import 'service_preview_page.dart';

class ServiceCatalogPage extends StatefulWidget {
  const ServiceCatalogPage({
    super.key,
    required this.onStartReport,
    this.loadCatalog,
  });

  final ValueChanged<String> onStartReport;
  final Future<List<Map<String, dynamic>>> Function()? loadCatalog;

  @override
  State<ServiceCatalogPage> createState() => _ServiceCatalogPageState();
}

class _ServiceCatalogPageState extends State<ServiceCatalogPage> {
  late Future<List<Map<String, dynamic>>> _catalog = _load();
  String _query = '';
  String? _group;

  Future<List<Map<String, dynamic>>> _load() async {
    final json = await rootBundle.loadString('assets/service_catalog.json');
    final previews = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    final loadCatalog = widget.loadCatalog;
    if (loadCatalog == null) return previews;
    final catalog = await loadCatalog();
    final evidence = {
      for (final service in previews) service['name']: service['evidence'],
    };
    return [
      for (final service in catalog)
        {...service, 'evidence': evidence[service['name']] ?? ''},
    ];
  }

  void open(Map<String, dynamic> service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicePreviewPage(
          service: service,
          onStartReport:
              [
                illegalDumpingRequestType,
                barricadeRemovalServiceName,
              ].contains(service['name'])
              ? () => widget.onStartReport(service['name'] as String)
              : null,
        ),
      ),
    );
  }

  Widget row(String title, String subtitle, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton(
      onPressed: action,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(22),
        alignment: Alignment.centerLeft,
        backgroundColor: const Color(0xfff7f7f7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Services')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _catalog,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final services = snapshot.data ?? [];
        final query = _query.trim().toLowerCase();
        final groups = services.map((item) => item['group'] as String).toSet();
        final filtered = services.where(
          (item) => _group != null
              ? item['group'] == _group
              : '${item['name']} ${item['group']}'.toLowerCase().contains(
                  query,
                ),
        );
        final headingStyle = Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontSize: 30, height: 1.2, letterSpacing: -1.05);
        return ListView(
          key: ValueKey(_group),
          padding: const EdgeInsets.all(20),
          children: [
            if (_group != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 48),
                    foregroundColor: ReportsStyle.ink,
                    textStyle: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  onPressed: () => setState(() => _group = null),
                  child: const Text('All services'),
                ),
              ),
            if (_group != null) Text(_group!, style: headingStyle),
            if (_group == null) Text('Services', style: headingStyle),
            const SizedBox(height: 16),
            Text(
              _group == null
                  ? 'Find the right place to start. Browse by category or search by name.'
                  : 'Choose the service that best matches your concern.',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: ReportsStyle.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (_group == null)
              TextField(
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: const InputDecoration(
                  labelText: 'Search services',
                  contentPadding: EdgeInsets.all(18),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            if (_group == null) const SizedBox(height: 24),
            if (loading)
              const Text('Loading services…')
            else if (snapshot.hasError) ...[
              const Text('Could not load services. Please try again.'),
              TextButton(
                onPressed: () => setState(() {
                  _catalog = _load();
                }),
                child: const Text('Retry'),
              ),
            ] else if (_group == null && query.isEmpty)
              for (final group in groups)
                row(
                  group,
                  '${services.where((item) => item['group'] == group).length} ${services.where((item) => item['group'] == group).length == 1 ? 'service' : 'services'}',
                  () => setState(() => _group = group),
                )
            else
              for (final service in filtered)
                row(
                  service['name'] as String,
                  _group == null ? service['group'] as String : '',
                  () => open(service),
                ),
            if (!loading &&
                !snapshot.hasError &&
                _group == null &&
                query.isNotEmpty &&
                filtered.isEmpty)
              const Text('No services found'),
          ],
        );
      },
    ),
  );
}
