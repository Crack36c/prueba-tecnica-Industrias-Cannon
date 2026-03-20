export interface Towel {
  towelId: number;
  itemCode: string;
  productCode: string;
  status: string;
  boxId: number | null;
}

export interface CreateTowelRequest {
  itemCode: string;
  productCode: string;
}
