// YANGON: Life above the neon -- top-down pixel map of the campus_terrain 3D world.
// Style target: reference/topdown/topdown_03_cyberpunk_plaza.png (dark violet city, amber windows,
// cyan + pink neon, pink palms, glow). Layout target: the Godot world in campus_terrain/scripts
// (road_layout.gd, terrain_layout.gd, world.gd, reference_buildings.gd, skytrain.gd).
// World coordinates are metres (x east, z south); S = pixels per metre.

const S = 2
const OX = 300, OY = 700            // world x,z that maps to pixel 0,0
const WM = 914, HM = 1510           // world extent in metres: x -300..614, z -700..810
const px = (x) => Math.round((x + OX) * S)
const pz = (z) => Math.round((z + OY) * S)

pal({
  n: "#090c22", k: "#0b0a1c", x: "#04050e",                       // void, ink, deep shadow
  g: "#1c3a3e", G: "#15303a", f: "#27504b", h: "#112832",          // grass dark / darker / lit, hills
  T: "#0e3035", t: "#1b5648", u: "#2e7d5b", U: "#52a06c",          // tree crowns
  a: "#2a2750", A: "#201e3f", y: "#e0a64a", Y: "#f4cc6e",          // asphalt, lane paint
  p: "#4f4b7b", P: "#3a3664", q: "#6e6aa6", e: "#7a76b4",          // paving, light edge
  r: "#4a4678", R: "#35325d", w: "#3a3764", W: "#2a2751",          // roof, roof dark, wall, wall dark
  o: "#d4553a", O: "#8c3a3d",                                      // red-orange circuit lines
  l: "#ffd479", L: "#f0983f", J: "#233a6a",                        // lit window, amber, dark window
  m: "#ff4fa3", M: "#a8286f", c: "#58f0e0", C: "#23919d",          // neon pink, cyan
  b: "#2f5f97", B: "#204676", v: "#79cbee",                        // water
  s: "#2f62ad", S: "#1c3f7c", z: "#5189d2",                        // solar / glass vault
  d: "#80533b", D: "#5a3a2b", E: "#4d3a43",                        // wood, dark wood, dirt trail
  i: "#9aa0c8", I: "#6b7099", V: "#c9cde8",                        // metal
})
ramps("xGgf", "xAa", "xWPpq", "xBbv", "xRre", "xTtuU")

// ------------------------------------------------------------------ data (from the Godot project)
const NODES = {
  nw: [8, 8], n: [302, 8], ne_return: [580, 8], ne: [610, 8],
  w: [8, 302], c: [302, 302], e: [610, 302],
  sw: [8, 616], s: [302, 616], se: [610, 616],
  market_nw: [8, -680], market_ne: [610, -680],
  market_sw: [8, -360], market_return: [580, -360], market_se: [610, -360],
  upper_w: [-250, 618], upper_c: [300, 618],
  ramp_w_top: [-250, 638], ramp_w_bottom: [-90, 638], lower_w: [-90, 654],
  ramp_e_top: [300, 638], ramp_e_bottom: [460, 638], lower_e: [460, 654],
  tech_nw: [335, 60], tech_ne: [594, 60], tech_se: [594, 255], tech_sw: [335, 255],
  home_nw: [25, 365], home_ne: [270, 365], home_w_mid: [25, 450], home_e_mid: [270, 450],
  home_sw: [25, 550], home_se: [270, 550], home_exit: [270, 590], home_join: [270, 614],
}
const EDGES = [
  ["nw", "n"], ["n", "ne_return"], ["ne_return", "ne"], ["nw", "w"], ["w", "sw"], ["n", "c"], ["c", "s"],
  ["ne", "e"], ["e", "se"], ["w", "c"], ["c", "e"], ["sw", "s"], ["s", "se"],
  ["market_nw", "market_ne"], ["market_nw", "market_sw"], ["market_sw", "market_return"],
  ["market_return", "market_se"], ["market_se", "market_ne"], ["market_return", "ne_return"], ["market_se", "ne"],
  ["s", "upper_c"], ["upper_w", "upper_c"], ["upper_w", "ramp_w_top"], ["ramp_w_top", "ramp_w_bottom"],
  ["ramp_w_bottom", "lower_w"], ["lower_w", "lower_e"], ["lower_e", "ramp_e_bottom"],
  ["ramp_e_bottom", "ramp_e_top"], ["ramp_e_top", "upper_c"],
  ["n", "tech_nw"], ["tech_nw", "tech_ne"], ["tech_ne", "tech_se"], ["tech_se", "tech_sw"], ["tech_sw", "tech_nw"],
  ["tech_se", "e"],
  ["home_nw", "home_ne"], ["home_ne", "home_e_mid"], ["home_e_mid", "home_se"], ["home_se", "home_sw"],
  ["home_sw", "home_w_mid"], ["home_w_mid", "home_nw"], ["home_se", "home_exit"], ["home_exit", "home_join"],
  ["home_join", "s"],
]
const MAIN = new Set(["n-c", "c-s", "w-c", "c-e"])
const edgeW = (e) => (MAIN.has(e[0] + "-" + e[1]) ? 18 : 8)
const segs = EDGES.map((e) => ({ a: NODES[e[0]], b: NODES[e[1]], w: edgeW(e) }))
const deg = {}
for (const e of EDGES) for (const n of e) deg[n] = (deg[n] || 0) + 1

