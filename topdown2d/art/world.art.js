// YANGON whole world, top-down pixel art at 16 px per metre, rendered in 100 m chunks.
// `DATA` is injected by build.mjs from world_data.mjs. Style: reference/topdown/topdown_03_cyberpunk_plaza.png.
const U = DATA.U, OX = DATA.OX, OY = DATA.OY, CM = DATA.CHUNK_M, CW = CM * U
let CX0 = 0, CY0 = 0, MX0 = 0, MZ0 = 0
const setChunk = (ch) => { CX0 = ch.i * CW; CY0 = ch.j * CW; MX0 = ch.x; MZ0 = ch.z }
const px = (x) => Math.round((x + OX) * U) - CX0
const pz = (z) => Math.round((z + OY) * U) - CY0
const vis = (x, z, w, d, pad = 2) => x < MX0 + CM + pad && x + w > MX0 - pad && z < MZ0 + CM + pad && z + d > MZ0 - pad
const RM = (c, x, z, w, d, col) => { if (!vis(x, z, w, d, 1)) return; const x0 = px(x), y0 = pz(z); c.rect(x0, y0, px(x + w) - x0, pz(z + d) - y0, col) }
const streamX = (z) => { const S = DATA.STREAM; for (let i = 0; i < S.length - 1; i++) if (z >= S[i][1] && z <= S[i + 1][1]) return S[i][0] + ((S[i + 1][0] - S[i][0]) * (z - S[i][1])) / (S[i + 1][1] - S[i][1]); return 65 }
const northStreamX = (z) => 355 + 8 * Math.sin(z * 0.027)
const riverBank = (x) => 685 + 7 * Math.sin(x * 0.012) + 3 * Math.sin(x * 0.032)
const riverWidth = (x) => 65 + 7 * Math.sin(x * 0.016 + 1)

pal({
  n: "#090c22", k: "#0b0a1c", x: "#04050e", "8": "#04050e99",
  g: "#1f4540", G: "#173730", f: "#2f5f50", h: "#112832",
  T: "#0e3035", t: "#1b5648", u: "#2e7d5b", U: "#52a06c",
  a: "#2b2850", A: "#221f42", y: "#e0a64a", Y: "#f4cc6e",
  p: "#4f4b7b", P: "#403c6b", q: "#6e6aa6", e: "#8782c0", "9": "#58548a",
  r: "#4a4678", R: "#35325d", w: "#3a3764", W: "#2a2751",
  o: "#d4553a", O: "#8c3a3d",
  l: "#ffd479", L: "#f0983f", Q: "#8d6a3f", J: "#233a6a", j: "#aab0d0",
  m: "#ff4fa3", M: "#a8286f", c: "#58f0e0", C: "#23919d",
  b: "#2f5f97", B: "#204676", v: "#79cbee",
  s: "#2f62ad", S: "#1c3f7c", z: "#5189d2",
  d: "#80533b", D: "#5a3a2b", E: "#4d3a43",
  i: "#9aa0c8", I: "#6b7099", V: "#c9cde8",
  H: "#15121f", N: "#d9a074", F: "#b9805a", Z: "#2f7a62", X: "#1d5242",
})
ramps("xGgf", "xAa", "xWPp9q", "xBbv", "xRre", "xTtuU")


function rng(seed) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

// ------------------------------------------------------------------ small parts
sprite("_tuft0", `
  .u.
  fuf
  GfG`)
sprite("_tuft1", `
  f..u
  Gf.fG
  GGfGG`)
sprite("_tuft2", `
  ..f
  .fu
  fGG`)
sprite("_bloom", `
  .m.
  mLm
  .M.`)
sprite("_bloomc", `
  .c.
  cLc
  .C.`)
sprite("_ac", { w: 46, h: 30, outline: "k" }, (c) => {
  c.rect(0, 0, 46, 30, "i"); c.rect(0, 22, 46, 8, "I"); c.hline(0, 0, 46, "V")
  for (const fx of [12, 34]) { c.circ(fx, 11, 9, "I"); c.circ(fx, 11, 7, "k"); c.ring(fx, 11, 4, "I"); c.px(fx, 11, "i"); c.line(fx - 5, 11, fx + 5, 11, "I"); c.line(fx, 6, fx, 16, "I") }
  c.px(43, 26, "l")
})
sprite("_tank", { w: 36, h: 36, outline: "k" }, (c) => {
  c.circ(18, 18, 17, "I"); c.circ(16, 16, 14, "i"); c.circ(14, 14, 7, "V"); c.ring(18, 18, 17, "k")
  c.hline(4, 18, 28, "I"); c.rect(14, 30, 8, 5, "I")
})
sprite("_skylight", { w: 44, h: 30, outline: "k" }, (c) => {
  c.rect(0, 0, 44, 30, "I"); c.rect(3, 3, 38, 24, "Q")
  for (let X = 3; X < 41; X += 9) c.vline(X, 3, 24, "I"); c.hline(3, 15, 38, "I")
})
sprite("_solar", { w: 64, h: 32, outline: "k" }, (c) => {
  c.rect(0, 0, 64, 32, "S")
  for (let X = 2; X < 62; X += 8) for (let Y = 2; Y < 30; Y += 10) { c.rect(X, Y, 7, 9, "s"); c.hline(X, Y, 7, "z") }
})
sprite("_vent", { w: 16, h: 16, outline: "k" }, (c) => { c.circ(8, 8, 8, "I"); c.circ(8, 8, 6, "k"); c.ring(8, 8, 3, "I"); c.circ(8, 8, 1, "i") })
sprite("_planter", { w: 48, h: 20, outline: "k" }, (c) => {
  c.rect(0, 0, 48, 20, "D"); c.rect(1, 1, 46, 12, "d"); c.rect(2, 2, 44, 8, "t")
  for (let X = 5; X < 44; X += 8) { c.circ(X, 6, 4, "u"); c.px(X - 1, 4, "U") ; if (X % 16 === 5) c.px(X + 1, 6, "m") }
})

// ------------------------------------------------------------------ chunked world drawing
const segDistA = (x, z, a, b) => {
  const dx = b[0] - a[0], dz = b[1] - a[1], L = dx * dx + dz * dz
  const t = L ? Math.max(0, Math.min(1, ((x - a[0]) * dx + (z - a[1]) * dz) / L)) : 0
  return Math.hypot(x - (a[0] + dx * t), z - (a[1] + dz * t))
}
const polyDistA = (x, z, pts) => { let d = 1e9; for (let i = 0; i < pts.length - 1; i++) d = Math.min(d, segDistA(x, z, pts[i], pts[i + 1])); return d }
const roadMargin = (x, z) => Math.min(...DATA.ROADS.map((r) => segDistA(x, z, r.a, r.b) - r.w / 2))
const hash2 = (a, b) => (((a * 73856093) ^ (b * 19349663)) >>> 0) % 1000 / 1000

function slabs(c, x, z, w, d, base, joint) {
  if (!vis(x, z, w, d, 1)) return
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0
  c.rect(x0, y0, W, D, base)
  const xa = Math.max(x0, 0), xb = Math.min(x0 + W, CW), ya = Math.max(y0, 0), yb = Math.min(y0 + D, CW)
  for (let X = Math.ceil(xa / U) * U; X < xb; X += U) c.vline(X, ya, yb - ya, joint)
  for (let Y = Math.ceil(ya / U) * U; Y < yb; Y += U) c.hline(xa, Y, xb - xa, joint)
  if (base === "p") for (let X = Math.floor(xa / U) * U; X < xb; X += U) for (let Y = Math.floor(ya / U) * U; Y < yb; Y += U) {
    if (X < x0 || Y < y0 || X + U > x0 + W || Y + U > y0 + D) continue
    if (hash2((X + CX0) / U, (Y + CY0) / U) < 0.03) c.rect(X + 1, Y + 1, U - 1, U - 1, "9")
  }
}
function pline(c, pts, wm, col) {
  const wp = Math.max(2, Math.round(wm * U))
  for (let i = 0; i < pts.length - 1; i++) {
    const [a, b] = [pts[i], pts[i + 1]]
    if (!vis(Math.min(a[0], b[0]) - wm, Math.min(a[1], b[1]) - wm, Math.abs(b[0] - a[0]) + 2 * wm, Math.abs(b[1] - a[1]) + 2 * wm, 1)) continue
    c.line(px(a[0]), pz(a[1]), px(b[0]), pz(b[1]), col, wp)
  }
}
const labelA = (s, W) => s.split(" ").reduce((o, w) => ((o + " " + w).trim().length * 8 <= W - 24 ? (o + " " + w).trim() : o), "")

