import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { BoxService } from '../../services/box.service';
import { TowelService } from '../../services/towel.service';
import { Box } from '../../models/box';
import { Towel } from '../../models/towel';

@Component({
  selector: 'app-box-detail',
  imports: [CommonModule, FormsModule],
  templateUrl: './box-detail.component.html',
  styleUrl: './box-detail.component.css'
})
export class BoxDetailComponent implements OnInit {
  boxId!: number;
  box: Box | null = null;
  packedTowels: Towel[] = [];
  looseTowels: Towel[] = [];
  selectedTowelId: number | null = null;
  error = '';
  loading = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private boxService: BoxService,
    private towelService: TowelService
  ) {}

  ngOnInit(): void {
    this.boxId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadData();
  }

  loadData(): void {
    this.boxService.getAll().subscribe({
      next: boxes => {
        this.box = boxes.find(b => b.boxId === this.boxId) ?? null;
        if (!this.box) {
          this.error = 'Caja no encontrada';
          return;
        }
        this.loadTowels();
      },
      error: () => this.error = 'Error al cargar caja'
    });
  }

  loadTowels(): void {
    this.towelService.getAll().subscribe({
      next: towels => {
        this.packedTowels = towels.filter(t => t.status === 'PACKED' && t.boxId === this.boxId);
        this.looseTowels = towels.filter(t => t.status === 'LOOSE' && this.box && t.productCode === this.box.productCode);
        this.selectedTowelId = this.looseTowels.length > 0 ? this.looseTowels[0].towelId : null;
      }
    });
  }

  pack(): void {
    if (!this.selectedTowelId) return;
    this.error = '';
    this.loading = true;
    this.boxService.pack(this.boxId, this.selectedTowelId).subscribe({
      next: () => { this.loading = false; this.loadData(); },
      error: err => {
        this.error = typeof err.error === 'string' ? err.error : (err.error?.message || 'Error al empacar');
        this.loading = false;
      }
    });
  }

  unpack(towel: Towel): void {
    this.error = '';
    this.loading = true;
    this.boxService.unpack(this.boxId, towel.towelId).subscribe({
      next: () => { this.loading = false; this.loadData(); },
      error: err => {
        this.error = typeof err.error === 'string' ? err.error : (err.error?.message || 'Error al sacar');
        this.loading = false;
      }
    });
  }

  closeBox(): void {
    if (!confirm('Cerrar esta caja? No se podrá empacar ni sacar unidades después.')) return;
    this.error = '';
    this.boxService.close(this.boxId).subscribe({
      next: () => this.loadData(),
      error: err => {
        this.error = typeof err.error === 'string' ? err.error : (err.error?.message || 'Error al cerrar');
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/boxes']);
  }
}