function segDist(x, z, a, b) {
  const dx = b[0] - a[0], dz = b[1] - a[1]
  const t = Math.max(0, Math.min(1, ((x - a[0]) * dx + (z - a[1]) * dz) / (dx * dx + dz * dz)))
  return Math.hypot(x - (a[0] + dx * t), z - (a[1] + dz * t))
}
const roadClear = (x, z, m) => segs.every((s) => segDist(x, z, s.a, s.b) > s.w / 2 + 2 + m)

// pads / plots: [x, z, w, d, label, floors]
const PADS = [
  [110, 20, 35, 35, "PILOT SCHOOL", 3], [160, 20, 35, 35, "CLASSROOMS", 3], [17, 104, 27, 35, "DORM A", 3],
  [17, 157, 27, 35, "DORM B", 3], [78, 108, 25, 25, "FOOD COMMONS", 2], [203, 105, 35, 40, "HANGAR", 0],
]
const TRAINING = [205, 160, 70, 40]
const INFILL = [
  [17, 20, 27, 35, "CAMPUS ADMIN", 3], [205, 20, 33, 35, "RESEARCH", 3], [78, 157, 25, 35, "STUDENT UNION", 2],
  [17, 232, 27, 28, "BOOKSHOP", 1], [205, 232, 33, 28, "CLUBS", 2], [408, 82, 30, 48, "DESIGN STUDIOS", 3],
  [490, 155, 62, 32, "TECH APTS", 4], [480, 265, 65, 25, "MAKER STUDIOS", 2], [72, 378, 55, 47, "GARDEN APTS", 4],
  [175, 380, 50, 35, "NEIGHBOUR APTS", 3], [175, 515, 50, 35, "TERRACE APTS", 4],
  [175, 462, 20, 38, "COURT EAST", 3], [205, 462, 20, 38, "COURT WEST", 4], [545, 330, 47, 45, "RECREATION", 2],
]
const PLOTS = [
  [365, 20, 55, 32, "CLINIC", 3], [475, 20, 65, 32, "APARTMENTS", 5], [365, 80, 36, 48, "REPAIR", 2],
  [500, 95, 50, 45, "ROBOT WORKSHOP", 3], [365, 175, 36, 45, "ARCADE", 2], [490, 200, 62, 34, "SHOPS TEA", 1],
  [375, 255, 65, 22, "TRANSIT", -1],
  [72, 460, 58, 45, "FAMILY CAFE", 5], [175, 460, 50, 40, "COURTYARD", -2], [72, 330, 55, 32, "TEA MOHINGA", 1],
  [175, 335, 50, 30, "LAUNDRY", 1], [68, 575, 60, 30, "APARTMENTS", 5], [175, 575, 52, 30, "GARDEN", -2],
  [365, 330, 42, 20, "FOOD STRIP", 1], [475, 330, 60, 45, "SPORTS COURT", -3], [470, 420, 48, 30, "PICNIC LAWN", -2],
  [365, 525, 48, 38, "GARDEN", -2], [455, 460, 28, 18, "LAKE CAFE", -1],
  [460, -405, 90, 28, "TRAM", -1], [100, -405, 90, 28, "BIKE INFO", 1],
  [95, -645, 150, 35, "WHOLESALE", 1], [345, -645, 150, 35, "DELIVERY", 1],
  [95, -545, 55, 65, "CRAFT BOOKS", 1], [450, -545, 55, 65, "CAFES", 2],
]
const HALLS = [[195, -590, 95, 55], [310, -590, 45, 55], [358, -590, 45, 55], [195, -515, 95, 55], [310, -515, 95, 55]]
// walkways / paved rects
const PAVED = []
for (const z of [65, 150, 270]) PAVED.push([5, z - 3, 281, 6])
for (const cx of [50, 150, 250]) PAVED.push([cx - 3, 8, 6, 282])
PAVED.push([125, 125, 50, 55])
for (const x of [282, 318]) PAVED.push([x, 5, 4, 604])
for (const z of [282, 318]) PAVED.push([5, z, 604, 4])
for (const z of [65, 150, 245]) PAVED.push([314, z - 3, 294, 6])
for (const x of [350, 450, 570]) PAVED.push([x - 3, 8, 6, 278])
PAVED.push([410, 110, 80, 80])
for (const z of [350, 450, 560]) PAVED.push([8, z - 3, 278, 6])
for (const x of [50, 150, 250]) PAVED.push([x - 3, 314, 6, 294])
PAVED.push([72, 427, 56, 18], [175, 427, 50, 18], [72, 530, 56, 25])
for (const z of [350, 400]) PAVED.push([314, z - 3, 294, 6])
PAVED.push([345, 314, 6, 294], [430, 350, 6, 258], [345, 490, 130, 5], [430, 595, 68, 4])
PAVED.push([590, -700, 5, 700])
for (const z of [-670, -410]) PAVED.push([20, z - 4, 575, 8])
PAVED.push([175, -610, 250, 175], [245, -405, 110, 45], [300, -380, 290, 6])

