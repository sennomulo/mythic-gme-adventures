import 'package:flutter/material.dart';

import '../../helpers/utils.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import '../threads/thread.dart';
import '../threads/thread_discovery_lookup_view.dart';
import 'fate_chart.dart';

class FateChartLookupView extends StatelessWidget {
  final Probability probability;
  final FateChartOutcomeProbability outcomeProbability;
  final Thread? thread;

  const FateChartLookupView({
    required this.probability,
    required this.outcomeProbability,
    this.thread,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget additionalContent;
    if (thread != null) {
      additionalContent = TextButton(
        onPressed: () {
          Navigator.pop(context);

          final content = ThreadDiscoveryLookupView(thread!);

          showAppModalBottomSheet<void>(context, content);
        },
        child: const Text('掷探索检定'),
      );
    } else {
      additionalContent = TextButton(
        onPressed: () {
          Navigator.pop(context);

          showRandomEventLookup(context);
        },
        child: const Text('掷随机事件'),
      );
    }

    return RollLookupView(
      header: probability.text,
      rollColors: AppStyles.fateChartColors,
      entries: [
        if (outcomeProbability.extremeYes > 0)
          RollLookupEntry(
            value: _getValueLabel(1, outcomeProbability.extremeYes),
            label: '非常肯定',
          ),
        RollLookupEntry(
          value: _getValueLabel(
            outcomeProbability.extremeYes + 1,
            outcomeProbability.threshold,
          ),
          label: '肯定',
        ),
        RollLookupEntry(
          value: _getValueLabel(
            outcomeProbability.threshold + 1,
            outcomeProbability.extremeNo - 1,
          ),
          label: '否定',
        ),
        if (outcomeProbability.extremeNo <= 100)
          RollLookupEntry(
            value: _getValueLabel(outcomeProbability.extremeNo, 100),
            label: '非常否定',
          ),
      ],
      additionalContent: additionalContent,
    );
  }

  String _getValueLabel(int low, int high) {
    return low == high ? low.toString() : '$low - $high';
  }
}