function ground(c) {
  c.rect(0, 0, CW, CW, "n")
  const fill = (r, col) => { if (vis(r[0], r[1], r[2], r[3], 0)) RM(c, r[0], r[1], r[2], r[3], col) }
  for (const r of [[0, 0, 614, 614], [0, -700, 614, 400], [500, -300, 114, 300], [-300, 500, 300, 114], [-300, 614, 914, 196]]) fill(r, "g")
  fill([0, -300, 500, 300], "h"); fill([-300, 0, 300, 500], "h")
  if (vis(-300, 380, 300, 70, 0)) for (const [z, dn] of [[395, 0.25], [410, 0.5], [425, 0.75]]) if (vis(-300, z, 300, 15, 0)) c.dither(px(-300), pz(z), 300 * U, 15 * U, "h", "g", dn)
  c.scatter("_tuft*", 0, 0, CW, CW, 3600, { on: "gh", rflip: "x" })
  c.scatter("_bloom", 0, 0, CW, CW, 36, { on: "g" })
  c.scatter("_bloomc", 0, 0, CW, CW, 26, { on: "g" })
}
function waters(c) {
  // south river: one pixel column at a time
  if (vis(-300, 600, 914, 210, 0)) for (let X = 0; X < CW; X++) {
    const x = (X + CX0) / U - OX
    if (x < -300 || x > 614) continue
    const bank = riverBank(x), wd = riverWidth(x)
    const top = pz(bank), bot = pz(bank + wd)
    if (bot < 0 || top > CW) continue
    c.rect(X, top, 1, bot - top, "b"); c.rect(X, top, 1, 3, "e"); c.rect(X, top + 3, 1, 4, "B"); c.rect(X, bot - 7, 1, 4, "B"); c.rect(X, bot - 3, 1, 3, "e")
    c.rect(X, top - 6, 1, 6, "f")
    if (x < 614) { c.rect(X, pz(bank - 11), 1, 48, "p"); c.rect(X, pz(bank - 7), 1, 56, "C"); c.rect(X, pz(bank - 7), 1, 3, "c") }   // promenade + cycle path
  }
  if (vis(-300, 600, 914, 210, 0)) { const r = rng(7); for (let k = 0; k < 900; k++) { const x = -300 + r() * 914, z = riverBank(x) + 5 + r() * (riverWidth(x) - 10); if (vis(x, z, 1, 1, 0)) c.hline(px(x), pz(z), 5 + Math.floor(r() * 9), "v") } }
  // lake + boardwalk
  const L = DATA.LAKE
  if (vis(L.cx - 60, L.cz - 60, 120, 120, 0)) {
    for (const z of [497, 597]) RM(c, 496, z - 2, 108, 4, "d")
    for (const x of [498, 602]) RM(c, x - 2, 495, 4, 104, "d")
    c.ellipse(px(L.cx), pz(L.cz), 49 * U, 46 * U, "D"); c.ellipse(px(L.cx), pz(L.cz), L.rx * U, L.rz * U, "b")
    c.ellipse(px(L.cx), pz(L.cz), 36 * U, 32 * U, "B"); c.ellipse(px(L.cx), pz(L.cz), 30 * U, 26 * U, "b")
    const r = rng(8); for (let k = 0; k < 120; k++) { const a = r() * 6.28, d = Math.sqrt(r()) * 40; c.hline(px(L.cx + Math.cos(a) * d), pz(L.cz + Math.sin(a) * d * 0.9), 5 + Math.floor(r() * 7), "v") }
  }
  // north stream, waterfall, pool
  if (vis(300, -300, 120, 300, 8)) {
    for (let z = Math.max(-300, MZ0 - 2); z < Math.min(-30, MZ0 + CM + 2); z += 0.25) {
      const x = northStreamX(z), fall = z > -165 && z < -151, wd = z < -165 ? 6 : fall ? 4 : 5
      RM(c, x - wd / 2 - 0.5, z, wd + 1, 0.3, "e"); RM(c, x - wd / 2, z, wd, 0.3, fall ? "V" : "b")
      if (!fall) RM(c, x - wd / 4, z, wd / 2, 0.3, "B")
    }
    const P = DATA.POOL
    c.ellipse(px(P.x), pz(P.z), (P.rx + 1) * U, (P.rz + 1) * U, "e"); c.ellipse(px(P.x), pz(P.z), P.rx * U, P.rz * U, "B"); c.ellipse(px(P.x), pz(P.z), (P.rx - 3) * U, (P.rz - 3) * U, "b")
    const r = rng(9); for (let k = 0; k < 120; k++) { const z = -300 + r() * 264, x = northStreamX(z) + (r() - 0.5) * 3; if (vis(x, z, 1, 1, 0)) c.hline(px(x), pz(z), 5 + Math.floor(r() * 6), "v") }
  }
  // graded channels (decorative, flush crossing decks where paths pass)
  for (const ch of DATA.CHANNELS) { pline(c, ch.p, ch.w + 1.4, "e"); pline(c, ch.p, ch.w, "b") }
}
function paths(c) {
  for (const t of DATA.TRAILS) pline(c, t, 3.2, "E")        // under the forest trees? no: drawn after forest in forests()
  for (const p of DATA.PAVED) slabs(c, p[0], p[1], p[2], p[3], "p", "P")
  for (const [q, ring, sq] of [[DATA.QUAD, [150, 152.5], 1], [DATA.PLAZA, [450, 150], 1]]) {
    slabs(c, q[0], q[1], q[2], q[3], "P", "W"); slabs(c, q[0] + 2, q[1] + 2, q[2] - 4, q[3] - 4, "p", "P")
    if (vis(ring[0] - 18, ring[1] - 16, 36, 32, 0)) { const rr = q === DATA.QUAD ? 1 : 1.3; const qx = px(ring[0]), qy = pz(ring[1])
      c.ellipse(qx, qy, 16 * rr * U, 14 * rr * U, "9"); c.ellipse(qx, qy, 14.5 * rr * U, 12.8 * rr * U, "p"); c.ellipse(qx, qy, 11 * rr * U, 9.6 * rr * U, "P"); c.ellipse(qx, qy, 10.4 * rr * U, 9 * rr * U, "9") }
  }
}
function openPlots(c) {
  const t = DATA.TRAINING
  if (vis(t[0], t[1], t[2], t[3], 3)) {
    RM(c, t[0] - 1.5, t[1] - 1.5, t[2] + 3, t[3] + 3, "P"); RM(c, t[0], t[1], t[2], t[3], "f")
    for (let k = 0; k < t[2] / 3.5; k++) RM(c, t[0] + k * 3.5, t[1], 1.75, t[3], "u")
    const x0 = px(t[0] + 3), y0 = pz(t[1] + 3), W = (t[2] - 6) * U, D = (t[3] - 6) * U
    c.box(x0, y0, W, D, "V"); c.vline(x0 + W / 2, y0, D, "V"); c.ring(x0 + W / 2, y0 + D / 2, 5 * U, "V"); c.circ(x0 + W / 2, y0 + D / 2, 3, "V")
    c.box(x0, y0 + D / 2 - 3 * U, 2.2 * U, 6 * U, "V"); c.box(x0 + W - 2.2 * U, y0 + D / 2 - 3 * U, 2.2 * U, 6 * U, "V")
  }
  for (const [x, z, w, d, kind] of DATA.OPEN_PLOTS) {
    if (!vis(x, z, w, d, 3)) continue
    RM(c, x - 2, z - 2, w + 4, d + 4, "P")
    if (kind === "court") { RM(c, x, z, w, d, "C"); RM(c, x + 1, z + 1, w - 2, d - 2, "b"); const x0 = px(x + 3), y0 = pz(z + 3); c.box(x0, y0, (w - 6) * U, (d - 6) * U, "V"); c.vline(x0 + (w - 6) * U / 2, y0, (d - 6) * U, "V"); continue }
    RM(c, x, z, w, d, "f")
    if (kind === "lawn") { for (let k = 0; k < w / 3; k++) RM(c, x + k * 3, z, 1.5, d, "u"); continue }
    const r = rng(Math.round(x * 7 + z))
    for (let k = 0; k < w * d / 5; k++) {
      const gx = x + 1 + r() * (w - 2), gz = z + 1 + r() * (d - 2)
      if (!vis(gx, gz, 1, 1, 1)) continue
      c.circ(px(gx), pz(gz), 6 + Math.floor(r() * 6), r() < 0.7 ? "u" : "t"); if (r() < 0.35) c.px(px(gx), pz(gz) - 2, r() < 0.5 ? "m" : "L")
    }
  }
}
function terraces(c) {
  if (vis(5, 70, 281, 150, 3)) for (const ez of [80, 210]) {
    if (!vis(5, ez, 281, 3, 2)) continue
    const x0 = px(5), W = px(286) - x0, y0 = pz(ez)
    c.rect(x0, y0, W, 2 * U + 4, "w"); c.hline(x0, y0, W, "e"); c.hline(x0, y0 + 1, W, "q"); c.rect(x0, y0 + 2 * U + 1, W, 3, "W")
    for (let X = x0 + 12; X < x0 + W; X += 40) c.vline(X, y0 + 2, 2 * U - 1, "W")
    for (let X = x0 + 34; X < x0 + W; X += 120) { c.rect(X, y0 + 14, 2, 18, "o"); c.vline(X, y0 + 2, 12, "O") }
    for (const cx of DATA.CX) {
      slabs(c, cx - 4, ez - 0.2, 8, 3, "P", "W")
      for (let t = 0; t < 8; t++) { c.rect(px(cx - 4), y0 + t * 6, 8 * U, 2, "q"); c.rect(px(cx - 4), y0 + t * 6 + 2, 8 * U, 4, t % 2 ? "p" : "9") }
      c.rect(px(cx - 4), y0 + 50, 8 * U, 3, "W"); c.rect(px(cx - 4.3), y0 - 2, 5, 52, "I"); c.rect(px(cx + 4), y0 - 2, 5, 52, "I")
      c.rect(px(cx + 25), y0 - 4, 6 * U, 2 * U + 8, "P")
      for (let t = 0; t < 5; t++) c.poly([px(cx + 26), y0 + 30 - t * 6, px(cx + 28), y0 + 24 - t * 6, px(cx + 30), y0 + 30 - t * 6, px(cx + 28), y0 + 33 - t * 6], "Y")
    }
  }
  // waterfront retaining wall + the three stairs
  if (vis(-300, 640, 914, 14, 2)) {
    const x0 = px(-300), W = px(614) - x0, y0 = pz(645)
    c.rect(x0, y0, W, 2 * U, "w"); c.hline(x0, y0, W, "e"); c.hline(x0, y0 + 1, W, "q"); c.rect(x0, y0 + 2 * U - 3, W, 3, "W")
    for (let X = x0 + 14; X < x0 + W; X += 48) c.vline(X, y0 + 2, 2 * U - 5, "W")
  }
  for (const sx of [-30, 150, 520]) if (vis(sx - 4, 622, 8, 30, 2)) {
    for (let k = 0; k < 13; k++) { RM(c, sx - 3.5, 624 + k * 2, 7, 1, "q"); RM(c, sx - 3.5, 625 + k * 2, 7, 1, k % 2 ? "P" : "9") }
    RM(c, sx - 3.8, 624, 0.3, 26, "I"); RM(c, sx + 3.5, 624, 0.3, 26, "I")
  }
}
function campusStream(c) {
  if (!vis(55, 0, 30, 316, 2)) return
  const W = 2.9
  for (let z = Math.max(0, MZ0 - 1); z < Math.min(316, MZ0 + CM + 1); z += 0.25) { const x = streamX(z); RM(c, x - (W + 0.9) / 2, z, W + 0.9, 0.3, "e"); RM(c, x - W / 2, z, W, 0.3, "b"); RM(c, x - W / 4, z, W / 2, 0.3, "B") }
  const r = rng(77); for (let k = 0; k < 500; k++) { const z = r() * 316, x = streamX(z) + (r() - 0.5) * 2; if (vis(x, z, 1, 1, 0)) c.hline(px(x), pz(z), 5 + Math.floor(r() * 7), "v") }
  for (const z of DATA.PROM) { const x = streamX(z)
    slabs(c, x - 2.4, z - 3, 4.8, 6, "p", "P"); RM(c, x - 2.6, z - 3.2, 5.2, 0.3, "I"); RM(c, x - 2.6, z + 2.9, 5.2, 0.3, "I")
    for (const dz of [-3.2, 2.9]) for (const dx of [-2.6, 2.3]) RM(c, x + dx, z + dz - 0.1, 0.35, 0.5, "i") }
}
const deg = {}
for (const r of DATA.ROADS) for (const p of [r.a, r.b]) { const k = p[0] + "," + p[1]; deg[k] = (deg[k] || 0) + 1 }
function roads(c) {
  const V = (x, z, w, d, col) => RM(c, x, z, w, d, col)
  const R = DATA.ROADS
  for (const r of R) {
    const horiz = r.a[1] === r.b[1], h = r.w / 2 + 2, x0 = Math.min(r.a[0], r.b[0]), z0 = Math.min(r.a[1], r.b[1])
    if (horiz) slabs(c, x0 - h, r.a[1] - h, Math.abs(r.b[0] - r.a[0]) + 2 * h, 2 * h, "p", "P"); else slabs(c, r.a[0] - h, z0 - h, 2 * h, Math.abs(r.b[1] - r.a[1]) + 2 * h, "p", "P")
  }
  for (const r of R) {
    const horiz = r.a[1] === r.b[1], h = r.w / 2, x0 = Math.min(r.a[0], r.b[0]), z0 = Math.min(r.a[1], r.b[1])
    if (horiz) V(x0 - h, r.a[1] - h, Math.abs(r.b[0] - r.a[0]) + 2 * h, 2 * h, "a"); else V(r.a[0] - h, z0 - h, 2 * h, Math.abs(r.b[1] - r.a[1]) + 2 * h, "a")
  }
  for (const r of R) {
    const horiz = r.a[1] === r.b[1], h = r.w / 2, x0 = Math.min(r.a[0], r.b[0]), z0 = Math.min(r.a[1], r.b[1])
    const len = horiz ? Math.abs(r.b[0] - r.a[0]) : Math.abs(r.b[1] - r.a[1])
    const bx = horiz ? x0 - h : r.a[0] - h, bz = horiz ? r.a[1] - h : z0 - h, bw = horiz ? len + 2 * h : 2 * h, bd = horiz ? 2 * h : len + 2 * h
    if (!vis(bx, bz, bw, bd, 1)) continue
    // asphalt grain (granular: noise is right here), clipped to the chunk
    const gx0 = Math.max(px(bx), 0), gy0 = Math.max(pz(bz), 0), gx1 = Math.min(px(bx + bw), CW), gy1 = Math.min(pz(bz + bd), CW)
    if (gx1 > gx0 && gy1 > gy0) c.noise(gx0, gy0, gx1 - gx0, gy1 - gy0, "A", 0.05, 9, "a")
    for (let t = 1; t < len - 1; t += 3) {
      const wx = horiz ? x0 + t : 0, wz = horiz ? 0 : z0 + t
      if (horiz ? !(wx > MX0 - 3 && wx < MX0 + CM + 3) : !(wz > MZ0 - 3 && wz < MZ0 + CM + 3)) continue
      if (r.w === 18) {
        for (const off of [-0.35, 0.35]) horiz ? V(wx, r.a[1] + off, 2.4, 0.12, "y") : V(r.a[0] + off, wz, 0.12, 2.4, "y")
        for (const off of [-4.5, 4.5]) horiz ? V(wx, r.a[1] + off, 1.4, 0.1, "i") : V(r.a[0] + off, wz, 0.1, 1.4, "i")
      } else horiz ? V(wx, r.a[1] - 0.06, 1.8, 0.12, "Y") : V(r.a[0] - 0.06, wz, 0.12, 1.8, "Y")
    }
    const E = (xx, yy, ww, hh) => c.rect(xx, yy, ww, hh, "e")
    const x1 = px(bx), y1 = pz(bz), W1 = px(bx + bw) - x1, D1 = pz(bz + bd) - y1
    if (horiz) { E(x1, y1, W1, 2); E(x1, y1 + D1 - 3, W1, 3) } else { E(x1, y1, 2, D1); E(x1 + W1 - 3, y1, 3, D1) }
  }
  for (const k in deg) if (deg[k] === 2) {   // corner squares
    const [x, z] = k.split(",").map(Number)
    const w = Math.max(...R.filter((r) => (r.a[0] === x && r.a[1] === z) || (r.b[0] === x && r.b[1] === z)).map((r) => r.w))
    if (!vis(x - w / 2 - 2, z - w / 2 - 2, w + 4, w + 4, 1)) continue
    V(x - w / 2 - 2, z - w / 2 - 2, w + 4, w + 4, "p"); V(x - w / 2, z - w / 2, w, w, "a")
  }
  for (let k = 0; k < 9; k++) {     // zebra crossings around the central junction
    V(293.2 + k * 2, 276, 1, 2.4, "V"); V(293.2 + k * 2, 323.6, 1, 2.4, "V"); V(276, 293.2 + k * 2, 2.4, 1, "V"); V(323.6, 293.2 + k * 2, 2.4, 1, "V")
  }
}
function forests(c) {
  for (const f of DATA.FORESTS) {
    if (!vis(f[0], f[1], f[2], f[3], 8)) continue
    const sp = 6.2
    const ix0 = Math.floor((Math.max(f[0], MX0 - 8) - f[0]) / sp), ix1 = Math.ceil((Math.min(f[0] + f[2], MX0 + CM + 8) - f[0]) / sp)
    const iz0 = Math.floor((Math.max(f[1], MZ0 - 8) - f[1]) / sp), iz1 = Math.ceil((Math.min(f[1] + f[3], MZ0 + CM + 8) - f[1]) / sp)
    for (let iz = iz0; iz <= iz1; iz++) for (let ix = ix0; ix <= ix1; ix++) {
      const r = rng(((ix + 1000) * 7919 + (iz + 1000) * 104729 + Math.round(f[0])) >>> 0)
      const tx = f[0] + ix * sp + (r() - 0.5) * sp * 0.9, tz = f[1] + iz * sp + (r() - 0.5) * sp * 0.9
      const rad = 26 + r() * 14, thin = r(), hi = r()
      if (tx < f[0] || tx > f[0] + f[2] || tz < f[1] || tz > f[1] + f[3]) continue
      if (f[0] < 0 && tz > 330 && thin < (tz - 330) / 100) continue
      if (DATA.TRAILS.some((t) => polyDistA(tx, tz, t) < 4)) continue
      if (tz < 0 && Math.abs(tx - northStreamX(tz)) < 8) continue
      if (Math.hypot((tx - DATA.POOL.x) / 17, (tz - DATA.POOL.z) / 13) < 1) continue
      if (roadMargin(tx, tz) < 3) continue
      const X = px(tx), Y = pz(tz)
      if (X < -60 || X > CW + 60 || Y < -60 || Y > CW + 90) continue
      c.ellipse(X + 8, Y + 22, rad * 0.9, rad * 0.35, "8"); c.rect(X - 4, Y + 6, 8, 18, "D")
      c.circ(X, Y - 8, rad, "T"); c.circ(X - 3, Y - 11, rad * 0.78, "t"); c.circ(X - rad * 0.28, Y - 8 - rad * 0.32, rad * 0.42, "u")
      if (hi < 0.5) c.circ(X - rad * 0.4, Y - 8 - rad * 0.4, rad * 0.16, "U")
    }
  }
  for (const t of DATA.TRAILS) pline(c, t, 3.2, "E")
}

