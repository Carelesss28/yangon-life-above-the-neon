// YUST campus layout for the 2D top-down game. Metres, x east / z south (same axes as campus_terrain).
// Source of truth: campus_terrain/scripts/{terrain_layout,road_layout,reference_buildings,world}.gd
export const U = 16            // pixels per metre
export const OX = 8, OY = 8    // world metres of pixel (0,0) are (-OX,-OY)
export const SIZE = 324        // metres, -8..316
export const BOUNDS = [0, 0, 314, 314]

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

// [id, interior type, label, x, z, w, d, floors]
export const BUILDINGS = [
  ["admin", "office", "CAMPUS ADMIN", 17, 20, 27, 35, 3],
  ["pilot", "sim", "PILOT SCHOOL", 110, 20, 35, 35, 3],
  ["class", "classroom", "CLASSROOMS", 160, 20, 35, 35, 3],
  ["research", "classroom", "RESEARCH", 205, 20, 33, 35, 3],
  ["dormA", "dorm", "DORM A", 17, 104, 27, 35, 3],
  ["commons", "cafe", "FOOD COMMONS", 78, 108, 25, 25, 2],
  ["hangar", "hangar", "ENGINEERING HANGAR", 203, 105, 35, 40, 2],
  ["dormB", "dorm", "DORM B", 17, 157, 27, 35, 3],
  ["union", "union", "STUDENT UNION", 78, 157, 25, 35, 2],
  ["books", "shop", "BOOKSHOP", 17, 232, 27, 28, 1],
  ["clubs", "club", "STUDENT CLUBS", 205, 232, 33, 28, 2],
]
export const TRAINING = [205, 160, 70, 40]
export const QUAD = [125, 125, 50, 55]
export const CX = [50, 150, 250]
export const PROM = [65, 150, 270]

// walkable paved rects [x, z, w, d]
export const PAVED = []
for (const z of PROM) PAVED.push([5, z - 3, 281, 6])
for (const cx of CX) PAVED.push([cx - 3, 8, 6, 282])
PAVED.push(QUAD)
for (const b of BUILDINGS) PAVED.push([b[3] - 2, b[4] - 2, b[5] + 4, b[6] + 4])   // building pads

for (const b of BUILDINGS) {
  const bottom = b[4] + b[6], p = PROM.find((p) => p - 3 > bottom)
  if (p) PAVED.push([b[3] + b[5] / 2 - 2, bottom, 4, p - 3 - bottom])
}

// perimeter vehicle loop: the 8 m roads on the north + west, the 18 m avenues on the east + south
export const ROADS = [
  { a: [8, 8], b: [302, 8], w: 8 }, { a: [8, 8], b: [8, 302], w: 8 },
  { a: [302, 8], b: [302, 302], w: 18 }, { a: [8, 302], b: [302, 302], w: 18 },
]
export const CAR_LOOP = [[10, 10], [297.5, 10], [297.5, 297.5], [10, 297.5]]

// campus stream (graded route 1): x runs ~65 through the campus
export const STREAM = [[65, 0], [65, 40], [64, 95], [63, 150], [70, 198], [75, 235], [75, 290], [75, 316]]
export const BRIDGES = PROM.map((z) => [z - 3.5, z + 3.5])    // z ranges where promenades cross the stream
export const streamX = (z) => {
  for (let i = 0; i < STREAM.length - 1; i++) {
    const [a, b] = [STREAM[i], STREAM[i + 1]]
    if (z >= a[1] && z <= b[1]) return a[0] + ((b[0] - a[0]) * (z - a[1])) / (b[1] - a[1])
  }
  return 65
}