const NORTH_TRAIL = [[150, 0], [150, -35], [205, -65], [240, -105], [205, -145], [145, -175], [180, -215], [260, -235], [305, -210], [320, -180]]
const MARKET_TRAIL = [[320, -180], [290, -230], [300, -285], [300, -330], [300, -365]]
const WEST_TRAIL = [[0, 150], [-35, 150], [-75, 195], [-115, 230], [-160, 195], [-195, 145], [-235, 175], [-250, 250], [-205, 300], [-155, 340], [-115, 395], [-60, 445]]
const WATER = [
  { w: 1.6, p: [[355, -36], [260, -70], [100, -50], [65, 0], [65, 65], [65, 95], [63, 150], [70, 198], [75, 235], [75, 350], [65, 450], [65, 560], [65, 625], [65, 675], [65, 705]] },
  { w: 0.9, p: [[130, 550], [135, 535], [135, 475], [135, 440], [135, 380], [135, 350], [75, 350]] },
  { w: 1.1, p: [[460, 105], [465, 150], [465, 215], [470, 265], [470, 330], [465, 395], [490, 465], [520, 520]] },
  { w: 1.2, p: [[565, -640], [565, -520], [565, -365], [575, -280], [575, -190], [575, -85], [575, 0], [575, 150], [575, 270], [465, 395]] },
  { w: 1.0, p: [[605, 565], [608, 610], [608, 660], [608, 710]] },
]
const northStreamX = (z) => 355 + 8 * Math.sin(z * 0.027)
const riverBank = (x) => 685 + 7 * Math.sin(x * 0.012) + 3 * Math.sin(x * 0.032)
const riverWidth = (x) => 65 + 7 * Math.sin(x * 0.016 + 1)
const STATIONS = [
  ["C1", 150, 8], ["C2", 610, 150], ["C3", 610, 450], ["C4", 420, 610], ["C5", 150, 610], ["C6", 8, 270],
  ["M2", 535, -425], ["M3", 535, -600],
]

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
const R = (c, x, z, w, d, col) => {
  const x0 = px(x), y0 = pz(z)
  c.rect(x0, y0, Math.max(1, px(x + w) - x0), Math.max(1, pz(z + d) - y0), col)
}
const inRect = (x, z, r, m = 0) => x > r[0] - m && x < r[0] + r[2] + m && z > r[1] - m && z < r[1] + r[3] + m
function polyline(c, pts, wm, col) {
  const wpx = Math.max(2, Math.round(wm * S))
  for (let i = 0; i < pts.length - 1; i++)
    c.line(px(pts[i][0]), pz(pts[i][1]), px(pts[i + 1][0]), pz(pts[i + 1][1]), col, wpx)
}
const trailDist = (x, z, pts) => {
  let d = 1e9
  for (let i = 0; i < pts.length - 1; i++) d = Math.min(d, segDist(x, z, pts[i], pts[i + 1]))
  return d
}
const nearBuilt = (x, z, m) =>
  [...PADS, ...INFILL, ...PLOTS, TRAINING].some((r) => inRect(x, z, r, m)) ||
  HALLS.some((r) => inRect(x, z, r, m)) || PAVED.some((r) => inRect(x, z, r, m - 1)) ||
  inRect(x, z, [410, 110, 80, 80], m)
const nearWater = (x, z, m) => {
  if (Math.hypot((x - 550) / 56, (z - 548) / 53) < 1 + m / 50) return true
  for (const wt of WATER) if (trailDist(x, z, wt.p) < wt.w / 2 + 2 + m) return true
  return false
}

// ------------------------------------------------------------------ small parts
sprite("_ac", { outline: "k" }, `
  iiiiiiii
  iIIiiIIi
  iIiIiIiI
  iIIiiIIi
  IIIIIIII`)
sprite("_tank", { outline: "k" }, `
  .iiii.
  iiVViI
  iVVIII
  iiIIII
  .IIII.`)
sprite("_skylight", { outline: "k" }, `
  LLLLLL
  LllLll
  LLLLLL
  LllLll`)
sprite("_solar", { outline: "k" }, `
  szszszsz
  SSSSSSSS
  szszszsz
  SSSSSSSS`)
sprite("_car", { outline: "k" }, `
  ..iiiiii..
  .iVVIIVVi.
  iiiIIIIiii
  ccIIIIIIcc
  .CCC..CCC.`)
sprite("_carv", { base: "_car", rot: 90 })
sprite("_lamp", `
  c
  I
  I`)

// ------------------------------------------------------------------ layers
function drawGround(c) {
  R(c, -300, -700 + 0, 914, 1510, "n")
  const land = (x, z, w, d, col) => R(c, x, z, w, d, col)
  land(0, 0, 614, 614, "g")
  land(0, -700, 614, 400, "g")
  land(0, -300, 500, 300, "h")
  land(500, -300, 114, 300, "g")
  land(-300, 0, 300, 500, "h")
  land(-300, 500, 300, 114, "g")
  land(-300, 614, 914, 196, "g")
  c.grad(px(-300), pz(395), 300 * S, 45 * S, "hg", "v")          // west hills ease into town grass
  // lighter lawns inside the campus + lakeside
  for (const r of [[5, 8, 281, 280], [8, 314, 278, 294], [314, 314, 294, 294], [314, 8, 294, 275]]) {
    c.dither(px(r[0]), pz(r[1]), r[2] * S, r[3] * S, "g", "g", 0)
  }
  // market plateau: paved forecourt around the shopping core
  R(c, 20, -690, 575, 330, "G")
}

