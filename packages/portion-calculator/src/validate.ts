export type Result<T> =
  | { ok: true; value: T }
  | { ok: false; error: string };

function isFiniteNumber(v: unknown): v is number {
  return typeof v === "number" && Number.isFinite(v);
}

function asRecord(body: unknown): Record<string, unknown> {
  return typeof body === "object" && body !== null ? (body as Record<string, unknown>) : {};
}

export interface VesselInput {
  name: string;
  weight: number;
}

export function validateVessel(body: unknown): Result<VesselInput> {
  const r = asRecord(body);

  if (typeof r.name !== "string") {
    return { ok: false, error: "name is required" };
  }
  const name = r.name.trim();
  if (name.length === 0) {
    return { ok: false, error: "name is required" };
  }
  if (name.length > 100) {
    return { ok: false, error: "name must be at most 100 characters" };
  }

  if (!isFiniteNumber(r.weight)) {
    return { ok: false, error: "weight must be a number" };
  }
  if (r.weight < 0) {
    return { ok: false, error: "weight must be non-negative" };
  }

  return { ok: true, value: { name, weight: r.weight } };
}

export interface CalculationInput {
  vesselId: string;
  totalWeight: number;
  portions: number;
  note?: string;
}

export function validateCalculation(body: unknown): Result<CalculationInput> {
  const r = asRecord(body);

  if (typeof r.vesselId !== "string" || r.vesselId.trim() === "") {
    return { ok: false, error: "vesselId is required" };
  }

  if (!isFiniteNumber(r.totalWeight)) {
    return { ok: false, error: "totalWeight must be a number" };
  }
  if (r.totalWeight < 0) {
    return { ok: false, error: "totalWeight must be non-negative" };
  }

  if (!isFiniteNumber(r.portions) || !Number.isInteger(r.portions)) {
    return { ok: false, error: "portions must be an integer" };
  }
  if (r.portions < 1) {
    return { ok: false, error: "portions must be at least 1" };
  }

  let note: string | undefined;
  if (r.note !== undefined && r.note !== null) {
    if (typeof r.note !== "string") {
      return { ok: false, error: "note must be a string" };
    }
    const trimmed = r.note.trim();
    if (trimmed.length > 500) {
      return { ok: false, error: "note must be at most 500 characters" };
    }
    note = trimmed === "" ? undefined : trimmed;
  }

  return {
    ok: true,
    value: { vesselId: r.vesselId, totalWeight: r.totalWeight, portions: r.portions, note },
  };
}