// ---- buildings
function roofProps(c, x0, y0, W, RH, id, name, solar) {
  const r = rng(id * 977 + 3)
  const garden = /APART|APT|FAMILY|COURT|HOME|GARDEN|TECH/.test(name)
  for (let gx = x0 + 28; gx < x0 + W - 80; gx += 96) for (let gy = y0 + 24; gy < y0 + RH - 64; gy += 84) {
    const k = r(), ox = gx + Math.floor(r() * 24), oy = gy + Math.floor(r() * 18)
    if (ox > CW + 100 || oy > CW + 100 || ox < -100 || oy < -100) continue
    if (k < 0.2) c.stamp("_ac", ox, oy)
    else if (k < 0.3) c.stamp("_tank", ox, oy)
    else if (k < 0.4) c.stamp("_skylight", ox, oy)
    else if (k < 0.62 && solar) c.stamp("_solar", ox, oy)
    else if (k < 0.62 && garden) c.stamp("_planter", ox, oy)
    else if (k < 0.7) c.stamp("_vent", ox, oy)
    else if (k < 0.76) { c.line(ox, oy, ox + 40, oy, "I", 3); c.line(ox, oy, ox, oy + 30, "I", 3) }
  }
  c.vline(x0 + W - 22, y0 + 14, 34, "I"); c.px(x0 + W - 22, y0 + 12, "o")
}
function building(c, b, mode) {
  const [id, type, name, x, z, w, d, floors] = b
  if (!vis(x, z, w, d + 4, 8)) return
  const idn = DATA.BUILDINGS.indexOf(b) + 1
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0
  const faceM = 3.2 + floors * 1.7, F = Math.round(faceM * U), RH = D - F
  const emis = mode === "emis", fy = y0 + RH
  if (!emis) {
    c.rect(x0, y0, W, RH, "W"); c.rect(x0 + 5, y0 + 5, W - 10, RH - 9, "r")
    c.rect(x0 + 5, y0 + 5, W - 10, 6, "R"); c.rect(x0 + 5, y0 + 5, 6, RH - 9, "R")
    c.hline(x0, y0, W, "e"); c.hline(x0, y0 + 1, W, "q"); c.vline(x0, y0, RH, "e"); c.vline(x0 + 1, y0, RH, "q")
    for (let X = x0 + 40; X < x0 + W - 6; X += 40) if (X > -2 && X < CW + 2) c.vline(X, y0 + 11, RH - 20, "R")
    for (let Y = y0 + 40; Y < y0 + RH - 6; Y += 40) if (Y > -2 && Y < CW + 2) c.hline(x0 + 11, Y, W - 20, "R")
    if (id === "hangar") {
      c.rect(x0 + 6, y0 + 6, W - 12, RH - 12, "I")
      for (let Y = y0 + 12; Y < y0 + RH - 8; Y += 12) { c.hline(x0 + 6, Y, W - 12, "R"); c.hline(x0 + 6, Y + 1, W - 12, "i") }
      c.rect(x0 + 6, y0 + RH / 2 - 8, W - 12, 16, "R"); c.rect(x0 + 6, y0 + RH / 2 - 5, W - 12, 3, "c")
      for (let X = x0 + 30; X < x0 + W - 12; X += 56) c.vline(X, y0 + 6, RH - 12, "W")
    } else roofProps(c, x0, y0, W, RH, idn, name, /ADMIN|CLASS|RESEARCH|PILOT|DORM|UNION|CLINIC|STUDIO|APART|APT/.test(name))
    c.rect(x0, fy, W, F, "w"); c.hline(x0, fy, W, "e"); c.hline(x0, fy + 1, W, "q"); c.rect(x0, fy + 2, W, 3, "W")
    for (let X = x0 + 24; X < x0 + W; X += 24) if (X > -2 && X < CW + 2) c.vline(X, fy + 5, F - 12, "W")
    c.rect(x0, fy + F - 7, W, 7, "W"); c.hline(x0, fy + F - 1, W, "k")
  }
  const bandH = 22, sgn = labelA(name, W)
  if (!emis) { c.rect(x0 + 8, fy + 9, W - 16, bandH, "k"); c.box(x0 + 8, fy + 9, W - 16, bandH, "W") }
  const nc = ["c", "m", "L"][idn % 3], tx = x0 + Math.floor((W - sgn.length * 8 + 2) / 2)
  if (emis) c.text(tx, fy + 14, sgn, nc, { scale: 2 }); else c.text(tx, fy + 14, sgn, { c: "C", m: "M", L: "Q" }[nc], { scale: 2 })
  const wy0 = fy + 9 + bandH + 10, avail = fy + F - 20 - wy0
  const rows = Math.max(1, Math.min(floors, Math.floor(avail / 30))), rowH = Math.floor(avail / rows)
  const r = rng(idn * 313 + 5)
  for (let rI = 0; rI < rows; rI++) for (let cx = x0 + 14; cx + 26 <= x0 + W - 12; cx += 38) {
    const lit = r() < 0.55, wy = wy0 + rI * rowH, wh = Math.min(rowH - 8, 26)
    if (emis) { if (lit) { c.rect(cx, wy, 24, wh, "l"); c.rect(cx + 2, wy + 2, 20, 2, "V"); c.vline(cx + 12, wy, wh, "L") } }
    else { c.rect(cx - 2, wy - 2, 28, wh + 4, "k"); c.rect(cx, wy, 24, wh, lit ? "Q" : "J"); if (!lit) { c.hline(cx, wy, 24, "s"); c.line(cx + 4, wy + wh - 2, cx + 12, wy + 2, "z", 1) } c.hline(cx - 2, wy + wh + 2, 28, "I") }
  }
  doorGlyph(c, x + w / 2, fy + F, mode)
  if (!emis && idn % 2 === 0) { c.rect(x0 + W - 11, fy + 6, 3, F - 14, "o"); c.rect(x0 + W - 11, fy + 6, 3, 3, "O") }
  if (!emis && idn % 3 === 0) { c.rect(x0 + 8, fy + 6, 3, F - 14, "i"); c.rect(x0 + 8, fy + 6, 3, 5, "I") }
}
function doorGlyph(c, xm, yBottomPx, mode) {
  const dx = px(xm) - 28, dy = yBottomPx - 52
  if (mode !== "emis") {
    c.rect(dx - 6, dy - 8, 68, 8, "R"); c.hline(dx - 6, dy - 8, 68, "e")
    c.rect(dx, dy, 56, 46, "k"); c.rect(dx + 3, dy + 3, 24, 42, "J"); c.rect(dx + 29, dy + 3, 24, 42, "J")
    c.line(dx + 6, dy + 38, dx + 14, dy + 6, "s", 1); c.line(dx + 32, dy + 38, dx + 40, dy + 6, "s", 1); c.rect(dx + 2, dy + 46, 52, 3, "q")
  } else { c.rect(dx, dy, 56, 3, "c"); c.vline(dx, dy, 46, "c"); c.vline(dx + 55, dy, 46, "c"); c.vline(dx + 28, dy + 3, 43, "c"); c.rect(dx + 3, dy + 3, 24, 4, "C"); c.rect(dx + 29, dy + 3, 24, 4, "C") }
}
function hall(c, h, mode) {
  const [id, type, name, x, z, w, d] = h
  if (!vis(x, z, w, d + 4, 8)) return
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0, emis = mode === "emis"
  if (!emis) {
    c.rect(x0, y0, W, D, "S"); c.rect(x0 + 3, y0 + 3, W - 6, D - 20, "s")
    for (let X = x0 + 20; X < x0 + W - 3; X += 24) if (X > -2 && X < CW + 2) { c.vline(X, y0 + 3, D - 20, "S"); c.vline(X + 1, y0 + 3, D - 20, "z") }
    c.rect(x0 + 3, y0 + (D - 20) / 2 - 12, W - 6, 24, "z"); c.hline(x0 + 3, y0 + (D - 20) / 2 + 12, W - 6, "S")
    c.hline(x0, y0, W, "e"); c.rect(x0, y0 + D - 18, W, 18, "w"); c.hline(x0, y0 + D - 18, W, "e"); c.hline(x0, y0 + D - 1, W, "k")
  }
  const sgn = labelA(name, W), tx = x0 + Math.floor((W - sgn.length * 8 + 2) / 2)
  if (emis) c.text(tx, y0 + D - 14, sgn, "L", { scale: 1 }); else c.text(tx, y0 + D - 14, sgn, "Q", { scale: 1 })
  if (emis) for (let X = x0 + 10; X < x0 + W - 20; X += 38) c.rect(X, y0 + D - 20, 24, 3, "l")
  doorGlyph(c, x + w / 2, y0 + D, mode)
}
function shelter(c, s, mode) {
  const [x, z, w, d, name] = s
  if (!vis(x, z, w, d, 6)) return
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = Math.min(pz(z + d) - y0, 26 * U / 2)
  if (mode !== "emis") {
    c.rect(x0, y0, W, D, "R"); c.rect(x0 + 3, y0 + 3, W - 6, D - 6, "r"); c.hline(x0, y0, W, "e")
    for (let X = x0 + 12; X < x0 + W - 12; X += 56) c.rect(X, y0 + 12, 40, 16, "s")
    for (let X = x0 + 20; X < x0 + W - 20; X += 120) { c.rect(X, y0 + D, 4, 22, "I"); }
    c.text(x0 + 16, y0 + D - 14, name, "C", { scale: 1 })
  } else { c.rect(x0 + 3, y0 + D - 6, W - 6, 3, "c"); c.text(x0 + 16, y0 + D - 14, name, "c", { scale: 1 }) }
}
function skytrain(c, mode) {
  const lines = [DATA.CITY_LINE.concat([DATA.CITY_LINE[0]]), DATA.MARKET_LINE]
  for (const pts of lines) for (let i = 0; i < pts.length - 1; i++) {
    const [a, b] = [pts[i], pts[i + 1]]
    const bx = Math.min(a[0], b[0]) - 4, bz = Math.min(a[1], b[1]) - 4, bw = Math.abs(b[0] - a[0]) + 8, bd = Math.abs(b[1] - a[1]) + 8
    if (!vis(bx, bz, bw, bd, 2)) continue
    const horiz = a[1] === b[1], len = horiz ? Math.abs(b[0] - a[0]) : Math.abs(b[1] - a[1])
    const x0 = Math.min(a[0], b[0]), z0 = Math.min(a[1], b[1])
    if (mode !== "emis") {
      if (horiz) { RM(c, x0, a[1] - 2.2, len, 0.5, "x"); RM(c, x0, a[1] - 1.7, len, 3.4, "W"); RM(c, x0, a[1] - 1.7, len, 0.3, "e"); RM(c, x0, a[1] - 1.0, len, 0.25, "i"); RM(c, x0, a[1] + 0.75, len, 0.25, "i")
        for (let t = 6; t < len; t += 24) { RM(c, x0 + t, a[1] + 1.7, 1.6, 2.2, "I"); RM(c, x0 + t, a[1] + 3.6, 1.6, 0.4, "x") } }
      else { RM(c, a[0] - 2.2, z0, 0.5, len, "x"); RM(c, a[0] - 1.7, z0, 3.4, len, "W"); RM(c, a[0] - 1.7, z0, 0.3, len, "e"); RM(c, a[0] - 1.0, z0, 0.25, len, "i"); RM(c, a[0] + 0.75, z0, 0.25, len, "i")
        for (let t = 6; t < len; t += 24) { RM(c, a[0] + 1.7, z0 + t, 1.6, 2.2, "I"); RM(c, a[0] + 1.7, z0 + t + 2.0, 1.6, 0.4, "x") } }
    } else for (let t = 2; t < len; t += 6) horiz ? RM(c, x0 + t, a[1] - 0.15, 0.35, 0.3, "c") : RM(c, a[0] - 0.15, z0 + t, 0.3, 0.35, "c")
  }
  for (const s of DATA.STATIONS) {
    if (!vis(s.x - 12, s.z - 6, 24, 12, 2)) continue
    const horiz = s.z === 8 || s.z === 616 || s.id === "M2"
    const W = (horiz ? 20 : 7) * U, D = (horiz ? 7 : 20) * U, x0 = px(s.x) - W / 2, y0 = pz(s.z) - D / 2
    if (mode !== "emis") {
      c.rect(x0, y0, W, D, "k"); c.rect(x0 + 3, y0 + 3, W - 6, D - 6, "q"); c.rect(x0 + 6, y0 + 6, W - 12, D - 12, "R")
      c.box(x0 + 6, y0 + 6, W - 12, D - 12, "Y"); c.rect(x0 + 10, y0 + 10, W - 20, D - 20, "S")
      for (let k = 0; k < (horiz ? 5 : 3); k++) horiz ? c.rect(x0 + 24 + k * 56, y0 + 14, 40, D - 28, "s") : c.rect(x0 + 14, y0 + 24 + k * 56, W - 28, 40, "s")
    } else { c.box(x0 + 6, y0 + 6, W - 12, D - 12, "c"); c.text(x0 + W / 2 - 8, y0 + D / 2 - 5, s.id, "c", { scale: 2 }) }
  }
}
function drawBase(c) {
  ground(c); waters(c); paths(c); campusStream(c); roads(c); openPlots(c); terraces(c); forests(c)
  for (const b of DATA.BUILDINGS.concat(DATA.HALLS.map((h) => [h[0], h[1], h[2], h[3], h[4], h[5], h[6], 1]))) {
    const x0 = px(b[3]), y0 = pz(b[4]), W = px(b[3] + b[5]) - x0, D = pz(b[4] + b[6]) - y0
    if (vis(b[3] - 4, b[4] - 4, b[5] + 8, b[6] + 6, 0)) { c.shade([x0 + W, y0 + 22, 56, D - 22]); c.shade([x0 + 24, y0 + D, W + 56, 40]) }
  }
  for (const s of DATA.SHELTERS) if (vis(s[0], s[1], s[2], s[3], 6)) { const x0 = px(s[0]), y0 = pz(s[1]); c.shade([x0 + 8, y0 + 26 * U / 2, px(s[0] + s[2]) - x0, 28]) }
  for (const b of DATA.BUILDINGS) building(c, b, "base")
  for (const h of DATA.HALLS) hall(c, h, "base")
  for (const s of DATA.SHELTERS) shelter(c, s, "base")
  skytrain(c, "base")
}
function drawEmis(c) {
  for (const b of DATA.BUILDINGS) building(c, b, "emis")
  for (const h of DATA.HALLS) hall(c, h, "emis")
  for (const s of DATA.SHELTERS) shelter(c, s, "emis")
  for (const [cx, cz, rr, col] of [[150, 152.5, 1, "c"], [450, 150, 1.3, "c"]]) if (vis(cx - 20, cz - 18, 40, 36, 2)) {
    const qx = px(cx), qy = pz(cz)
    c.ellipse(qx, qy, 11 * rr * U, 9.6 * rr * U, "c", true); c.ellipse(qx, qy, 14.3 * rr * U, 12.6 * rr * U, "m", true); c.ring(qx, qy, 10.2 * rr * U, "c")
  }
  for (const z of DATA.PROM) if (vis(streamX(z) - 4, z - 4, 8, 8, 1)) { const x = streamX(z); RM(c, x - 2.6, z - 3.1, 5.2, 0.12, "c"); RM(c, x - 2.6, z + 3.0, 5.2, 0.12, "c") }
  for (const ez of [80, 210]) for (const cx of DATA.CX) if (vis(cx - 4, ez - 1, 8, 2, 1)) c.hline(px(cx - 4), pz(ez) - 3, 8 * U, "c")
  skytrain(c, "emis")
}
for (const ch of DATA.CHUNKS) {
  const nm = ch.i + "_" + ch.j
  scene("b_" + nm, { w: CW, h: CW, bg: "n" }, (c) => { setChunk(ch); drawBase(c) })
  if (ch.emis) scene("e_" + nm, { w: CW, h: CW }, (c) => { setChunk(ch); drawEmis(c) }, glow("lLcm", { r: 7, strength: 0.6, bands: 4 }))
}