// interior rooms: size [w, d] metres (back wall = top 3 m) + furniture [kind, x, z, w, d, opts]
export const INTERIORS = {
  classroom: { w: 16, d: 11, f: [
    ["board", 4, 0.4, 8, 2.2], ["desk", 6, 3.6, 4, 1.2, { teacher: 1 }],
    ...[0, 1, 2].flatMap((r) => [0, 1, 2, 3].map((c) => ["student", 2.2 + c * 3.2, 5.6 + r * 1.7, 2, 1]) ),
    ["shelf", 0.6, 3.4, 0.7, 3], ["plant", 14.4, 3.4, 0.9, 0.9], ["locker", 12, 0.6, 3.4, 1.8]] },
  dorm: { w: 12, d: 9, f: [
    ["bed", 1, 3.4, 2.2, 3.2], ["bed", 9, 3.4, 2.2, 3.2], ["rug", 3.8, 5.4, 4.4, 2.6],
    ["desk", 4.6, 3.3, 3, 1.1], ["wardrobe", 0.8, 0.6, 2.4, 2.2], ["shelf", 8.8, 0.8, 2.4, 1],
    ["plant", 11, 7, 0.9, 0.9]] },
  cafe: { w: 15, d: 11, f: [
    ["counter", 1, 3.4, 8, 1.4], ["kettle", 1.4, 3.1, 0.7, 0.7], ["menu", 2.5, 0.5, 6, 1.6],
    ...[[2, 7], [6, 6.4], [10, 7], [11.6, 4.2], [4, 9.2], [8.4, 9]].flatMap(([x, z]) => [["tea", x, z, 1.2, 1.2], ["stool", x - 0.9, z + 0.2, 0.55, 0.55], ["stool", x + 1.55, z + 0.2, 0.55, 0.55]]),
    ["vending", 13, 3.2, 1.1, 1.3]] },
  hangar: { w: 24, d: 14, f: [
    ["toolwall", 1, 0.3, 22, 2.6], ["bench", 2, 3.6, 5, 1.4], ["bench", 17, 3.6, 5, 1.4],
    ["mech", 8.5, 4.6, 7, 5.6], ["crate", 1.4, 9.4, 1.6, 1.6], ["crate", 3.2, 9.8, 1.4, 1.4],
    ["crate", 20.6, 9.4, 1.6, 1.6], ["arm", 19, 7, 2.2, 2.2], ["console", 20, 11, 2.4, 1]] },
  office: { w: 13, d: 10, f: [
    ["shelf", 1, 0.6, 3.4, 1.2], ["shelf", 5, 0.6, 3.4, 1.2], ["holo", 9.4, 0.8, 2.6, 1.8],
    ["desk", 1.6, 4.2, 3, 1.4], ["desk", 6.2, 4.2, 3, 1.4], ["desk", 10, 4.8, 2.2, 1.4],
    ["plant", 0.9, 8, 0.9, 0.9], ["sofa", 5, 8, 3.2, 1.2]] },
  union: { w: 15, d: 11, f: [
    ["screen", 5, 0.4, 5, 2.2], ["sofa", 1, 4.6, 3.2, 1.2], ["sofa", 1, 7, 3.2, 1.2], ["tea", 5, 5.4, 2, 1.6],
    ["sofa", 8.6, 4.6, 3.2, 1.2], ["tea", 8.2, 7.4, 2, 1.6], ["vending", 12.4, 3.4, 1.1, 1.3], ["plant", 13.2, 8.6, 0.9, 0.9],
    ["arcade", 12, 7, 1.4, 1.3]] },
  shop: { w: 12, d: 9, f: [
    ["bookshelf", 1, 3.4, 3.4, 1.1], ["bookshelf", 5, 3.4, 3.4, 1.1], ["bookshelf", 1, 5.8, 3.4, 1.1],
    ["bookshelf", 5, 5.8, 3.4, 1.1], ["counter", 9, 4, 2.2, 3.2], ["plant", 10.6, 0.9, 0.9, 0.9],
    ["poster", 1.5, 0.4, 3, 2], ["poster", 6, 0.4, 3, 2]] },
  club: { w: 14, d: 10, f: [
    ["arcade", 1, 3.2, 1.4, 1.3], ["arcade", 3, 3.2, 1.4, 1.3], ["arcade", 5, 3.2, 1.4, 1.3],
    ["tea", 8, 4.2, 2, 1.8], ["tea", 8, 7, 2, 1.8], ["sofa", 1, 7.6, 3.2, 1.2], ["screen", 8.4, 0.4, 4, 2.2],
    ["poster", 1, 0.5, 2.4, 2], ["poster", 4.2, 0.5, 2.4, 2], ["plant", 12.6, 8, 0.9, 0.9]] },
  sim: { w: 20, d: 14, f: [
    ["screen", 2, 0.4, 7, 2.3], ["holo", 12, 0.6, 5, 2],
    ...[0, 1, 2, 3, 4].map((i) => ["pod", 1.5 + i * 3.6, 3.4, 2.6, 3]),
    ...[0, 1, 2, 3].map((i) => ["student", 2 + i * 4, 9, 2, 1]), ["desk", 14.6, 9.4, 3.4, 1.2, { teacher: 1 }],
    ["plant", 18, 12, 0.9, 0.9]] },
}
for (const k in INTERIORS) { INTERIORS[k].type = k }

