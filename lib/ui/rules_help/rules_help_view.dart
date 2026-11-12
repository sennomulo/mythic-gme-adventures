import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:formatted_text/formatted_text.dart';
import 'package:get/get.dart';

import '../chaos_factor/chaos_factor.dart';
import '../fate_chart/fate_chart.dart';
import '../widgets/responsive_dialog.dart';

class RulesHelpView extends HookWidget {
  static const title = '规则帮助';

  final RulesHelpEntry? initialEntry;

  const RulesHelpView({this.initialEntry, super.key});

  @override
  Widget build(BuildContext context) {
    final selectedEntry = useState(initialEntry ?? fateChartHelp);

    final scrollController = useScrollController();

    final String content;
    if (selectedEntry.value == fateChartHelp) {
      content = _getFateChartContent();
    } else {
      content = selectedEntry.value.content;
    }

    return ResponsiveDialog.withAppBar(
      title: title,
      childBuilder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // rule selection
          Center(
            child: DropdownMenu<RulesHelpEntry>(
              initialSelection: selectedEntry.value,
              enableFilter: false,
              enableSearch: false,
              onSelected: (value) {
                if (value != null) {
                  selectedEntry.value = value;

                  scrollController.jumpTo(0);
                }
              },
              dropdownMenuEntries:
                  [
                        fateChartHelp,
                        randomEventHelp,
                        scenesHelp,
                        threadProgressTrackHelp,
                      ]
                      .map(
                        (e) => DropdownMenuEntry<RulesHelpEntry>(
                          value: e,
                          label: e.label,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // rule content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: FormattedText(
                content,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Text(
              '* 本摘要仅供参考，可能存在错误。',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getFateChartContent() {
    final chaosFactor = Get.find<ChaosFactorService>().fateChartFactor.value;

    const probabilities = [
      Probability.certain,
      Probability.nearlyCertain,
      Probability.veryLikely,
      Probability.likely,
      Probability.fiftyFifty,
      Probability.unlikely,
      Probability.veryUnlikely,
      Probability.nearlyImpossible,
      Probability.impossible,
    ];

    final fateChartService = Get.find<FateChartService>();

    final probabilitiesBlock = probabilities
        .map((e) {
          final outcome = fateChartService.getOutcomeProbability(e);

          return '- _${e.text}:_ ${outcome.threshold}%';
        })
        .join('\n');

    return fateChartHelp.content
        .replaceFirst('{chaos_factor}', chaosFactor.toString())
        .replaceFirst('{probabilities_block}', probabilitiesBlock);
  }
}

class RulesHelpEntry {
  final String label;
  final String content;

  const RulesHelpEntry(this.label, this.content);
}

const fateChartHelp = RulesHelpEntry(
  '命运图表',
  '提出命运问题时，请将问题表述为“肯定”的答案会带来更多行动或危险的形式，'
      '然后评估该事件发生的可能性，并在命运图表上掷骰。'
      '\n'
      '\n命运问题的答案可以是：非常肯定、肯定、否定、非常否定。'
      '\n每种答案的概率取决于你选择的机率以及当前的混乱因子。'
      '混乱因子越高，概率就越向“肯定”倾斜。'
      '\n“非常”答案与普通答案相同，但被推到下一个逻辑层级。'
      '\n'
      '\n当前混乱因子为 {chaos_factor} 时，“肯定”或“非常肯定”的概率为：'
      '\n{probabilities_block}'
      '\n'
      '\n如果掷出对子（11、22、33…）且该数字小于等于当前混乱因子，将触发随机事件。',
);

const randomEventHelp = RulesHelpEntry(
  '随机事件',
  '随机事件可由命运图表掷骰中掷出对子，或由被中断的场景触发。'
      '\n'
      '\n解读一个事件需要：情境、焦点和含义：'
      '\n- 情境是冒险进行到此刻所发生的一切，连同命运问题或正在测试的场景。'
      '\n- 焦点通过随机事件焦点表掷出。'
      '\n- 含义通过意义表掷出（通常是“行动”或“描述”表），并可用命运问题进一步细化。'
      '\n'
      '\n各事件焦点的说明：'
      '\n- _遥远事件:_ 你的角色没有亲眼所见、刚刚才得知的某件事。'
      '该事件通常与已有的角色或线索相关。'
      '\n- _模糊事件:_ 发生了与当前场景没有直接关系的事情，'
      '既无害也无益，甚至可能暂时令人费解。'
      '你可以借此机会探究这个耐人寻味的新事件（提出命运问题），也可以先放下不管，它日后或许会再次浮现。'
      '\n- _新 NPC:_ 一个新的 NPC 进入冒险。'
      '它会在当前场景中发挥作用，场景结束后大概率会被加入角色列表。'
      '你可以掷意义表来充实它的设定。'
      '\n- _NPC 行动:_ 某个已有角色做出了影响冒险进程的举动。'
      '\n- _NPC/玩家角色负面或正面事件:_ 某个角色或玩家角色遭遇了好事或坏事。'
      '\n- _推进一条线索:_ 该事件让玩家角色向解决某条未决线索又迈进了一步。'
      '\n- _远离一条线索:_ 新的障碍或挫折阻碍了玩家角色关闭线索的进程。'
      '\n- _关闭一条线索:_ 该事件解决了某条线索，或以某种方式使其了结。'
      '\n- _当前情境:_ 焦点即命运问题的情境，或冒险中正在发生的事情。'
      '事件在此基础上叠加了新的一层。'
      '\n'
      '\n如果掷出的焦点与某个角色或线索相关，而对应列表为空，'
      '则改用“当前情境”作为焦点。',
);

const scenesHelp = RulesHelpEntry(
  '场景',
  '开始一个新场景时，先确定预期场景，然后针对新场景用混乱因子对其进行测试。'
      '混乱因子越高，场景越有可能不按预期发生，'
      '此时场景可能被变更，或成为中断场景。'
      '\n'
      '\n对于变更场景，你可以：'
      '\n- 切换到下一个最可能发生的场景。'
      '\n- 更改预期场景的任意元素（NPC、地点、行动等），必要时借助意义表。'
      '\n- 掷一次场景调整。如果结果与你的场景不符，就再掷一次。'
      '\n'
      '\n场景调整：'
      '\n- _移除一个角色:_ 选择最合理的角色，将其从预期场景中移除。'
      '\n- _增加一个角色:_ 从角色列表中选择最合理的 NPC，将其加入场景。'
      '\n- _减弱/移除一个活动:_ 减弱预期场景中某个活跃元素的强度，'
      '如果更合理也可以将其完全移除。'
      '\n- _增强一个活动:_ 增强预期场景中某个活动的强度。'
      '\n- _移除一个物品:_ 从预期场景中移除一件重要物品，选择最合理的那件。'
      '\n- _增加一个物品:_ 向预期场景中加入一件重要物品。'
      '如果一时想不出合理的物品，可以掷意义表寻找灵感。'
      '\n- _进行两次调整:_ 对预期场景进行两次调整而非一次，'
      '在场景调整表上反复掷骰，直到确定两项调整。'
      '如果再次掷出该结果，直接忽略并重掷。'
      '如果两次结果互相冲突，忽略第二次，只采用第一次。'
      '\n'
      '\n对于中断场景，掷一次随机事件，创造一个全新的场景。'
      '\n'
      '\n场景结束时：'
      '\n1. 为场景中活跃且重要的角色或线索的列表计数加一（但不要超过 3）。'
      '\n2. 将任何新出现的角色或线索加入其列表。'
      '\n3. 将不再与冒险相关的角色或线索从其列表中移除。'
      '\n4. 更新混乱因子：若玩家角色在场景中占据主导，减 1；否则加 1。',
);

const threadProgressTrackHelp = RulesHelpEntry(
  '线索进度跟踪器',
  '进度跟踪器以 5 个进度点为一个阶段进行划分。'
      '每个阶段必须发生一次闪点，才能进入下一阶段。'
      '\n闪点是涉及所跟踪线索的戏剧性或重要事件。'
      '\n场景结束时，如果玩家角色向解决该线索明显迈进了一步，标记 +2 进度。'
      '你也可以在场景进行中标记进度，这可能触发一次闪点事件，应立即予以解决。'
      '\n闪点在正常游戏过程中发生时，标记 +2 进度，并为当前阶段标记一次闪点。'
      '该阶段不会再出现新的闪点。'
      '\n如果一个阶段结束时闪点尚未发生，则触发一次闪点事件：'
      '将其视为以“当前情境”为焦点的随机事件。'
      '它会涉及该线索，但不会将其完全解决。'
      '\n'
      '\n当你想不出如何推进某条线索时，可以进行一次探索检定：'
      '想出一个可能推动线索前进的玩家角色行动，'
      '掷一次命运问题来判断该行动是否有效，并按以下方式解读结果：'
      '\n- _肯定:_ 在线索探索检定表上掷骰。'
      '\n- _否定:_ 一无所获。不在线索探索检定表上掷骰。'
      '\n- _非常肯定:_ 在线索探索检定表上掷两次，合并结果。'
      '\n- _非常否定:_ 与否定相同，并且在本场景余下时间内不能再进行探索检定。'
      '\n'
      '\n使用意义表来解读线索探索检定表的结果。'
      '\n'
      '\n线索探索检定表结果：'
      '\n- _进度 +2/+3:_ 你发现了让你更接近焦点线索的东西，获得 2 或 3 个进度点。'
      '\n- _闪点 +2/+3:_ 你发现了以重要且富有戏剧性的方式涉及焦点线索的东西，'
      '并在此过程中获得 2 或 3 个进度点。'
      '\n- _推进 +1/+2:_ 你一无所获，'
      '但尝试本身让你在线索进度跟踪器上前进 1 或 2 点。'
      '\n- _巩固进度 +1/+2:_ 此前取得的部分进度得到强化，让你获得 1 或 2 个进度点。'
      '\n'
      '\n被跟踪的线索在到达终点（最后一个进度点）之前无法关闭。'
      '\n将终点视为一次闪点。'
      '\n如果终点将在新场景中到来，不要测试该场景，它将按预期发生。',
);
