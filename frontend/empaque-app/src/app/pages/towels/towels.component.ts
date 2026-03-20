import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TowelService } from '../../services/towel.service';
import { Towel } from '../../models/towel';

@Component({
  selector: 'app-towels',
  imports: [CommonModule, FormsModule],
  templateUrl: './towels.component.html',
  styleUrl: './towels.component.css'
})
export class TowelsComponent implements OnInit {
  towels: Towel[] = [];
  itemCode = '';
  productCode = '';
  error = '';
  loading = false;

  constructor(private towelService: TowelService) {}

  ngOnInit(): void {
    this.loadTowels();
  }

  loadTowels(): void {
    this.towelService.getAll().subscribe({
      next: data => this.towels = data,
      error: err => this.error = err.error || 'Error al cargar unidades'
    });
  }

  create(): void {
    this.error = '';
    if (!this.itemCode.trim() || !this.productCode.trim()) {
      this.error = 'ItemCode y ProductCode son requeridos.';
      return;
    }
    this.loading = true;
    this.towelService.create({ itemCode: this.itemCode.trim(), productCode: this.productCode.trim() }).subscribe({
      next: () => {
        this.itemCode = '';
        this.productCode = '';
        this.loading = false;
        this.loadTowels();
      },
      error: err => {
        this.error = typeof err.error === 'string' ? err.error : 'Error al crear unidad';
        this.loading = false;
      }
    });
  }

  disable(towel: Towel): void {
    if (!confirm(`Deshabilitar ${towel.itemCode}?`)) return;
    this.error = '';
    this.towelService.disable(towel.towelId).subscribe({
      next: () => this.loadTowels(),
      error: err => this.error = typeof err.error === 'string' ? err.error : 'Error al deshabilitar'
    });
  }
}
