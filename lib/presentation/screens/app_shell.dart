/// Coquille de navigation — barre basse à trois onglets.
///
/// TROIS ONGLETS, JAMAIS PLUS. Les destinations « Révisions », « Progression »
/// et « Paramètres » sont des emplacements RÉSERVÉS : elles n'existent pas en
/// V1 et ne doivent pas apparaître, même grisées.
///
/// PILES INDÉPENDANTES : chaque onglet possède son propre [Navigator], construit
/// une seule fois et conservé dans l'[IndexedStack]. Changer d'onglet ne
/// détruit pas l'onglet quitté — revenir restaure son dernier état (brouillon
/// de saisie, position de défilement, panneau de retour).
library;


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/relio_theme.dart';
import 'app_shell_nav.dart';

/// Barre basse à trois onglets.
class RelioBottomNav extends StatelessWidget {
  const RelioBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  /// Onglet sélectionné.
  final RelioTab current;

  /// Notifie le changement d'onglet.
  final ValueChanged<RelioTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.outline)),
      ),
      // SafeArea : la barre reste au-dessus des gestes système.
      child: SafeArea(
        top: false,
        child: SizedBox(
          // Hauteur minimale : la barre ne peut pas être plus basse que la
          // cible tactile, mais elle svelte si le libellé doit prendre deux
          // lignes (échelle de texte renforcée) plutôt que de déborder.
          height: RelioSizes.bottomNavHeight,
          child: Row(
            children: <Widget>[
              for (final tab in RelioTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onChanged(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final RelioTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final color = selected ? palette.primary : palette.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        // Cible tactile : toute la largeur de l'onglet, sur 56 dp de haut.
        //
        // `MainAxisSize.min` + `Flexible` : si la hauteur disponible devient
        // insuffisante — échelle de texte renforcée, barre réduite par les
        // gestes système — le libellé se réduit ou se tronque au lieu de
        // déborder. Un débordement dans la barre rendrait TOUS les onglets
        // inatteignables.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: RelioSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                selected ? tab.selectedIcon : tab.icon,
                size: 24,
                color: color,
                // Épaisseur de trait 1.75 dp, cohérente avec les rayons de
                // carte.
                weight: 1.75,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  tab.label,
                  // SemiBold à l'actif, Medium à l'inactif : l'état se lit à
                  // la fois par la couleur ET par le poids du trait.
                  // L'information n'est donc jamais portée par la seule
                  // couleur.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    fontFamily: RelioTheme.fontFamily,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coquille applicative : les trois onglets et leurs piles.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.tabs,
    this.navigatorKeys = const <GlobalKey<NavigatorState>>[],
    required this.hideBottomBar,
  });

  /// Contenu racine de chaque onglet, dans l'ordre de [RelioTab.values].
  ///
  /// Chaque entrée construit le NAVIGATEUR de son onglet : la pile est ainsi
  /// réellement indépendante d'un onglet à l'autre.
  final List<Widget Function(BuildContext context, GlobalKey<NavigatorState> key)>
      tabs;

  /// Clés des navigateurs, une par onglet.
  ///
  /// Permettent à un écran d'un onglet de pousser une page dans la pile d'un
  /// AUTRE onglet — par exemple « Commence ici » (Accueil) ouvrant S1 dans la
  /// pile d'Apprendre.
  final List<GlobalKey<NavigatorState>> navigatorKeys;

  /// La barre basse doit-elle être masquée ?
  ///
  /// Signal EXPLICITE, et non calculé sur la profondeur de la pile : la barre
  /// reste visible sur S1 mais disparaît sur S2, où la barre d'action fixe
  /// du champ doit rester seule. La profondeur seule ne distingue pas ces deux
  /// écrans — tous deux sont empilés dans la pile de l'onglet.
  ///
  /// C'est S2 lui-même qui lève ce signal, via [onFullscreenChanged].
  final ValueListenable<bool> hideBottomBar;

  @override
  State<AppShell> createState() => AppShellState();
}

/// État de la coquille, pour permettrait le changement d'onglet depuis un écran.
class AppShellState extends State<AppShell> {
  RelioTab _current = RelioTab.home;

  /// Onglet affiché.
  RelioTab get currentTab => _current;

  /// Bascule sur l'onglet [tab].
  void selectTab(RelioTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.hideBottomBar,
      builder: (context, hidden, _) {
        return Scaffold(
          body: IndexedStack(
            index: _current.index,
            children: <Widget>[
              for (var i = 0; i < widget.tabs.length; i++)
                Navigator(
                  key: i < widget.navigatorKeys.length
                      ? widget.navigatorKeys[i]
                      : null,
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (context) =>
                        widget.tabs[i](context, widget.navigatorKeys[i]),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: hidden
              ? null
              : RelioBottomNav(
                  current: _current,
                  onChanged: selectTab,
                ),
        );
      },
    );
  }
}

/// Carte de navigation réutilisable : titre + sous-titre + chevron.
///
/// Partagée par les cartes d'ACCUEIL et par les cartes de chapitre
/// d'APPRENDRE, afin qu'un même geste et une même marge d'erreur s'appliquent
/// partout.
class NavCard extends StatelessWidget {
  const NavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
    this.elevated = false,
  });

  /// Titre de la carte.
  final String title;

  /// Sous-titre de la carte.
  final String subtitle;

  /// Action au tap. `null` rend la carte non cliquable.
  final VoidCallback? onTap;

  /// Chevron à droite. Absent sur un élément inactif.
  final bool showChevron;

  /// Carte principale d'accueil : ombre légère.
  ///
  /// Les cartes secondaires sont plates, sans ombre.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final enabled = onTap != null;

    final content = Container(
      width: double.infinity,
      // La carte occupe la hauteur minimale imposée par l'appelant, et
      // grandit si le texte l'exige : jamais de débordement.
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: RelioRadius.cardAll,
        border: Border.all(color: palette.outline),
        boxShadow: elevated
            ? <BoxShadow>[
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(RelioSpacing.xl),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      fontFamily: RelioTheme.fontFamily,
                      // Un élément inactif ne doit pas ressembler à un
                      // élément cliquable.
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      fontFamily: RelioTheme.fontFamily,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron) ...<Widget>[
              const SizedBox(width: RelioSpacing.md),
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ],
        ),
      ),
    );

    if (!enabled) return content;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: RelioRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: RelioRadius.cardAll,
          child: content,
        ),
      ),
    );
  }
}


