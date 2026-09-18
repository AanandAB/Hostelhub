import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/document.dart';
import '../../data/models/user.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

const _docTypes = ['agreement', 'rules', 'id_proof', 'other'];

/// Document vault. Owners see hostel documents; inmates see hostel docs
/// (read-only) plus their own uploaded KYC documents.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) {
              final isOwner = user?.role == UserRole.owner;
              final propertyId = prop?.id ?? '';
              final inmateId = isOwner ? '' : (user?.id ?? '');
              return _content(context, ref, isOwner, propertyId, inmateId);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, bool isOwner,
      String propertyId, String inmateId) {
    final hostelDocs = propertyId.isEmpty
        ? const <Document>[]
        : ref.watch(documentsProvider(('hostel', propertyId))).value ??
            const <Document>[];
    final ownDocs = (!isOwner && inmateId.isNotEmpty)
        ? ref.watch(documentsProvider(('inmate', inmateId))).value ??
            const <Document>[]
        : const <Document>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _section(context, 'Hostel documents', hostelDocs, Icons.folder_rounded),
        if (!isOwner) ...[
          const SizedBox(height: 20),
          _section(context, 'My documents', ownDocs, Icons.person_rounded),
        ],
        const SizedBox(height: 16),
        GlassButton(
          label: isOwner ? 'Add hostel document' : 'Upload document',
          icon: Icons.add_rounded,
          onPressed: () => _addDialog(
              context, ref, isOwner ? 'hostel' : 'inmate',
              isOwner ? propertyId : inmateId),
        ),
      ],
    );
  }

  Widget _section(
      BuildContext context, String title, List<Document> docs, IconData icon) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text('No documents yet.', style: textTheme.bodySmall),
          )
        else
          for (final d in docs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: textTheme.bodyLarge),
                          if (d.uploadedAt != null)
                            Text(
                              'Uploaded ${d.uploadedAt!.substring(0, 10)}',
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(d.type,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  void _addDialog(BuildContext context, WidgetRef ref, String ownerType,
      String ownerId) {
    final controller = TextEditingController();
    String type = _docTypes.first;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Add document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Document name'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in _docTypes)
                    ChoiceChip(
                      label: Text(t),
                      selected: type == t,
                      onSelected: (_) => setState(() => type = t),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await ref.read(backendProvider).ops.createDocument(Document(
                      id: '',
                      ownerType: ownerType,
                      ownerId: ownerId,
                      name: name,
                      type: type,
                    ));
                ref.invalidate(documentsProvider((ownerType, ownerId)));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
