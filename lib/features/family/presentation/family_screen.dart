import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../application/family_controller.dart';
import '../domain/family_member.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  Future<void> _openEditor(BuildContext context, {FamilyMember? member}) async {
    final controller = FamilyScope.read(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FamilyEditorSheet(
        member: member,
        onSave: ({required nickname, required relationship}) async {
          if (member == null) {
            await controller.add(
              nickname: nickname,
              relationship: relationship,
            );
          } else {
            await controller.updateDetails(
              id: member.id,
              nickname: nickname,
              relationship: relationship,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FamilyScope.watch(context);
    final members = controller.members;
    return Scaffold(
      key: const ValueKey('familyScreen'),
      extendBody: true,
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s4,
              StevSpace.s5,
              128,
            ),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: StevLogo(markSize: 30),
              ),
              const SizedBox(height: StevSpace.s7),
              Row(
                children: [
                  Expanded(child: Text('Keluarga', style: StevType.title)),
                  StevButton(
                    key: const ValueKey('addFamilyMember'),
                    label: 'Tambah',
                    expand: false,
                    height: StevSize.tapMin,
                    variant: StevButtonVariant.leaf,
                    onPressed: () => _openEditor(context),
                  ),
                ],
              ),
              const SizedBox(height: StevSpace.s2),
              Text(
                'Pantau langkah pendampingan tanpa menyimpan jawaban atau data kesehatan.',
                style: StevType.body.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s6),
              if (members.isEmpty)
                _EmptyFamily(onAdd: () => _openEditor(context))
              else
                for (var index = 0; index < members.length; index++) ...[
                  if (index > 0) const SizedBox(height: StevSpace.s3),
                  _FamilyMemberCard(
                    member: members[index],
                    onEdit: () => _openEditor(context, member: members[index]),
                    onStatusChanged: (status) =>
                        controller.updateStatus(members[index].id, status),
                    onRemove: () => controller.remove(members[index].id),
                    onAssess: () =>
                        context.push('/risk', extra: members[index].id),
                  ),
                ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.family,
        onHome: () => context.go('/'),
        onFamily: () {},
        onScan: () => context.push('/scan'),
        onWeekly: () => context.go('/weekly'),
      ),
    );
  }
}

typedef _SaveFamilyMember = Future<void> Function({
  required String nickname,
  required String relationship,
});

class _FamilyEditorSheet extends StatefulWidget {
  const _FamilyEditorSheet({required this.member, required this.onSave});

  final FamilyMember? member;
  final _SaveFamilyMember onSave;

  @override
  State<_FamilyEditorSheet> createState() => _FamilyEditorSheetState();
}

class _FamilyEditorSheetState extends State<_FamilyEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.nickname);
    _relationshipController = TextEditingController(
      text: widget.member?.relationship,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _relationshipController.text.trim().isEmpty) {
      return;
    }
    await widget.onSave(
      nickname: _nameController.text,
      relationship: _relationshipController.text,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            StevSpace.s5,
            StevSpace.s6,
            StevSpace.s5,
            StevSpace.s6 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: StevColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(StevRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.member == null ? 'Tambah anggota' : 'Edit anggota',
                style: StevType.heading,
              ),
              const SizedBox(height: StevSpace.s5),
              TextField(
                key: const ValueKey('familyNameField'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama panggilan',
                  hintText: 'Contoh: Ibu',
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              TextField(
                key: const ValueKey('familyRelationshipField'),
                controller: _relationshipController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Hubungan keluarga',
                  hintText: 'Contoh: Orang tua',
                ),
              ),
              const SizedBox(height: StevSpace.s5),
              StevButton(
                key: const ValueKey('saveFamilyMember'),
                label: 'Simpan',
                variant: StevButtonVariant.leaf,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const ValueKey('emptyFamilyState'),
      child: Column(
        children: [
          const StevMascot(mood: StevMood.happy),
          const SizedBox(height: StevSpace.s4),
          Text('Belum ada anggota', style: StevType.heading),
          const SizedBox(height: StevSpace.s2),
          Text(
            'Tambahkan orang yang ingin kamu dampingi untuk cek kesehatan.',
            textAlign: TextAlign.center,
            style: StevType.body.copyWith(color: StevColors.ink2),
          ),
          const SizedBox(height: StevSpace.s5),
          StevButton(
            label: 'Tambah anggota',
            variant: StevButtonVariant.leaf,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.onEdit,
    required this.onStatusChanged,
    required this.onRemove,
    required this.onAssess,
  });

  final FamilyMember member;
  final VoidCallback onEdit;
  final ValueChanged<FamilyProgressStatus> onStatusChanged;
  final VoidCallback onRemove;
  final VoidCallback onAssess;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: ValueKey('familyMember-${member.id}'),
      padding: const EdgeInsets.all(StevSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.nickname, style: StevType.heading),
                    Text(
                      member.relationship,
                      style: StevType.caption.copyWith(color: StevColors.ink2),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('editFamilyMember-${member.id}'),
                tooltip: 'Edit ${member.nickname}',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: ValueKey('removeFamilyMember-${member.id}'),
                tooltip: 'Hapus ${member.nickname}',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: StevSpace.s3),
          DropdownButtonFormField<FamilyProgressStatus>(
            key: ValueKey('familyStatus-${member.id}'),
            initialValue: member.status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final status in FamilyProgressStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (status) {
              if (status != null) onStatusChanged(status);
            },
          ),
          const SizedBox(height: StevSpace.s4),
          StevButton(
            key: ValueKey('assessFamilyMember-${member.id}'),
            label: 'Cek risiko',
            variant: StevButtonVariant.card,
            onPressed: onAssess,
          ),
        ],
      ),
    );
  }
}
