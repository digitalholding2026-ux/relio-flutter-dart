/// Génération d'identifiants stables.
///
/// Les identifiants sont produits AVANT écriture en base et servent de
/// clé primaire déterministe. Cela permet d'insérer deux fois le même
/// événement sans le dupliquer (insertion idempotente), et de s'appuyer
/// sur l'identifiant lors des migrations de données.
library;

import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Identifiant opaque, au format UUID v4.
typedef RelioId = String;

/// Produit un nouvel identifiant unique.
///
/// [generator] est injectable pour rendre les tests déterministes.
String newId({String Function()? generator}) =>
    (generator ?? _uuid.v4)();
