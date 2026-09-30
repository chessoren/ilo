// SVG port of ilo/Bloub/BloubView.swift (static pose: no idle motion).
// Usage: <div data-bloub="shape=circle;color=ilo;expr=happy;size=300;gloss=1"></div>
(function () {
  const COLORS = {
    ink: '#0A0A0C', brown: '#8B5E3C', red: '#E8483F', orange: '#F08A24', amber: '#F0B429',
    green: '#3ECF8E', turquoise: '#2FBFA0', blue: '#3B93F0', violet: '#8B5CF6', pink: '#E152B0',
    grey: '#A3A3A3', cream: '#F1EFE9', ilo: '#5A6BFF'
  };
  const rad = d => d * Math.PI / 180;

  function rotate(e, t, angle) {
    const r = Math.cos(angle), i = Math.sin(angle);
    return [[e[0] * r + t[0] * i, e[1] * r + t[1] * i, e[2] * r + t[2] * i],
            [t[0] * r - e[0] * i, t[1] * r - e[1] * i, t[2] * r - e[2] * i]];
  }
  function project(gaze, radius, split) {
    let r = [0, 0, 1], i = [1, 0, 0], a = [0, 1, 0];
    [r, i] = rotate(r, i, rad(gaze[0]));
    [a, r] = rotate(a, r, rad(gaze[1]));
    [i, a] = rotate(i, a, rad(gaze[2]));
    return [-1, 1].map(side => {
      const [o, s] = rotate(r, i, rad(split * side));
      return { x: o[0] * radius, y: o[1] * radius, a: s[0], b: s[1], c: a[0], d: a[1], depth: o[2] };
    });
  }
  function radiusAt(angle, radii) {
    const n = radii.length;
    const turn = angle / (Math.PI * 2);
    const pos = (((turn % 1) + 1) % 1) * n;
    const i = Math.floor(pos);
    const a = radii[i % n], b = radii[(i + 1) % n];
    return a + (b - a) * (pos - i);
  }
  function smoothPath(pts, tension = 1 / 6) {
    const n = pts.length;
    let d = `M${pts[0][0].toFixed(2)},${pts[0][1].toFixed(2)}`;
    for (let i = 0; i < n; i++) {
      const p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
      const c1 = [p1[0] + (p2[0] - p0[0]) * tension, p1[1] + (p2[1] - p0[1]) * tension];
      const c2 = [p2[0] - (p3[0] - p1[0]) * tension, p2[1] - (p3[1] - p1[1]) * tension];
      d += `C${c1[0].toFixed(2)},${c1[1].toFixed(2)} ${c2[0].toFixed(2)},${c2[1].toFixed(2)} ${p2[0].toFixed(2)},${p2[1].toFixed(2)}`;
    }
    return d + 'Z';
  }

  let uid = 0;
  function bloubSVG(opts) {
    const shape = opts.shape || 'circle', colorName = opts.color || 'ilo';
    const exprName = opts.expr || 'neutral', size = +(opts.size || 200);
    const mode = opts.mode || 'face';
    const color = COLORS[colorName] || colorName;
    const eyeColor = colorName === 'cream' ? '#0A0A0C' : '#FFFFFF';
    const face = window.BLOUB_EXPRESSIONS[exprName];
    let radii = window.BLOUB_SHAPES[shape];
    const unit = size * 100 / 316, cx = size / 2, cy = size / 2;
    const id = 'bg' + (uid++);
    let out = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">`;
    const gloss = opts.gloss === '1' || opts.gloss === true;
    if (gloss) {
      out += `<defs><radialGradient id="${id}" cx="0.3" cy="0.22" r="0.95">` +
        `<stop offset="0" stop-color="#fff" stop-opacity="0.42"/><stop offset="0.45" stop-color="#fff" stop-opacity="0.08"/>` +
        `<stop offset="1" stop-color="#1a1f7a" stop-opacity="0.16"/></radialGradient></defs>`;
    }
    if (mode === 'thinking') {
      const dotR = 0.165;
      const dots = [[-0.557, dotR, 0.6], [-0.013, dotR * 1.25, 1], [0.532, dotR, 0.85]];
      dots.forEach(([x, r, o]) => {
        out += `<circle cx="${cx + x * unit}" cy="${cy}" r="${r * unit}" fill="${color}" opacity="${o}"/>`;
      });
      return out + '</svg>';
    }
    const pts = [];
    for (let i = 0; i < 64; i++) {
      const a = i / 64 * Math.PI * 2;
      pts.push([cx + radii[i] * Math.cos(a) * unit, cy + radii[i] * Math.sin(a) * unit]);
    }
    const d = smoothPath(pts);
    out += `<path d="${d}" fill="${color}"/>`;
    if (gloss) out += `<path d="${d}" fill="url(#${id})"/>`;
    const proj = project(face.gaze, unit, face.split);
    proj.forEach((p, index) => {
      if (p.depth <= 0.02) return;
      const eye = face.eyes[index];
      const [ew, eh, etilt, eopen] = eye;
      const s = radiusAt(Math.atan2(p.y, p.x), radii);
      const tilt = rad(etilt);
      const l = Math.cos(tilt), u = Math.sin(tilt);
      const A = p.a * l + p.c * u, F = p.b * l + p.d * u;
      const P = -p.a * u + p.c * l, M = -p.b * u + p.d * l;
      const v = 0.06 + 0.94 * Math.min(Math.max(eopen, 0), 1);
      const w = Math.max(ew * unit, 0.01), h = Math.max(eh * unit, 0.01);
      const tx = cx + p.x * s, ty = cy + p.y * s;
      const op = Math.min(Math.max(p.depth / 0.12, 0), 1);
      out += `<rect x="${-w / 2}" y="${-h / 2}" width="${w}" height="${h}" rx="${Math.min(w, h) / 2}" fill="${eyeColor}" opacity="${op}" ` +
        `transform="matrix(${A} ${F * v} ${P} ${M * v} ${tx} ${ty})"/>`;
    });
    return out + '</svg>';
  }
  window.bloubSVG = bloubSVG;

  function render() {
    document.querySelectorAll('[data-bloub]').forEach(el => {
      const opts = {};
      el.getAttribute('data-bloub').split(';').forEach(kv => {
        const [k, v] = kv.split('=');
        if (k) opts[k.trim()] = (v || '').trim();
      });
      el.innerHTML = bloubSVG(opts);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', render);
  else render();
})();
