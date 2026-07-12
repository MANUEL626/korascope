# Korascope — Guide d'intégration mobile (Flutter)

**Base URL :** `http://localhost:7777` *(dev)* — à remplacer par l'URL de production  
**Préfixe API :** `/api/v1`  
**Format :** JSON (`Content-Type: application/json`)

---

## Authentification

L'API utilise un système de **token basé sur email + secretKey**. Après connexion, tu reçois un `token` que tu stockes localement et que tu envoies dans **toutes** les requêtes protégées via le header :

```
X-Secret-Key: <valeur du token>
```

**Format du token :** `base64(email):secretKey`

Exemple : `am9obi5kb2VAZXhhbXBsZS5jb20=:a3f2b1c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0`

---

## Flux de connexion

### Étape 1 — Demander un code OTP

```
POST /api/v1/auth/request-otp
```

```json
{ "email": "utilisateur@exemple.com" }
```

L'utilisateur reçoit un code à 6 chiffres par email. Si l'email n'existe pas, un compte est créé automatiquement.

**Rate limit :** 5 requêtes/heure par IP

| Code | Signification               |
|------|-----------------------------|
| 200  | Email envoyé                |
| 400  | Email invalide ou manquant  |
| 429  | Trop de tentatives          |

---

### Étape 2 — Vérifier le code OTP

```
POST /api/v1/auth/verify-otp
```

```json
{
  "email": "utilisateur@exemple.com",
  "otp": "123456"
}
```

**Rate limit :** 5 requêtes/heure par IP

**Réponse 200**

```json
{
  "token": "am9obi5kb2VAZXhhbXBsZS5jb20=:a3f2b1c4d5e6...",
  "isNew": true
}
```

| Champ   | Type    | Description                                                    |
|---------|---------|----------------------------------------------------------------|
| `token` | string  | À stocker en local — envoyer dans toutes les requêtes suivantes (format: `base64(email):secretKey`) |
| `isNew` | boolean | `true` = première connexion → rediriger vers l'écran de profil  |

| Code | Signification            |
|------|--------------------------|
| 200  | Connexion réussie        |
| 400  | Champ manquant           |
| 401  | Code OTP incorrect       |
| 404  | Email inconnu            |
| 429  | Trop de tentatives       |

> **Conseil Flutter :** stocker le `token` dans `flutter_secure_storage` plutôt que dans `SharedPreferences`.

---

### Vérifier / renouveler la session

À appeler au démarrage de l'app pour vérifier que la session est encore valide.

```
GET /api/v1/auth/validate
Header: X-Secret-Key: <token>
```

**Rate limit :** 100 requêtes/heure par IP

**Réponse 200**

```json
{
  "status": "VALID",
  "message": "Session valide"
}
```

| Champ     | Type   | Valeurs possibles      |
|-----------|--------|------------------------|
| `status`  | enum   | `VALID` ou `INVALID`   |
| `message` | string | Message descriptif     |

| Code | Signification                                          |
|------|--------------------------------------------------------|
| 200  | Validation effectuée — vérifier le champ `status`      |
| 429  | Trop de tentatives                                     |

> **Important :** Même avec un code 200, vérifier `status`. Si `INVALID`, renvoyer l'utilisateur vers l'écran de connexion.
>
> La session expire après **8 jours sans utilisation**. Chaque validation remet le compteur à zéro (8 jours supplémentaires).

---

## Limites de compte

| Type de compte | Max domaines d'intérêt | Max concurrents |
|----------------|------------------------|-----------------|
| STANDARD       | 5                      | 5               |
| PREMIUM        | 50                     | 50              |
| ENTERPRISE     | 999                    | 999             |

Lorsqu'une limite est atteinte, l'API retourne un code **403 Forbidden** avec `errorCode: "ACCOUNT_LIMIT_EXCEEDED"`.

Pour libérer de la place, il faut supprimer un domaine/concurrent existant.

---

## Upload d'image

### Uploader une photo (profil, etc.)

