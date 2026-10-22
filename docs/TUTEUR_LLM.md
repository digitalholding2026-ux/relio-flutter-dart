# Tuteur Relio — prompt système et appel du modèle

Ce document est la **source de référence** du cerveau du tuteur. Le texte
ci-dessous est envoyé tel quel au modèle, et
`lib/domain/tutor/tutor_prompt.dart` doit rester identique : un test
(`test/tutor/tutor_prompt_test.dart`) rejoue la comparaison et échoue à la
moindre dérive.

<!-- SYSTEM_PROMPT_START -->
Rôle :
Tu es "Relio", le tuteur personnel de mathématiques pour des élèves de 3e au Cameroun. Tu es bienveillant, patient et encourageant. Tu ne juges jamais. Ton objectif n'est pas de donner la réponse, mais de faire comprendre la méthode.

Contexte de la discussion :
L'élève est bloqué sur un exercice spécifique. Tu as accès à l'énoncé et à la réponse attendue, mais tu ne dois JAMAIS donner la réponse finale directement.

Règles d'or de ta pédagogie :

La méthode socratique : Pose des questions pour guider l'élève. (Ex: "Si tu dois soustraire 12 à 18, quel est le résultat ?").

Le guidage pas à pas : Ne donne qu'une seule instruction ou une seule question à la fois. Attends que l'élève réponde avant de continuer.

L'erreur est permise : Si l'élève se trompe, ne dis pas "C'est faux". Dis plutôt "Presque ! Regarde bien ce que tu as écris. Et si tu faisais l'opération dans l'autre sens ?".

Interdiction de donner la réponse : Si l'élève te demande "Donne-moi la réponse", refuse poliment : "Je ne peux pas te donner la réponse, mais je peux t'aider à la trouver toi-même. On essaie ?".

Le langage : Utilise un français simple, clair et adapté à un élève de 3e. Pas de jargon inutile. Utilise le formatage mathématique (ex: 18 − 12 = 6) pour la clarté.

La brièveté : Tes réponses doivent tenir en 2 ou 3 phrases maximum. C'est un chat, pas un cours magistral.

Le rendu : N'utilise jamais de balises LaTeX comme \( ou \). Écris les mathématiques en texte simple.

Gestion de l'énoncé :
Tu connais l'exercice. Si l'élève te pose une question sur l'énoncé, aide-le à le décortiquer (ex: "Qu'est-ce qu'on te demande de chercher exactement ?").
<!-- SYSTEM_PROMPT_END -->

## Contexte ajouté à chaque appel

Le prompt système est suivi d'un bloc interne, construit par
`systemPromptFor` :

- l'énoncé de l'exercice en cours ;
- la réponse attendue, marquée **à ne jamais révéler** ;
- rien d'autre : ni historique d'autres exercices, ni données personnelles.

La conversation (messages élève / tuteur) est ensuite envoyée dans l'ordre,
tronquée aux derniers `TUTOR_MAX_HISTORY` messages (12 par défaut).

## Configuration

L'API est **compatible OpenAI** : `POST {base}/chat/completions` avec
`Authorization: Bearer <clé>` et un corps `model` + `messages`.

Les valeurs sont lues au moment de la compilation (`dart-define`) :

| Variable | Défaut | Rôle |
|---|---|---|
| `TUTOR_API_KEY` | *(vide)* | Clé du fournisseur. **Vide : mode simulé**, voir plus bas. |
| `TUTOR_API_BASE_URL` | `https://openrouter.ai/api/v1` | Racine de l'API (OpenRouter, OpenAI, Groq, vLLM local…). |
| `TUTOR_MODEL` | `openrouter/auto` | `openrouter/auto` laisse OpenRouter choisir le modèle accessible avec la clé. |

Exemple :

```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=TUTOR_API_KEY=sk-or-v1-...
```

### Script de build

`tool/build_apk.ps1` construit l'APK en injectant la clé sans l'écrire dans le
dépôt : il lit `$env:TUTOR_API_KEY`, sinon `tool/tutor.env` (gitignoré). Sans
clé, il produit quand même un APK en mode simulé et l'annonce.

```powershell
powershell -File tool/build_apk.ps1
```

`TUTOR_MODEL` n'a pas besoin d'être fourni : `openrouter/auto` évite de
maintenir une liste de secours côté client. Si un modèle est indisponible ou
refusé pour cette clé, OpenRouter en essaie un autre.

Deux en-têtes d'attribution facultatifs sont ajoutés (`HTTP-Referer`,
`X-Title`) : ils identifient l'application dans le classement OpenRouter et
sont ignorés par les autres fournisseurs compatibles OpenAI.

## Mode simulé (sans clé)

Sans `TUTOR_API_KEY`, la fabrique renvoie `MockTutorClient`
(`lib/domain/tutor/mock_tutor_client.dart`) :

- aucune requête réseau, l'exercice n'est pas transmis ;
- même attente affichée (`Relio réfléchit…`) et même fil que le mode réel ;
- réponse fixe : `kMockTutorReply` — « Je ne peux pas encore te répondre,
  as-tu essayé de relire la règle ? ».

Ce mode sert à tester l'interface avant l'injection de la clé. Il ne produit
aucun contenu pédagogique : inventer une correction reviendrait à écrire du
cours sans validation (règle 8).

## Panne en cours de conversation

Si l'appel échoue (réseau, HTTP, réponse illisible), l'élève reçoit une bulle
`RelioStrings.tutorBusyReply` — « Relio est un peu occupé, réessaie dans un
instant. » — **suivie d'un bouton « Réessayer »**. Le bouton relance le même
appel : la question de l'élève est déjà dans le fil, rien n'est à retaper.
Aucun détail technique n'est affiché, et l'interface ne se bloque jamais.

## Sécurité

> **La clé est embarquée dans l'APK** (les `dart-define` sont compilés dans le
> binaire). Elle y est extractible par quiconque possède le fichier.

- Ne jamais commiter de clé, ni dans le code, ni dans un fichier de config.
- Pour une diffusion réelle, passer par un **proxy serveur** qui garde la clé
  et applique les quotas ; l'application pointerait alors vers ce proxy.
- Le tuteur ne reçoit que l'énoncé, la correction validée de l'exercice et les
  messages de la conversation. **Aucun fait d'apprentissage n'est envoyé ni
  journalisé** : la conversation n'est pas persistée.

## Coût et latence

- `max_tokens` : 180 (réponses de 2 à 3 phrases).
- `temperature` : 0,4 (guidage stable, sans rigidité).
- Délai maximal : 20 s ; au-delà, repli.

## Vérifications

```bash
flutter test test/tutor              # prompt, client, configuration
flutter test test/presentation/relio_tutor_sheet_test.dart
```
