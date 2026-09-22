import 'package:file_picker/file_picker.dart';
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
        _section(context, ref, 'Hostel documents', hostelDocs,
            Icons.folder_rounded, 'hostel', propertyId),
        if (!isOwner) ...[
          const SizedBox(height: 20),
          _section(context, ref, 'My documents', ownDocs, Icons.person_rounded,
              'inmate', inmateId),
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

  Widget _section(BuildContext context, WidgetRef ref, String title,
      List<Document> docs, IconData icon, String ownerType, String ownerId) {
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
                          Text(d.type, style: textTheme.bodySmall),
                          if (d.uploadedAt != null)
                            Text(
                              'Uploaded ${d.uploadedAt!.substring(0, 10)}',
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          size: 20, color: AppColors.accent),
                      onPressed: () => _editDialog(
                          context, ref, d, ownerType, ownerId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.danger),
                      onPressed: () => _deleteDoc(
                          context, ref, d, ownerType, ownerId),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _deleteDoc(BuildContext context, WidgetRef ref, Document d,
      String ownerType, String ownerId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Delete "${d.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(backendProvider).ops.deleteDocument(d.id);
    ref.invalidate(documentsProvider((ownerType, ownerId)));
  }

  void _editDialog(BuildContext context, WidgetRef ref, Document d,
      String ownerType, String ownerId) {
    final controller = TextEditingController(text: d.name);
    String type = d.type;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Edit document'),
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
                await ref.read(backendProvider).ops.updateDocument(d.id,
                    name: name, type: type);
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

  void _addDialog(BuildContext context, WidgetRef ref, String ownerType,
      String ownerId) {
    final controller = TextEditingController();
    String type = _docTypes.first;
    String? filePath;
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                    filePath == null ? 'Pick file (optional)' : 'File selected'),
                onPressed: () async {
                  final file = await FilePicker.pickFile();
                  if (file != null) {
                    setState(() {
                      filePath = file.path;
                      if (controller.text.trim().isEmpty) {
                        controller.text = file.name;
                      }
                    });
                  }
                },
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
                      fileUrl: filePath,
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
