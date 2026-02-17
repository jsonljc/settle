import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/v2_enums.dart';
import '../../providers/regulation_events_provider.dart';
import '../../theme/settle_tokens.dart';
import 'step_acknowledge.dart';
import 'step_action.dart';
import 'step_breathe.dart';
import 'step_reframe.dart';
import 'step_repair.dart';

/// Multi-step parent regulation flow: Acknowledge → Breathe → Reframe (optional) → Action → Repair (optional).
/// Creates [RegulationEvent] on completion.
class RegulateFlowScreen extends ConsumerStatefulWidget {
  const RegulateFlowScreen({super.key});

  @override
  ConsumerState<RegulateFlowScreen> createState() => _RegulateFlowScreenState();
}

class _RegulateFlowScreenState extends ConsumerState<RegulateFlowScreen> {
  int _step = 0;
  RegulationTrigger? _trigger;
  DateTime? _breatheStartTime;

  void _onAcknowledgeNext() {
    setState(() {
      _step = 1;
      _breatheStartTime = DateTime.now();
    });
  }

  void _onBreatheComplete() {
    setState(() {
      final skipReframe = _trigger == RegulationTrigger.needMinute;
      _step = skipReframe ? 3 : 2; // 2 = reframe, 3 = action
    });
  }

  void _onReframeNext() {
    setState(() => _step = 3);
  }

  void _onActionNext() {
    setState(() {
      if (_trigger == RegulationTrigger.alreadyYelled) {
        _step = 4;
      } else {
        _finish();
      }
    });
  }

  void _onRepairDone() {
    _finish();
  }

  Future<void> _finish() async {
    final trigger = _trigger;
    if (trigger != null) {
      final durationSeconds = _breatheStartTime != null
          ? DateTime.now().difference(_breatheStartTime!).inSeconds
          : 0;
      await ref.read(regulationEventsProvider.notifier).log(
            trigger: trigger,
            completed: true,
            durationSeconds: durationSeconds,
          );
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.pal.focusBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: T.space.screen),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/plan');
                    }
                  },
                  child: Text(
                    'back',
                    style: T.type.caption.copyWith(color: T.pal.textTertiary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return RegulateStepAcknowledge(
          selectedTrigger: _trigger,
          onSelect: (t) => setState(() => _trigger = t),
          onNext: _onAcknowledgeNext,
        );
      case 1:
        return RegulateStepBreathe(onComplete: _onBreatheComplete);
      case 2:
        return RegulateStepReframe(onNext: _onReframeNext);
      case 3:
        return RegulateStepAction(onNext: _onActionNext);
      case 4:
        return RegulateStepRepair(onDone: _onRepairDone);
      default:
        return const SizedBox.shrink();
    }
  }
}