function drawWater(c) {
  // south river, one pixel column at a time
  for (let X = 0; X < WM * S; X++) {
    const x = X / S - OX
    const top = pz(riverBank(x)), bot = pz(riverBank(x) + riverWidth(x))
    c.rect(X, top, 1, bot - top, "b")
    c.rect(X, top, 1, 2, "B"); c.rect(X, bot - 2, 1, 2, "B")
    c.rect(X, top - 3, 1, 3, "f"); c.rect(X, bot, 1, 3, "f")
  }
  const r = rng(7)
  for (let i = 0; i < 700; i++) {
    const x = -300 + r() * 914, z = riverBank(x) + 6 + r() * (riverWidth(x) - 12)
    c.hline(px(x), pz(z), 3 + Math.floor(r() * 5), "v")
  }
  // lake
  c.ellipse(px(550), pz(548), 49 * S, 46 * S, "D")
  c.ellipse(px(550), pz(548), 46 * S, 43 * S, "b")
  c.ellipse(px(550), pz(548), 36 * S, 32 * S, "B")
  c.ellipse(px(550), pz(548), 30 * S, 26 * S, "b")
  for (let i = 0; i < 40; i++) {
    const a = r() * 6.28, d = Math.sqrt(r()) * 38
    c.hline(px(550 + Math.cos(a) * d), pz(548 + Math.sin(a) * d * 0.9), 3 + Math.floor(r() * 4), "v")
  }
  // boardwalk
  for (const z of [497, 597]) R(c, 496, z - 2, 108, 4, "d")
  for (const x of [498, 602]) R(c, x - 2, 495, 4, 104, "d")
  // north stream, pool and waterfall
  for (let z = -300; z < -36; z += 0.5) {
    const x = northStreamX(z), wd = z < -165 ? 6 : z < -151 ? 4 : 5
    R(c, x - wd / 2, z, wd, 0.6, z > -165 && z < -151 ? "V" : "b")
  }
  c.ellipse(px(northStreamX(-36)), pz(-36), 14 * S, 10 * S, "B")
  c.ellipse(px(northStreamX(-36)), pz(-36), 11 * S, 7 * S, "b")
  // channels (graded routes) + the campus stream
  for (const wt of WATER) {
    polyline(c, wt.p, wt.w + 1.2, "P")
    polyline(c, wt.p, wt.w, "b")
  }
}

function drawPaths(c) {
  for (const t of [NORTH_TRAIL, MARKET_TRAIL, WEST_TRAIL]) polyline(c, t, 3, "E")
  for (const r of PAVED) R(c, r[0], r[1], r[2], r[3], "p")
  R(c, 125, 125, 50, 55, "P"); R(c, 128, 128, 44, 49, "p")          // central quad
  c.ring(px(150), pz(152), 11 * S, "c"); c.ring(px(150), pz(152), 8 * S, "m")
  R(c, 410, 110, 80, 80, "P"); R(c, 413, 113, 74, 74, "p")           // student plaza
  c.ring(px(450), pz(150), 14 * S, "c"); c.ring(px(450), pz(150), 10 * S, "C")
  c.circ(px(450), pz(150), 4 * S, "m")
  for (const r of [...PADS, ...INFILL, ...PLOTS]) R(c, r[0] - 2, r[1] - 2, r[2] + 4, r[3] + 4, "P")
  // training ground
  const [tx, tz, tw, td] = TRAINING
  R(c, tx - 2, tz - 2, tw + 4, td + 4, "P"); R(c, tx, tz, tw, td, "f")
  c.box(px(tx + 4), pz(tz + 4), (tw - 8) * S, (td - 8) * S, "e")
  c.vline(px(tx + tw / 2), pz(tz + 4), (td - 8) * S, "e"); c.ring(px(tx + tw / 2), pz(tz + td / 2), 6 * S, "e")
  // sports court + picnic + gardens
  R(c, 475, 330, 60, 45, "C"); R(c, 478, 333, 54, 39, "b")
  c.box(px(480), pz(336), 50 * S, 33 * S, "V"); c.vline(px(505), pz(336), 33 * S, "V")
  for (const g of PLOTS.filter((p) => p[5] === -2)) {
    R(c, g[0], g[1], g[2], g[3], "f")
    const r = rng(g[0] * 7 + g[1])
    for (let i = 0; i < g[2] * g[3] / 28; i++) {
      const gx = g[0] + 2 + r() * (g[2] - 4), gz = g[1] + 2 + r() * (g[3] - 4)
      c.circ(px(gx), pz(gz), 2 + Math.floor(r() * 2), r() < 0.7 ? "u" : "t")
      if (r() < 0.25) c.px(px(gx), pz(gz) - 1, r() < 0.5 ? "m" : "L")
    }
  }
  // stairs at the retaining wall + lower waterfront
  R(c, -300, 645, 914, 2, "I"); R(c, -300, 644, 914, 1, "e")
  for (const sx of [-30, 150, 520]) for (let k = 0; k < 13; k++) R(c, sx - 3.5, 624 + k * 2, 7, 1, k % 2 ? "q" : "P")
  for (let X = 0; X < WM * S; X++) {
    const x = X / S - OX
    c.rect(X, pz(riverBank(x) - 7), 1, 3 * S, "C")                    // cycle path
    c.rect(X, pz(riverBank(x) - 11), 1, 3 * S, "p")                   // promenade
  }
}

