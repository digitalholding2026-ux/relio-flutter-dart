/// Fiche d'aide structurée — modèle de données du « Bottom Sheet ».
///
/// CONTRAT AVEC LE MOTEUR, PAS UNE MESURE D'INTERFACE.
///
/// L'interface ne CALCULE rien : elle consomme des [RichHint] construites par
/// le cœur. Cette fichier ne décrit que la FORME que le cœur devra produire,
/// sans jamais inventer le contenu pédagogique qui y sera versé (règle 8).
///
/// Trois hypothèses de conception :
///
///  1. **Aucun contenu ici.** Les blocs sont des contenants vides tant que le
///     cœur ne les remplit pas. Le texte validé du chapitre 1 est aujourd'hui
///     constitué de phrases simples : le dérivateur mécanique
///     (`rich_hint_adapter.dart`) le verse en [TextBlock], et rien de plus.
///
///  2. **Un contenu absent est un contenu absent.** Un bloc ne porte jamais de
///     texte de repli rédigé ici : `[HintBlock.text]` est non nullable, donc
///     une fiche ne peut pas Mentir sur son contenu.
///
///  3. **Le budget est séparé des fiches.** [RichHint] décrit CE QUE l'on
///     montre ; le nombre de fiches que l'élève a le droit de consommer est
///     une décision du moteur, portée par `HintBudget`.
library;

/// Un fragment de fiche d'aide.
///
/// SEALED : la liste des natures de bloc est fermée par le compilateur. Ajouter
/// une nature oblige alors à traiter le nouveau cas partout — ce qui est
/// exactement ce qu'on veut d'un contenu pédagogique.
sealed class HintBlock {
  const HintBlock();

  /// Texte du bloc, tel que rédigé par le cœur.
  String get text;
}

/// Explication en Body 16 / Regular.
///
/// Le bloc par défaut : une phrase, une consigne, une justification.

class TextBlock extends HintBlock {
  const TextBlock(this.text);

  @override
  final String text;

  @override
  String toString() => 'TextBlock("$text")';
}

/// Formule, égalité ou calcul.
///
/// Rendu dans un encadré gris, par le formateur mathématique existant : les
/// variables isolées passent en italique, les chiffres en tabulaire.

class MathBlock extends HintBlock {
  const MathBlock(this.text);

  @override
  final String text;

  @override
  String toString() => 'MathBlock("$text")';
}

/// Point à retenir — le « bilan » de l'étape.
///
/// Rendu sur fond orange pâle, liseré orange à gauche : c'est ce que l'élève
/// doit conserver en sortant de la fiche.

class HighlightBlock extends HintBlock {
  const HighlightBlock(this.text);

  @override
  final String text;

  @override
  String toString() => 'HighlightBlock("$text")';
}

/// Retour vers l'élève : une question, une invitation à répondre.
///
/// VOLONTAIREMENT TRÈS VISUEL (indigo gras, séparé par un filet) : c'est le
/// seul bloc qui attend une ACTION de l'élève, pas une lecture.

class HandoffBlock extends HintBlock {
  const HandoffBlock(this.text);

  @override
  final String text;

  @override
  String toString() => 'HandoffBlock("$text")';
}

/// Une fiche d'aide complète, affichée dans une [RichHintSheet].
///
/// Ce que le cœur fournit, et que l'interface se contente de rendre :
///  - [title] : l'intitulé de la fiche ;
///  - [blocks] : les fragments, dans l'ordre de lecture ;
///  - [isFinal] : signale qu'il s'agit du DERNIER indice du budget.

class RichHint {
  const RichHint({
    required this.order,
    required this.title,
    required this.blocks,
    this.isFinal = false,
  });

  /// Rang de l'indice, à partir de 1.
  ///
  /// Reprend [ExerciseHint.order] : les rangs ne sont jamais réattribués, ils
  /// sont référencés par l'historique d'apprentissage.
  final int order;

  /// Intitulé de la fiche.
  ///
  /// EXEMPLES DE VALEUR ATTENDUE (fournis par le cœur, jamais générés ici) :
  ///   « 💡 Comprendre cette étape »   — indice d'étape
  ///   « 💡 Pour aller plus loin »    — indice de prolongement
  final String title;

  /// Fragments de la fiche, dans l'ordre de lecture.
  final List<HintBlock> blocks;

