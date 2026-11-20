// YUST campus, top-down pixel art at 16 px per metre. Style: reference/topdown/topdown_03_cyberpunk_plaza.png.
// `DATA` is injected by build.mjs from campus_data.mjs. Emissive things (lit windows, neon, door strips) are drawn dim in
// the "base" scene and bright in the "emis" scene; the game fades the emis layer in at dusk.

DATA.streamX = (z) => {
  const S = DATA.STREAM
  for (let i = 0; i < S.length - 1; i++) if (z >= S[i][1] && z <= S[i + 1][1]) return S[i][0] + ((S[i + 1][0] - S[i][0]) * (z - S[i][1])) / (S[i + 1][1] - S[i][1])
  return 65
}
const U = DATA.U, OX = DATA.OX, OY = DATA.OY, SZ = DATA.SIZE * U
const px = (x) => Math.round((x + OX) * U)
const pz = (z) => Math.round((z + OY) * U)

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

// ------------------------------------------------------------------ helpers
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
const RM = (c, x, z, w, d, col) => { const x0 = px(x), y0 = pz(z); c.rect(x0, y0, px(x + w) - x0, pz(z + d) - y0, col) }
function slabs(c, x, z, w, d, base, joint, seed) {
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0, r = rng(seed)
  c.rect(x0, y0, W, D, base)
  for (let X = Math.ceil(x0 / U) * U; X < x0 + W; X += U) c.vline(X, y0, D, joint)
  for (let Y = Math.ceil(y0 / U) * U; Y < y0 + D; Y += U) c.hline(x0, Y, W, joint)
  for (let k = 0; k < (W * D) / 9000; k++) {                       // a few re-laid slabs
    const sx = x0 + Math.floor(r() * (W / U)) * U - (x0 % U), sy = y0 + Math.floor(r() * (D / U)) * U - (y0 % U)
    if (sx >= x0 && sy >= y0 && sx + U <= x0 + W && sy + U <= y0 + D) c.rect(sx + 1, sy + 1, U - 1, U - 1, "9")
  }
}
const label = (s, W) => s.split(" ").reduce((o, w) => ((o + " " + w).trim().length * 8 <= W - 24 ? (o + " " + w).trim() : o), "")

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

