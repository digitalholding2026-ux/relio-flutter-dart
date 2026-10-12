/// Sequence de l'ecran d'entree â€” chronologie pure, sans widget.
///
/// WHY SEPAREE : la sequence est une SPECIFICATION TEMPORELLE. La tester
/// via `pumpAndSettle` sur des widgets rendrait les assertions fragiles et
/// lentes. Ici, l'etat a un instant T se calcule sans aucun rendu : les
/// tests verifient la chronologie exacte (1,5 s / 3 s / 5 s / 5,3 s) en
/// quelques assertions.
///
/// L'ecran ne fait qu'APPLIQUER ces etats. Il n'invente aucun temps.
library;

import 'package:flutter/foundation.dart';

/// Etape visible de la sequence.
enum IntroStage {
  /// Personnage seul, aucun texte. T = 0.
  character,

  /// Â« Salut. Je suis Relio. Â» T = 1,5 s.
  greeting,

  /// Â« Je t'accompagne en maths, a ton rythme. Â» T = 3 s.
  promise,

  /// Â« On commence ? Â» T = 5 s.
  question,

  /// Bouton Â« Commencer Â» visible. T = 5,3 s.
  ready,
}

/// Chronologie de la sequence, en secondes.
///
/// Ces valeurs sont FIGEES. La mission 2 interdit explicitement de les
/// allonger pour compenser un appareil lent : sur un appareil lent, la
/// sequence doit sauter des etapes, pas durer plus longtemps.
abstract final class IntroTiming {
  /// Micro-animation d'entree du personnage : 300 ms.
  static const Duration characterIn = Duration(milliseconds: 300);

  /// Fondu d'apparition d'un texte : 250 ms.
  static const Duration textIn = Duration(milliseconds: 250);

  /// Fondu d'effacement d'un texte : 200 ms.
  static const Duration textOut = Duration(milliseconds: 200);

  /// Transition du bouton : 250 ms, glissement de 8 dp vers le haut.
  static const Duration buttonIn = Duration(milliseconds: 250);

  /// Premiere phrase.
  static const Duration greeting = Duration(milliseconds: 1500);

  /// Deuxieme phrase.
  static const Duration promise = Duration(milliseconds: 3000);

  /// Question.
  static const Duration question = Duration(milliseconds: 5000);

  /// Bouton visible.
  static const Duration ready = Duration(milliseconds: 5300);

  /// Delai apres un tap d'acceleration, avant le bouton.
  ///
  /// La sequence sautee : texte en 150 ms, bouton 200 ms plus tard.
  static const Duration accelerateTextIn = Duration(milliseconds: 150);
  static const Duration accelerateButtonDelay = Duration(milliseconds: 200);
}

/// Etat complet de la sequence a un instant donne.
@immutable
class IntroSequenceState {
  /// Cree un etat.
  const IntroSequenceState({
    required this.stage,
    required this.textVisible,
    required this.buttonVisible,
    required this.buttonOpacity,
    required this.textOpacity,
    required this.characterOpacity,
    required this.characterScale,
    required this.leanDegrees,
    required this.finished,
    required this.accelerates,
  });

  /// Etape atteinte.
  final IntroStage stage;

  /// Un texte est-il a l'ecran ?
  ///
  /// Vrai des que l'etape porte un texte â€” donc des que sa FONDUE commence â€”
  /// et non des que l'opacite est strictement positive. A T = 1,5 s exactement,
  /// le texte est Â« arrive Â» : il commence a s'afficher. Confondre l'un et
  /// l'autre ferait clignoter l'ecran a chaque changement de phrase.
  final bool textVisible;

  /// Le bouton est-il a l'ecran ?
  ///
  /// Vrai des 5,3 s, c'est-a-dire des le DEBUT de sa transition.
  final bool buttonVisible;

  /// Opacite du bouton, de 0 a 1, pendant sa transition de 250 ms.
  final double buttonOpacity;

  /// Opacite du texte courant, de 0 a 1.
  final double textOpacity;

  /// Opacite du personnage, de 0 a 1.
  final double characterOpacity;

  /// Echelle du personnage : 0,9 a l'entree, 1 ensuite.
  final double characterScale;

  /// Inclinaison du personnage, en degres.
  ///
  /// Le personnage s'incline quand un texte apparait, comme pour saluer, et se
  /// redresse pour la question.
  final double leanDegrees;

  /// La sequence est-elle terminee (bouton visible) ?
  final bool finished;

  /// L'ecran doit-il encore capter les taps pour accelerer ?
  ///
  /// Faux des que le bouton est visible : Â« si l'eleve tape apres que le
  /// bouton est deja visible, rien ne se passe Â».
  final bool accelerates;