```
POST /api/v1/uploads
Header: X-Secret-Key: <token>
Content-Type: multipart/form-data
Champ: file
```

Formats acceptés : `jpg`, `jpeg`, `png`, `gif`, `webp` — taille max : **5 Mo**

**Réponse 200**

```json
{ "url": "http://localhost:7777/api/v1/uploads/3f2a1b4c-uuid.jpg" }
```

Utiliser l'`url` retournée pour renseigner `profileUrl` lors de la mise à jour du profil.

| Code | Signification                              |
|------|--------------------------------------------|
| 200  | Fichier uploadé, URL retournée             |
| 400  | Fichier vide ou format non autorisé        |
| 401  | Non authentifié                            |

**Exemple Flutter (avec `http` ou `dio`) :**

```dart
// Avec le package `http`
var request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/v1/uploads'),
);
request.headers['X-Secret-Key'] = token;
request.files.add(await http.MultipartFile.fromPath('file', imagePath));
var response = await request.send();
// Lire la réponse JSON → extraire "url"
```

---

### Afficher une image uploadée

Les images sont publiques (pas besoin de header) :

```
GET /api/v1/uploads/{filename}
```

L'URL complète est directement utilisable dans `Image.network(url)`.

---

## Profil utilisateur

### Récupérer le profil de l'utilisateur connecté

```
GET /api/v1/utilisateurs/me
Header: X-Secret-Key: <token>
```

