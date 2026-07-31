export interface CalcInput {
  vesselWeight: number;
  totalWeight: number;
  portions: number;
}

export interface CalcResult {
  netWeight: number;
  portionWeight: number;
  warning: boolean;
}

/** Round to 2 decimal places (EPSILON nudges half-way cases like 1.005 up). */
export function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

/**
 * Core portion math.
 * netWeight = totalWeight - vesselWeight
 * portionWeight = netWeight / portions
 * warning is true when the vessel weighs at least as much as the total
 * (i.e. net weight is zero or negative); saving is still allowed.
 */
export function calculate({ vesselWeight, totalWeight, portions }: CalcInput): CalcResult {
  const netWeight = round2(totalWeight - vesselWeight);
  const portionWeight = round2(netWeight / portions);
  const warning = vesselWeight >= totalWeight;
  return { netWeight, portionWeight, warning };
}