function drawRoads(c) {
  // sidewalks first, then asphalt, so junctions merge cleanly
  for (const s of segs) {
    const [a, b] = [s.a, s.b], h = (s.w + 4) / 2
    R(c, Math.min(a[0], b[0]) - (a[1] === b[1] ? 0 : h), Math.min(a[1], b[1]) - (a[0] === b[0] ? 0 : h),
      Math.abs(b[0] - a[0]) + (a[1] === b[1] ? 0 : s.w + 4), Math.abs(b[1] - a[1]) + (a[0] === b[0] ? 0 : s.w + 4), "p")
  }
  for (const n in NODES) if (deg[n] === 2) {
    const w = Math.max(...segs.filter((s) => s.a === NODES[n] || s.b === NODES[n]).map((s) => s.w)) + 4
    R(c, NODES[n][0] - w / 2, NODES[n][1] - w / 2, w, w, "p")
  }
  for (const s of segs) {
    const [a, b] = [s.a, s.b], h = s.w / 2
    R(c, Math.min(a[0], b[0]) - (a[1] === b[1] ? 0 : h), Math.min(a[1], b[1]) - (a[0] === b[0] ? 0 : h),
      Math.abs(b[0] - a[0]) + (a[1] === b[1] ? 0 : s.w), Math.abs(b[1] - a[1]) + (a[0] === b[0] ? 0 : s.w), "a")
  }
  for (const n in NODES) if (deg[n] === 2) {
    const w = Math.max(...segs.filter((s) => s.a === NODES[n] || s.b === NODES[n]).map((s) => s.w))
    R(c, NODES[n][0] - w / 2, NODES[n][1] - w / 2, w, w, "a")
  }
  // lane paint + curb light line
  for (const s of segs) {
    const [a, b] = [s.a, s.b], horiz = a[1] === b[1]
    const len = Math.abs(horiz ? b[0] - a[0] : b[1] - a[1]), x0 = Math.min(a[0], b[0]), z0 = Math.min(a[1], b[1])
    const p = (t, off) => (horiz ? [x0 + t, a[1] + off] : [a[0] + off, z0 + t])
    for (let t = 4; t < len - 4; t += 6) {
      const [cx, cz] = p(t, 0)
      if (s.w === 18) {
        for (const off of [-0.6, 0.6]) { const [qx, qz] = p(t, off); R(c, qx, qz, horiz ? 6.4 : 0.5, horiz ? 0.5 : 6.4, "y") }
        for (const off of [-4.5, 4.5]) { const [qx, qz] = p(t, off); R(c, qx, qz, horiz ? 3 : 0.4, horiz ? 0.4 : 3, "i") }
      } else R(c, cx, cz, horiz ? 3 : 0.5, horiz ? 0.5 : 3, "Y")
    }
    for (const off of [-(s.w / 2) + 0.3, s.w / 2 - 0.8]) {
      const [qx, qz] = p(0, off); R(c, qx, qz, horiz ? len : 0.5, horiz ? 0.5 : len, "A")
    }
  }
  // crossings at the main junction
  for (let k = 0; k < 8; k++) {
    R(c, 291 + k * 2.4, 278, 1.2, 4, "V"); R(c, 291 + k * 2.4, 322, 1.2, 4, "V")
    R(c, 278, 291 + k * 2.4, 4, 1.2, "V"); R(c, 322, 291 + k * 2.4, 4, 1.2, "V")
  }
}

