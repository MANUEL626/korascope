# Korascope — Guide d'intégration mobile (Flutter)

**Base URL :** `http://localhost:8080` *(dev)* — à remplacer par l'URL de production  
**Préfixe API :** `/api/v1`  
**Format :** JSON (`Content-Type: application/json`)

---

## Authentification

L'API n'utilise ni JWT ni cookie. Après connexion, tu reçois un `secretKey` que tu stockes localement et que tu envoies dans **toutes** les requêtes protégées via le header :

```
X-Secret-Key: <valeur du secretKey>
```

---

## Flux de connexion

### Étape 1 — Demander un code OTP

```
POST /api/v1/auth/request-otp
```

```json
{ "email": "utilisateur@exemple.com" }
```

L'utilisateur reçoit un code à 6 chiffres par email.

| Code | Signification               |
|------|-----------------------------|
| 200  | Email envoyé                |
| 400  | Email invalide ou manquant  |

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

**Réponse 200**

```json
{
  "secretKey": "550e8400-e29b-41d4-a716-446655440000",
  "isNew": true
}
```

| Champ       | Type    | Description                                                    |
|-------------|---------|----------------------------------------------------------------|
| `secretKey` | string  | À stocker en local — envoyer dans toutes les requêtes suivantes |
| `isNew`     | boolean | `true` = première connexion → rediriger vers l'écran de profil  |

| Code | Signification            |
|------|--------------------------|
| 200  | Connexion réussie        |
| 400  | Champ manquant           |
| 401  | Code OTP incorrect       |
| 404  | Email inconnu            |

> **Conseil Flutter :** stocker le `secretKey` dans `flutter_secure_storage` plutôt que dans `SharedPreferences`.

---

### Vérifier / renouveler la session

À appeler au démarrage de l'app pour vérifier que la session est encore valide. Si `401` → renvoyer l'utilisateur vers l'écran de connexion.

```
GET /api/v1/auth/validate
Header: X-Secret-Key: <secretKey>
```

| Code | Signification                              |
|------|--------------------------------------------|
| 200  | Session valide — expiration repoussée de 30 jours |
| 401  | Session expirée → reconnecter l'utilisateur |

> La session expire après **30 jours sans utilisation**. Chaque appel à `/validate` remet le compteur à zéro.

---

## Upload d'image

### Uploader une photo (profil, etc.)

```
POST /api/v1/uploads
Header: X-Secret-Key: <secretKey>
Content-Type: multipart/form-data
Champ: file
```

Formats acceptés : `jpg`, `jpeg`, `png`, `gif`, `webp` — taille max : **5 Mo**

**Réponse 200**

```json
{ "url": "http://localhost:8080/api/v1/uploads/3f2a1b4c-uuid.jpg" }
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
request.headers['X-Secret-Key'] = secretKey;
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
Header: X-Secret-Key: <secretKey>
```

**Réponse 200**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "fullName": "Jean Dupont",
  "email": "jean.dupont@exemple.com",
  "profileUrl": "http://localhost:8080/api/v1/uploads/uuid.jpg",
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
| `accountType`     | string  | Type de compte (`STANDARD`)                    |
| `interestDomains` | liste   | Domaines d'intérêt suivis par l'utilisateur    |

| Code | Signification   |
|------|-----------------|
| 200  | Profil retourné |
| 401  | Non authentifié |

---

### Mettre à jour le profil

```
PUT /api/v1/utilisateurs/{id}
Header: X-Secret-Key: <secretKey>
Content-Type: application/json
```

```json
{
  "fullName": "Jean-Pierre Dupont",
  "profileUrl": "http://localhost:8080/api/v1/uploads/uuid.jpg"
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
Header: X-Secret-Key: <secretKey>
```

**Réponse 200**

```json
[
  { "id": "dom-1", "name": "Technologie", "description": "Secteur des nouvelles technologies" },
  { "id": "dom-2", "name": "Finance",     "description": "Marchés financiers et banque" }
]
```

---

### Ajouter un domaine d'intérêt à l'utilisateur

```
POST /api/v1/utilisateurs/{userId}/interest-domains/{domainId}
Header: X-Secret-Key: <secretKey>
```

Retourne le profil mis à jour (même format que `GET /api/v1/utilisateurs/me`).

| Code | Signification                      |
|------|------------------------------------|
| 200  | Domaine ajouté, profil retourné    |
| 401  | Non authentifié                    |
| 404  | Utilisateur ou domaine introuvable |

---

### Retirer un domaine d'intérêt

```
DELETE /api/v1/utilisateurs/{userId}/interest-domains/{domainId}
Header: X-Secret-Key: <secretKey>
```

| Code | Signification           |
|------|-------------------------|
| 204  | Domaine retiré          |
| 401  | Non authentifié         |
| 404  | Utilisateur introuvable |

---

## Erreurs

Toutes les erreurs ont le même format :

```json
{
  "status": 401,
  "message": "Authentification requise",
  "timestamp": "2026-06-23T00:22:15.117"
}
```

| Code | Cas typique                               |
|------|-------------------------------------------|
| 400  | Champ manquant ou invalide                |
| 401  | `secretKey` absent, invalide ou expiré    |
| 404  | Ressource introuvable                     |
| 500  | Erreur serveur (ex. problème d'envoi email) |

---

## Modèle de données Flutter (suggestion)

```dart
class AuthResponse {
  final String secretKey;
  final bool isNew;
}

class UploadResponse {
  final String url;
}

class UtilisateurDto {
  final String id;
  final String? fullName;
  final String email;
  final String? profileUrl;
  final String accountType;
  final List<InterestDomainDto> interestDomains;
}

class InterestDomainDto {
  final String id;
  final String name;
  final String description;
}
```

---

## Flux complet — résumé

```
Ouverture de l'app
       │
       ▼
secretKey en storage ?
   │              │
  Non            Oui
   │              │
   ▼              ▼
/request-otp   /api/v1/auth/validate
/verify-otp        │
   │           200 OK ? ──Non──► écran connexion
   ▼               │
 isNew ?          Oui
   │               │
  Oui             ▼
   ▼          Écran principal
Écran profil
(photo → POST /api/v1/uploads,
 remplir fullName via PUT /api/v1/utilisateurs/{id},
 choisir domaines via POST /api/v1/utilisateurs/{id}/interest-domains/{domId})
```
