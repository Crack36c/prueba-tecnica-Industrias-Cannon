import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Towel, CreateTowelRequest } from '../models/towel';

@Injectable({ providedIn: 'root' })
export class TowelService {
  private readonly api = 'http://localhost:5273/api/towels';

  constructor(private http: HttpClient) {}

  getAll(): Observable<Towel[]> {
    return this.http.get<Towel[]>(this.api);
  }

  create(req: CreateTowelRequest): Observable<Towel> {
    return this.http.post<Towel>(this.api, req);
  }

  disable(towelId: number): Observable<void> {
    return this.http.put<void>(`${this.api}/${towelId}/disable`, {});
  }
}