**Réponse 200**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "fullName": "Jean Dupont",
  "email": "jean.dupont@exemple.com",
  "profileUrl": "http://localhost:7777/api/v1/uploads/uuid.jpg",
  "accountType": "STANDARD",
  "interestDomains": [
    {
      "id": "dom-1",
      "name": "Technologie",
      "description": "Secteur des nouvelles technologies"
    }
  ]
}
```

| Champ             | Type    | Description                                    |
|-------------------|---------|------------------------------------------------|
| `id`              | string  | Identifiant de l'utilisateur                   |
| `fullName`        | string  | Nom complet (peut être `null`)                 |
| `email`           | string  | Email                                          |
| `profileUrl`      | string  | URL complète de la photo de profil (peut être `null`) |
| `accountType`     | string  | Type de compte (`STANDARD`, `PREMIUM`, `ENTERPRISE`) |
| `interestDomains` | liste   | Domaines d'intérêt suivis par l'utilisateur    |

| Code | Signification   |
|------|-----------------|
| 200  | Profil retourné |
| 401  | Non authentifié |

---

### Récupérer un profil par ID

```
GET /api/v1/utilisateurs/{id}
Header: X-Secret-Key: <token>
```

Retourne le même format que `/me`.

| Code | Signification           |
|------|-------------------------|
| 200  | Profil retourné         |
| 401  | Non authentifié         |
| 404  | Utilisateur introuvable |

---

### Mettre à jour le profil

```
PUT /api/v1/utilisateurs/{id}
Header: X-Secret-Key: <token>
Content-Type: application/json
```

```json
{
  "fullName": "Jean-Pierre Dupont",
  "profileUrl": "http://localhost:7777/api/v1/uploads/uuid.jpg"
}
```

> `profileUrl` est facultatif. Envoyer `null` pour ne pas modifier la photo.  
> Pour mettre à jour la photo : uploader d'abord via `POST /api/v1/uploads`, puis utiliser l'URL retournée ici.

| Code | Signification             |
|------|---------------------------|
| 200  | Profil mis à jour         |
| 400  | `fullName` vide ou absent |
| 401  | Non authentifié           |
| 404  | Utilisateur introuvable   |

---

## Domaines d'intérêt

### Lister tous les domaines disponibles

```
GET /api/v1/interest-domains
Header: X-Secret-Key: <token>
```

**Réponse 200**

```json
[
  { "id": "dom-1", "name": "Technologie", "description": "Secteur des nouvelles technologies" },
  { "id": "dom-2", "name": "Finance",     "description": "Marchés financiers et banque" }
]
```

---

### Récupérer un domaine par ID

```
GET /api/v1/interest-domains/{id}
Header: X-Secret-Key: <token>
```

**Réponse 200**

```json
{
  "id": "dom-1",
  "name": "Technologie",
  "description": "Secteur des nouvelles technologies"
}
```

| Code | Signification       |
|------|---------------------|
| 200  | Domaine retourné    |
| 401  | Non authentifié     |
| 404  | Domaine introuvable |

---

### Ajouter un domaine d'intérêt à l'utilisateur

```
POST /api/v1/utilisateurs/{userId}/interest-domains/{domainId}
Header: X-Secret-Key: <token>
```

Retourne le profil mis à jour (même format que `GET /api/v1/utilisateurs/me`).

**Limite :** Maximum **5 domaines** pour les comptes STANDARD.

| Code | Signification                                                       |
|------|---------------------------------------------------------------------|
| 200  | Domaine ajouté, profil retourné                                     |
| 401  | Non authentifié                                                     |
| 403  | Limite de domaines atteinte (code: `ACCOUNT_LIMIT_EXCEEDED`)       |
| 404  | Utilisateur ou domaine introuvable                                  |

---

### Retirer un domaine d'intérêt

```
DELETE /api/v1/utilisateurs/{userId}/interest-domains/{domainId}
Header: X-Secret-Key: <token>
```

Libère une place dans la limite de 5 domaines.

| Code | Signification           |
|------|-------------------------|
| 204  | Domaine retiré          |
| 401  | Non authentifié         |
| 404  | Utilisateur introuvable |

---

## Entreprises concurrentes à surveiller

### Créer une entreprise à surveiller

```
POST /api/v1/competitor-companies/utilisateurs/{utilisateurId}
Header: X-Secret-Key: <token>
Content-Type: application/json
```

```json
{
  "name": "Concurrent Tech Inc.",
  "description": "Entreprise spécialisée dans les solutions cloud et l'IA",
  "active": true,
  "priority": 1,
  "category": "Technologie",
  "website": "https://concurrent-tech.com",
  "github": "https://github.com/concurrent-tech"
}
```

**Champs requis :** `name`  
**Champs optionnels :** `description` (max 1000 caractères), `active` (défaut: `true`), `priority`, `category`, `website`, `github`

**Limite :** Maximum **5 concurrents** pour les comptes STANDARD.

**Réponse 201**

```json
{
  "id": "550e8400...",
  "name": "Concurrent Tech Inc.",
  "description": "Entreprise spécialisée dans les solutions cloud et l'IA",
  "active": true,
  "priority": 1,
  "category": "Technologie",
  "website": "https://concurrent-tech.com",
  "github": "https://github.com/concurrent-tech",
  "createdAt": "2026-06-24T10:30:00Z",
  "updatedAt": "2026-06-24T10:30:00Z"
}
```

| Code | Signification                                                       |
|------|---------------------------------------------------------------------|
| 201  | Entreprise créée                                                    |
| 400  | Nom manquant ou invalide                                            |
| 401  | Non authentifié                                                     |
| 403  | Limite de concurrents atteinte (code: `ACCOUNT_LIMIT_EXCEEDED`)    |
| 404  | Utilisateur introuvable                                             |

---

### Lister les entreprises d'un utilisateur

```
GET /api/v1/competitor-companies/utilisateurs/{utilisateurId}?activeOnly=false
Header: X-Secret-Key: <token>
```

**Paramètre de requête :**
- `activeOnly` (optionnel, défaut: `false`) — si `true`, retourne uniquement les entreprises actives

**Réponse 200**

```json
[
  {
    "id": "550e8400...",
    "name": "Concurrent Tech Inc.",
    "description": "Entreprise spécialisée dans les solutions cloud et l'IA",
    "active": true,
    "priority": 1,
    "category": "Technologie",
    "website": "https://concurrent-tech.com",
    "github": "https://github.com/concurrent-tech",
    "createdAt": "2026-06-24T10:30:00Z",
    "updatedAt": "2026-06-24T10:30:00Z"
  }
]
```

| Code | Signification   |
|------|-----------------|
| 200  | Liste retournée |
| 401  | Non authentifié |

---

### Récupérer une entreprise par ID

```
GET /api/v1/competitor-companies/{id}
Header: X-Secret-Key: <token>
```

Retourne le même format qu'à la création.

| Code | Signification          |
|------|------------------------|
| 200  | Entreprise retournée   |
| 401  | Non authentifié        |
| 404  | Entreprise introuvable |

---

### Mettre à jour une entreprise

```
PUT /api/v1/competitor-companies/{id}
Header: X-Secret-Key: <token>
Content-Type: application/json
```

```json
{
  "name": "Nouveau nom",
  "description": "Description mise à jour",
  "active": false,
  "priority": 2,
  "category": "Finance",
  "website": "https://nouveau-site.com",
  "github": "https://github.com/nouveau"
}
```

**Tous les champs sont optionnels.** Seuls les champs fournis seront mis à jour.

| Code | Signification          |
|------|------------------------|
| 200  | Entreprise mise à jour |
| 401  | Non authentifié        |
| 404  | Entreprise introuvable |

---

### Supprimer une entreprise

```
DELETE /api/v1/competitor-companies/{id}
Header: X-Secret-Key: <token>
```

Libère une place dans la limite de 5 concurrents.

| Code | Signification          |
|------|------------------------|
| 204  | Entreprise supprimée   |
| 401  | Non authentifié        |
| 404  | Entreprise introuvable |

---

## Rapports

### Créer un rapport

```
POST /api/v1/reports
Header: X-Secret-Key: <token>
Content-Type: application/json
```

```json
{
  "date": "2026-06-24",
  "name": "Rapport mensuel Juin 2026",
  "contenu": "Contenu détaillé du rapport généré automatiquement...",
  "utilisateurId": "550e8400-..."
}
```

**Champs requis :** `date`, `name`, `contenu`, `utilisateurId`

**Réponse 201**

```json
{
  "id": "abc123...",
  "date": "2026-06-24",
  "name": "Rapport mensuel Juin 2026",
  "contenu": "Contenu détaillé du rapport généré automatiquement...",
  "utilisateurId": "550e8400-...",
  "createdAt": "2026-06-24T10:30:00Z",
  "updatedAt": "2026-06-24T10:30:00Z"
}
```

| Code | Signification                  |
|------|--------------------------------|
| 201  | Rapport créé                   |
| 400  | Champ manquant ou invalide     |
| 401  | Non authentifié                |
| 404  | Utilisateur introuvable        |

> **Note :** Cet endpoint est principalement utilisé par n8n pour créer automatiquement des rapports. L'app mobile l'utilisera probablement en lecture seule.

---

### Lister les rapports d'un utilisateur

```
GET /api/v1/reports/utilisateurs/{utilisateurId}
Header: X-Secret-Key: <token>
```

Les rapports sont triés par date de création (plus récent en premier).

**Réponse 200**

```json
[
  {
    "id": "abc123...",
    "date": "2026-06-24",
    "name": "Rapport mensuel Juin 2026",
    "contenu": "Contenu détaillé du rapport...",
    "utilisateurId": "550e8400-...",
    "createdAt": "2026-06-24T10:30:00Z",
    "updatedAt": "2026-06-24T10:30:00Z"
  }
]
```

| Code | Signification   |
|------|-----------------|
| 200  | Liste retournée |
| 401  | Non authentifié |

---

### Récupérer un rapport par ID

```
GET /api/v1/reports/{id}
Header: X-Secret-Key: <token>
```

**Réponse 200**

```json
{
  "id": "abc123...",
  "date": "2026-06-24",
  "name": "Rapport mensuel Juin 2026",
  "contenu": "Contenu détaillé du rapport...",
  "utilisateurId": "550e8400-...",
  "createdAt": "2026-06-24T10:30:00Z",
  "updatedAt": "2026-06-24T10:30:00Z"
}
```

| Code | Signification        |
|------|----------------------|
| 200  | Rapport retourné     |
| 401  | Non authentifié      |
| 404  | Rapport introuvable  |

---

### Supprimer un rapport

```
DELETE /api/v1/reports/{id}
Header: X-Secret-Key: <token>
```

| Code | Signification        |
|------|----------------------|
| 204  | Rapport supprimé     |
| 401  | Non authentifié      |
| 404  | Rapport introuvable  |

---

## Erreurs

Toutes les erreurs ont le même format :

```json
{
  "status": 403,
  "errorCode": "ACCOUNT_LIMIT_EXCEEDED",
  "message": "Limite de concurrents atteinte pour le type de compte STANDARD (5 maximum)",
  "timestamp": "2026-06-23T00:22:15.117"
}
```

### Codes d'erreur principaux

| Code HTTP | errorCode                 | Description                                        |
|-----------|---------------------------|----------------------------------------------------|
| 400       | `VALIDATION_ERROR`        | Champ manquant ou format invalide                  |
| 401       | `UNAUTHORIZED`            | Token manquant, invalide ou expiré                 |
| 401       | `INVALID_OTP`             | Code OTP incorrect                                 |
| 401       | `SECRET_KEY_EXPIRED`      | Token expiré (renouveler via request-otp)          |
| 403       | `ACCOUNT_LIMIT_EXCEEDED`  | Limite de compte atteinte (domaines/concurrents)   |
| 404       | `RESOURCE_NOT_FOUND`      | Ressource introuvable                              |
| 429       | `RATE_LIMIT_EXCEEDED`     | Trop de tentatives                                 |
| 500       | `INTERNAL_ERROR`          | Erreur serveur (ex. problème d'envoi email)        |

---

## Modèle de données Flutter (suggestion)

```dart
// Authentification
class AuthResponse {
  final String token;  // Format: base64(email):secretKey
  final bool isNew;
}