  /// Rendu du widget pour l'etat donne.
  static IntroSequenceState at(Duration elapsed) {
    // --- Personnage : micro-animation d'entree sur 300 ms ---------------
    final double p = _ease(
      (elapsed.inMicroseconds / IntroTiming.characterIn.inMicroseconds)
          .clamp(0.0, 1.0),
    );
    final double opacity = p;
    final double scale = 0.9 + 0.1 * p;

    // --- Phase des textes ----------------------------------------------
    // Un texte existe entre son apparition et la suivante : le precedent
    // s'efface pendant que le suivant arrive.
    final int ms = elapsed.inMilliseconds;

    double textOpacity;
    IntroStage stage;

    if (ms < IntroTiming.greeting.inMilliseconds) {
      stage = IntroStage.character;
      textOpacity = 0;
    } else if (ms < IntroTiming.promise.inMilliseconds) {
      stage = IntroStage.greeting;
      textOpacity = _fadeIn(
        ms - IntroTiming.greeting.inMilliseconds,
        IntroTiming.textIn,
      );
    } else if (ms < IntroTiming.question.inMilliseconds) {
      stage = IntroStage.promise;
      textOpacity = _fadeIn(
        ms - IntroTiming.promise.inMilliseconds,
        IntroTiming.textIn,
      );
    } else if (ms < IntroTiming.ready.inMilliseconds) {
      stage = IntroStage.question;
      textOpacity = _fadeIn(
        ms - IntroTiming.question.inMilliseconds,
        IntroTiming.textIn,
      );
    } else {
      stage = IntroStage.ready;
      textOpacity = 1;
    }

    // --- Bouton : 300 ms apres la question ------------------------------
    final double buttonOpacity = _fadeIn(
      ms - IntroTiming.ready.inMilliseconds,
      IntroTiming.buttonIn,
    );
    // Le bouton est Â« visible Â» des 5,3 s : sa transition commence la. Il
    // n'est pas encore opaque a cet instant â€” et c'est voulu, la transition
    // dure 250 ms. La.sequence est donc TERMINEE a 5,3 s, conformement a la
    // specification, qui compte l'apparition du bouton et non sa fin.
    final bool buttonVisible = ms >= IntroTiming.ready.inMilliseconds;

    // --- Inclinaison -----------------------------------------------------
    // Le personnage s'incline quand un texte apparait, et se redresse pour la
    // question. L'amplitude reste dans la plage de la specification.
    double lean;
    if (stage == IntroStage.character) {
      lean = 0;
    } else if (stage == IntroStage.ready) {
      lean = 0;
    } else if (stage == IntroStage.question) {
      // Il se redresse progressivement vers 0.
      lean = 0.0;
    } else {
      lean = 2.5;
    }

    return IntroSequenceState(
      stage: stage,
      textVisible: stage != IntroStage.character,
      buttonVisible: buttonVisible,
      buttonOpacity: buttonOpacity,
      textOpacity: textOpacity,
      characterOpacity: opacity,
      characterScale: scale,
      leanDegrees: lean,
      finished: buttonVisible,
      accelerates: !buttonVisible,
    );
  }

  /// Etat atteint quand un tap ACCELERE la sequence.
  ///
  /// La sequence intermediaire est court-circuitee : le texte arrive en
  /// 150 ms, le bouton 200 ms apres. Aucun effet visuel immediat.
  static IntroSequenceState accelerated(Duration since) {
    final int ms = since.inMilliseconds;
    final double textOpacity =
        _fadeIn(ms, IntroTiming.accelerateTextIn);
    final bool buttonVisible = ms >= IntroTiming.accelerateButtonDelay.inMilliseconds;
    final double buttonOpacity =
        _fadeIn(ms - IntroTiming.accelerateButtonDelay.inMilliseconds,
            IntroTiming.buttonIn);

    return IntroSequenceState(
      stage: IntroStage.ready,
      textVisible: true,
      buttonVisible: buttonVisible,
      buttonOpacity: buttonOpacity,
      textOpacity: textOpacity,
      // Le personnage est deja la : pas de micro-animation rejouee.
      characterOpacity: 1,
      characterScale: 1,
      leanDegrees: 0,
      finished: buttonVisible,
      accelerates: !buttonVisible,
    );
  }

  /// Fondu d'entree lineaire sur [duration].
  static double _fadeIn(int elapsedMs, Duration duration) {
    if (elapsedMs <= 0) return 0;
    if (elapsedMs >= duration.inMilliseconds) return 1;
    return elapsedMs / duration.inMilliseconds;
  }

  /// Courbe d'adoucissement sortante, pour l'entree du personnage.
  ///
  /// `easeOutCubic` : l'acceleration est douce, sans rebond ni exces â€” le
  /// personnage ne doit jamais avoir l'air de bondir.
  static double _ease(double t) {
    final double u = 1 - t;
    return 1 - (u * u * u);
  }
}

/// Les trois textes de la sequence.
///
/// Volontairement SANS promesse de resultat : pas de Â« je vais t'aider a
/// reussir Â», seulement Â« je t'accompagne Â». La mission 2 l'interdit.
abstract final class IntroTexts {
  const IntroTexts._();

  static const String greeting = 'Salut. Je suis Relio.';
  static const String promise = 'Je t\'accompagne en maths, à ton rythme.';
  static const String question = 'On commence ?';
  static const String startButton = 'Commencer';

  /// Texte correspondant a une etape.
  ///
  /// L'etape `character` n'a pas de texte : le personnage est seul.
  static String? forStage(IntroStage stage) => switch (stage) {
        IntroStage.character => null,
        IntroStage.greeting => greeting,
        IntroStage.promise => promise,
        IntroStage.question => question,
        IntroStage.ready => question,
      };
}