// ------------------------------------------------------------------ ground
function grass(c) {
  c.rect(0, 0, SZ, SZ, "g")
  c.scatter("_tuft*", 0, 0, SZ, SZ, 36000, { on: "g", rflip: "x" })
  c.scatter("_bloom", 0, 0, SZ, SZ, 220, { on: "g" })
  c.scatter("_bloomc", 0, 0, SZ, SZ, 160, { on: "g" })
}
function outerForest(c) {
  const r = rng(5), B = DATA.BOUNDS
  const out = [[0, 0, SZ, px(0)], [0, pz(314), SZ, SZ - pz(314)], [0, 0, px(0), SZ], [px(314), 0, SZ - px(314), SZ]]
  for (const [x, y, w, h] of out) {
    c.rect(x, y, w, h, "T")
    for (let k = 0; k < (w * h) / 700; k++) {
      const cx = x + r() * w, cy = y + r() * h, rad = 14 + r() * 14
      c.circ(cx, cy, rad, "T"); c.circ(cx - 3, cy - 3, rad - 6, "t"); c.circ(cx - 6, cy - 6, rad - 14, r() < 0.5 ? "u" : "t")
    }
  }
}
function paths(c) {
  for (const p of DATA.PAVED) slabs(c, p[0], p[1], p[2], p[3], "p", "P", Math.round(p[0] * 7 + p[1]))
  // central quad: concentric tiled plaza with holo crest rings (emissive part drawn separately)
  const q = DATA.QUAD
  slabs(c, q[0], q[1], q[2], q[3], "P", "W", 11)
  slabs(c, q[0] + 2, q[1] + 2, q[2] - 4, q[3] - 4, "p", "P", 12)
  const qx = px(150), qy = pz(152.5)
  c.ellipse(qx, qy, 16 * U, 14 * U, "9"); c.ellipse(qx, qy, 14.5 * U, 12.8 * U, "p"); c.ellipse(qx, qy, 11 * U, 9.6 * U, "P")
  c.ellipse(qx, qy, 10.4 * U, 9 * U, "9")
}
function roads(c) {
  const V = (x, z, w, d, col) => RM(c, x, z, w, d, col)
  // sidewalks (2 m) then asphalt
  for (const r of DATA.ROADS) {
    const horiz = r.a[1] === r.b[1], h = r.w / 2 + 2
    if (horiz) slabs(c, r.a[0] - h, r.a[1] - h, r.b[0] - r.a[0] + 2 * h, 2 * h, "p", "P", 3)
    else slabs(c, r.a[0] - h, r.a[1] - h, 2 * h, r.b[1] - r.a[1] + 2 * h, "p", "P", 4)
  }
  for (const r of DATA.ROADS) {
    const horiz = r.a[1] === r.b[1], h = r.w / 2
    if (horiz) V(r.a[0] - h, r.a[1] - h, r.b[0] - r.a[0] + 2 * h, 2 * h, "a")
    else V(r.a[0] - h, r.a[1] - h, 2 * h, r.b[1] - r.a[1] + 2 * h, "a")
  }
  // asphalt grain (granular material: noise is right here) + lane markings + curb light
  for (const r of DATA.ROADS) {
    const horiz = r.a[1] === r.b[1], h = r.w / 2
    const x0 = px(r.a[0] - h), y0 = pz(r.a[1] - h), W = horiz ? px(r.b[0] + h) - x0 : 2 * h * U, D = horiz ? 2 * h * U : pz(r.b[1] + h) - y0
    c.noise(x0, y0, W, D, "A", 0.05, 9, "a")
    const len = horiz ? r.b[0] - r.a[0] : r.b[1] - r.a[1]
    for (let t = 1; t < len - 1; t += 3) {
      if (r.w === 18) {
        for (const off of [-0.35, 0.35]) horiz ? V(r.a[0] + t, r.a[1] + off, 2.4, 0.12, "y") : V(r.a[0] + off, r.a[1] + t, 0.12, 2.4, "y")
        for (const off of [-4.5, 4.5]) horiz ? V(r.a[0] + t, r.a[1] + off, 1.4, 0.1, "i") : V(r.a[0] + off, r.a[1] + t, 0.1, 1.4, "i")
      } else horiz ? V(r.a[0] + t, r.a[1] - 0.06, 1.8, 0.12, "Y") : V(r.a[0] - 0.06, r.a[1] + t, 0.12, 1.8, "Y")
    }
    const edge = (xx, yy, ww, hh) => c.rect(xx, yy, ww, hh, "e")
    if (horiz) { edge(x0, y0, W, 2); edge(x0, y0 + D - 3, W, 3) } else { edge(x0, y0, 2, D); edge(x0 + W - 3, y0, 3, D) }
  }
  // zebra crossings where the main avenues meet the campus perimeter
  for (let k = 0; k < 9; k++) {
    V(293.2 + k * 2, 14, 1, 2.4, "V"); V(293.2 + k * 2, 288, 1, 2.4, "V")
  }
  slabs(c, 313.2, 0, 2.8, 316, "P", "W", 30)          // tech-district kerb beyond the east avenue
  slabs(c, 0, 313.2, 316, 2.8, "P", "W", 31)
}
function stream(c) {
  const pts = DATA.STREAM
  const W = 2.9
  for (let z = 0; z < 316; z += 0.25) {
    const x = DATA.streamX(z)
    RM(c, x - (W + 0.9) / 2, z, W + 0.9, 0.3, "e")
  }
  for (let z = 0; z < 316; z += 0.25) {
    const x = DATA.streamX(z)
    RM(c, x - W / 2, z, W, 0.3, "b"); RM(c, x - W / 4, z, W / 2, 0.3, "B")
  }
  const r = rng(77)
  for (let k = 0; k < 400; k++) { const z = r() * 316, x = DATA.streamX(z) + (r() - 0.5) * 2; c.hline(px(x), pz(z), 5 + Math.floor(r() * 7), "v") }
  // bridges: the promenade deck crosses the water, rails glow cyan at night
  for (const z of DATA.PROM) {
    const x = DATA.streamX(z)
    slabs(c, x - 2.4, z - 3, 4.8, 6, "p", "P", 40)
    RM(c, x - 2.6, z - 3.2, 5.2, 0.3, "I"); RM(c, x - 2.6, z + 2.9, 5.2, 0.3, "I")
    for (const dz of [-3.2, 2.9]) for (const dx of [-2.6, 2.3]) RM(c, x + dx, z + dz - 0.1, 0.35, 0.5, "i")
  }
}
function terraces(c) {
  // retaining walls at z=80 and z=210 with stairs (cx) and access ramps (cx+28)
  for (const ez of [80, 210]) {
    const x0 = px(5), W = px(286) - x0, y0 = pz(ez)
    c.rect(x0, y0, W, 2 * U + 4, "w"); c.hline(x0, y0, W, "e"); c.hline(x0, y0 + 1, W, "q"); c.rect(x0, y0 + 2 * U + 1, W, 3, "W")
    for (let X = x0 + 12; X < x0 + W; X += 40) c.vline(X, y0 + 2, 2 * U - 1, "W")     // panel joints
    for (let X = x0 + 34; X < x0 + W; X += 120) { c.rect(X, y0 + 14, 2, 18, "o"); c.vline(X, y0 + 2, 12, "O") } // red conduit run
    for (const cx of DATA.CX) {
      slabs(c, cx - 4, ez - 0.2, 8, 3, "P", "W", 50)                                     // stairs: treads
      for (let t = 0; t < 8; t++) { c.rect(px(cx - 4), y0 + t * 6, 8 * U, 2, "q"); c.rect(px(cx - 4), y0 + t * 6 + 2, 8 * U, 4, t % 2 ? "p" : "9") }
      c.rect(px(cx - 4), y0 + 50, 8 * U, 3, "W")
      c.rect(px(cx - 4.3), y0 - 2, 5, 52, "I"); c.rect(px(cx + 4), y0 - 2, 5, 52, "I")  // handrails
      c.rect(px(cx + 25), y0 - 4, 6 * U, 2 * U + 8, "P")                                  // ramp
      for (let t = 0; t < 5; t++) c.poly([px(cx + 26), y0 + 24 - t * 6 + 6, px(cx + 28), y0 + 24 - t * 6, px(cx + 30), y0 + 24 - t * 6 + 6, px(cx + 28), y0 + 24 - t * 6 + 9], "Y")
    }
  }
}
function lawns(c) {
  const t = DATA.TRAINING
  RM(c, t[0] - 1.5, t[1] - 1.5, t[2] + 3, t[3] + 3, "P")
  slabs(c, t[0], t[1], t[2], t[3], "f", "f", 60)
  for (let k = 0; k < t[2] / 3.5; k++) RM(c, t[0] + k * 3.5, t[1], 1.75, t[3], "u")          // mow stripes
  const x0 = px(t[0] + 3), y0 = pz(t[1] + 3), W = (t[2] - 6) * U, D = (t[3] - 6) * U
  c.box(x0, y0, W, D, "V"); c.vline(x0 + W / 2, y0, D, "V"); c.ring(x0 + W / 2, y0 + D / 2, 5 * U, "V"); c.circ(x0 + W / 2, y0 + D / 2, 3, "V")
  c.box(x0, y0 + D / 2 - 3 * U, 2.2 * U, 6 * U, "V"); c.box(x0 + W - 2.2 * U, y0 + D / 2 - 3 * U, 2.2 * U, 6 * U, "V")
  // flower beds along the building doors + hedges
  for (const b of DATA.BUILDINGS) {
    const dx = b[3] + b[5] / 2
    for (const sx of [-1, 1]) {
      const bx = dx + sx * 5.5 - 1.5
      c.stamp("_planter", px(bx), pz(b[4] + b[6]) + 8)
    }
  }
}

