import { randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { Hono } from "hono";
import { calculate } from "./calc.ts";
import type { Store } from "./db.ts";
import type { Calculation, Vessel } from "./types.ts";
import { validateCalculation, validateVessel } from "./validate.ts";

const CONTENT_TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
};

function byName(a: Vessel, b: Vessel): number {
  return a.name.localeCompare(b.name);
}

function byNewest(a: Calculation, b: Calculation): number {
  return b.createdAt.localeCompare(a.createdAt);
}

export function createApp(store: Store, publicDir: string): Hono {
  const app = new Hono();

  // --- Vessels ---

  app.get("/api/vessels", async (c) => {
    const data = await store.read();
    return c.json([...data.vessels].sort(byName));
  });

  app.post("/api/vessels", async (c) => {
    const parsed = validateVessel(await c.req.json().catch(() => null));
    if (!parsed.ok) return c.json({ error: parsed.error }, 400);

    const vessel: Vessel = {
      id: randomUUID(),
      name: parsed.value.name,
      weight: parsed.value.weight,
      createdAt: new Date().toISOString(),
    };
    await store.update((data) => {
      data.vessels.push(vessel);
    });
    return c.json(vessel, 201);
  });

  app.put("/api/vessels/:id", async (c) => {
    const id = c.req.param("id");
    const parsed = validateVessel(await c.req.json().catch(() => null));
    if (!parsed.ok) return c.json({ error: parsed.error }, 400);

    let updated: Vessel | undefined;
    await store.update((data) => {
      const vessel = data.vessels.find((v) => v.id === id);
      if (!vessel) return;
      vessel.name = parsed.value!.name;
      vessel.weight = parsed.value!.weight;
      updated = vessel;
    });
    if (!updated) return c.json({ error: "vessel not found" }, 404);
    return c.json(updated);
  });

  app.delete("/api/vessels/:id", async (c) => {
    const id = c.req.param("id");
    let found = false;
    await store.update((data) => {
      const idx = data.vessels.findIndex((v) => v.id === id);
      if (idx === -1) return;
      data.vessels.splice(idx, 1);
      found = true;
    });
    if (!found) return c.json({ error: "vessel not found" }, 404);
    return c.json({ ok: true });
  });

  // --- Calculations ---

  app.get("/api/calculations", async (c) => {
    const data = await store.read();
    return c.json([...data.calculations].sort(byNewest));
  });

  app.post("/api/calculations", async (c) => {
    const parsed = validateCalculation(await c.req.json().catch(() => null));
    if (!parsed.ok) return c.json({ error: parsed.error }, 400);

    // Look up the vessel inside the update so a concurrent delete can't
    // slip between lookup and save.
    const saved = await store.update((data) => {
      const vessel = data.vessels.find((v) => v.id === parsed.value.vesselId);
      if (!vessel) return undefined;

      const { netWeight, portionWeight, warning } = calculate({
        vesselWeight: vessel.weight,
        totalWeight: parsed.value.totalWeight,
        portions: parsed.value.portions,
      });

      const calculation: Calculation = {
        id: randomUUID(),
        vesselId: vessel.id,
        vesselName: vessel.name,
        vesselWeight: vessel.weight,
        totalWeight: parsed.value.totalWeight,
        portions: parsed.value.portions,
        portionWeight,
        netWeight,
        note: parsed.value.note,
        createdAt: new Date().toISOString(),
      };
      data.calculations.push(calculation);
      return { calculation, warning };
    });
    if (!saved) return c.json({ error: "vessel not found" }, 404);
    return c.json({ ...saved.calculation, warning: saved.warning }, 201);
  });

  // --- Static frontend ---

  app.get("*", async (c) => {
    const url = new URL(c.req.url);
    const reqPath = url.pathname === "/" ? "/index.html" : url.pathname;
    // Prevent path traversal outside publicDir.
    const file = join(publicDir, normalize(reqPath).replace(/^(\.\.[/\\])+/, ""));
    if (!file.startsWith(publicDir)) return c.notFound();

    try {
      const body = await readFile(file);
      const type = CONTENT_TYPES[extname(file)] ?? "application/octet-stream";
      return c.body(body, 200, { "Content-Type": type });
    } catch {
      return c.notFound();
    }
  });

  return app;
}
