import { initVet45DS, VET45_DS_VERSION } from '../../../../../vet45-html-design-system/src/vet45-ds.js';
const host = document.getElementById('app-screen');
function hydrate(){ if (!host) return; initVet45DS(host); host.dataset.htmlDsVersion = VET45_DS_VERSION; }
if (host) {
  host.addEventListener('vet45canonicalrender', () => queueMicrotask(hydrate));
  hydrate();
}
