import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../family/application/family_controller.dart';
import '../../family/domain/family_member.dart';
import '../data/risk_reminder_scheduler.dart';
import '../domain/risk_assessment.dart';

typedef RiskMessageSharer = Future<void> Function(
  String message,
  Rect? sharePositionOrigin,
);

class RiskInviteScreen extends StatefulWidget {
  const RiskInviteScreen({
    super.key,
    required this.subject,
    this.shareMessage,
    this.reminderScheduler,
    this.familyMemberId,
  });

  static const defaultMessage =
      'Bu/Pak, aku habis cek risiko diabetes lewat Stev.AI. Yuk kita cek gula darah gratis di Puskesmas.';

  final RiskSubject subject;
  final RiskMessageSharer? shareMessage;
  final RiskReminderScheduler? reminderScheduler;
  final String? familyMemberId;

  @override
  State<RiskInviteScreen> createState() => _RiskInviteScreenState();
}

class _RiskInviteScreenState extends State<RiskInviteScreen> {
  late final TextEditingController _messageController;
  var _remindInSevenDays = false;
  var _updatingReminder = false;
  var _sharing = false;

  RiskReminderScheduler get _reminderScheduler =>
      widget.reminderScheduler ?? LocalRiskReminderScheduler.instance;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: RiskInviteScreen.defaultMessage,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _share(BuildContext buttonContext) async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sharing) return;

    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);

    try {
      final customShare = widget.shareMessage;
      if (customShare != null) {
        await customShare(message, origin);
      } else {
        await SharePlus.instance.share(
          ShareParams(text: message, sharePositionOrigin: origin),
        );
      }
      if (!mounted) return;
      if (widget.familyMemberId case final memberId?) {
        await FamilyScope.read(context)
            .updateStatus(memberId, FamilyProgressStatus.invited);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan belum dapat dibagikan. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _updateReminder(bool enabled) async {
    if (_updatingReminder) return;
    setState(() => _updatingReminder = true);

    if (!enabled) {
      await _reminderScheduler.cancelReminder();
      if (mounted) {
        setState(() {
          _remindInSevenDays = false;
          _updatingReminder = false;
        });
      }
      return;
    }

    final status = await _reminderScheduler.scheduleSevenDayReminder();
    if (!mounted) return;
    setState(() {
      _remindInSevenDays = status == RiskReminderScheduleStatus.scheduled;
      _updatingReminder = false;
    });
    if (status != RiskReminderScheduleStatus.scheduled) {
      final message = switch (status) {
        RiskReminderScheduleStatus.denied =>
          'Izinkan notifikasi agar Stev.AI dapat mengingatkanmu.',
        RiskReminderScheduleStatus.unsupported =>
          'Pengingat terjadwal tersedia di aplikasi Android.',
        RiskReminderScheduleStatus.failed =>
          'Pengingat belum dapat dijadwalkan. Coba lagi.',
        RiskReminderScheduleStatus.scheduled => '',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('riskInviteScreen'),
      body: AuraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StevSpace.s5,
                  StevSpace.s3,
                  StevSpace.s5,
                  0,
                ),
                child: Row(
                  children: [
                    StevIconButton(
                      icon: const StevIcon(StevIconName.back),
                      label: 'Kembali',
                      onPressed: context.pop,
                    ),
                    Expanded(
                      child: Text(
                        'Ajak & Rujukan',
                        textAlign: TextAlign.center,
                        style: StevType.heading,
                      ),
                    ),
                    const SizedBox(width: StevSize.roundButton),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    StevSpace.s5,
                    StevSpace.s6,
                    StevSpace.s5,
                    StevSpace.s6,
                  ),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pesan buat Ibu/Bapak', style: StevType.heading),
                          const SizedBox(height: StevSpace.s4),
                          TextField(
                            key: const ValueKey('riskInviteMessage'),
                            controller: _messageController,
                            minLines: 4,
                            maxLines: 7,
                            maxLength: 400,
                            style: StevType.body,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: StevColors.card,
                              hintText: 'Tulis pesan ajakan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  StevRadius.small,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: StevSpace.s3),
                          Builder(
                            builder: (buttonContext) => StevButton(
                              key: const ValueKey('shareRiskMessage'),
                              label: _sharing
                                  ? 'Membuka pilihan...'
                                  : 'Bagikan ke WhatsApp',
                              variant: StevButtonVariant.leaf,
                              onPressed: _sharing
                                  ? null
                                  : () => _share(buttonContext),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StevSpace.s4),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cek Kesehatan Gratis (Kemenkes)',
                            style: StevType.heading,
                          ),
                          const SizedBox(height: StevSpace.s4),
                          const _InfoRow(
                            label: 'Siapa yang berhak',
                            value: 'Dewasa 18+',
                          ),
                          const _InfoRow(
                            label: 'Di mana',
                            value: 'Puskesmas terdekat',
                          ),
                          const _InfoRow(
                            label: 'Apa yang dicek',
                            value: 'Termasuk gula darah',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StevSpace.s4),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StevSpace.s5,
                        vertical: StevSpace.s4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ingatkan aku dalam 7 hari',
                              style: StevType.label,
                            ),
                          ),
                          const SizedBox(width: StevSpace.s3),
                          Switch.adaptive(
                            key: const ValueKey('riskReminderSwitch'),
                            value: _remindInSevenDays,
                            activeTrackColor: StevColors.leaf,
                            onChanged: _updatingReminder
                                ? null
                                : _updateReminder,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StevSpace.s5),
                    StevButton(
                      label: 'Selesai',
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StevSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: StevType.caption.copyWith(color: StevColors.ink2),
            ),
          ),
          const SizedBox(width: StevSpace.s3),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: StevType.body),
          ),
        ],
      ),
    );
  }
}