// ------------------------------------------------------------------ buildings
function roofProps(c, x0, y0, W, RH, id, solar) {
  const r = rng(id * 977 + 3)
  for (let gx = x0 + 28; gx < x0 + W - 80; gx += 96) for (let gy = y0 + 24; gy < y0 + RH - 64; gy += 84) {
    const k = r(), ox = gx + Math.floor(r() * 24), oy = gy + Math.floor(r() * 18)
    if (k < 0.24) c.stamp("_ac", ox, oy)
    else if (k < 0.34) c.stamp("_tank", ox, oy)
    else if (k < 0.46) c.stamp("_skylight", ox, oy)
    else if (k < 0.66 && solar) c.stamp("_solar", ox, oy)
    else if (k < 0.74) c.stamp("_vent", ox, oy)
    else if (k < 0.8) { c.line(ox, oy, ox + 40, oy, "I", 3); c.line(ox, oy, ox, oy + 30, "I", 3) }
  }
  c.vline(x0 + W - 22, y0 + 14, 34, "I"); c.px(x0 + W - 22, y0 + 12, "o")
}
function building(c, b, mode) {
  const [id, type, name, x, z, w, d, floors] = b
  const idn = DATA.BUILDINGS.indexOf(b) + 1
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0
  const faceM = 3.2 + floors * 1.7, F = Math.round(faceM * U), RH = D - F
  const emis = mode === "emis"
  const fy = y0 + RH
  if (!emis) {
    // roof: parapet ring, membrane panel joints, cast shadow of the parapet
    c.rect(x0, y0, W, RH, "W"); c.rect(x0 + 5, y0 + 5, W - 10, RH - 9, "r")
    c.rect(x0 + 5, y0 + 5, W - 10, 6, "R"); c.rect(x0 + 5, y0 + 5, 6, RH - 9, "R")
    c.hline(x0, y0, W, "e"); c.hline(x0, y0 + 1, W, "q"); c.vline(x0, y0, RH, "e"); c.vline(x0 + 1, y0, RH, "q")
    for (let X = x0 + 40; X < x0 + W - 6; X += 40) c.vline(X, y0 + 11, RH - 20, "R")
    for (let Y = y0 + 40; Y < y0 + RH - 6; Y += 40) c.hline(x0 + 11, Y, W - 20, "R")
    roofProps(c, x0, y0, W, RH, idn, /ADMIN|CLASS|RESEARCH|PILOT|DORM|UNION/.test(name))
    // facade
    c.rect(x0, fy, W, F, "w"); c.hline(x0, fy, W, "e"); c.hline(x0, fy + 1, W, "q"); c.rect(x0, fy + 2, W, 3, "W")
    for (let X = x0 + 24; X < x0 + W; X += 24) c.vline(X, fy + 5, F - 12, "W")                 // composite panel joints
    c.rect(x0, fy + F - 7, W, 7, "W"); c.hline(x0, fy + F - 1, W, "k")                         // plinth
  }
  // sign band (neon)
  const bandH = 22
  const sgn = label(name, W)
  if (!emis) { c.rect(x0 + 8, fy + 9, W - 16, bandH, "k"); c.box(x0 + 8, fy + 9, W - 16, bandH, "W") }
  const nc = ["c", "m", "L"][idn % 3]
  const tx = x0 + Math.floor((W - sgn.length * 8 + 2) / 2)
  if (emis) c.text(tx, fy + 14, sgn, nc, { scale: 2 }); else c.text(tx, fy + 14, sgn, { c: "C", m: "M", L: "Q" }[nc], { scale: 2 })
  // window rows
  const wy0 = fy + 9 + bandH + 10, avail = fy + F - 20 - wy0
  const rows = Math.max(1, Math.min(floors, Math.floor(avail / 30)))
  const rowH = Math.floor(avail / rows)
  const r = rng(idn * 313 + 5)
  for (let rI = 0; rI < rows; rI++) for (let cx = x0 + 14; cx + 26 <= x0 + W - 12; cx += 38) {
    const lit = r() < 0.55, wy = wy0 + rI * rowH, wh = Math.min(rowH - 8, 26)
    if (emis) { if (lit) { c.rect(cx, wy, 24, wh, "l"); c.rect(cx + 2, wy + 2, 20, 2, "V"); c.vline(cx + 12, wy, wh, "L") } }
    else {
      c.rect(cx - 2, wy - 2, 28, wh + 4, "k"); c.rect(cx, wy, 24, wh, lit ? "Q" : "J")
      if (!lit) { c.hline(cx, wy, 24, "s"); c.line(cx + 4, wy + wh - 2, cx + 12, wy + 2, "z", 1) }
      c.hline(cx - 2, wy + wh + 2, 28, "I")
    }
  }
  // door: double slide door, cyan frame, awning
  const dx = px(x + w / 2) - 28, dy = fy + F - 52
  if (!emis) {
    c.rect(dx - 6, dy - 8, 68, 8, "R"); c.hline(dx - 6, dy - 8, 68, "e")
    c.rect(dx, dy, 56, 46, "k"); c.rect(dx + 3, dy + 3, 24, 42, "J"); c.rect(dx + 29, dy + 3, 24, 42, "J")
    c.line(dx + 6, dy + 38, dx + 14, dy + 6, "s", 1); c.line(dx + 32, dy + 38, dx + 40, dy + 6, "s", 1)
    c.rect(dx + 2, dy + 46, 52, 3, "q")
  } else {
    c.rect(dx, dy, 56, 3, "c"); c.vline(dx, dy, 46, "c"); c.vline(dx + 55, dy, 46, "c"); c.vline(dx + 28, dy + 3, 43, "c")
    c.rect(dx + 3, dy + 3, 24, 4, "C"); c.rect(dx + 29, dy + 3, 24, 4, "C")
  }
  // red conduit down one side (the reference's circuit lines)
  if (!emis && idn % 2 === 0) { c.rect(x0 + W - 11, fy + 6, 3, F - 14, "o"); c.rect(x0 + W - 11, fy + 6, 3, 3, "O") }
  if (!emis && idn % 3 === 0) { c.rect(x0 + 8, fy + 6, 3, F - 14, "i"); c.rect(x0 + 8, fy + 6, 3, 5, "I") }
}
function hangarExtras(c, b, mode) {
  // the hangar has a curved roof; drawn over the generic roof
  if (mode === "emis") return
  const [id, type, name, x, z, w, d, floors] = b
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0, F = Math.round((3.2 + floors * 1.7) * U), RH = D - F
  c.rect(x0 + 6, y0 + 6, W - 12, RH - 12, "I")
  for (let Y = y0 + 12; Y < y0 + RH - 8; Y += 12) { c.hline(x0 + 6, Y, W - 12, "R"); c.hline(x0 + 6, Y + 1, W - 12, "i") }
  c.rect(x0 + 6, y0 + RH / 2 - 8, W - 12, 16, "R"); c.rect(x0 + 6, y0 + RH / 2 - 5, W - 12, 3, "c")
  for (let X = x0 + 30; X < x0 + W - 12; X += 56) c.vline(X, y0 + 6, RH - 12, "W")
  c.rect(x0 + W / 2 - 60, y0 + RH - 52, 120, 40, "W"); c.hline(x0 + W / 2 - 60, y0 + RH - 52, 120, "L")   // hangar bay marking
}