// ------------------------------------------------------------------ interiors
function furn(c, f, ox, oy) {
  const [kind, fx, fz, fw, fd, o] = f
  const x = ox + Math.round(fx * U), y = oy + Math.round(fz * U), W = Math.round(fw * U), D = Math.round(fd * U)
  const top = (col, hi, face, fh) => { c.rect(x, y, W, D - fh, col); c.hline(x, y, W, hi); c.rect(x, y + D - fh, W, fh, face); c.hline(x, y + D - 1, W, "k") }
  switch (kind) {
    case "rug": c.rect(x, y, W, D, "M"); c.rect(x + 3, y + 3, W - 6, D - 6, "O"); c.box(x + 6, y + 6, W - 12, D - 12, "m"); break
    case "desk": top("d", "L", "D", 8); c.rect(x + W / 2 - 8, y + 3, 16, 8, "J"); c.hline(x + W / 2 - 8, y + 3, 16, "c"); break
    case "student": top("d", "L", "D", 6); c.rect(x + 8, y + 3, 10, 6, "J"); c.hline(x + 8, y + 3, 10, "z"); c.rect(x + W - 12, y + D, 8, 6, "I"); break
    case "bed": c.rect(x, y, W, D, "W"); c.rect(x + 2, y + 2, W - 4, D - 6, "S"); c.rect(x + 4, y + 4, W - 8, 10, "V"); c.rect(x + 2, y + 18, W - 4, D - 24, "s"); c.hline(x + 2, y + 18, W - 4, "z"); c.rect(x, y + D - 4, W, 4, "D"); break
    case "wardrobe": top("D", "d", "d", 14); for (let X = x + 12; X < x + W; X += 18) c.vline(X, y + D - 14, 14, "D"); c.px(x + W / 2, y + D - 8, "L"); break
    case "shelf": case "bookshelf": top("D", "d", "d", 16); for (let X = x + 2; X < x + W - 2; X += 4) c.rect(X, y + D - 15, 3, 12, ["r", "m", "c", "L", "s", "z"][(X >> 2) % 6]); c.hline(x, y + D - 9, W, "D"); break
    case "locker": top("I", "i", "I", 18); for (let X = x + 12; X < x + W; X += 14) c.vline(X, y + D - 18, 18, "k"); break
    case "counter": top("I", "V", "w", 14); c.hline(x, y + D - 14, W, "c"); c.rect(x + 4, y + 3, 10, 6, "l"); break
    case "kettle": c.circ(x + W / 2, y + D / 2, 7, "I"); c.circ(x + W / 2 - 2, y + D / 2 - 2, 4, "i"); c.px(x + W - 2, y + D / 2, "L"); break
    case "tea": c.circ(x + W / 2, y + D / 2, W / 2, "I"); c.circ(x + W / 2, y + D / 2 - 2, W / 2 - 2, "V"); c.circ(x + W / 2 - 4, y + D / 2 - 4, 3, "L"); break
    case "stool": c.circ(x + W / 2, y + D / 2, W / 2, ["M", "C", "Q", "S"][(fx * 3 + fz) % 4 | 0]); c.circ(x + W / 2 - 1, y + D / 2 - 1, W / 2 - 2, "V"); break
    case "pod": c.rect(x, y + 6, W, D - 6, "W"); c.rect(x + 3, y, W - 6, D - 10, "I"); c.rect(x + 6, y + 4, W - 12, D - 20, "J"); c.line(x + 8, y + D - 24, x + W - 12, y + 8, "z", 1)
      c.rect(x + 8, y + D - 10, W - 16, 4, "c"); c.rect(x + 3, y + D - 5, W - 6, 5, "k"); break
    case "console": top("I", "i", "w", 10); c.rect(x + 4, y + 3, W - 8, 8, "J"); c.hline(x + 4, y + 3, W - 8, "c"); break
    case "bench": case "workbench": top("I", "i", "w", 12); for (let X = x + 6; X < x + W - 6; X += 22) { c.rect(X, y + 3, 14, 5, "D"); c.px(X + 4, y + 5, "o") } break
    case "mech": c.rect(x + 6, y + D - 14, W - 12, 14, "W"); c.rect(x + 18, y + 20, 22, D - 30, "I"); c.rect(x + W - 40, y + 20, 22, D - 30, "I")
      c.rect(x + 24, y + 6, W - 48, 36, "i"); c.rect(x + 30, y + 12, W - 60, 12, "I"); c.rect(x + W / 2 - 8, y + 16, 16, 8, "c"); c.hline(x + 24, y + 6, W - 48, "V"); c.circ(x + 28, y + 14, 8, "i"); c.circ(x + W - 28, y + 14, 8, "i"); break
    case "arm": c.circ(x + W / 2, y + D - 8, 14, "I"); c.line(x + W / 2, y + D - 8, x + W - 8, y + 10, "i", 5); c.circ(x + W - 8, y + 10, 5, "c"); break
    case "crate": top("d", "L", "D", 10); c.line(x, y, x + W, y + D - 10, "D", 1); break
    case "toolwall": c.rect(x, y, W, D, "k"); for (let X = x + 6; X < x + W - 10; X += 20) { c.rect(X, y + 8, 14, 5, "i"); c.rect(X + 2, y + 18, 10, 4, "o"); c.rect(X, y + 28, 14, 3, "I") } break
    case "board": c.rect(x, y, W, D, "k"); c.rect(x + 3, y + 3, W - 6, D - 6, "J"); for (let Y = y + 9; Y < y + D - 8; Y += 8) c.hline(x + 8, Y, (W - 20) * (0.5 + ((Y * 7) % 5) / 12), "c"); break
    case "screen": c.rect(x, y, W, D, "k"); c.rect(x + 3, y + 3, W - 6, D - 6, "J"); c.rect(x + 6, y + 6, W - 12, 6, "m"); c.circ(x + W / 2, y + D / 2 + 4, D / 4, "c"); break
    case "holo": c.rect(x, y, W, D, "x"); c.rect(x + 4, y + 4, W - 8, D - 8, "C"); c.ring(x + W / 2, y + D / 2, D / 3, "c"); c.hline(x + 4, y + D - 5, W - 8, "c"); break
    case "menu": c.rect(x, y, W, D, "k"); for (let k = 0; k < 4; k++) { c.hline(x + 8, y + 6 + k * 8, W / 2 - 10, "L"); c.hline(x + W / 2 + 6, y + 6 + k * 8, W / 2 - 14, "m") } break
    case "poster": c.rect(x, y, W, D, "k"); c.rect(x + 3, y + 3, W - 6, D - 6, ["M", "C", "O"][(fx | 0) % 3]); c.circ(x + W / 2, y + D / 2, D / 4, "l"); break
    case "plant": c.rect(x + 8, y + D - 12, W - 16, 12, "D"); c.circ(x + W / 2, y + D / 2 - 4, W / 2 - 2, "t"); c.circ(x + W / 2 - 2, y + D / 2 - 7, W / 2 - 6, "u"); c.px(x + W / 2, y + 4, "m"); break
    case "sofa": top("M", "m", "O", 12); c.rect(x + 2, y + 2, W - 4, 8, "M"); c.rect(x + 3, y + 10, 4, 4, "L"); break
    case "stall": c.rect(x, y, W, D, "k"); c.rect(x + 2, y + 2, W - 4, D - 8, "d"); for (let X = x + 4; X < x + W - 6; X += 9) { c.circ(X + 3, y + 7, 3, ["u", "L", "m", "c", "o"][(X >> 3) % 5]); c.circ(X + 3, y + 7, 1, "V") } c.rect(x, y + D - 8, W, 8, "M"); for (let X = x; X < x + W; X += 8) c.rect(X, y + D - 8, 4, 8, "V"); break
    case "vending": case "arcade": c.rect(x, y, W, D, "k"); c.rect(x + 3, y + 3, W - 6, D - 12, kind === "arcade" ? "J" : "L"); c.rect(x + 5, y + 5, W - 10, 6, kind === "arcade" ? "c" : "l"); c.rect(x + 3, y + D - 8, W - 6, 4, "m"); break
    default: c.rect(x, y, W, D, "I")
  }
}
for (const type in DATA.INTERIORS) {
  const R = DATA.INTERIORS[type], w = R.w, d = R.d, PADm = 1
  const SW = (w + 2 * PADm) * U, SH = (d + 2 * PADm) * U, ox = PADm * U, oy = PADm * U
  scene("int_" + type, { w: SW, h: SH, bg: "x" }, (c) => {
    // floor: 1 m tiles, two tones
    const r = rng(type.length * 31)
    for (let X = 0; X < w; X++) for (let Y = 3; Y < d; Y++) c.rect(ox + X * U, oy + Y * U, U, U, (X + Y) % 2 ? "P" : "p")
    for (let X = 0; X < w; X++) for (let Y = 3; Y < d; Y++) { c.hline(ox + X * U, oy + Y * U, U, "9"); c.vline(ox + X * U, oy + Y * U, U, "9") }
    // back wall (3 m): panels, baseboard, neon strip, windows
    c.rect(ox, oy, w * U, 3 * U, "w")
    for (let X = 0; X < w * U; X += 24) c.vline(ox + X, oy + 2, 3 * U - 8, "W")
    c.rect(ox, oy + 3 * U - 8, w * U, 8, "W"); c.hline(ox, oy + 3 * U - 1, w * U, "k"); c.hline(ox, oy, w * U, "e")
    c.rect(ox + 4, oy + 6, w * U - 8, 2, type === "cafe" || type === "club" ? "m" : "c")
    for (let X = 12; X < w * U - 40; X += 96) { c.rect(ox + X, oy + 14, 40, 20, "k"); c.rect(ox + X + 2, oy + 16, 36, 16, r() < 0.5 ? "l" : "J"); c.vline(ox + X + 20, oy + 16, 16, "k") }
    // side + front walls
    c.rect(0, 0, ox, SH, "W"); c.rect(ox + w * U, 0, ox, SH, "W"); c.rect(0, 0, SW, oy, "W")
    c.rect(0, oy + d * U, SW, oy, "W"); c.hline(0, oy + d * U, SW, "e")
    c.rect(ox + (w / 2 - 1.5) * U, oy + d * U, 3 * U, oy, "k"); c.rect(ox + (w / 2 - 1.5) * U, oy + d * U, 3 * U, 3, "c")      // exit door (glowing threshold)
    c.rect(ox + (w / 2 - 1.5) * U + 2, oy + d * U + 3, 3 * U - 4, 4, "c")
    for (const f of R.f) furn(c, f, ox, oy)
    // soft shadow under the back wall
    c.shade([ox, oy + 3 * U, w * U, 6])
  }, glow("lcm", { r: 6, strength: 0.4, bands: 3 }))
}

