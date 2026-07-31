export interface Vessel {
  id: string;
  name: string;
  weight: number;
  createdAt: string;
}

export interface Calculation {
  id: string;
  vesselId: string;
  vesselName: string;
  vesselWeight: number;
  totalWeight: number;
  portions: number;
  portionWeight: number;
  netWeight: number;
  note?: string;
  createdAt: string;
}

export interface Data {
  vessels: Vessel[];
  calculations: Calculation[];
}
