// Generates the Wolf OS artwork (SVG) into files/system/usr/share/wolf-os/art/.
// The image build turns these into PNGs (files/scripts/look.sh).
// Run from the repo root:  node art/generate.mjs
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";

const OUT = "files/system/usr/share/wolf-os/art";
mkdirSync(OUT, { recursive: true });

// ---- Palette -----------------------------------------------------------------
const C = {
  frost: "#CFF3FF",
  ice: "#8BE0FF",
  accent: "#33B5F0",
  deep: "#1D7FC0",
  abyss: "#0F4C7A",
  trench: "#0A2F4F",
  night: "#0B1220",
  text: "#DDF4FF",
};
// The right half of the head is one shade darker, as if lit from the left.
const darker = { [C.frost]: C.ice, [C.ice]: C.accent, [C.accent]: C.deep, [C.deep]: C.abyss, [C.abyss]: C.trench };

// ---- Wolf head (256 x 256), drawn as left-half facets and mirrored ------------------
const leftFacets = [
  { fill: C.ice, pts: [[58, 26], [100, 80], [46, 104]] }, // ear
  { fill: C.abyss, pts: [[64, 46], [90, 80], [58, 92]] }, // inner ear
  { fill: C.frost, pts: [[100, 80], [128, 70], [128, 122]] }, // forehead
  { fill: C.ice, pts: [[100, 80], [128, 122], [110, 134], [80, 124]] }, // brow
  { fill: C.accent, pts: [[46, 104], [100, 80], [80, 124]] }, // temple
  { fill: C.deep, pts: [[46, 104], [80, 124], [36, 142]] }, // upper cheek
  { fill: C.accent, pts: [[36, 142], [80, 124], [110, 134], [98, 172], [72, 190]] }, // cheek
  { fill: C.frost, pts: [[110, 134], [128, 122], [128, 198], [98, 172]] }, // muzzle
  { fill: C.ice, pts: [[72, 190], [98, 172], [128, 198], [128, 238]] }, // jaw
];
const eye = [[82, 126], [108, 133], [100, 139], [88, 136]];
const nose = [[114, 196], [142, 196], [128, 212]];

const mirror = (pts) => pts.map(([x, y]) => [256 - x, y]).reverse();
const poly = (pts, fill, extra = "") =>
  `<polygon points="${pts.map((p) => p.join(",")).join(" ")}" fill="${fill}"${extra}/>`;

function wolfHead({ stroke = true } = {}) {
  const s = stroke ? ` stroke="${C.night}" stroke-width="1.5" stroke-linejoin="round"` : "";
  const facets = [
    ...leftFacets.map((f) => poly(f.pts, f.fill, s)),
    ...leftFacets.map((f) => poly(mirror(f.pts), darker[f.fill], s)),
    poly(eye, C.night),
    poly(mirror(eye), C.night),
    poly(nose, C.night),
  ];
  return facets.join("\n  ");
}

const svg = (w, h, body, extra = "") =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"${extra}>\n  ${body}\n</svg>\n`;

// Icon: used for the app-menu button, About page and os-release LOGO
writeFileSync(`${OUT}/wolf-os-logo.svg`, svg(256, 256, wolfHead()));

// Emblem: head above the name, for the boot screen
writeFileSync(
  `${OUT}/wolf-os-emblem.svg`,
  svg(
    400,
    340,
    `<g transform="translate(88,0) scale(0.875)">\n  ${wolfHead()}\n  </g>
  <text x="200" y="318" text-anchor="middle" font-family="Noto Sans, DejaVu Sans, sans-serif" font-size="40" font-weight="300" letter-spacing="14" fill="${C.text}">WOLF OS</text>`,
  ),
);

// ---- Seeded random, so the wallpapers come out the same every run ---------------------
function rng(seed) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };
}

// ---- Wallpaper: Night (mountains, moon, stars) -------------------------------------
// A mountain ridge: `peaks` sharp summits with small shoulders and valleys between them.
function ridge(rand, { baseY, amp, peaks, W }) {
  const pts = [[0, baseY - amp * 0.2 * rand()]];
  const r = (v) => Math.round(v);
  for (let x = 0; x < W; ) {
    const w = (W / peaks) * (0.6 + rand() * 0.8);
    const px = x + w * (0.35 + rand() * 0.3);
    const py = baseY - amp * (0.45 + rand() * 0.55);
    pts.push([r(px - w * 0.18), r(py + amp * (0.15 + rand() * 0.15))]); // left shoulder
    pts.push([r(px), r(py)]); // summit
    pts.push([r(px + w * 0.14), r(py + amp * (0.12 + rand() * 0.15))]); // right shoulder
    x += w;
    pts.push([r(x), r(baseY - amp * 0.15 * rand())]); // valley
  }
  return pts;
}