// ------------------------------------------------------------------ characters
function person(c, dir, f) {
  const step = f === 1 ? 1 : f === 3 ? -1 : 0
  const bob = f === 1 || f === 3 ? 0 : 0
  c.ellipse(6, 24, 6, 2, "8")
  if (dir === "d" || dir === "u") {
    const back = dir === "u"
    // legs / longyi hem + feet
    c.rect(2, 16, 8, 6, "Z"); c.rect(2, 19, 8, 1, "X"); c.rect(2, 21, 8, 1, "X")
    c.rect(3, 22 + (step > 0 ? 1 : 0), 2, 2, "N"); c.rect(7, 22 + (step < 0 ? 1 : 0), 2, 2, "N")
    c.rect(3, 24 + (step > 0 ? 0 : -1) + 0, 2, 1, "H"); c.rect(7, 24 + (step < 0 ? 0 : -1), 2, 1, "H")
    // torso + arms
    c.rect(2, 9, 8, 8, "V"); c.rect(2, 15, 8, 2, "j"); c.rect(5, 9, 2, 8, back ? "j" : "V")
    c.rect(0, 10 + step, 2, 6, "V"); c.rect(10, 10 - step, 2, 6, "V"); c.rect(0, 16 + step, 2, 2, "N"); c.rect(10, 16 - step, 2, 2, "N")
    // head
    if (back) { c.rect(2, 1, 8, 8, "H") } else {
      c.rect(2, 1, 8, 4, "H"); c.rect(2, 4, 1, 3, "H"); c.rect(9, 4, 1, 3, "H"); c.rect(3, 4, 6, 5, "N"); c.hline(3, 8, 6, "F")
      c.px(4, 6, "k"); c.px(7, 6, "k"); c.rect(4, 7, 1, 1, "F"); c.px(6, 8, "M")
    }
  } else {
    c.rect(3, 16, 6, 6, "Z"); c.rect(3, 19, 6, 1, "X"); c.rect(3, 21, 6, 1, "X")
    c.rect(4 - step, 22, 2, 2, "N"); c.rect(6 + step, 22, 2, 2, "N"); c.rect(4 - step, 24, 3, 1, "H"); c.rect(6 + step, 24, 3, 1, "H")
    c.rect(3, 9, 6, 8, "V"); c.rect(3, 15, 6, 2, "j"); c.rect(4 + step, 10, 3, 6, "j"); c.rect(4 + step, 16, 2, 2, "N")
    c.rect(2, 1, 8, 4, "H"); c.rect(7, 4, 3, 5, "H"); c.rect(3, 4, 5, 5, "N"); c.hline(3, 8, 5, "F"); c.px(3, 6, "k"); c.px(3, 4, "H")
  }
}
const dirs = { d: "d", u: "u", l: "l" }
for (const d of ["d", "u", "l"]) for (let f = 0; f < 4; f++) sprite("p_" + d + f, { w: 12, h: 26, outline: "k" }, (c) => person(c, d, f))
for (let f = 0; f < 4; f++) sprite("p_r" + f, { base: "p_l" + f, flip: "x" })
const NPC = [
  { Z: "M", X: "M", H: "x", V: "j" }, { Z: "S", X: "B", H: "D", V: "V" }, { Z: "L", X: "o", H: "H", V: "c" },
  { Z: "Q", X: "D", H: "O", V: "m" }, { Z: "C", X: "S", H: "x", V: "i" }, { Z: "u", X: "t", H: "d", V: "L" },
]
NPC.forEach((sw, i) => { for (const d of ["d", "u", "l", "r"]) for (let f = 0; f < 4; f++) sprite("n" + i + "_" + d + f, { base: "p_" + d + f, swap: sw }) })
// cats: 2 walk frames + sit; birds: stand / hop / fly
const catBase = (c, f, sit) => {
  c.ellipse(9, 10, 7, 2, "8")
  if (sit) { c.rect(4, 3, 6, 6, "L"); c.rect(3, 1, 2, 3, "L"); c.rect(9, 1, 2, 3, "L"); c.rect(5, 4, 1, 1, "k"); c.rect(8, 4, 1, 1, "k"); c.rect(10, 6, 3, 3, "L"); c.px(6, 6, "m"); return }
  c.rect(2, 3, 10, 5, "L"); c.rect(10, 1, 5, 5, "L"); c.rect(10, 0, 1, 2, "L"); c.rect(13, 0, 1, 2, "L"); c.px(13, 3, "k"); c.px(14, 4, "m")
  c.rect(0, 2 - (f ? 1 : 0), 3, 2, "L"); c.rect(2, 3, 10, 1, "l")
  c.rect(3, 8, 2, 2 - (f ? 0 : 1), "O"); c.rect(9, 8, 2, 2 - (f ? 1 : 0), "O"); c.rect(6, 8, 1, 2 - (f ? 1 : 0), "O")
}
sprite("cat_0", { w: 16, h: 11, outline: "k" }, (c) => catBase(c, 0, false))
sprite("cat_1", { w: 16, h: 11, outline: "k" }, (c) => catBase(c, 1, false))
sprite("cat_s", { w: 16, h: 11, outline: "k" }, (c) => catBase(c, 0, true))
sprite("cat2_0", { base: "cat_0", swap: { L: "i", l: "V", O: "I" } }); sprite("cat2_1", { base: "cat_1", swap: { L: "i", l: "V", O: "I" } }); sprite("cat2_s", { base: "cat_s", swap: { L: "i", l: "V", O: "I" } })
sprite("bird_0", { outline: "k" }, `
  ..mm..
  .mmmm.
  MmmmmM
  .MMMM.
  ..L.L.`)