class ValidationResponse {
  final String status;  // "VALID" ou "INVALID"
  final String message;
}

// Upload
class UploadResponse {
  final String url;
}

// Utilisateur
class UtilisateurDto {
  final String id;
  final String? fullName;
  final String email;
  final String? profileUrl;
  final String accountType;  // "STANDARD", "PREMIUM", "ENTERPRISE"
  final List<InterestDomainDto> interestDomains;
}

// Domaine d'intérêt
class InterestDomainDto {
  final String id;
  final String name;
  final String description;
}

// Entreprise concurrente
class CompetitorCompanyDto {
  final String id;
  final String name;
  final String? description;
  final bool active;
  final int? priority;
  final String? category;
  final String? website;
  final String? github;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// Rapport
class ReportDto {
  final String id;
  final String date;
  final String name;
  final String contenu;
  final String utilisateurId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// Erreur API
class ApiError {
  final int status;
  final String errorCode;
  final String message;
  final DateTime timestamp;
}
```

---

## Flux complet — résumé

```
Ouverture de l'app
       │
       ▼
token en storage ?
   │              │
  Non            Oui
   │              │
   ▼              ▼
/request-otp   /api/v1/auth/validate
/verify-otp        │
   │          status == VALID ?
   ▼               │
 isNew ?       Non ──► écran connexion
   │              │
  Oui            Oui
   │              │
   ▼              ▼
Écran profil   Écran principal
(photo → POST /api/v1/uploads,
 remplir fullName via PUT /api/v1/utilisateurs/{id},
 choisir domaines via POST /api/v1/utilisateurs/{id}/interest-domains/{domId})
       │
       ▼
   Écran principal
       │
       ├─► Onglet Profil
       │   └─► GET /api/v1/utilisateurs/me
       │       PUT /api/v1/utilisateurs/{id}
       │
       ├─► Onglet Domaines d'intérêt
       │   └─► GET /api/v1/interest-domains
       │       POST/DELETE /api/v1/utilisateurs/{id}/interest-domains/{domId}
       │       ⚠️ Max 5 pour STANDARD (403 si dépassé)
       │
       ├─► Onglet Entreprises à surveiller
       │   └─► GET /api/v1/competitor-companies/utilisateurs/{id}
       │       POST /api/v1/competitor-companies/utilisateurs/{id}
       │       PUT /api/v1/competitor-companies/{id}
       │       DELETE /api/v1/competitor-companies/{id}
       │       ⚠️ Max 5 pour STANDARD (403 si dépassé)
       │
       └─► Onglet Rapports
           └─► GET /api/v1/reports/utilisateurs/{id}
               GET /api/v1/reports/{id}
               DELETE /api/v1/reports/{id}
```

---

## Conseils d'implémentation Flutter

### 1. Service HTTP centralisé

Créer un service qui gère automatiquement le header `X-Secret-Key` :

```dart
class ApiService {
  final String baseUrl;
  final FlutterSecureStorage _storage;

