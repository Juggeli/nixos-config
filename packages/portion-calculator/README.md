# Portion Calculator

Mobile-first web app for calculating food portion weights from batch cooking.

Save cooking vessels with their empty (tare) weights, then enter the total
weight (food + vessel) and the number of portions. The app computes:

```txt
netWeight     = totalWeight - vesselWeight
portionWeight = netWeight / portions      (rounded to 2 decimals)
```

It warns when the vessel weight is greater than or equal to the total weight,
but still lets you save.

## Features

- **Vessels** — add / edit / delete, listed alphabetically.
- **Calculator** — pick a vessel, enter total weight and portions, see a live
  preview, then save to history.
- **History** — newest first, grouped by Today / Yesterday / date, with a
  recalculate button that pre-fills the calculator.
- Calculations snapshot the vessel name and weight, so history stays correct if
  a vessel is later deleted.

## Stack

- Backend: Node + [Hono](https://hono.dev), serving the REST API and static
  frontend. Runs TypeScript directly via Node's native type stripping.
- Frontend: vanilla HTML/CSS/TypeScript, bundled with esbuild.
- Storage: a single JSON file.
- Tests: `node:test`.
- UI: dark, [Catppuccin Mocha](https://catppuccin.com) palette. Fonts
  (Fraunces, Karla) are self-hosted in `public/fonts`, so the app has no
  external dependencies at runtime.

## Run locally

Requires Node 24+.

```sh
npm install
npm run build      # bundle the frontend -> public/app.js
npm start          # start the server
```

For development:

```sh
npm run watch      # rebuild the frontend on change (separate terminal)
npm run dev        # run the server with --watch
```

Then open <http://127.0.0.1:3000>.

## Configuration

Environment variables (with defaults):

| Variable    | Default              | Description                    |
| ----------- | -------------------- | ------------------------------ |
| `DATA_FILE` | `./data/data.json`   | Path to the JSON store         |
| `PORT`      | `3000`               | Listen port                    |
| `HOST`      | `127.0.0.1`          | Bind address                   |

## API

```txt
GET    /api/vessels
POST   /api/vessels
PUT    /api/vessels/:id
DELETE /api/vessels/:id

GET    /api/calculations
POST   /api/calculations
```

## Tests

```sh
npm test
```

## Nix

Packaged with `buildNpmPackage` and exposed on the flake overlay as
`portion-calculator`. On host `haruka` it runs as a systemd service
(`haruka-portion-calculator`) storing data in
`/mnt/appdata/portion-calculator/data.json`, bound to `127.0.0.1:8091` and
published on the tailnet via `tailscale serve`.