sprite("bird_1", { outline: "k" }, `
  ..mm..
  .mmmm.
  .mmmm.
  MMMMMM
  .L..L.`)
sprite("bird_f0", { outline: "k" }, `
  M....M
  mM..Mm
  .mmmm.
  ..MM..`)
sprite("bird_f1", { outline: "k" }, `
  ......
  ..mm..
  mmmmmm
  .MMMM.`)

// ------------------------------------------------------------------ vehicles
sprite("car_h", { w: 80, h: 40, outline: "k" }, (c) => {
  c.ellipse(40, 38, 40, 5, "8")
  c.rect(2, 8, 76, 26, "I"); c.rect(2, 24, 76, 10, "W"); c.hline(2, 8, 76, "V")
  c.rect(10, 4, 50, 22, "i"); c.rect(14, 8, 18, 14, "J"); c.rect(36, 8, 20, 14, "J"); c.line(18, 18, 26, 9, "z", 1); c.line(40, 18, 48, 9, "z", 1)
  c.rect(4, 14, 8, 6, "M"); c.rect(66, 12, 12, 10, "l"); c.rect(76, 14, 2, 6, "V")
  c.rect(6, 33, 68, 3, "c"); c.rect(0, 20, 4, 4, "m")
})
sprite("car_v", { base: "car_h", rot: 90 })
sprite("car2_h", { base: "car_h", swap: { i: "m", I: "M", c: "m" } }); sprite("car2_v", { base: "car2_h", rot: 90 })
sprite("car3_h", { base: "car_h", swap: { i: "L", I: "Q", c: "L" } }); sprite("car3_v", { base: "car3_h", rot: 90 })