function drawWorld(c, mode) {
  const emis = mode === "emis"
  if (!emis) {
    grass(c); outerForest(c); paths(c); stream(c); roads(c); lawns(c); terraces(c)
    // shadows: light from the north-west. Buildings + roof props fall south-east.
    for (const b of DATA.BUILDINGS) {
      const x0 = px(b[3]), y0 = pz(b[4]), W = px(b[3] + b[5]) - x0, D = pz(b[4] + b[6]) - y0
      c.shade([x0 + W, y0 + 22, 56, D - 22])
      c.shade([x0 + 24, y0 + D, W + 56, 40])
    }
    c.shade([px(125) + 10, pz(125) + 8, 50 * U, 4])
    for (const b of DATA.BUILDINGS) { building(c, b, "base"); if (b[0] === "hangar") hangarExtras(c, b, "base") }
  } else {
    for (const b of DATA.BUILDINGS) building(c, b, "emis")
    // holo crest rings in the central quad, bridge rails, stair edge strips, training-ground floodlights
    const qx = px(150), qy = pz(152.5)
    c.ring(qx, qy, 10.2 * U, "c"); c.ellipse(qx, qy, 11 * U, 9.6 * U, "c", true); c.ellipse(qx, qy, 14.3 * U, 12.6 * U, "m", true)
    for (const z of DATA.PROM) {
      const x = DATA.streamX(z)
      RM(c, x - 2.6, z - 3.1, 5.2, 0.12, "c"); RM(c, x - 2.6, z + 3.0, 5.2, 0.12, "c")
    }
    for (const ez of [80, 210]) for (const cx of DATA.CX) { c.hline(px(cx - 4), pz(ez) - 3, 8 * U, "c") }
  }
}

scene("campus_base", { w: SZ, h: SZ, bg: "g" }, (c) => drawWorld(c, "base"))
scene("campus_emis", { w: SZ, h: SZ }, (c) => drawWorld(c, "emis"), glow("lLcm", { r: 7, strength: 0.6, bands: 4 }))

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