// ---------------------------------------------------------------- buildings
function building(c, r, label, floors, idx) {
  const [x, z, w, d] = r
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0
  const rd = rng(idx * 131 + 17)
  const faceM = Math.min(d * 0.46, 4 + floors * 1.8)
  const F = Math.round(faceM * S), RH = D - F
  // roof slab: lit top/left edge, dark inner parapet
  c.rect(x0, y0, W, RH, "R"); c.rect(x0 + 2, y0 + 2, W - 4, RH - 4, "r")
  c.hline(x0, y0, W, "e"); c.vline(x0, y0, RH, "e")
  // roof props on a jittered grid; each prop has a reason (plant, solar, vent, tank, skylight)
  const solar = /APT|CLASS|RESEARCH|PILOT|ADMIN|STUDIO|CLINIC|FAMILY/.test(label)
  for (let gx = x0 + 5; gx < x0 + W - 12; gx += 14) for (let gy = y0 + 5; gy < y0 + RH - 9; gy += 12) {
    const k = rd()
    const ox = gx + Math.floor(rd() * 4), oy = gy + Math.floor(rd() * 3)
    if (k < 0.2) c.stamp("_ac", ox, oy)
    else if (k < 0.3) c.stamp("_tank", ox, oy)
    else if (k < 0.4) c.stamp("_skylight", ox, oy)
    else if (k < 0.55 && solar) c.stamp("_solar", ox, oy)
    else if (k < 0.62 && /APT|FAMILY|CAFE/.test(label)) { c.rect(ox, oy, 8, 4, "t"); c.px(ox + 2, oy + 1, "m"); c.px(ox + 5, oy + 2, "L") }
  }
  if (rd() < 0.5) { c.vline(x0 + W - 5, y0 + 3, 5, "I"); c.px(x0 + W - 5, y0 + 2, "o") }
  // facade
  const fy = y0 + RH
  c.rect(x0, fy, W, F, "w"); c.hline(x0, fy, W, "e"); c.hline(x0, fy + 1, W, "W"); c.hline(x0, fy + F - 1, W, "k")
  const band = F >= 16
  const wy0 = fy + (band ? 9 : 3), whh = fy + F - 2 - wy0
  const rows = Math.max(1, Math.min(floors, Math.floor(whh / 4)))
  const rowH = Math.floor(whh / rows)
  if (band) {
    c.rect(x0 + 1, fy + 2, W - 2, 6, "k")
    const txt = label.toUpperCase().split(" ").reduce((s, wd) => ((s + " " + wd).trim().length * 4 <= W - 6 ? (s + " " + wd).trim() : s), "")
    const col = ["c", "m", "L"][Math.floor(rd() * 3)]
    if (txt) c.text(x0 + Math.floor((W - txt.length * 4 + 1) / 2), fy + 3, txt, col)
  }
  for (let rI = 0; rI < rows; rI++) for (let cx = x0 + 3; cx + 3 <= x0 + W - 3; cx += 5) {
    const t = rd()
    c.rect(cx, wy0 + rI * rowH, 3, Math.max(2, rowH - 2), t < 0.55 ? "l" : t < 0.7 ? "L" : "J")
  }
  const dx = x0 + 3 + Math.floor(rd() * Math.max(1, W - 12))
  c.rect(dx, fy + F - 6, 5, 5, "k"); c.rect(dx + 1, fy + F - 5, 3, 4, "c")
  if (idx % 3 === 0) c.vline(x0 + W - 3, wy0, whh + 1, "o")            // red conduit run
}

function hall(c, r) {
  const [x, z, w, d] = r
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = pz(z + d) - y0
  c.rect(x0, y0, W, D, "S"); c.rect(x0 + 1, y0 + 1, W - 2, D - 3, "s")
  for (let X = x0 + 3; X < x0 + W - 1; X += 5) c.vline(X, y0 + 1, D - 3, "S")
  c.rect(x0 + 2, y0 + Math.floor(D / 2) - 2, W - 4, 3, "z")           // glass ridge
  c.hline(x0, y0, W, "e")
  c.rect(x0, y0 + D - 3, W, 3, "L"); c.hline(x0, y0 + D - 1, W, "k")    // lit trim along the front
  for (let X = x0 + 4; X < x0 + W - 4; X += 8) c.rect(X, y0 + D - 3, 3, 2, "l")
}

function shelter(c, r, idx) {
  const [x, z, w, d] = r
  const x0 = px(x), y0 = pz(z), W = px(x + w) - x0, D = Math.min(pz(z + d) - y0, 14)
  c.rect(x0, y0, W, D, "R"); c.rect(x0 + 1, y0 + 1, W - 2, D - 2, "r")
  c.hline(x0 + 2, y0 + D - 2, W - 4, "c"); c.hline(x0, y0, W, "e")
  for (let X = x0 + 3; X < x0 + W - 4; X += 10) c.rect(X, y0 + 3, 6, 3, "J")
}

function drawBuildings(c) {
  let i = 0
  const list = []
  for (const p of PADS) list.push(p)
  for (const p of PLOTS) if (p[5] > 0 || p[5] === -1) list.push(p)
  for (const p of INFILL) list.push(p)
  list.sort((a, b) => a[1] - b[1])
  for (const p of list) {
    i++
    if (p[5] === -1) shelter(c, p, i)
    else if (p[4] === "HANGAR") {
      // curved hangar roof
      const x0 = px(p[0]), y0 = pz(p[1]), W = px(p[0] + p[2]) - x0, D = pz(p[1] + p[3]) - y0
      c.rect(x0, y0, W, D, "I"); c.rect(x0 + 1, y0 + 1, W - 2, D - 4, "i")
      for (let Y = y0 + 3; Y < y0 + D - 4; Y += 5) c.hline(x0 + 1, Y, W - 2, "I")
      c.rect(x0 + 6, y0 + D - 9, W - 12, 8, "k"); c.rect(x0 + 8, y0 + D - 8, W - 16, 6, "J")
      c.hline(x0 + 8, y0 + D - 3, W - 16, "c")
    } else if (p[2] > 100) {
      for (let k = 0; k < 2; k++) building(c, [p[0] + k * p[2] / 2, p[1], p[2] / 2 - 5, p[3]], p[4], 1, i * 5 + k)
    } else building(c, p, p[4], p[5], i)
  }
  for (const h of HALLS) hall(c, h)
}

