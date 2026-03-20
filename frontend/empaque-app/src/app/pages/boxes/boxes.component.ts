import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { BoxService } from '../../services/box.service';
import { Box } from '../../models/box';

@Component({
  selector: 'app-boxes',
  imports: [CommonModule, FormsModule],
  templateUrl: './boxes.component.html',
  styleUrl: './boxes.component.css'
})
export class BoxesComponent implements OnInit {
  boxes: Box[] = [];
  boxCode = '';
  productCode = '';
  capacity: number | null = null;
  error = '';
  loading = false;

  constructor(private boxService: BoxService, private router: Router) {}

  ngOnInit(): void {
    this.loadBoxes();
  }

  loadBoxes(): void {
    this.boxService.getAll().subscribe({
      next: data => this.boxes = data,
      error: err => this.error = err.error || 'Error al cargar cajas'
    });
  }

  create(): void {
    this.error = '';
    if (!this.boxCode.trim() || !this.productCode.trim()) {
      this.error = 'BoxCode y ProductCode son requeridos.';
      return;
    }
    if (!this.capacity || this.capacity <= 0) {
      this.error = 'Capacity debe ser mayor a 0.';
      return;
    }
    this.loading = true;
    this.boxService.create({
      boxCode: this.boxCode.trim(),
      productCode: this.productCode.trim(),
      capacity: this.capacity
    }).subscribe({
      next: () => {
        this.boxCode = '';
        this.productCode = '';
        this.capacity = null;
        this.loading = false;
        this.loadBoxes();
      },
      error: err => {
        this.error = typeof err.error === 'string' ? err.error : 'Error al crear caja';
        this.loading = false;
      }
    });
  }

  disable(box: Box): void {
    if (!confirm(`Deshabilitar ${box.boxCode}?`)) return;
    this.error = '';
    this.boxService.disable(box.boxId).subscribe({
      next: () => this.loadBoxes(),
      error: err => this.error = typeof err.error === 'string' ? err.error : 'Error al deshabilitar'
    });
  }

  goDetail(box: Box): void {
    this.router.navigate(['/boxes', box.boxId]);
  }
}
