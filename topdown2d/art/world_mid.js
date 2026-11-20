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
    const horiz = (s.line === "C" && (s.z === 8 || s.z === 616)) || (s.line === "M" && false)
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
