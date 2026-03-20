export interface Box {
  boxId: number;
  boxCode: string;
  productCode: string;
  capacity: number;
  currentCount: number;
  status: string;
}

export interface CreateBoxRequest {
  boxCode: string;
  productCode: string;
  capacity: number;
}