function night() {
  const W = 3840, H = 2160, rand = rng(4242);
  const stars = Array.from({ length: 420 }, () => {
    const x = Math.round(rand() * W), y = Math.round(rand() * H * 0.62);
    const r = (rand() < 0.08 ? 2.6 : 1.2 + rand() * 1.1).toFixed(1);
    const o = (0.25 + rand() * 0.6).toFixed(2);
    return `<circle cx="${x}" cy="${y}" r="${r}" fill="${C.text}" opacity="${o}"/>`;
  }).join("");
  const layers = [
    { baseY: 1420, amp: 560, peaks: 5, fill: "#12243A", snow: 0.25 },
    { baseY: 1640, amp: 420, peaks: 7, fill: "#0E1C2E", snow: 0.16 },
    { baseY: 1860, amp: 300, peaks: 9, fill: "#0A1523", snow: 0.1 },
  ].map((l) => {
    const top = ridge(rand, { ...l, W });
    const body = [...top, [W, H], [0, H]];
    const line = top.map((p) => p.join(",")).join(" ");
    return `${poly(body, l.fill)}<polyline points="${line}" fill="none" stroke="${C.ice}" stroke-width="3" opacity="${l.snow}"/>`;
  }).join("\n  ");
  return svg(W, H, `<defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#050912"/><stop offset="0.65" stop-color="#0C1A2C"/><stop offset="1" stop-color="#10233A"/>
    </linearGradient>
    <radialGradient id="glow"><stop offset="0" stop-color="${C.ice}" stop-opacity="0.35"/><stop offset="1" stop-color="${C.ice}" stop-opacity="0"/></radialGradient>
    <radialGradient id="haze"><stop offset="0" stop-color="${C.accent}" stop-opacity="0.14"/><stop offset="1" stop-color="${C.accent}" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#sky)"/>
  <ellipse cx="${W * 0.55}" cy="1250" rx="2600" ry="520" fill="url(#haze)"/>
  ${stars}
  <circle cx="2860" cy="560" r="520" fill="url(#glow)"/>
  <circle cx="2860" cy="560" r="150" fill="#E6F7FF"/>
  <circle cx="2912" cy="530" r="150" fill="#0B1626" opacity="0.18"/>
  ${layers}`);
}

// ---- Wallpaper: Emblem (logo on a dark gradient) -------------------------------------
function emblem() {
  const W = 3840, H = 2160;
  return svg(W, H, `<defs>
    <radialGradient id="bg" cx="0.5" cy="0.45" r="0.75">
      <stop offset="0" stop-color="#132A44"/><stop offset="0.55" stop-color="#0A1422"/><stop offset="1" stop-color="#05080F"/>
    </radialGradient>
    <radialGradient id="glow"><stop offset="0" stop-color="${C.accent}" stop-opacity="0.28"/><stop offset="1" stop-color="${C.accent}" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#bg)"/>
  <circle cx="${W / 2}" cy="${H * 0.46}" r="760" fill="url(#glow)"/>
  <g transform="translate(${W / 2 - 320},${H * 0.46 - 330}) scale(2.5)" opacity="0.92">
  ${wolfHead()}
  </g>`);
}

writeFileSync(`${OUT}/wallpaper-night.svg`, night());
writeFileSync(`${OUT}/wallpaper-emblem.svg`, emblem());

// ---- Terminal logo for fastfetch: the same head as blocks, 31 columns wide ---------------
// Each row lists filled column ranges for the left half; the right half is mirrored.
// $1 = ice (left), $2 = accent (right), $3 = deep blue (inner ears); eyes and nose are gaps.
function terminalLogo() {
  const W = 31;
  const rows = [[[7, 7]], [[6, 8]], [[6, 10]], [[5, 11], [14, 15]], [[5, 15]], [[4, 15]], [[4, 15]],
    [[4, 15]], [[5, 15]], [[7, 15]], [[9, 15]], [[11, 15]], [[13, 15]], [[15, 15]]];
  const innerEar = { 1: [7, 7], 2: [8, 9], 3: [8, 10] };
  const gaps = { 7: [9, 12], 11: [14, 15] }; // eyes, nose
  return rows.map((ranges, r) => {
    const cells = Array(W).fill(" ");
    // right first, so the centre column (15) keeps the left colour
    const set = (a, b, left, right) => { for (let c = a; c <= b; c++) { cells[W - 1 - c] = right; cells[c] = left; } };
    for (const [a, b] of ranges) set(a, b, "$1", "$2");
    if (innerEar[r]) set(...innerEar[r], "$3", "$3");
    if (gaps[r]) set(...gaps[r], " ", " ");
    let line = "", colour = "";
    for (const cell of cells) {
      if (cell === " ") { line += " "; continue; }
      if (cell !== colour) { line += cell; colour = cell; }
      line += "█";
    }
    return line.trimEnd();
  }).join("\n") + "\n";
}
writeFileSync("files/system/usr/share/wolf-os/fastfetch-logo.txt", terminalLogo());

// ---- Preview page: open art/preview.html in a browser to check everything at once -------
const uri = (f) => `data:image/svg+xml;base64,${Buffer.from(readFileSync(`${OUT}/${f}`)).toString("base64")}`;
const logo = uri("wolf-os-logo.svg");
writeFileSync(
  "art/preview.html",
  `<!doctype html><html><head><meta charset="utf-8"><title>Wolf OS art preview</title><style>
body{margin:0;background:#1a1d21;color:#ddd;font:14px sans-serif}
.row{display:flex;gap:24px;align-items:end;padding:16px;flex-wrap:wrap}
.light{background:#eff0f1;color:#222}
.panel{background:#171e29;padding:6px 10px;display:flex;gap:12px;align-items:center}
img.wp{width:760px;display:block}
.ply{background:linear-gradient(#0e1726,#070b14);width:760px;height:428px;display:flex;flex-direction:column;align-items:center;justify-content:center}
</style></head><body>
<div class="row"><img src="${logo}" width="256"><img src="${logo}" width="64"><img src="${logo}" width="32">
<div class="panel"><img src="${logo}" width="24"><span>dark panel, 24px</span></div></div>
<div class="row light"><img src="${logo}" width="128"><img src="${logo}" width="22"> light panel, 22px</div>
<div class="row"><div class="ply"><img src="${uri("wolf-os-emblem.svg")}" height="200">
<div style="margin-top:60px;opacity:.6">boot screen: the password box goes here</div></div></div>
<div class="row"><img class="wp" src="${uri("wallpaper-night.svg")}"><img class="wp" src="${uri("wallpaper-emblem.svg")}"></div>
</body></html>
`,
);
console.log("wrote", OUT, "and art/preview.html");
