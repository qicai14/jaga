import '../../data/models/stage.dart';
import 'gen/app_localizations.dart';

extension StageLabels on Stage {
  /// 1..6 for pretext..money; `money` and `credentials` tie at 6 (GLOSSARY). 0 for none.
  int get step => this == Stage.credentials ? Stage.money.index : index;

  /// Plain-word label; empty for [Stage.none].
  String label(AppLocalizations l) => switch (this) {
    Stage.none => '',
    Stage.pretext => l.stageLabelPretext,
    Stage.authority => l.stageLabelAuthority,
    Stage.fear => l.stageLabelFear,
    Stage.isolation => l.stageLabelIsolation,
    Stage.handoff => l.stageLabelHandoff,
    Stage.money => l.stageLabelMoney,
    Stage.credentials => l.stageLabelCredentials,
  };
}
