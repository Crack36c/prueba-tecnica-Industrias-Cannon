import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Box, CreateBoxRequest } from '../models/box';
import { Towel } from '../models/towel';

@Injectable({ providedIn: 'root' })
export class BoxService {
  private readonly api = 'http://localhost:5273/api/boxes';

  constructor(private http: HttpClient) {}

  getAll(): Observable<Box[]> {
    return this.http.get<Box[]>(this.api);
  }

  create(req: CreateBoxRequest): Observable<Box> {
    return this.http.post<Box>(this.api, req);
  }

  disable(boxId: number): Observable<void> {
    return this.http.put<void>(`${this.api}/${boxId}/disable`, {});
  }

  pack(boxId: number, towelId: number): Observable<any> {
    return this.http.post(`${this.api}/${boxId}/pack`, { towelId });
  }

  unpack(boxId: number, towelId: number): Observable<any> {
    return this.http.post(`${this.api}/${boxId}/unpack`, { towelId });
  }

  close(boxId: number): Observable<any> {
    return this.http.post(`${this.api}/${boxId}/close`, {});
  }
}