function drawShadows(c) {
  const all = [...PADS, ...INFILL, ...PLOTS.filter((p) => p[5] > 0 || p[5] === -1), ...HALLS.map((h) => [...h, "", 1])]
  for (const p of all) {
    const x0 = px(p[0]), y0 = pz(p[1]), W = px(p[0] + p[2]) - x0
    const D = p[5] === -1 ? 14 : pz(p[1] + p[3]) - y0
    c.rect(x0 + 6, y0 + 5, W, D, "x")
  }
  for (const t of TREES) c.ellipse(px(t.x) + 3, pz(t.z) + t.r, t.r + 1, Math.max(2, t.r - 2), "x")
}

// ------------------------------------------------------------------ trees
const TREES = []
;(function plant() {
  const r = rng(2026)
  const add = (x, z, rr, kind) => TREES.push({ x, z, r: rr, kind })
  // forests: north hills, west hills
  const forest = (x0, z0, w, d, spacing, thin) => {
    for (let x = x0; x < x0 + w; x += spacing) for (let z = z0; z < z0 + d; z += spacing) {
      const tx = x + (r() - 0.5) * spacing * 0.9, tz = z + (r() - 0.5) * spacing * 0.9
      if (thin && r() < thin(tz)) continue
      if (Math.abs(tx - northStreamX(tz)) < 8 && tz < 0 && tz > -300) continue
      if (trailDist(tx, tz, NORTH_TRAIL) < 4 || trailDist(tx, tz, WEST_TRAIL) < 4 || trailDist(tx, tz, MARKET_TRAIL) < 4) continue
      if (Math.hypot((tx - northStreamX(-36)) / 17, (tz + 36) / 13) < 1) continue
      if (!roadClear(tx, tz, 2)) continue
      add(tx, tz, 4 + Math.floor(r() * 3), "forest")
    }
  }
  forest(0, -296, 500, 292, 6.2)
  forest(500, -296, 78, 292, 14, () => 0.3)
  forest(-298, 4, 296, 420, 6.2, (z) => (z < 330 ? 0 : (z - 330) / 100))
  // street + park planting
  const perim = (x0, z0, w, d) => {
    for (let x = x0 + 12; x < x0 + w - 8; x += 22) for (let z = z0 + 12; z < z0 + d - 8; z += 22) {
      if (x > x0 + 25 && x < x0 + w - 25 && z > z0 + 25 && z < z0 + d - 25) continue
      if (x > 470 && z > 410 && z < 614) continue
      const tx = x + (r() - 0.5) * 8, tz = z + (r() - 0.5) * 8
      if (nearBuilt(tx, tz, 4) || nearWater(tx, tz, 3) || !roadClear(tx, tz, 2)) continue
      add(tx, tz, 4 + Math.floor(r() * 2), r() < 0.2 ? "palm" : "tree")
    }
  }
  perim(314, 0, 300, 280); perim(0, 314, 280, 300); perim(314, 314, 300, 300)
  // campus planting (terrain_layout.clear_for_planting)
  for (let x = 12; x < 280; x += 17) for (let z = 12; z < 284; z += 17) {
    const tx = x + (r() - 0.5) * 6, tz = z + (r() - 0.5) * 6
    if (nearBuilt(tx, tz, 5) || nearWater(tx, tz, 4) || !roadClear(tx, tz, 2)) continue
    if (Math.abs(tz - 80) < 23 || Math.abs(tz - 210) < 23) continue
    if ([50, 150, 250].some((cx) => Math.abs(tx - cx) < 7)) continue
    if (r() < 0.55) add(tx, tz, 4 + Math.floor(r() * 2), r() < 0.12 ? "palm" : "tree")
  }
  // market perimeter + plaza, lake shore, river banks
  for (let x = 20; x < 590; x += 18) for (const z of [-695, -352, -540])
    if (r() < 0.7 && !nearBuilt(x, z, 4) && roadClear(x, z, 3)) add(x + (r() - 0.5) * 5, z + (r() - 0.5) * 3, 4, r() < 0.3 ? "palm" : "tree")
  for (let a = 0; a < 6.28; a += 0.2) if (r() < 0.8) add(550 + Math.cos(a) * 60, 548 + Math.sin(a) * 56, 4, "tree")
  for (let x = -290; x < 610; x += 14) {
    if (r() < 0.55) add(x, riverBank(x) - 16 + r() * 4, 4, "tree")
    if (r() < 0.6) add(x, riverBank(x) + riverWidth(x) + 8 + r() * 24, 4 + Math.floor(r() * 2), "tree")
  }
  // pink palms ring the plazas and the lake promenade (neon-palm accent from the reference)
  for (const [cx, cz, rad, n] of [[150, 152, 17, 8], [450, 150, 22, 10], [550, 548, 62, 12], [300, -495, 70, 10]])
    for (let k = 0; k < n; k++) { const a = (k / n) * 6.283; add(cx + Math.cos(a) * rad, cz + Math.sin(a) * rad, 4, "palm") }
  TREES.sort((a, b) => a.z - b.z)
})()