const r = rng(20261119)
const inRect = (x, z, q, m = 0) => x > q[0] - m && x < q[0] + q[2] + m && z > q[1] - m && z < q[1] + q[3] + m
const allRects = () => [...BUILDINGS.map((b) => [b[3], b[4], b[5], b[6]]), TRAINING]
export function treeOk(x, z) {
  if (x < 3 || x > 308 || z < 3 || z > 308) return false
  if (x > 286 && x < 296) return false
  if (z > 285 && z < 300) return false
  for (const q of allRects()) if (inRect(x, z, q, 4)) return false
  if (inRect(x, z, [122, 120, 56, 65], 3)) return false
  for (const p of PROM) if (Math.abs(z - p) < 6) return false
  for (const c of CX) if (Math.abs(x - c) < 6) return false
  if (Math.abs(x - streamX(z)) < 6) return false
  if (Math.abs(z - 80) < 8 || Math.abs(z - 210) < 8) return false
  if (x < 14 && z > 12) return false
  return true
}
export const TREES = []
for (let x = 8; x < 306; x += 11) for (let z = 10; z < 306; z += 11) {
  const tx = x + (r() - 0.5) * 7, tz = z + (r() - 0.5) * 7
  if (!treeOk(tx, tz) || r() < 0.4) continue
  TREES.push({ x: +tx.toFixed(1), z: +tz.toFixed(1), k: r() < 0.14 ? "palm" : "tree" + Math.floor(r() * 3) })
}
TREES.sort((a, b) => a.z - b.z)
// pink palms ring the central quad (reference 03 accent)
for (let k = 0; k < 10; k++) { const a = (k / 10) * 6.283 + 0.3; TREES.push({ x: +(150 + Math.cos(a) * 19.5).toFixed(1), z: +(152.5 + Math.sin(a) * 17.5).toFixed(1), k: "palm" }) }

// props: kind, base x/z, collision [w, d] or null
export const PROPS = []
const prop = (k, x, z, coll) => PROPS.push({ k, x, z, coll: coll || null })
for (const c of CX) for (const z of [30, 100, 180, 245]) { prop("lamp", c - 3.8, z, [0.5, 0.5]); prop("lamp", c + 3.8, z + 12, [0.5, 0.5]) }
for (const z of PROM) for (const x of [25, 100, 200, 270]) { if (Math.abs(x - 65) > 6) prop("lamp", x, z - 3.9, [0.5, 0.5]) }
for (let x = 20; x < 300; x += 40) { prop("lamp", x, 13.5, [0.5, 0.5]); }
for (let z = 40; z < 300; z += 40) { prop("lamp", 14.5, z, [0.5, 0.5]) }
for (const [x, z] of [[130, 142], [170, 142], [130, 168], [170, 168], [100, 66], [200, 66], [100, 152], [200, 152], [100, 271], [200, 271]]) prop("bench", x, z, [1.8, 0.7])
for (const [x, z] of [[46, 85], [154, 85], [254, 85], [46, 205], [154, 205]]) prop("bin", x, z, [0.6, 0.6])
prop("vending", 40.5, 115, [1.1, 0.9]); prop("vending", 41.8, 116, [1.1, 0.9])
prop("board", 119, 63, [2.4, 0.5]); prop("board", 182, 63, [2.4, 0.5]); prop("board", 120, 148, [2.4, 0.5])
for (const [x, z] of [[24, 144], [30, 144], [24, 196], [30, 196]]) prop("bikerack", x, z, [2.8, 0.8])
prop("statue", 150, 152, [4.8, 3.2])
prop("signmap", 151, 60, [2.4, 0.5])
prop("kiosk", 224, 154, [3, 2])

// doors: trigger rect just south of each building's front door
export const DOORS = BUILDINGS.map((b) => ({ id: b[0], type: b[1], label: b[2], x: b[3] + b[5] / 2, z: b[4] + b[6], r: [b[3] + b[5] / 2 - 2, b[4] + b[6] - 0.2, 4, 2.4] }))

// NPC waypoint graph on the path grid
const xs = [10, 50, 150, 250, 284], zs = [12, 65, 150, 270, 288]
export const NODES = []
const key = (x, z) => x + "," + z
for (const x of xs) for (const z of zs) NODES.push([x, z])
export const EDGES = []
for (const z of PROM) for (let i = 0; i < xs.length - 1; i++) EDGES.push([[xs[i], z], [xs[i + 1], z]])
for (const x of CX) for (let i = 0; i < zs.length - 1; i++) EDGES.push([[x, zs[i]], [x, zs[i + 1]]])
export const NPC_NODES = [...new Set(EDGES.flat().map((p) => key(p[0], p[1])))].map((s) => s.split(",").map(Number))

// collision rects in metres [x, z, w, d]
export function colliders() {
  const out = []
  for (const b of BUILDINGS) out.push([b[3], b[4], b[5], b[6]])
  out.push([QUAD[0] + 18, QUAD[1] + 22, 14, 10])    // statue plinth handled by prop; keep ring open
  out.pop()
  // terrace retaining walls (z=80 and z=210) with openings for stairs (cx) and ramps (cx+28)
  for (const ez of [80, 210]) {
    const gaps = [...CX.map((c) => [c - 4, c + 4]), ...CX.map((c) => [c + 25, c + 31])].sort((a, b) => a[0] - b[0])
    let x = 5
    for (const g of gaps) { if (g[0] > x) out.push([x, ez, g[0] - x, 2.1]); x = g[1] }
    if (x < 286) out.push([x, ez, 286 - x, 2.1])
  }
  // stream: split at bridges
  for (let z = 0; z < 316; z += 2) {
    if (BRIDGES.some((b) => z + 1 > b[0] && z < b[1])) continue
    out.push([streamX(z) - 1.4, z, 2.8, 2])
  }
  return out
}
