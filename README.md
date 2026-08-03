# TrackExpense

**TrackExpense** est une application mobile de gestion de budget personnel, 100 % hors ligne, sécurisée et développée avec Flutter.

## Fonctionnalités principales

- **Dashboard interactif** : Solde, revenus/dépenses, graphique camembert dynamique.
- **Gestion des transactions** : Ajout, modification et suppression.
- **Catégories personnalisables** : Création et gestion de vos propres catégories.
- **Budgets mensuels** : Fixez des limites par catégorie avec barres de progression et alertes.
- **Sécurité avancée** : Chiffrement AES-256 des données, code PIN anti-bruteforce et biométrie (empreinte / Face ID).
- **Thème** : Mode clair et mode sombre (bascule rapide via l'AppBar).
- **Monnaie** : Adaptée au FCFA (facilement modifiable).

## 🛠 Technologies utilisées

| Technologie | Rôle |
| :--- | :--- |
| **Flutter** | Framework UI |
| **Riverpod** | Gestion d'état |
| **sqflite** | Base de données locale (SQLite) |
| **flutter_secure_storage** | Stockage sécurisé (clés, PIN) |
| **encrypt / crypto** | Chiffrement AES-256 |
| **local_auth** | Authentification biométrique |
| **fl_chart** | Graphiques (camembert) |

## Installation

1. Clonez le dépôt ou téléchargez le code source.
2. Ouvrez un terminal à la racine du projet.
3. Exécutez la commande suivante pour installer les dépendances :

   flutter pub get

## Architecture
Le projet suit une Clean Architecture structurée en trois couches :

- Domain : Entités et Use Cases (logique métier).
- Data : Repositories et base de données (SQLite).
- Presentation : UI, Providers (Riverpod) et écrans.

## Aperçu

- Dashboard : Vue d'ensemble de vos finances.
- Ajout de transaction : Formulaire avec sélecteur de catégorie et type (Dépense/Revenu).
- Budgets : Visualisation de l'état de vos budgets mensuels.

# Adama Diaw