// ------------------------------------------------------------------ trees + props
function crown(c, cx, cy, R, seed, hi) {
  const r = rng(seed)
  c.circ(cx, cy, R, "T")
  const lobes = 7
  for (let k = 0; k < lobes; k++) { const a = (k / lobes) * 6.283 + r(), d = R * 0.55; c.circ(cx + Math.cos(a) * d, cy + Math.sin(a) * d * 0.9, R * 0.42, "T") }
  c.circ(cx - R * 0.12, cy - R * 0.14, R * 0.8, "t")
  for (let k = 0; k < 7; k++) { const a = r() * 6.283, d = R * 0.5 * r(); c.circ(cx - R * 0.15 + Math.cos(a) * d, cy - R * 0.2 + Math.sin(a) * d, R * 0.3, "t") }
  c.circ(cx - R * 0.28, cy - R * 0.32, R * 0.5, "u")
  for (let k = 0; k < 5; k++) { const a = r() * 6.283, d = R * 0.35 * r(); c.circ(cx - R * 0.3 + Math.cos(a) * d, cy - R * 0.38 + Math.sin(a) * d, R * 0.18, hi) }
}
for (let i = 0; i < 3; i++) {
  const R = [34, 40, 30][i]
  sprite("tree" + i, { w: 96, h: 120, outline: "k" }, (c) => {
    c.ellipse(48, 108, 30, 7, "8")
    c.rect(43, 78, 10, 32, "D"); c.rect(43, 78, 4, 32, "d"); c.rect(40, 106, 16, 4, "D")
    crown(c, 48, 48, R, 10 + i * 17, "U")
  })
}
sprite("palm", { w: 96, h: 128, outline: "k" }, (c) => {
  c.ellipse(48, 120, 20, 5, "8")
  for (let Y = 40; Y < 120; Y += 6) { c.rect(45, Y, 7, 6, "I"); c.hline(45, Y, 7, "i"); c.hline(46, Y + 5, 6, "W") }
  const cx = 48, cy = 36
  for (let k = 0; k < 9; k++) {
    const a = (k / 9) * 6.283 + 0.35, L = 40 + (k % 2) * 6
    for (let t = 0; t < 1; t += 0.05) {
      const x = cx + Math.cos(a) * L * t, y = cy + Math.sin(a) * L * t * 0.62 + t * t * 14
      c.circ(x, y, 3.5 - t * 2, k % 2 ? "m" : "M")
    }
  }
  c.circ(cx, cy, 5, "L"); c.px(cx - 1, cy - 1, "l")
})
sprite("lamp", { w: 14, h: 76, outline: "k" }, (c) => {
  c.ellipse(7, 71, 5, 2, "8")
  c.rect(5, 12, 4, 58, "I"); c.rect(5, 12, 1, 58, "i"); c.rect(3, 66, 8, 5, "W")
  c.rect(0, 6, 14, 4, "I"); c.rect(1, 7, 12, 2, "c"); c.px(0, 8, "V"); c.px(13, 8, "V")
})
sprite("bench", { w: 30, h: 22, outline: "k" }, (c) => {
  c.ellipse(15, 21, 16, 3, "8")
  c.rect(0, 0, 30, 8, "D"); for (let X = 2; X < 30; X += 5) c.vline(X, 0, 8, "d"); c.hline(0, 0, 30, "L")
  c.rect(0, 8, 30, 8, "d"); c.hline(0, 8, 30, "L"); c.rect(1, 16, 3, 5, "I"); c.rect(26, 16, 3, 5, "I")
})
sprite("bin", { w: 10, h: 19, outline: "k" }, (c) => { c.ellipse(5, 18, 6, 2, "8"); c.rect(0, 2, 10, 14, "C"); c.rect(0, 2, 10, 3, "c"); c.rect(1, 8, 8, 2, "W"); c.rect(3, 5, 4, 1, "k") })
sprite("vending", { w: 22, h: 38, outline: "k" }, (c) => {
  c.ellipse(11, 36, 12, 3, "8")
  c.rect(0, 0, 22, 34, "W"); c.rect(2, 2, 18, 24, "k"); c.rect(3, 3, 16, 22, "L")
  for (let Y = 5; Y < 24; Y += 6) for (let X = 5; X < 17; X += 5) c.rect(X, Y, 3, 4, ["m", "c", "V", "l"][(X + Y) % 4])
  c.rect(2, 27, 18, 5, "M"); c.rect(5, 29, 8, 2, "k"); c.rect(16, 27, 3, 5, "l")
})
sprite("board", { w: 38, h: 44, outline: "k" }, (c) => {
  c.ellipse(19, 42, 18, 3, "8")
  c.rect(0, 0, 38, 30, "k"); c.rect(2, 2, 34, 26, "C"); c.rect(4, 4, 30, 22, "J")
  for (let Y = 8; Y < 24; Y += 5) c.hline(7, Y, 10 + ((Y * 3) % 14), "c"); c.rect(24, 8, 8, 10, "m")
  c.rect(8, 30, 3, 10, "I"); c.rect(27, 30, 3, 10, "I")
})
sprite("bikerack", { w: 44, h: 22, outline: "k" }, (c) => {
  c.ellipse(22, 20, 22, 3, "8")
  c.rect(0, 12, 44, 3, "I")
  for (let k = 0; k < 2; k++) { const x = 2 + k * 22; c.rect(x, 3, 18, 8, k ? "m" : "c"); c.rect(x + 3, 0, 8, 5, "i"); c.rect(x + 2, 11, 14, 2, "k"); c.rect(x + 14, 4, 3, 4, "l") }
})
sprite("signmap", { w: 38, h: 48, outline: "k" }, (c) => {
  c.ellipse(19, 46, 18, 3, "8")
  c.rect(0, 0, 38, 34, "W"); c.rect(2, 2, 34, 30, "J"); c.rect(6, 6, 12, 8, "c"); c.rect(20, 10, 12, 10, "m"); c.rect(8, 18, 8, 10, "L"); c.hline(4, 30, 30, "i")
  c.rect(8, 34, 3, 10, "I"); c.rect(27, 34, 3, 10, "I")
})
sprite("kiosk", { w: 48, h: 42, outline: "k" }, (c) => {
  c.ellipse(24, 40, 24, 3, "8")
  c.rect(0, 14, 48, 22, "w"); c.rect(3, 18, 42, 12, "L"); c.rect(6, 20, 8, 8, "m"); c.rect(18, 20, 8, 8, "c"); c.rect(30, 20, 8, 8, "V")
  for (let X = 0; X < 48; X += 8) c.rect(X, 4, 8, 12, (X / 8) % 2 ? "m" : "V"); c.hline(0, 4, 48, "L")
})
sprite("statue", { w: 80, h: 138, outline: "k" }, (c) => {
  c.ellipse(40, 132, 40, 7, "8")
  c.rect(0, 112, 80, 24, "W"); c.rect(2, 112, 76, 20, "P"); c.rect(6, 108, 68, 8, "q"); c.rect(10, 104, 60, 6, "9")
  c.rect(20, 76, 16, 30, "I"); c.rect(44, 76, 16, 30, "I"); c.rect(18, 100, 20, 6, "i"); c.rect(42, 100, 20, 6, "i")      // legs + boots
  c.rect(26, 62, 28, 18, "W"); c.rect(24, 36, 32, 28, "i"); c.rect(28, 40, 24, 14, "I"); c.circ(40, 47, 6, "c"); c.hline(24, 36, 32, "V") // torso + core
  c.rect(10, 32, 16, 18, "I"); c.rect(54, 32, 16, 18, "I"); c.hline(10, 32, 16, "V"); c.hline(54, 32, 16, "V")                // pauldrons
  c.rect(8, 50, 10, 30, "i"); c.rect(62, 50, 10, 30, "i"); c.rect(8, 78, 10, 8, "I"); c.rect(62, 78, 10, 8, "I")             // arms
  c.rect(31, 18, 18, 18, "i"); c.rect(34, 24, 12, 5, "c"); c.rect(36, 12, 8, 7, "I"); c.hline(31, 18, 18, "V")             // head + visor + crest
})


