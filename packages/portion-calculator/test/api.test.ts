import assert from "node:assert";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { Store } from "../src/db.ts";
import { createApp } from "../src/server.ts";
import type { Calculation, Vessel } from "../src/types.ts";

async function makeApp() {
  const dir = await mkdtemp(join(tmpdir(), "portion-"));
  const store = new Store(join(dir, "data.json"));
  await store.init();
  const app = createApp(store, join(dir, "public"));
  return {
    app,
    cleanup: () => rm(dir, { recursive: true, force: true }),
  };
}

function json(res: Response): Promise<any> {
  return res.json();
}

const vesselBody = (name: string, weight: number) => ({
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ name, weight }),
});

test("vessel CRUD lifecycle", async () => {
  const { app, cleanup } = await makeApp();
  try {
    // Create two vessels.
    let res = await app.request("/api/vessels", vesselBody("Dutch oven", 1200));
    assert.strictEqual(res.status, 201);
    const created = (await json(res)) as Vessel;
    assert.strictEqual(created.name, "Dutch oven");
    assert.ok(created.id);

    await app.request("/api/vessels", vesselBody("Baking tray", 400));

    // List is alphabetical.
    res = await app.request("/api/vessels");
    const list = (await json(res)) as Vessel[];
    assert.deepStrictEqual(list.map((v) => v.name), ["Baking tray", "Dutch oven"]);

    // Update.
    res = await app.request(`/api/vessels/${created.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Big pot", weight: 1500 }),
    });
    assert.strictEqual(res.status, 200);
    assert.strictEqual((await json(res)).name, "Big pot");

    // Delete.
    res = await app.request(`/api/vessels/${created.id}`, { method: "DELETE" });
    assert.strictEqual(res.status, 200);

    res = await app.request(`/api/vessels/${created.id}`, { method: "DELETE" });
    assert.strictEqual(res.status, 404);
  } finally {
    await cleanup();
  }
});

test("vessel validation rejects bad input", async () => {
  const { app, cleanup } = await makeApp();
  try {
    let res = await app.request("/api/vessels", vesselBody("", 100));
    assert.strictEqual(res.status, 400);

    res = await app.request("/api/vessels", vesselBody("x".repeat(101), 100));
    assert.strictEqual(res.status, 400);

    res = await app.request("/api/vessels", vesselBody("Pot", -5));
    assert.strictEqual(res.status, 400);
  } finally {
    await cleanup();
  }
});

test("calculation stores snapshot and computes portion weight", async () => {
  const { app, cleanup } = await makeApp();
  try {
    const res = await app.request("/api/vessels", vesselBody("Pot", 500));
    const vessel = (await json(res)) as Vessel;

    const calcRes = await app.request("/api/calculations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ vesselId: vessel.id, totalWeight: 1500, portions: 4, note: "chili" }),
    });
    assert.strictEqual(calcRes.status, 201);
    const calc = (await json(calcRes)) as Calculation & { warning: boolean };
    assert.strictEqual(calc.netWeight, 1000);
    assert.strictEqual(calc.portionWeight, 250);
    assert.strictEqual(calc.vesselName, "Pot");
    assert.strictEqual(calc.vesselWeight, 500);
    assert.strictEqual(calc.warning, false);

    // Snapshot survives vessel deletion.
    await app.request(`/api/vessels/${vessel.id}`, { method: "DELETE" });
    const listRes = await app.request("/api/calculations");
    const list = (await json(listRes)) as Calculation[];
    assert.strictEqual(list.length, 1);
    assert.strictEqual(list[0].vesselName, "Pot");
  } finally {
    await cleanup();
  }
});

test("calculation validation and missing vessel", async () => {
  const { app, cleanup } = await makeApp();
  try {
    let res = await app.request("/api/calculations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ vesselId: "nope", totalWeight: 1000, portions: 2 }),
    });
    assert.strictEqual(res.status, 404);

    const v = (await json(await app.request("/api/vessels", vesselBody("Pot", 100)))) as Vessel;
    res = await app.request("/api/calculations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ vesselId: v.id, totalWeight: 1000, portions: 0 }),
    });
    assert.strictEqual(res.status, 400);
  } finally {
    await cleanup();
  }
});