  /// Vrai si ce hint est le dernier que le budget autorise.
  final bool isFinal;

  /// Les blocs, en texte simple : la fiche réduite à son contenu.
  ///
  /// N'ajoute aucun mot et n'en retire aucun — c'est la concaténation des
  /// blocs dans l'ordre de lecture. Sert à l'historique et aux rendus de
  /// résumé ; n'est jamais la source d'un affichage enrichi, pour lequel la
  /// liste de blocs reste seule faisant foi.
  String get plainText =>
      blocks.map((block) => block.text).join(' ').trim();

  /// Même fiche, avec un [isFinal] différent.
  ///
  /// `isFinal` n'est JAMAIS saisi dans la banque : il se déduit du budget, qui
  /// ne dépend pas du contenu mais de la position dans la leçon. La copie
  /// permet à l'adaptateur de l'appliquer sans que la banque ait à le
  /// deviner — et sans réécrire un seul mot du contenu.
  RichHint withIsFinal(bool value) => RichHint(
        order: order,
        title: title,
        blocks: blocks,
        isFinal: value,
      );

  /// Identifiant stable, dérivé du rang.
  ///
  /// Même convention que [ExerciseHint.hintId] (`h<rang>`) : les deux
  /// représentations d'un même indice restent donc joignables dans
  /// l'historique.
  String get hintId => 'h$order';

  @override
  String toString() => 'RichHint(#$order, $title, ${blocks.length} blocs)';
}

/// Ce que le bouton d'aide doit afficher.
///
/// DÉDUIT du budget, jamais demandé à l'élève ni à l'écran : c'est une
/// énumération fermée pour que l'interface ne puisse pas inventer un état
/// intermédiaire.
enum HintCta {
  /// Budget intact : « Demander un indice ».
  askFirst,

  /// Des fiches restent : « Indice suivant ».
  next,

  /// La prochaine fiche sera la DERNIÈRE : « Indice final ».
  finalOne,

  /// Budget épuisé, un exercice précédent existe : « Revoir l'exercice N ».
  reviewPrevious,

  /// Budget épuisé, aucun exercice précédent : le bouton disparaît.
  none,
}

/// Budget d'aide d'un exercice.
///
/// PORTÉ PAR LE MOTEUR, PAS CALCULÉ PAR L'ÉCRAN.
///
/// L'interface lit ce budget et en déduit le libellé du bouton. Elle ne
/// décompte rien elle-même : c'est le cœur qui, après avoir enregistré une
/// consultation, fournit le nouveau [hintsConsumed].

class HintBudget {
  const HintBudget({
    required this.maxHintsAllowed,
    required this.hintsConsumed,
    this.previousExerciseId,
  });

  /// Combien de fiches l'élève a le droit d'ouvrir sur cet exercice.
  final int maxHintsAllowed;

  /// Combien de fiches ont déjà été ouvertes.
  final int hintsConsumed;

  /// Exercice de référence consultable une fois le budget épuisé, ou `null`.
  final String? previousExerciseId;

  /// Combien de fiches restent.
  ///
  /// Jamais négatif : au-delà de [maxHintsAllowed], le budget est considéré
  /// épuisé.
  int get remaining =>
      (maxHintsAllowed - hintsConsumed).clamp(0, maxHintsAllowed);

  /// Budget épuisé ?
  bool get isExhausted => hintsConsumed >= maxHintsAllowed;

  /// Libellé du bouton, déduit de la seule position dans le budget.
  ///
  /// Les quatre cas sont exclusifs et couvrent tout l'espace :
  ///  - [hintsConsumed] nul → [HintCta.askFirst] ;
  ///  - il en reste plus d'une → [HintCta.next] ;
  ///  - il en reste exactement une → [HintCta.finalOne] ;
  ///  - il n'en reste aucune → [HintCta.reviewPrevious] ou [HintCta.none].
  HintCta get cta {
    if (isExhausted) {
      return previousExerciseId == null
          ? HintCta.none
          : HintCta.reviewPrevious;
    }
    if (hintsConsumed == 0) return HintCta.askFirst;
    return remaining == 1 ? HintCta.finalOne : HintCta.next;
  }

  @override
  String toString() =>
      'HintBudget($hintsConsumed/$maxHintsAllowed, cta=${cta.name})';
}
