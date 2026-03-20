import { Routes } from '@angular/router';
import { TowelsComponent } from './pages/towels/towels.component';
import { BoxesComponent } from './pages/boxes/boxes.component';
import { BoxDetailComponent } from './pages/box-detail/box-detail.component';

export const routes: Routes = [
  { path: '', redirectTo: 'towels', pathMatch: 'full' },
  { path: 'towels', component: TowelsComponent },
  { path: 'boxes', component: BoxesComponent },
  { path: 'boxes/:id', component: BoxDetailComponent },
];
