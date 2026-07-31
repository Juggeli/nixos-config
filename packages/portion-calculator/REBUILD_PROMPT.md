# Portion Calculator — Build Prompt

Build a functional mobile-first web app for calculating food portion weights from batch cooking.

## Core idea

User saves cooking vessels with their empty weights. Then enters total weight (food + vessel) and number of portions. App calculates:

```txt
netWeight = totalWeight - vesselWeight
portionWeight = netWeight / portions
```

Round portion weight to 2 decimals. Warn if vessel weight >= total weight, but still allow saving.

## Stack

Use a simple, common web stack:

- Frontend: HTML, CSS, TypeScript
- Backend: Node
- Storage: JSON file or SQLite
- No heavy frameworks required
- Keep dependencies minimal

The app should be easy to run locally.

## Features

### 1. Vessel management

- Add vessel: name + empty weight in grams
- Edit vessel
- Delete vessel with confirmation
- List vessels sorted alphabetically

Validation:

- Name required, max 100 chars
- Weight required, non-negative number

### 2. Calculator

Inputs:

- Select vessel
- Total weight in grams
- Number of portions, integer >= 1
- Optional note

Outputs:

- Portion weight
- Net weight
- Warning if vessel weight >= total weight

UX:

- Show live preview before saving
- Save calculation to history
- If no vessels exist, prompt user to add one first

### 3. History

- Show saved calculations newest first
- Group by date: Today, Yesterday, or date
- Each entry shows vessel, portion weight, net weight, total weight, portions, note
- Recalculate button pre-fills calculator from history entry

### 4. Navigation

Bottom navigation with:

- Calculator
- Vessels
- History

## API

```txt
GET    /api/vessels
POST   /api/vessels
PUT    /api/vessels/:id
DELETE /api/vessels/:id

GET    /api/calculations
POST   /api/calculations
```

Calculation stores vessel name and vessel weight at time of calculation, so history still works if vessel is deleted.

## Data model

```ts
Vessel {
  id: string
  name: string
  weight: number
  createdAt: string
}

Calculation {
  id: string
  vesselId: string
  vesselName: string
  vesselWeight: number
  totalWeight: number
  portions: number
  portionWeight: number
  netWeight: number
  note?: string
  createdAt: string
}
```

## Requirements

- Persistent storage
- Server-side validation
- Simple tests for calculation logic and API
- Mobile-friendly dark UI, Catppuccin Mocha colorscheme
- Provide run instructions in README