function drawTrees(c) {
  for (const t of TREES) {
    const X = px(t.x), Y = pz(t.z), rr = t.r
    if (t.kind === "palm") {
      c.line(X, Y + rr, X, Y - 1, "I", 1)
      for (let k = 0; k < 7; k++) {
        const a = (k / 7) * 6.283 + 0.4
        c.line(X, Y - 2, X + Math.round(Math.cos(a) * 6), Y - 2 + Math.round(Math.sin(a) * 4), k % 2 ? "m" : "M", 1)
      }
      c.circ(X, Y - 2, 1, "L")
    } else {
      const forest = t.kind === "forest"
      c.circ(X, Y, rr, forest ? "T" : "t")
      c.circ(X - 1, Y - 1, Math.max(2, rr - 2), forest ? "t" : "u")
      c.circ(X - 2, Y - 2, Math.max(1, rr - 4), forest ? "u" : "U")
    }
  }
}

// ------------------------------------------------------------------ lamps, cars, skytrain, labels
function drawLife(c) {
  const r = rng(99)
  for (const s of segs) {
    const [a, b] = [s.a, s.b], horiz = a[1] === b[1]
    const len = Math.abs(horiz ? b[0] - a[0] : b[1] - a[1]), x0 = Math.min(a[0], b[0]), z0 = Math.min(a[1], b[1])
    for (let t = 14; t < len - 10; t += 30) for (const side of [-1, 1]) {
      const off = side * (s.w / 2 + 1.5)
      const lx = horiz ? x0 + t : a[0] + off, lz = horiz ? a[1] + off : z0 + t
      c.stamp("_lamp", px(lx), pz(lz) - 2)
    }
    const nCars = Math.floor(len / 70)
    for (let k = 0; k < nCars; k++) {
      const t = 12 + r() * (len - 24), lane = (r() < 0.5 ? -1 : 1) * (s.w === 18 ? 6.5 : 2)
      const cx = horiz ? x0 + t : a[0] + lane, cz = horiz ? a[1] + lane : z0 + t
      c.stamp(horiz ? "_car" : "_carv", px(cx) - 5, pz(cz) - 3, { swap: r() < 0.4 ? { C: "M", c: "m" } : {} })
    }
  }
}

function drawSky(c) {
  const track = (pts) => {
    polyline(c, pts, 5, "x"); polyline(c, pts, 3.4, "I"); polyline(c, pts, 2.2, "i")
    for (let k = 0; k < pts.length - 1; k++) {
      const [a, b] = [pts[k], pts[k + 1]], n = Math.hypot(b[0] - a[0], b[1] - a[1])
      for (let t = 0; t < n; t += 12) c.px(px(a[0] + ((b[0] - a[0]) * t) / n), pz(a[1] + ((b[1] - a[1]) * t) / n), "c")
    }
  }
  // City Loop follows the outer street corridors, 7 m outside the road edge
  track([[-1, -1], [622, -1], [622, 625], [-1, 625], [-1, -1]])
  track([[622, 150], [622, -425], [535, -425], [535, -600]])           // Market Link
  for (const st of STATIONS) {
    const [nm, x, z] = st
    const sx = x <= 8 ? -1 : x >= 610 ? 622 : x, sz = z <= 8 && z > -100 ? -1 : z >= 610 ? 625 : z
    const X = px(sx), Y = pz(sz)
    c.rect(X - 14, Y - 7, 28, 14, "k"); c.rect(X - 13, Y - 6, 26, 12, "C")
    c.rect(X - 12, Y - 5, 24, 10, "w")
    c.text(X - 5, Y - 3, nm, "c")
    c.hline(X - 12, Y + 6, 24, "L")
  }
}

function drawLabels(c) {
  const lab = (t, x, z, col = "c") => {
    const X = px(x) - Math.floor((t.length * 4 * 3) / 2), Y = pz(z)
    c.text(X + 1, Y + 1, t, "x", { scale: 3 })
    c.text(X, Y, t, col, { scale: 3 })
  }
  lab("YUST CAMPUS", 150, 6); lab("STUDENT TECH HUB", 460, 6, "m")
  lab("HOME TERRACES", 150, 312, "L"); lab("LAKESIDE MARKET", 460, 312, "c")
  lab("NORTH HILLS", 250, -290, "C"); lab("WEST HILLS", -150, 10, "C")
  lab("NORTHERN MARKET", 300, -698, "L"); lab("SOUTH RIVERFRONT", 200, 800, "m")
}

// ------------------------------------------------------------------ scenes
const WORLD_ITEMS = [
  layer("ground", drawGround),
  layer("water", drawWater),
  layer("paths", drawPaths),
  layer("roads", drawRoads),
  layer("shadows", { shade: true }, drawShadows),
  layer("buildings", drawBuildings),
  layer("trees", drawTrees),
  layer("life", drawLife),
  layer("sky", drawSky),
  layer("labels", drawLabels),
]
scene("world", { w: WM * S, h: HM * S, bg: "n" }, ...WORLD_ITEMS,
  glow("lLcm", { r: 5, strength: 0.45, bands: 3 }))

// district close-ups (stamps of the full world)
const view = (name, x, z, w, d) =>
  scene(name, { w: w * S, h: d * S, bg: "n" }, stamp("world", -px(x), -pz(z)))
view("view_campus", 0, 0, 300, 300)
view("view_tech", 314, 0, 300, 300)
view("view_home", 0, 314, 300, 300)
view("view_lake", 314, 314, 300, 300)
view("view_market", 0, -700, 614, 400)
view("view_riverfront", -300, 600, 914, 210)
