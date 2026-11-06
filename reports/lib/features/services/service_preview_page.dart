import 'package:flutter/material.dart';
import '../../design/reports_design.dart';
import '../account/account_page.dart';
import '../report/data/remembered_contact_store.dart';
import '../report/domain/report.dart';
import 'service_preview_store.dart';

class ServicePreviewPage extends StatefulWidget {
  const ServicePreviewPage({
    super.key,
    required this.service,
    this.draft,
    this.onStartReport,
  });

  final Map<String, dynamic> service;
  final Map<String, dynamic>? draft;
  final VoidCallback? onStartReport;

  @override
  State<ServicePreviewPage> createState() => _ServicePreviewPageState();
}

class _ServicePreviewPageState extends State<ServicePreviewPage> {
  int step = -1;
  String description = '';
  bool extra = false;
  String extraDetail = '';
  String address = '';
  String reference = '';
  String firstName = '';
  String lastName = '';
  String phone = '';
  bool remember = false;
  bool updates = true;
  bool reviewConsent = false;
  bool contactLoaded = false;
  bool advancing = false;
  String email = '';
  bool confirmed = false;
  bool? named;
  int photos = 0;
  String error = '';
  bool stored = true;
  final validationErrorKey = GlobalKey();
  late final String id;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    id =
        draft?['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString();
    if (draft != null) {
      step = draft['step'] as int;
      description = draft['description'] as String? ?? '';
      extra = draft['extra'] == true;
      extraDetail = draft['extraDetail'] is String
          ? draft['extraDetail'] as String
          : '';
      address = draft['address'] as String? ?? '';
      reference = draft['reference'] is String
          ? draft['reference'] as String
          : '';
      firstName = draft['firstName'] as String? ?? '';
      lastName = draft['lastName'] as String? ?? '';
      phone = draft['phone'] as String? ?? '';
      email = draft['email'] as String? ?? '';
      confirmed = draft['confirmed'] as bool? ?? false;
      named = draft['named'] as bool?;
      photos = draft['photos'] as int? ?? 0;
      updates = draft['updates'] != false;
      reviewConsent = draft['reviewConsent'] == true;
    }
    loadContact();
  }

  Future<void> loadContact() async {
    try {
      final contact = await const RememberedContactStore().load();
      if (contact != null &&
          firstName.isEmpty &&
          lastName.isEmpty &&
          email.isEmpty) {
        firstName = contact.firstName;
        lastName = contact.lastName;
        email = contact.email;
        phone = contact.phone;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => contactLoaded = true);
    }
  }

  String get evidence => widget.service['evidence'] as String;
  String get boundary {
    final supplied = widget.service['boundary'] ?? widget.draft?['boundary'];
    if (supplied is String) return supplied;
    return RegExp(
          r'location boundary ([^;]+)',
        ).firstMatch(evidence)?.group(1) ??
        'Service boundary not confirmed';
  }

  bool get contactRequired => evidence.contains('contact required');
  bool get accountRequired => evidence.contains('account required');
  bool get accessKnown =>
      evidence.contains('anonymous available') ||
      contactRequired ||
      accountRequired;
  bool get noPhotos => evidence.contains('no upload control');
  int? get photoLimit => int.tryParse(
    RegExp(r'advertised limit (\d+)').firstMatch(evidence)?.group(1) ?? '',
  );

  Future<bool> save() async {
    final data = <String, Object?>{
      'id': id,
      'service': widget.service['name'] as String,
      'group': widget.service['group'] as String,
      'evidence': evidence,
      if (widget.draft?['following'] case final bool following)
        'following': following,
      'step': step,
      'description': description,
      'extra': extra,
      'extraDetail': extraDetail,
      'address': address,
      'reference': reference,
      'boundary': boundary,
      if (named == true || contactRequired) ...{
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'updates': updates,
      },
      'confirmed': confirmed,
      'named': named,
      'photos': photos,
      'reviewConsent': reviewConsent,
    };
    stored = await const ServicePreviewStore().save(data);
    if (mounted) setState(() {});
    return stored;
  }

