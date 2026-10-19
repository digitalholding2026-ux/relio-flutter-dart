/// Dérivation mécanique : [ExerciseHint] → [RichHint].
///
/// RÈGLE 8 — AUCUN CONTENU INVENTÉ, ICI NI AILLEURS.
///
/// Ce fichier sert deux fonctions distinctes, et n'en invente aucune :
///
///  1. il lit les fiches DÉFINITIVES que la banque a désormais déclarées
///     ([Exercise.richHints]) et les rend telles quelles ;
///  2. pour les exercices qui n'en ont pas encore, il traduit l'existant,
///     à l'identique, vers la nouvelle forme d'affichage.
///
/// La deuxième fonction est transitoire : elle disparaîtra quand les fiches
/// définitives couvriront toute la banque.
///
/// Il ne reformule aucun mot, n'ajoute aucun texte de repli, ne complète
/// aucune fiche. Une [ExerciseHint] dont le texte est vide produit une fiche
/// vide — jamais une fiche qui dirait autre chose que la source.
///
/// La seule exception est [ExerciseHint.asRichHint], qui décide QUEL TYPE de
/// bloc porter le texte, sur un critère purement FORMEL :
///
///  - le texte contient-il une notation mathématique (opérateur, égalité,
///    nombres reliés) ? → [MathBlock], rendu dans l'encadré gris et passé au
///    formateur mathématique ;
///  - sinon → [TextBlock], rendu en corps de texte.
///
/// Ce choix porte sur la MISE EN FORME, pas sur le fond : les mots affichés
/// sont exactement ceux de la source, dans les deux cas.
library;

import 'exercise.dart';
import 'rich_hint.dart';

/// Dérivation d'une fiche d'aide depuis une [ExerciseHint] existante.
///
/// Extension, et non méthode de [ExerciseHint] : le modèle de la banque ne
/// doit pas dépendre de la représentation d'affichage.
extension ExerciseHintRichAdapter on ExerciseHint {
  /// La fiche correspondante, liste de blocs comprise.
  ///
  /// [title] est le libellé de RANG — « Indice 1 », « Indice 2 »… — repris
  /// de l'affichage actuel. Il ne contient aucun contenu pédagogique : c'est un
  /// numéro, pas une explication.
  RichHint asRichHint({bool isFinal = false}) => RichHint(
        order: order,
        title: 'Indice $order',
        blocks: <HintBlock>[blockFor(text)],
        isFinal: isFinal,
      );
}

/// Choisit le type de bloc portant [text], sans le modifier.
///
/// CRITÈRE STRICT, volontairement conservatoire : on ne reconnaît un bloc
/// mathématique que si le texte contient réellement une RELATION — un
/// opérateur, une égalité, ou deux nombres qui s'enchaînent.
///
/// Un texte qui contient simplement un nombre isolé (« prends 18 ») reste un
/// [TextBlock] : le nombre y est une DONNÉE, pas un calcul, et l'encadré
/// mathématique dirait à tort « voici la formule ».
HintBlock blockFor(String text) =>
    looksMathematical(text) ? MathBlock(text) : TextBlock(text);

/// Le texte porte-t-il une notation mathématique ?
///
/// Fonction pure et testable : aucun mot n'est réécrit, aucun cas n'est
/// inventé. Les seuls marqueurs reconnus sont ceux que le formateur
/// mathématique sait déjà traiter (`MathText`).
bool looksMathematical(String text) {
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    // Opérateurs et égalité : la notation se déclare elle-même.
    if (c == '=' || c == '×' || c == '÷' || c == '−') return true;
    if (c == '+') return true;
    // Deux nombres séparés par un espace : « 18 6 », cas de la division
    // euclidienne telle que la formule les note.
    if (_isDigit(c) &&
        i + 1 < text.length &&
        text[i + 1] == ' ' &&
        i + 2 < text.length &&
        _isDigit(text[i + 2])) {
      return true;
    }
  }
  return false;
}

bool _isDigit(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

/// Les fiches d'un exercice, dans l'ordre de la banque.
///
/// Les fiches DÉFINITIVES de l'exercice ([Exercise.richHints]) priment : elles
/// sont rendues telles quelles, sans dérivation. On ne retombe sur la
/// dérivation mécanique que pour les exercices qui n'en possèdent pas encore —
/// c'est l'état transitoire décrit par la règle 8.
///
/// [consumedOrders] restreint le résultat aux indices déjà ouverts.
///
/// [maxHintsAllowed] est le BUDGET : c'est lui qui désigne la dernière fiche,
/// jamais le contenu. À défaut, la liste entière est réputée accordable.
List<RichHint> richHintsOf(
  Exercise exercise, {
  Set<int> consumedOrders = const <int>{},
  int? maxHintsAllowed,
}) {
  final definitive = exercise.orderedRichHints;
  final List<RichHint> source = definitive.isNotEmpty
      ? definitive
      : <RichHint>[for (final hint in exercise.orderedHints) hint.asRichHint()];

  final budget = maxHintsAllowed ?? source.length;

  return <RichHint>[
    for (final hint in source)
      if (consumedOrders.isEmpty || consumedOrders.contains(hint.order))
        hint.withIsFinal(hint.order == budget),
  ];
}

/// Le prochain indice non consommé, dans l'ordre de la banque.
///
/// `null` si l'exercice n'a plus rien à distribuer : le moteur ne fabrique
/// jamais une aide de remplacement.
RichHint? nextRichHintAfter(Exercise exercise, Set<int> consumedOrders) {
  for (final hint in richHintsOf(exercise)) {
    if (!consumedOrders.contains(hint.order)) return hint;
  }
  return null;
}