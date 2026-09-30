## Veyn Frontend (Angular 16 + Tailwind)

Application frontend Angular servant d'interface pour Veyn, avec TailwindCSS et Font Awesome. Ce dépôt contient notamment une interface de chat (`src/app/chat`) et les services associés.

### Prérequis

- **Node.js**: 18.x ou 20.x recommandé
- **npm**: 9+ (fourni avec Node)
- Optionnel: **Angular CLI** 16 si vous souhaitez l'installer globalement

Installation CLI (optionnelle):

```bash
npm i -g @angular/cli@16
```

Sans installation globale, utilisez `npx`.

### Installation

```bash
npm ci
# ou
npm install
```

### Démarrer en local

```bash
npm start
# équivaut à: ng serve
```

Ouvrez `http://localhost:4200/`. Le rechargement à chaud est activé.

### Scripts NPM

- `npm start`: lance le serveur de dev (`ng serve`)
- `npm run build`: build de production (`ng build`)
- `npm run watch`: build en watch mode (configuration développement)
- `npm test`: lance les tests unitaires Karma/Jasmine

### Build et déploiement

Build de production:

```bash
npm run build
# sortie dans dist/frontend
```

Servez le contenu du dossier `dist/frontend` via un serveur HTTP statique (Nginx, Apache, S3 + CDN, etc.).

### Tests

```bash
npm test
```

Exécute les tests unitaires avec Karma/Jasmine en mode watch interactif.

### Pile technique

- Angular 16.2 (CLI 16.2.16)
- TailwindCSS 3
- RxJS 7
- Font Awesome 6

### Structure du projet (extrait)

```text
src/
  app/
    app.module.ts
    app-routing.module.ts
    chat/
      chat.component.ts
      chat.component.html
      chat.component.css
    services/
      chat.service.ts
  assets/
    IMG/
      BG1.jpg
  styles.css        # styles globaux (inclut Tailwind)
  main.ts
```

### TailwindCSS

Le projet inclut `tailwind.config.js` et `postcss.config.js`. Les utilitaires Tailwind peuvent être utilisés directement dans les templates HTML (ex: `class="flex gap-2"`).

### Génération de code (scaffolding)

Avec CLI global:

```bash
ng generate component feature/ma-nouvelle-vue
ng generate service services/mon-service
```

Avec `npx` sans CLI global:

```bash
npx @angular/cli@16 generate component feature/ma-nouvelle-vue --yes
```

### Dépannage

- Versions Node non compatibles: utilisez Node 18/20 LTS.
- Problèmes de cache: supprimez `node_modules` et `package-lock.json`, puis `npm ci`.
- Port déjà utilisé: `ng serve --port 4300`.

### Licence

Ce projet est un projet interne développé dans le cadre d'un stage d'été chez Veyn.