  Future<void> advance() async {
    if (advancing) return;
    setState(() => advancing = true);
    FocusManager.instance.primaryFocus?.unfocus();
    String problem = '';
    if (step == 0 && description.trim().isEmpty) {
      problem = 'Describe what needs attention.';
    } else if (step == 0 && extra && extraDetail.trim().isEmpty) {
      problem = 'Add the extra detail you selected.';
    }
    if (step == 1 && (!confirmed || address.trim().isEmpty)) {
      problem = 'Confirm the sample location.';
    }
    if (step == 2 && evidence.contains('required attachments') && photos == 0) {
      problem = 'Add sample evidence.';
    }
    if (step == 3 && (named == true || contactRequired) && !contactLoaded) {
      problem = 'Contact information is still loading.';
    }
    if (step == 3 && !contactRequired && named == null) {
      problem = 'Choose how to provide contact information.';
    }
    if (step == 3 &&
        (contactRequired || named == true) &&
        (firstName.trim().isEmpty ||
            lastName.trim().isEmpty ||
            !email.contains('@'))) {
      problem = 'Enter a name and valid email.';
    }
    if (step == 4 && !reviewConsent) {
      problem = 'Please confirm that this creates a local demo receipt only.';
    }
    if (problem.isEmpty &&
        step == 3 &&
        (named == true || contactRequired) &&
        remember) {
      try {
        await const RememberedContactStore().save(
          ReportContact(
            anonymous: false,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
          ),
        );
      } catch (_) {
        problem = 'Contact could not be saved on this device.';
      }
    }
    if (!mounted) return;
    setState(() {
      advancing = false;
      error = problem;
      if (problem.isEmpty) step++;
    });
    if (problem.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final errorContext = validationErrorKey.currentContext;
        if (errorContext == null) return;
        Scrollable.ensureVisible(
          errorContext,
          alignment: 1,
          duration: MediaQuery.disableAnimationsOf(errorContext)
              ? Duration.zero
              : const Duration(milliseconds: 200),
        );
      });
    }
    if (problem.isEmpty) save();
  }

  Widget input(
    String label,
    String initial,
    ValueChanged<String> update, {
    int maxLines = 1,
  }) => TextFormField(
    initialValue: initial,
    maxLines: maxLines,
    readOnly: advancing,
    style: const TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.all(14),
    ),
    onChanged: (value) {
      if (advancing) return;
      update(value);
      reviewConsent = false;
      save();
    },
  );

  void backStep() {
    if (advancing) return;
    setState(() {
      step--;
      error = '';
    });
    save();
  }

  Widget heading(String text) {
    final style = Theme.of(context).textTheme.headlineMedium;
    return Padding(
      padding: step >= 0 && step < 5
          ? const EdgeInsets.only(top: 12, bottom: 8)
          : step == -1
          ? const EdgeInsets.only(bottom: 4)
          : EdgeInsets.zero,
      child: Text(
        text,
        style: step < 5 ? style?.copyWith(fontSize: 30, height: 1.2) : style,
      ),
    );
  }

  Widget reviewEntry(String label, List<String> values) =>
      DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(label)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final value in values) Text(value)],
              ),
            ),
          ],
        ),
      );

  Widget contactChoice({required bool anonymous}) {
    final selected = (contactRequired && !anonymous) || named == !anonymous;
    final border = selected ? ReportsStyle.orangeDark : ReportsStyle.border;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xfffff1d9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (advancing) return;
            setState(() {
              named = !anonymous;
              reviewConsent = false;
            });
            save();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xfffff1d9) : Colors.white,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: border, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      anonymous ? Icons.shield_outlined : Icons.mail_outline,
                    ),
                    const Spacer(),
                    Icon(selected ? Icons.check_circle : Icons.circle_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  anonymous ? 'Anonymous' : 'Provide contact details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  anonymous
                      ? 'Keep your name and email out of this preview.'
                      : 'Add contact details to this local preview.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget contactChoices() => LayoutBuilder(
    builder: (context, constraints) {
      if (contactRequired) return contactChoice(anonymous: false);
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          children: [
            contactChoice(anonymous: true),
            const SizedBox(height: 12),
            contactChoice(anonymous: false),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: contactChoice(anonymous: true)),
          const SizedBox(width: 12),
          Expanded(child: contactChoice(anonymous: false)),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.service['name'] as String;
    final canStart = accessKnown || widget.onStartReport != null;
    final content = <Widget>[
      if (step == -1) ...[
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: Text('← ${widget.service['group']}'),
        ),
        Text(
          'SERVICE INFORMATION',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.6,
            fontWeight: FontWeight.w600,
            letterSpacing: .72,
          ),
        ),
        heading(title),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.service['group'] as String,
            style: const TextStyle(color: ReportsStyle.muted),
          ),
        ),
        if (!canStart) ...[
          const Text('Availability is still being confirmed.'),
          const Text('The next steps for this service are not verified yet.'),
        ],
        if (canStart)
          FilledButton(
            onPressed: () {
              if (accountRequired) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DemoSignInPage(),
                  ),
                );
              } else if (widget.onStartReport case final callback?) {
                Navigator.of(context).pop();
                callback();
              } else {
                setState(() => step = 0);
              }
            },
            child: Text(accountRequired ? 'Continue' : 'Start report'),
          ),
      ],
      if (step == 0) ...[
        heading(title),
        Text(
          'Example questions',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.6),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'These example questions illustrate the design. The live service may ask for more details.',
          ),
        ),
        input(
          title == 'Flooding'
              ? 'Where is water collecting?'
              : 'What needs attention?',
          description,
          (value) => description = value,
          maxLines: 4,
        ),
        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          value: extra,
          onChanged: (value) {
            setState(() {
              extra = value ?? false;
              reviewConsent = false;
            });
            save();
          },
          title: const Text('Add a useful extra detail'),
        ),
        if (extra)
          input('Extra detail', extraDetail, (value) => extraDetail = value),
      ],
      if (step == 1) ...[
        heading('Place it on the map.'),
        const Text(
          'Use an address or intersection. This sample pin stays in the preview.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            color: ReportsStyle.surface,
            child: SizedBox(
              height: 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    container: true,
                    label: 'Illustrative location pin, not a live map',
                    child: const Icon(Icons.location_on_outlined, size: 48),
                  ),
                  Text(boundary, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        input('Address or intersection', address, (value) {
          address = value;
          confirmed = false;
        }),
        input(
          'Nearby landmark (optional)',
          reference,
          (value) => reference = value,
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              confirmed = address.trim().isNotEmpty;
              reviewConsent = false;
            });
            save();
          },
          child: Text(confirmed ? 'Location confirmed' : 'Confirm sample pin'),
        ),
      ],
      if (step == 2) ...[
        heading('A little more context.'),
        Card(
          color: ReportsStyle.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.camera_alt_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  noPhotos
                      ? 'No photos are needed for this service.'
                      : evidence.contains('required attachments')
                      ? 'Photos are required for this service.'
                      : evidence.contains('optional attachments')
                      ? 'Photos are optional for this service.'
                      : 'Photo requirements are not confirmed.',
                  textAlign: TextAlign.center,
                ),
                if (!noPhotos)
                  const Text(
                    'Sample evidence previews the design only. No photo is uploaded.',
                    textAlign: TextAlign.center,
                  ),
                if (!noPhotos) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: photoLimit != null && photos >= photoLimit!
                        ? null
                        : () {
                            setState(() {
                              photos++;
                              reviewConsent = false;
                            });
                            save();
                          },
                    child: const Text('Add sample evidence'),
                  ),
                ],
                if (photos > 0) ...[
                  Text('$photos sample evidence'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        photos--;
                        reviewConsent = false;
                      });
                      save();
                    },
                    child: const Text('Remove sample evidence'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      if (step == 3) ...[
        heading('How should we reach you?'),
        const Text(
          'Choose how to provide contact information for this local preview.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: contactChoices(),
        ),
        if ((named == true || contactRequired) && !contactLoaded)
          const CircularProgressIndicator()
        else if (named == true || contactRequired) ...[
          input('First name', firstName, (value) => firstName = value),
          input('Last name', lastName, (value) => lastName = value),
          input('Email', email, (value) => email = value),
          input('Phone (optional)', phone, (value) => phone = value),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: updates,
            onChanged: (value) {
              if (advancing) return;
              setState(() {
                updates = value ?? false;
                reviewConsent = false;
              });
              save();
            },
            title: const Text('Preview email updates'),
            subtitle: const Text('Local preference only. No email is sent.'),
          ),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: remember,
            onChanged: (value) {
              if (advancing) return;
              setState(() => remember = value ?? false);
            },
            title: const Text('Remember contact on this device'),
          ),
        ],
      ],
      if (step == 4) ...[
        heading('One last look.'),
        const Text('This preview is local and will not be sent to the City.'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in [
                    reviewEntry('Service', [title]),
                    reviewEntry('Details', [
                      description,
                      if (extra) extraDetail,
                    ]),
                    reviewEntry('Location', [
                      address,
                      if (reference.isNotEmpty) reference,
                    ]),
                    reviewEntry('Evidence', ['$photos sample evidence']),
                    reviewEntry('Contact', [
                      named == true || contactRequired
                          ? '$firstName $lastName · $email${phone.isEmpty ? '' : ' · $phone'}'
                          : 'Anonymous',
                    ]),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: entry,
                    ),
                ],
              ),
            ),
          ),
        ),
        CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          value: reviewConsent,
          onChanged: (value) {
            setState(() => reviewConsent = value ?? false);
            save();
          },
          title: const Text(
            'I understand this creates a local demo receipt. Nothing is sent to the City.',
          ),
        ),
      ],
      if (step == 5) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: Color(0xff18703a),
                ),
                const SizedBox(height: 16),
                heading('Local receipt'),
                const SizedBox(height: 12),
                const Text('Local lookup ID'),
                Text(id, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text('This preview was not sent to the City.'),
                Text(title),
              ],
            ),
          ),
        ),
      ],
      if (error.isNotEmpty)
        Semantics(
          key: validationErrorKey,
          container: true,
          liveRegion: true,
          child: Text(error),
        ),
      if (!stored)
        const Text(
          'Local saving is unavailable. Your preview remains in this session.',
        ),
    ];
    final page = Scaffold(
      appBar: AppBar(
        leading: step > 0 && step < 5 ? BackButton(onPressed: backStep) : null,
        titleTextStyle: step >= 0 && step < 5
            ? const TextStyle(
                color: ReportsStyle.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              )
            : null,
        title: Text(step >= 0 && step < 5 ? 'New report' : 'Services'),
        actions: [
          if (step >= 0)
            TextButton(
              style: step < 5
                  ? TextButton.styleFrom(
                      foregroundColor: ReportsStyle.ink,
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(44, 44),
                    )
                  : null,
              onPressed: () async {
                if (advancing) return;
                final messenger = ScaffoldMessenger.of(context);
                final saved = await save();
                if (!context.mounted) return;
                Navigator.pop(context);
                if (!saved) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Preview could not be saved. It remains in this session.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save and close'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                if (step >= 0) ...[
                  Text(
                    'Step ${step + 1} of 6 · ${['Details', 'Location', 'Photos', 'Contact', 'Review', 'Receipt'][step]}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (step + 1) / 6,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    semanticsLabel: 'Report progress',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    [
                      'DETAILS',
                      'LOCATION',
                      'PHOTOS',
                      'CONTACT',
                      'REVIEW',
                      'RECEIPT',
                    ][step],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: ReportsStyle.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                KeyedSubtree(
                  key: Key('preview-section-$step'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final child in content)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: step < 5
                                ? child is TextFormField
                                      ? 20
                                      : 12
                                : 16,
                          ),
                          child: child,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: step >= 0 && step < 5
          ? SafeArea(
              top: false,
              child: Container(
                key: const Key('preview-action-footer'),
                padding: EdgeInsets.fromLTRB(
                  20,
                  13,
                  20,
                  12 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: ReportsStyle.border, width: 2),
                  ),
                ),
                child: FilledButton(
                  onPressed: advancing ? null : advance,
                  child: Text(step == 4 ? 'Create local receipt' : 'Continue'),
                ),
              ),
            )
          : null,
    );
    final theme = Theme.of(context);
    return Theme(
      data: step < 5
          ? theme.copyWith(
              textTheme: theme.textTheme.copyWith(
                bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            )
          : theme,
      child: PopScope<Object?>(
        canPop: !advancing,
        child: AbsorbPointer(absorbing: advancing, child: page),
      ),
    );
  }
}