sprite("swing", { w: 40, h: 44, outline: "k" }, (c) => {
  c.ellipse(20, 40, 18, 3, "8"); c.line(4, 38, 12, 4, "I", 3); c.line(36, 38, 28, 4, "I", 3); c.rect(10, 3, 20, 4, "i")
  c.line(16, 7, 15, 28, "I", 1); c.line(24, 7, 25, 28, "I", 1); c.rect(12, 28, 16, 5, "m"); c.hline(12, 28, 16, "V")
})
sprite("train_h", { w: 236, h: 46, outline: "k" }, (c) => {
  c.ellipse(118, 42, 112, 4, "8")
  for (let k = 0; k < 2; k++) { const x = 4 + k * 114; c.rect(x, 6, 112, 32, "V"); c.rect(x, 26, 112, 12, "I"); c.hline(x, 6, 112, "i")
    for (let X = x + 8; X < x + 104; X += 20) { c.rect(X, 12, 14, 10, "J"); c.hline(X, 12, 14, "z"); c.rect(X + 2, 14, 10, 2, "l") }
    c.rect(x, 30, 112, 3, "c") }
  c.rect(112, 14, 8, 20, "k"); c.rect(222, 12, 8, 14, "l")
})
sprite("train_v", { base: "train_h", rot: 90 })