  Future<String?> get token => _storage.read(key: 'auth_token');

  Future<http.Response> get(String path) async {
    final authToken = await token;
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'X-Secret-Key': authToken,
      },
    );
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final authToken = await token;
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'X-Secret-Key': authToken,
      },
      body: jsonEncode(body),
    );
  }

  // Idem pour PUT, DELETE...
}
```

### 2. Gestion des erreurs avec codes

Intercepter les erreurs et afficher des messages appropriés :

```dart
Future<T> handleResponse<T>(
  Future<http.Response> Function() request,
  T Function(Map<String, dynamic>) parser,
) async {
  final response = await request();
  
  if (response.statusCode == 401) {
    await _storage.delete(key: 'auth_token');
    throw AuthException('Session expirée');
  }
  
  if (response.statusCode == 403) {
    final error = ApiError.fromJson(jsonDecode(response.body));
    if (error.errorCode == 'ACCOUNT_LIMIT_EXCEEDED') {
      throw AccountLimitException(error.message);
    }
  }
  
  if (response.statusCode == 429) {
    throw RateLimitException('Trop de tentatives, réessayez plus tard');
  }
  
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return parser(jsonDecode(response.body));
  }
  
  final error = ApiError.fromJson(jsonDecode(response.body));
  throw ApiException(error.status, error.message, error.errorCode);
}
```

### 3. Gestion de la limite de compte

Afficher un message clair quand la limite est atteinte :

```dart
try {
  await apiService.post(
    '/api/v1/competitor-companies/utilisateurs/$userId',
    {'name': companyName, 'active': true},
  );
} on AccountLimitException catch (e) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Limite atteinte'),
      content: Text(e.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Rediriger vers l'écran de mise à niveau
            Navigator.pushNamed(context, '/upgrade');
          },
          child: Text('Passer à Premium'),
        ),
      ],
    ),
  );
}
```

### 4. Validation au démarrage

```dart
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final storage = FlutterSecureStorage();
    final authToken = await storage.read(key: 'auth_token');

    if (authToken == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/auth/validate'),
        headers: {'X-Secret-Key': authToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'VALID') {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          await storage.delete(key: 'auth_token');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        await storage.delete(key: 'auth_token');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      await storage.delete(key: 'auth_token');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
```

### 5. Gestion du premier login

```dart
// Après vérification OTP
final response = await apiService.post('/api/v1/auth/verify-otp', {
  'email': email,
  'otp': otp,
});

final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
await storage.write(key: 'auth_token', value: authResponse.token);

if (authResponse.isNew) {
  // Première connexion → écran de complétion du profil
  Navigator.of(context).pushReplacementNamed('/complete-profile');
} else {
  // Utilisateur existant → écran principal
  Navigator.of(context).pushReplacementNamed('/home');
}
```

---

## URL de production

Remplacer `http://localhost:7777` par l'URL de production finale fournie par l'équipe backend.

---

**Version :** 2026-07-12  
**Maintenu par :** Équipe Korascope / Koraclenet
