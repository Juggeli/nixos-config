import assert from "node:assert";
import { test } from "node:test";
import { calculate, round2 } from "../src/calc.ts";

test("round2 rounds to two decimals", () => {
  assert.strictEqual(round2(1.005), 1.01);
  assert.strictEqual(round2(1.004), 1.0);
  assert.strictEqual(round2(3.14159), 3.14);
});

test("calculate computes net and portion weight", () => {
  const r = calculate({ vesselWeight: 500, totalWeight: 1500, portions: 4 });
  assert.strictEqual(r.netWeight, 1000);
  assert.strictEqual(r.portionWeight, 250);
  assert.strictEqual(r.warning, false);
});

test("calculate rounds portion weight to 2 decimals", () => {
  const r = calculate({ vesselWeight: 200, totalWeight: 1000, portions: 3 });
  assert.strictEqual(r.netWeight, 800);
  assert.strictEqual(r.portionWeight, 266.67);
});

test("calculate warns when vessel weight equals total weight", () => {
  const r = calculate({ vesselWeight: 1000, totalWeight: 1000, portions: 2 });
  assert.strictEqual(r.netWeight, 0);
  assert.strictEqual(r.portionWeight, 0);
  assert.strictEqual(r.warning, true);
});

test("calculate warns but still computes when vessel exceeds total", () => {
  const r = calculate({ vesselWeight: 1200, totalWeight: 1000, portions: 2 });
  assert.strictEqual(r.netWeight, -200);
  assert.strictEqual(r.portionWeight, -100);
  assert.strictEqual(r.warning, true);
});
