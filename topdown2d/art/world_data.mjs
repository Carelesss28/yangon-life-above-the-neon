// Whole-world layout for the 2D game. Metres, x east / z south, same axes as campus_terrain.
// Sources: campus_terrain/scripts/{road_layout,terrain_layout,world,reference_buildings,skytrain}.gd
import { LORE } from "./lore.mjs"
export const U = 16
export const OX = 300, OY = 700          // metres of pixel (0,0) are (-OX, -OY)
export const WM = 914, HM = 1510
export const CHUNK_M = 100               // chunk edge in metres (1600 px)
export const LAND = [[0, 0, 614, 614], [0, -700, 614, 400], [0, -300, 500, 300], [500, -300, 114, 300], [-300, 0, 300, 500], [-300, 500, 300, 114], [-300, 614, 914, 196]]
export const VOID = [[-300, -700, 300, 700]]

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
const inRect = (x, z, q, m = 0) => x > q[0] - m && x < q[0] + q[2] + m && z > q[1] - m && z < q[1] + q[3] + m
const segDist = (x, z, a, b) => {
  const dx = b[0] - a[0], dz = b[1] - a[1], L = dx * dx + dz * dz
  const t = L ? Math.max(0, Math.min(1, ((x - a[0]) * dx + (z - a[1]) * dz) / L)) : 0
  return Math.hypot(x - (a[0] + dx * t), z - (a[1] + dz * t))
}
const polyDist = (x, z, pts) => { let d = 1e9; for (let i = 0; i < pts.length - 1; i++) d = Math.min(d, segDist(x, z, pts[i], pts[i + 1])); return d }

// ---------------------------------------------------------------- roads
export const NODES = {
  nw: [8, 8], n: [302, 8], ne_return: [580, 8], ne: [610, 8], w: [8, 302], c: [302, 302], e: [610, 302],
  sw: [8, 616], s: [302, 616], se: [610, 616],
  market_nw: [8, -680], market_ne: [610, -680], market_sw: [8, -360], market_return: [580, -360], market_se: [610, -360],
  upper_w: [-250, 618], upper_c: [300, 618], ramp_w_top: [-250, 638], ramp_w_bottom: [-90, 638], lower_w: [-90, 654],
  ramp_e_top: [300, 638], ramp_e_bottom: [460, 638], lower_e: [460, 654],
  tech_nw: [335, 60], tech_ne: [594, 60], tech_se: [594, 255], tech_sw: [335, 255],
  home_nw: [25, 365], home_ne: [270, 365], home_w_mid: [25, 450], home_e_mid: [270, 450],
  home_sw: [25, 550], home_se: [270, 550], home_exit: [270, 590], home_join: [270, 614],
}
export const EDGES = [
  ["nw", "n"], ["n", "ne_return"], ["ne_return", "ne"], ["nw", "w"], ["w", "sw"], ["n", "c"], ["c", "s"], ["ne", "e"], ["e", "se"],
  ["w", "c"], ["c", "e"], ["sw", "s"], ["s", "se"],
  ["market_nw", "market_ne"], ["market_nw", "market_sw"], ["market_sw", "market_return"], ["market_return", "market_se"],
  ["market_se", "market_ne"], ["market_return", "ne_return"], ["market_se", "ne"],
  ["s", "upper_c"], ["upper_w", "upper_c"], ["upper_w", "ramp_w_top"], ["ramp_w_top", "ramp_w_bottom"], ["ramp_w_bottom", "lower_w"],
  ["lower_w", "lower_e"], ["lower_e", "ramp_e_bottom"], ["ramp_e_bottom", "ramp_e_top"], ["ramp_e_top", "upper_c"],
  ["n", "tech_nw"], ["tech_nw", "tech_ne"], ["tech_ne", "tech_se"], ["tech_se", "tech_sw"], ["tech_sw", "tech_nw"], ["tech_se", "e"],
  ["home_nw", "home_ne"], ["home_ne", "home_e_mid"], ["home_e_mid", "home_se"], ["home_se", "home_sw"], ["home_sw", "home_w_mid"],
  ["home_w_mid", "home_nw"], ["home_se", "home_exit"], ["home_exit", "home_join"], ["home_join", "s"],
]
const MAIN = new Set(["n-c", "c-s", "w-c", "c-e"])
export const ROADS = EDGES.map((e) => ({ a: NODES[e[0]], b: NODES[e[1]], w: MAIN.has(e[0] + "-" + e[1]) ? 18 : 8 }))
// a few edges are not axis aligned in the graph (home_exit, join): treat as L-shaped by snapping
for (const r of ROADS) { if (r.a[0] !== r.b[0] && r.a[1] !== r.b[1]) { if (Math.abs(r.b[0] - r.a[0]) < Math.abs(r.b[1] - r.a[1])) r.b = [r.a[0], r.b[1]]; else r.b = [r.b[0], r.a[1]] } }

// clockwise car loops (lane = 1/4 road width to the right of travel)
function loop(nodes, laneW) {
  const pts = nodes.map((n) => NODES[n])
  const off = (a, b, w) => { const dx = Math.sign(b[0] - a[0]), dz = Math.sign(b[1] - a[1]); return [-dz * w / 4, dx * w / 4] }
  const edges = pts.map((p, i) => { const q = pts[(i + 1) % pts.length]; const w = laneW[i]; const o = off(p, q, w); return { horiz: p[1] === q[1], c: p[1] === q[1] ? p[1] + o[1] : p[0] + o[0] } }) // fixed coordinate of each edge
  return pts.map((p, i) => { const prev = edges[(i + pts.length - 1) % pts.length], cur = edges[i]; return cur.horiz ? [prev.c, cur.c] : [cur.c, prev.c] })
}
export const CAR_LOOPS = [
  loop(["nw", "n", "c", "w"], [8, 18, 18, 8]), loop(["n", "ne", "e", "c"], [8, 8, 18, 18]),
  loop(["c", "e", "se", "s"], [18, 8, 8, 18]), loop(["w", "c", "s", "sw"], [18, 18, 8, 8]),
  loop(["tech_nw", "tech_ne", "tech_se", "tech_sw"], [8, 8, 8, 8]), loop(["home_nw", "home_ne", "home_se", "home_sw"], [8, 8, 8, 8]),
  loop(["market_nw", "market_ne", "market_se", "market_sw"], [8, 8, 8, 8]),
]
for (const L of CAR_LOOPS) for (const p of L) { p[0] = +p[0].toFixed(2); p[1] = +p[1].toFixed(2) }

// ---------------------------------------------------------------- buildings  [id, interior type, label, x, z, w, d, floors]
export const BUILDINGS = [
  // campus
  ["admin", "office", "CAMPUS ADMIN", 17, 20, 27, 35, 3], ["pilot", "sim", "PILOT SCHOOL", 110, 20, 35, 35, 3],
  ["class", "classroom", "CLASSROOMS", 160, 20, 35, 35, 3], ["research", "classroom", "RESEARCH", 205, 20, 33, 35, 3],
  ["dormA", "dorm", "DORM A", 17, 104, 27, 35, 3], ["commons", "cafe", "FOOD COMMONS", 78, 108, 25, 25, 2],
  ["hangar", "hangar", "ENGINEERING HANGAR", 203, 105, 35, 40, 2], ["dormB", "dorm", "DORM B", 17, 157, 27, 35, 3],
  ["union", "union", "STUDENT UNION", 78, 157, 25, 35, 2], ["books", "shop", "BOOKSHOP", 17, 232, 27, 28, 1],
  ["clubs", "club", "STUDENT CLUBS", 205, 232, 33, 28, 2],
  // student / tech hub
  ["clinic", "clinic", "STUDENT CLINIC", 365, 20, 55, 32, 3], ["techapt", "apartment", "TECH APARTMENTS", 475, 20, 65, 32, 5],
  ["repair", "workshop", "ELECTRONICS REPAIR", 365, 80, 36, 48, 2], ["design", "office", "DESIGN STUDIOS", 408, 82, 30, 48, 3],
  ["robot", "workshop", "ROBOT WORKSHOP", 500, 95, 50, 45, 3], ["arcade", "club", "ARCADE", 365, 175, 36, 45, 2],
  ["techapt2", "apartment", "TECH APTS", 490, 155, 62, 32, 4], ["shopstea", "cafe", "SHOPS AND TEA", 490, 200, 62, 34, 1],
  ["maker", "workshop", "MAKER STUDIOS", 480, 265, 65, 25, 2],
  // home neighbourhood
  ["familycafe", "family", "FAMILY HOME AND ROOFTOP CAFE", 72, 460, 58, 45, 5], ["mohinga", "cafe", "TEA AND MOHINGA", 72, 330, 55, 32, 1],
  ["laundry", "shop", "LAUNDRY AND SHOPS", 175, 335, 50, 30, 1], ["gardenapt", "apartment", "GARDEN APTS", 72, 378, 55, 47, 4],
  ["neighbour", "apartment", "NEIGHBOUR APTS", 175, 380, 50, 35, 3], ["terrace", "apartment", "TERRACE APTS", 175, 515, 50, 35, 4],
  ["courtE", "apartment", "COURT EAST", 175, 462, 20, 38, 3], ["courtW", "apartment", "COURT WEST", 205, 462, 20, 38, 4],
  ["homeapt", "apartment", "HOME APARTMENTS", 68, 575, 60, 30, 5],
  // lakeside
  ["foodstrip", "cafe", "EVENING FOOD STRIP", 365, 330, 42, 20, 1], ["recreation", "union", "RECREATION CENTRE", 545, 330, 47, 45, 2],
  ["lakecafe", "cafe", "LAKESIDE CAFE", 455, 460, 28, 18, 1],
  // northern market
  ["wholesaleA", "warehouse", "WHOLESALE", 95, -645, 70, 35, 1], ["wholesaleB", "warehouse", "COLD STORAGE", 170, -645, 70, 35, 1],
  ["deliveryA", "warehouse", "DELIVERY", 345, -645, 70, 35, 1], ["deliveryB", "warehouse", "RECYCLING", 420, -645, 70, 35, 1],
  ["craft", "shop", "CRAFT AND BOOKS", 95, -545, 55, 65, 1], ["cafes", "cafe", "MARKET CAFES", 450, -545, 55, 65, 2],
  ["bikeinfo", "office", "BIKE PARKING INFO", 100, -405, 90, 28, 1],
]
export const HALLS = [  // barrel-vault glass market halls, enterable
  ["hallProduce", "market", "PRODUCE MARKET", 195, -590, 95, 55], ["hallClothes1", "market", "CLOTHING", 310, -590, 45, 55],
  ["hallClothes2", "market", "CRAFTS", 358, -590, 45, 55], ["hallFood", "market", "FOOD AND TEA", 195, -515, 95, 55],
  ["hallTech", "market", "ROBOT PARTS", 310, -515, 95, 55],
]
export const SHELTERS = [[375, 255, 65, 22, "TRANSIT"], [460, -405, 90, 28, "TRAM"]]
export const TRAINING = [205, 160, 70, 40]
export const QUAD = [125, 125, 50, 55]
export const PLAZA = [410, 110, 80, 80]
export const OPEN_PLOTS = [  // gardens / lawns / courts [x,z,w,d,kind]
  [175, 575, 52, 30, "garden"], [365, 525, 48, 38, "garden"], [470, 420, 48, 30, "lawn"], [475, 330, 60, 45, "court"],
  [180, 430, 18, 10, "playground"], [72, 530, 56, 25, "garden"],
]
export const CX = [50, 150, 250]
export const PROM = [65, 150, 270]

// ---------------------------------------------------------------- paved strips
export const PAVED = []
for (const z of PROM) PAVED.push([5, z - 3, 281, 6])
for (const cx of CX) PAVED.push([cx - 3, 8, 6, 282])
PAVED.push(QUAD)
for (const x of [282, 318]) PAVED.push([x, 5, 4, 604])
for (const z of [282, 318]) PAVED.push([5, z, 604, 4])
for (const z of [65, 150, 245]) PAVED.push([314, z - 3, 294, 6])
for (const x of [350, 450, 570]) PAVED.push([x - 3, 8, 6, 278])
PAVED.push(PLAZA)
for (const z of [350, 450, 560]) PAVED.push([8, z - 3, 278, 6])
for (const x of [50, 150, 250]) PAVED.push([x - 3, 314, 6, 294])
PAVED.push([72, 427, 56, 18], [175, 427, 50, 18], [72, 530, 56, 25])
for (const z of [350, 400]) PAVED.push([314, z - 3, 294, 6])
PAVED.push([345, 314, 6, 294], [430, 350, 6, 258], [345, 490, 130, 5], [430, 595, 68, 4])
PAVED.push([590, -700, 5, 700])
for (const z of [-670, -410]) PAVED.push([20, z - 4, 575, 8])
PAVED.push([175, -610, 250, 175], [245, -405, 110, 45], [300, -380, 290, 6])
const ALLB = () => [...BUILDINGS.map((b) => [b[3], b[4], b[5], b[6]]), ...HALLS.map((h) => [h[3], h[4], h[5], h[6]]), ...SHELTERS.map((s) => [s[0], s[1], s[2], s[3]])]
for (const r of ALLB()) PAVED.push([r[0] - 2, r[1] - 2, r[2] + 4, r[3] + 4])
// door paths: from each building's front to the nearest paved strip to the south (or the building's own pad)
const DOORPATH = []
for (const b of [...BUILDINGS, ...HALLS.map((h) => [...h, 1])]) {
  const bottom = b[4] + b[6], cx = b[3] + b[5] / 2
  let best = null
  for (const p of PAVED) { if (p[2] > 300 || p[3] > 300) { /* long strips ok */ } if (cx > p[0] && cx < p[0] + p[2] && p[1] > bottom + 1.5 && (!best || p[1] < best[1])) best = p }
  if (best && best[1] - bottom < 60) DOORPATH.push([cx - 2, bottom, 4, best[1] - bottom])
}
PAVED.push(...DOORPATH)

// ---------------------------------------------------------------- water, trails, forests
export const STREAM = [[65, 0], [65, 40], [64, 95], [63, 150], [70, 198], [75, 235], [75, 290], [75, 316]]   // campus stream (blocking)
export const streamX = (z) => { for (let i = 0; i < STREAM.length - 1; i++) { const [a, b] = [STREAM[i], STREAM[i + 1]]; if (z >= a[1] && z <= b[1]) return a[0] + ((b[0] - a[0]) * (z - a[1])) / (b[1] - a[1]) } return 65 }
export const BRIDGES = PROM
export const northStreamX = (z) => 355 + 8 * Math.sin(z * 0.027)
export const riverBank = (x) => 685 + 7 * Math.sin(x * 0.012) + 3 * Math.sin(x * 0.032)
export const riverWidth = (x) => 65 + 7 * Math.sin(x * 0.016 + 1)
export const LAKE = { cx: 550, cz: 548, rx: 46, rz: 43 }
export const CHANNELS = [
  { w: 1.6, p: [[355, -36], [260, -70], [100, -50], [65, 0]] },
  { w: 0.9, p: [[130, 550], [135, 535], [135, 475], [135, 440], [135, 380], [135, 350], [75, 350]] },
  { w: 1.1, p: [[460, 105], [465, 150], [465, 215], [470, 265], [470, 330], [465, 395], [490, 465], [520, 520]] },
  { w: 1.2, p: [[565, -640], [565, -520], [565, -365], [575, -280], [575, -190], [575, -85], [575, 0], [575, 150], [575, 270], [465, 395]] },
  { w: 1.0, p: [[605, 565], [608, 610], [608, 660], [608, 710]] },
  { w: 1.6, p: [[65, 316], [65, 560], [65, 625], [65, 675], [65, 705]] },
]
export const NORTH_TRAIL = [[150, 0], [150, -35], [205, -65], [240, -105], [205, -145], [145, -175], [180, -215], [260, -235], [305, -210], [320, -180]]
export const MARKET_TRAIL = [[320, -180], [290, -230], [300, -285], [300, -330], [300, -365]]
export const WEST_TRAIL = [[0, 150], [-35, 150], [-75, 195], [-115, 230], [-160, 195], [-195, 145], [-235, 175], [-250, 250], [-205, 300], [-155, 340], [-115, 395], [-60, 445]]
export const TRAILS = [NORTH_TRAIL, MARKET_TRAIL, WEST_TRAIL]
// forest zones (baked trees) [x, z, w, d, fadeFromZ?]
export const FORESTS = [[0, -296, 500, 292], [-298, 4, 296, 420]]
export const POOL = { x: northStreamX(-36), z: -36, rx: 14, rz: 10 }

// ---------------------------------------------------------------- stations / skytrain
export const STATIONS = [
  { id: "C1", name: "Campus North", x: 150, z: 8, line: "C" }, { id: "C2", name: "Tech Interchange", x: 610, z: 150, line: "C" },
  { id: "C3", name: "Lake Gardens", x: 610, z: 450, line: "C" }, { id: "C4", name: "Riverfront", x: 420, z: 616, line: "C" },
  { id: "C5", name: "Home Terraces", x: 150, z: 616, line: "C" }, { id: "C6", name: "YUST Gate", x: 8, z: 270, line: "C" },
  { id: "M2", name: "Market South", x: 535, z: -425, line: "M" }, { id: "M3", name: "Market Halls", x: 535, z: -600, line: "M" },
]
export const CITY_LINE = [[8, 8], [610, 8], [610, 616], [8, 616]]
export const MARKET_LINE = [[610, 150], [610, -425], [535, -425], [535, -600]]

// ---------------------------------------------------------------- collisions (metres)
const roadSegDist = (x, z) => Math.min(...ROADS.map((r) => segDist(x, z, r.a, r.b) - r.w / 2))
const clearOfRoad = (x, z, m) => roadSegDist(x, z) > 2 + m
const allBuildingRects = () => ALLB()
const water = (x, z, m = 0) => {
  if (Math.hypot((x - LAKE.cx) / (LAKE.rx + 4 + m), (z - LAKE.cz) / (LAKE.rz + 4 + m)) < 1) return true
  if (x > -300 && x < 614 && z > riverBank(x) - 14 - m && z < riverBank(x) + riverWidth(x) + 4 + m) return true
  if (Math.abs(x - streamX(z)) < 4 + m && z > 0 && z < 316) return true
  for (const c of CHANNELS) if (polyDist(x, z, c.p) < c.w / 2 + 1.5 + m) return true
  return false
}
const nearPaved = (x, z, m) => PAVED.some((p) => inRect(x, z, p, m))
const nearBuilding = (x, z, m) => allBuildingRects().some((r) => inRect(x, z, r, m)) || inRect(x, z, TRAINING, m) || inRect(x, z, PLAZA, m) || OPEN_PLOTS.some((o) => inRect(x, z, o, m - 1))
const inForest = (x, z) => FORESTS.some((f) => inRect(x, z, f))

export function colliders() {
  const out = []
  for (const r of allBuildingRects()) out.push(r)
  for (const o of OPEN_PLOTS) if (o[4] === "court") out.push([o[0] + 6, o[1] + 6, 0.01, 0.01]), out.pop()
  // void NW
  for (const v of VOID) out.push(v)
  // campus stream (blocking) with gaps at the promenade bridges
  for (let z = 0; z < 316; z += 2) { if (PROM.some((p) => z + 1 > p - 3.5 && z < p + 3.5)) continue; out.push([streamX(z) - 1.4, z, 2.8, 2]) }
  // campus terrace walls with openings for stairs and ramps
  for (const ez of [80, 210]) {
    const gaps = [...CX.map((c) => [c - 4, c + 4]), ...CX.map((c) => [c + 25, c + 31])].sort((a, b) => a[0] - b[0])
    let x = 5
    for (const g of gaps) { if (g[0] > x) out.push([x, ez, g[0] - x, 2.1]); x = g[1] }
    if (x < 286) out.push([x, ez, 286 - x, 2.1])
  }
  // waterfront retaining wall at z=645 with three stairs
  { const stairs = [-30, 150, 520].map((s) => [s - 3.5, s + 3.5]); let x = -300; for (const g of stairs) { out.push([x, 645, g[0] - x, 2]); x = g[1] } out.push([x, 645, 614 - x, 2]) }
  // river body (4 m columns)
  for (let x = -300; x < 614; x += 4) out.push([x, riverBank(x) - 0.5, 4, riverWidth(x) + 1.5])
  out.push([-300, 810 - 0.01, 914, 0.01])
  // lake: ellipse rows
  for (let z = LAKE.cz - LAKE.rz; z < LAKE.cz + LAKE.rz; z += 3) { const dz = (z + 1.5 - LAKE.cz) / LAKE.rz, hw = LAKE.rx * Math.sqrt(Math.max(0, 1 - dz * dz)) - 1; if (hw > 0) out.push([LAKE.cx - hw, z, 2 * hw, 3]) }
  // north stream + pool
  for (let z = -300; z < -30; z += 2) { if (z > -46 && z < -26) continue; out.push([northStreamX(z) - 2.6, z, 5.2, 2]) }
  for (let z = POOL.z - POOL.rz; z < POOL.z + POOL.rz; z += 3) { const dz = (z + 1.5 - POOL.z) / POOL.rz, hw = POOL.rx * Math.sqrt(Math.max(0, 1 - dz * dz)) - 0.5; if (hw > 0) out.push([POOL.x - hw, z, 2 * hw, 3]) }
  // forests: 4 m cells, blocked except trails, merged into runs
  const cell = 4
  for (const f of FORESTS) {
    for (let z = f[1]; z < f[1] + f[3]; z += cell) {
      let run = null
      for (let x = f[0]; x <= f[0] + f[2]; x += cell) {
        const cx = x + cell / 2, cz = z + cell / 2
        let blocked = x < f[0] + f[2]
        if (blocked && f[0] < 0 && cz > 330 && Math.abs((cx * 7 + cz * 13) % 5) < (cz - 330) / 20) blocked = false   // ragged edge where the west forest thins out
        if (blocked && TRAILS.some((t) => polyDist(cx, cz, t) < 3.2)) blocked = false
        if (blocked && roadSegDist(cx, cz) < 3) blocked = false
        if (blocked && Math.abs(cx - northStreamX(cz)) < 7 && cz < 0) blocked = false     // stream bank handled above
        if (blocked && Math.hypot((cx - POOL.x) / 18, (cz - POOL.z) / 14) < 1) blocked = false
        if (blocked && cz > f[1] + f[3] - 6 && f[1] < 0) blocked = false                 // open edge next to the town
        if (blocked && cx > -8 && cx < 8 && f[0] < 0) blocked = false                    // gap between west forest and campus road
        if (blocked) { if (!run) run = x } else if (run !== null) { out.push([run, z, x - run, cell]); run = null }
      }
    }
  }
  // gardens / planters are walkable; sports court is walkable
  return out
}

// ---------------------------------------------------------------- trees + props
const r = rng(20261119)
const planting = [[5, 5, 285, 285, 11, 0.6], [314, 0, 300, 285, 18, 0.45], [5, 314, 280, 300, 17, 0.5], [314, 314, 300, 300, 16, 0.5], [0, -690, 610, 330, 22, 0.5], [-300, 500, 300, 114, 16, 0.7], [-300, 614, 914, 30, 16, 0.5], [0, 645, 614, 40, 14, 0.4], [500, -296, 114, 292, 14, 0.5]]
export const TREES = []
const treeOk = (x, z) => {
  if (!LAND.some((l) => inRect(x, z, l))) return false
  if (inForest(x, z) || water(x, z, 3) || nearBuilding(x, z, 5) || nearPaved(x, z, 2.5) || !clearOfRoad(x, z, 2.5)) return false
  if (x < -10 && z > 100 && z < 330) return false
  if (z > 640 && z < 668 && Math.abs(z - 654) < 12) return false
  return true
}
for (const [px, pz, pw, pd, sp, prob] of planting) for (let x = px + 6; x < px + pw; x += sp) for (let z = pz + 6; z < pz + pd; z += sp) {
  const tx = x + (r() - 0.5) * sp * 0.7, tz = z + (r() - 0.5) * sp * 0.7
  if (!treeOk(tx, tz) || r() > prob) continue
  TREES.push({ x: +tx.toFixed(1), z: +tz.toFixed(1), k: r() < 0.14 ? "palm" : "tree" + Math.floor(r() * 3) })
}
for (const [cx, cz, rad, n] of [[150, 152.5, 19.5, 10], [450, 150, 25, 10], [550, 548, 60, 12], [300, -495, 70, 10], [307, 302, 16, 8]]) for (let k = 0; k < n; k++) { const a = (k / n) * 6.283 + 0.3; TREES.push({ x: +(cx + Math.cos(a) * rad).toFixed(1), z: +(cz + Math.sin(a) * rad * 0.9).toFixed(1), k: "palm" }) }
TREES.sort((a, b) => a.z - b.z)

export const PROPS = []
const prop = (k, x, z, coll) => PROPS.push({ k, x: +x.toFixed(1), z: +z.toFixed(1), coll: coll || null })
// lamps along every road edge, both sides
for (const rd of ROADS) {
  const horiz = rd.a[1] === rd.b[1], len = horiz ? Math.abs(rd.b[0] - rd.a[0]) : Math.abs(rd.b[1] - rd.a[1])
  for (let t = 18; t < len - 10; t += 34) for (const s of [-1, 1]) {
    const off = s * (rd.w / 2 + 1.6)
    const x = horiz ? Math.min(rd.a[0], rd.b[0]) + t : rd.a[0] + off, z = horiz ? rd.a[1] + off : Math.min(rd.a[1], rd.b[1]) + t
    if (LAND.some((l) => inRect(x, z, l))) prop("lamp", x, z, [0.5, 0.5])
  }
}
for (const c of CX) for (const z of [30, 100, 180, 245]) { prop("lamp", c - 3.8, z, [0.5, 0.5]); prop("lamp", c + 3.8, z + 12, [0.5, 0.5]) }
for (const z of PROM) for (const x of [25, 100, 200, 270]) if (Math.abs(x - 65) > 6) prop("lamp", x, z - 3.9, [0.5, 0.5])
for (const [x, z] of [[130, 142], [170, 142], [130, 168], [170, 168], [100, 66], [200, 66], [100, 152], [200, 152], [100, 271], [200, 271], [420, 118], [480, 118], [420, 182], [480, 182], [440, 400], [500, 400], [250, 365], [100, 352], [400, 352], [250, -400], [300, -498]]) prop("bench", x, z, [1.8, 0.7])
for (const [x, z] of [[46, 85], [154, 85], [254, 85], [46, 205], [154, 205], [352, 70], [352, 160], [452, 70], [52, 352], [152, 452]]) prop("bin", x, z, [0.6, 0.6])
for (const [x, z] of [[40.5, 115], [41.8, 116], [363, 125], [364.3, 126], [250, 142], [200, -392], [201.3, -391]]) prop("vending", x, z, [1.1, 0.9])
for (const [x, z] of [[119, 63], [182, 63], [120, 148], [412, 92], [348, 250], [148, 440], [330, 356], [280, -384], [140, -420]]) prop("board", x, z, [2.4, 0.5])
for (const [x, z] of [[24, 144], [30, 144], [24, 196], [30, 196], [372, 134], [378, 134], [60, 355]]) prop("bikerack", x, z, [2.8, 0.8])
prop("statue", 150, 152, [4.8, 3.2]); prop("statue", 450, 150, [4.8, 3.2])
for (const [x, z] of [[151, 60], [453, 262], [150, 270], [300, -386], [345, 570]]) prop("signmap", x, z, [2.4, 0.5])
for (const [x, z] of [[224, 154], [262, 316 + 0], [395, 345], [300, -480], [255, -480], [345, -480], [500, -420], [150, -420]]) prop("kiosk", x, z, [3, 2])
for (const [x, z] of [[190, 438], [196, 438]]) prop("swing", x, z, [1.6, 0.8])
for (const [x, z] of [[525, 405], [545, 395]]) prop("bench", x, z, [1.8, 0.7])

// ---------------------------------------------------------------- doors, NPC graph, wildlife homes
const interiorTypeOf = (b) => b[1]
export const DOORS = [...BUILDINGS, ...HALLS.map((h) => [h[0], h[1], h[2], h[3], h[4], h[5], h[6], 1])].map((b) => ({ id: b[0], type: interiorTypeOf(b), label: b[2], x: b[3] + b[5] / 2, z: b[4] + b[6], r: [b[3] + b[5] / 2 - 2, b[4] + b[6] - 0.2, 4, 2.4] }))

// NPC walk graph: centre lines of long paved strips + sidewalks along roads
const segs = []
for (const p of PAVED) { if (Math.min(p[2], p[3]) > 8 || Math.max(p[2], p[3]) < 20) continue; if (p[2] >= p[3]) segs.push([[p[0], p[1] + p[3] / 2], [p[0] + p[2], p[1] + p[3] / 2]]); else segs.push([[p[0] + p[2] / 2, p[1]], [p[0] + p[2] / 2, p[1] + p[3]]]) }
for (const rd of ROADS) { const horiz = rd.a[1] === rd.b[1]; for (const s of [-1, 1]) { const o = s * (rd.w / 2 + 1); if (horiz) segs.push([[Math.min(rd.a[0], rd.b[0]), rd.a[1] + o], [Math.max(rd.a[0], rd.b[0]), rd.a[1] + o]]); else segs.push([[rd.a[0] + o, Math.min(rd.a[1], rd.b[1])], [rd.a[0] + o, Math.max(rd.a[1], rd.b[1])]]) } }
export const NAV_NODES = [], NAV_EDGES = []
{
  const key = (p) => p[0].toFixed(1) + "," + p[1].toFixed(1), idx = new Map()
  const node = (p) => { const k = key(p); if (!idx.has(k)) { idx.set(k, NAV_NODES.length); NAV_NODES.push([+p[0].toFixed(1), +p[1].toFixed(1)]) } return idx.get(k) }
  const H = segs.filter((s) => s[0][1] === s[1][1]), V = segs.filter((s) => s[0][0] === s[1][0])
  const pts = segs.map(() => [])
  segs.forEach((s, i) => { pts[i].push(s[0], s[1]) })
  H.forEach((h) => V.forEach((v) => { const x = v[0][0], z = h[0][1]; if (x >= h[0][0] - 0.01 && x <= h[1][0] + 0.01 && z >= v[0][1] - 0.01 && z <= v[1][1] + 0.01) { pts[segs.indexOf(h)].push([x, z]); pts[segs.indexOf(v)].push([x, z]) } }))
  segs.forEach((s, i) => {
    const horiz = s[0][1] === s[1][1], ps = pts[i].sort((a, b) => (horiz ? a[0] - b[0] : a[1] - b[1]))
    for (let k = 0; k < ps.length - 1; k++) { const a = node(ps[k]), b = node(ps[k + 1]); if (a !== b) NAV_EDGES.push([a, b]) }
  })
}
const wr = rng(77)
export const CAT_HOMES = [], BIRD_HOMES = []
const grassSpot = () => { for (let k = 0; k < 200; k++) { const l = LAND[Math.floor(wr() * 3) + (wr() < 0.15 ? 6 : 0)] || LAND[0]; const x = l[0] + wr() * l[2], z = l[1] + wr() * l[3]; if (!water(x, z, 4) && !nearPaved(x, z, 2) && !nearBuilding(x, z, 3) && clearOfRoad(x, z, 3) && !inForest(x, z)) return [+x.toFixed(0), +z.toFixed(0)] } return [150, 100] }
for (let i = 0; i < 18; i++) { const p = grassSpot(); CAT_HOMES.push([...p, i % 2 ? "cat" : "cat2"]) }
for (let i = 0; i < 26; i++) BIRD_HOMES.push(grassSpot())
CAT_HOMES.push([142, 160, "cat"], [38, 120, "cat2"], [232, 88, "cat"], [270, 225, "cat2"], [440, 130, "cat"], [120, 470, "cat2"])
BIRD_HOMES.push([100, 140], [190, 70], [60, 230], [240, 150], [150, 100], [430, 200], [120, 400])

// ---------------------------------------------------------------- interiors (metres; the back wall is the top 3 m)
const stud = (x0, z0, cols, rows, dx, dz) => { const o = []; for (let rr = 0; rr < rows; rr++) for (let c = 0; c < cols; c++) o.push(["student", x0 + c * dx, z0 + rr * dz, 2, 1]); return o }
export const INTERIORS = {
  classroom: { w: 16, d: 11, f: [["board", 4, 0.4, 8, 2.2], ["desk", 6, 3.6, 4, 1.2], ...stud(2.2, 5.6, 4, 3, 3.2, 1.7), ["shelf", 0.6, 3.4, 0.7, 3], ["plant", 14.4, 3.4, 0.9, 0.9], ["locker", 12, 0.6, 3.4, 1.8]] },
  dorm: { w: 12, d: 9, f: [["bed", 1, 3.4, 2.2, 3.2], ["bed", 9, 3.4, 2.2, 3.2], ["rug", 3.8, 5.4, 4.4, 2.6], ["desk", 4.6, 3.3, 3, 1.1], ["wardrobe", 0.8, 0.6, 2.4, 2.2], ["shelf", 8.8, 0.8, 2.4, 1], ["plant", 11, 7, 0.9, 0.9]] },
  cafe: { w: 15, d: 11, f: [["counter", 1, 3.4, 8, 1.4], ["kettle", 1.4, 3.1, 0.7, 0.7], ["menu", 2.5, 0.5, 6, 1.6], ...[[2, 7], [6, 6.4], [10, 7], [11.6, 4.2], [4, 9.2], [8.4, 9]].flatMap(([x, z]) => [["tea", x, z, 1.2, 1.2], ["stool", x - 0.9, z + 0.2, 0.55, 0.55], ["stool", x + 1.55, z + 0.2, 0.55, 0.55]]), ["vending", 13, 3.2, 1.1, 1.3]] },
  hangar: { w: 24, d: 14, f: [["toolwall", 1, 0.3, 22, 2.6], ["bench", 2, 3.6, 5, 1.4], ["bench", 17, 3.6, 5, 1.4], ["mech", 8.5, 4.6, 7, 5.6], ["crate", 1.4, 9.4, 1.6, 1.6], ["crate", 3.2, 9.8, 1.4, 1.4], ["crate", 20.6, 9.4, 1.6, 1.6], ["arm", 19, 7, 2.2, 2.2], ["console", 20, 11, 2.4, 1]] },
  workshop: { w: 16, d: 11, f: [["toolwall", 1, 0.3, 14, 2.6], ["bench", 2, 3.6, 5, 1.4], ["bench", 9, 3.6, 5, 1.4], ["arm", 12.5, 6.8, 2.2, 2.2], ["crate", 1.6, 8, 1.6, 1.6], ["console", 4, 7.6, 2.4, 1], ["mech", 7, 6.4, 3.6, 3]] },
  office: { w: 13, d: 10, f: [["shelf", 1, 0.6, 3.4, 1.2], ["shelf", 5, 0.6, 3.4, 1.2], ["holo", 9.4, 0.8, 2.6, 1.8], ["desk", 1.6, 4.2, 3, 1.4], ["desk", 6.2, 4.2, 3, 1.4], ["desk", 10, 4.8, 2.2, 1.4], ["plant", 0.9, 8, 0.9, 0.9], ["sofa", 5, 8, 3.2, 1.2]] },
  clinic: { w: 14, d: 10, f: [["counter", 1, 3.4, 5, 1.4], ["menu", 1.5, 0.5, 4, 1.6], ["bed", 8, 3.4, 2.2, 3.2], ["bed", 11, 3.4, 2.2, 3.2], ["sofa", 1, 7.2, 3.2, 1.2], ["sofa", 5, 7.2, 3.2, 1.2], ["holo", 8, 0.8, 3, 1.8], ["plant", 12.6, 8.2, 0.9, 0.9]] },
  apartment: { w: 14, d: 10, f: [["sofa", 1, 4.4, 3.2, 1.2], ["rug", 1, 6.2, 5, 3], ["tea", 2.4, 7.2, 1.2, 1.2], ["screen", 1.5, 0.4, 5, 2.2], ["counter", 8, 3.6, 5, 1.4], ["kettle", 8.4, 3.3, 0.7, 0.7], ["bed", 11.4, 6.2, 2.2, 3.2], ["plant", 7.2, 8.4, 0.9, 0.9], ["shelf", 8.6, 0.8, 4, 1]] },
  family: { w: 16, d: 11, f: [["counter", 1, 3.4, 6, 1.4], ["kettle", 1.4, 3.1, 0.7, 0.7], ["menu", 2, 0.5, 5, 1.6], ["tea", 3, 6.8, 1.2, 1.2], ["stool", 2.1, 7, 0.55, 0.55], ["stool", 4.55, 7, 0.55, 0.55], ["rug", 8, 6, 4.6, 3.4], ["sofa", 8.4, 4.4, 3.2, 1.2], ["bed", 13.4, 3.4, 2.2, 3.2], ["shelf", 12, 0.8, 3, 1], ["plant", 14.4, 8.4, 0.9, 0.9], ["tea", 6.4, 9.2, 1.2, 1.2]] },
  union: { w: 15, d: 11, f: [["screen", 5, 0.4, 5, 2.2], ["sofa", 1, 4.6, 3.2, 1.2], ["sofa", 1, 7, 3.2, 1.2], ["tea", 5, 5.4, 2, 1.6], ["sofa", 8.6, 4.6, 3.2, 1.2], ["tea", 8.2, 7.4, 2, 1.6], ["vending", 12.4, 3.4, 1.1, 1.3], ["plant", 13.2, 8.6, 0.9, 0.9], ["arcade", 12, 7, 1.4, 1.3]] },
  shop: { w: 12, d: 9, f: [["bookshelf", 1, 3.4, 3.4, 1.1], ["bookshelf", 5, 3.4, 3.4, 1.1], ["bookshelf", 1, 5.8, 3.4, 1.1], ["bookshelf", 5, 5.8, 3.4, 1.1], ["counter", 9, 4, 2.2, 3.2], ["plant", 10.6, 0.9, 0.9, 0.9], ["poster", 1.5, 0.4, 3, 2], ["poster", 6, 0.4, 3, 2]] },
  club: { w: 14, d: 10, f: [["arcade", 1, 3.2, 1.4, 1.3], ["arcade", 3, 3.2, 1.4, 1.3], ["arcade", 5, 3.2, 1.4, 1.3], ["tea", 8, 4.2, 2, 1.8], ["tea", 8, 7, 2, 1.8], ["sofa", 1, 7.6, 3.2, 1.2], ["screen", 8.4, 0.4, 4, 2.2], ["poster", 1, 0.5, 2.4, 2], ["poster", 4.2, 0.5, 2.4, 2], ["plant", 12.6, 8, 0.9, 0.9]] },
  sim: { w: 20, d: 14, f: [["screen", 2, 0.4, 7, 2.3], ["holo", 12, 0.6, 5, 2], ...[0, 1, 2, 3, 4].map((i) => ["pod", 1.5 + i * 3.6, 3.4, 2.6, 3]), ...stud(2, 9, 4, 1, 4, 1), ["desk", 14.6, 9.4, 3.4, 1.2], ["plant", 18, 12, 0.9, 0.9]] },
  warehouse: { w: 20, d: 12, f: [["toolwall", 1, 0.3, 18, 2.6], ...[0, 1, 2, 3].flatMap((i) => [["crate", 2 + i * 4.4, 4, 2, 2], ["crate", 2.4 + i * 4.4, 6.6, 1.6, 1.6]]), ["console", 15, 9, 2.4, 1], ["crate", 17.4, 4.4, 1.6, 1.6]] },
  market: { w: 24, d: 14, f: [["menu", 4, 0.4, 7, 2], ["menu", 13, 0.4, 7, 2], ...[0, 1, 2, 3, 4].flatMap((i) => [["stall", 1.6 + i * 4.4, 3.6, 3.4, 1.6]]), ...[0, 1, 2, 3, 4].flatMap((i) => [["stall", 1.6 + i * 4.4, 8, 3.4, 1.6]]), ["plant", 22.4, 11.6, 0.9, 0.9], ["plant", 0.8, 11.6, 0.9, 0.9]] },
}
for (const k in INTERIORS) INTERIORS[k].type = k

// named people inside buildings (id -> list). positions in room metres. `lines` are authored lore.
export const INTERIOR_NPCS = LORE.interiorNpcs
export const AMBIENT = LORE.ambient
export const NAMES = LORE.names

// chunk bookkeeping --------------------------------------------------------------
const landHit = (x, z, w, d) => LAND.some((l) => x < l[0] + l[2] && x + w > l[0] && z < l[1] + l[3] && z + d > l[1])
export const CHUNKS = []
for (let i = 0; i < Math.ceil(WM / CHUNK_M); i++) for (let j = 0; j < Math.ceil(HM / CHUNK_M); j++) {
  const x = -OX + i * CHUNK_M, z = -OY + j * CHUNK_M
  if (!landHit(x, z, CHUNK_M, CHUNK_M)) continue
  if (VOID.some((v) => x >= v[0] && x + CHUNK_M <= v[0] + v[2] && z >= v[1] && z + CHUNK_M <= v[1] + v[3])) continue
  const emis = ALLB().some((b) => x < b[0] + b[2] + 6 && x + CHUNK_M > b[0] - 6 && z < b[1] + b[3] + 6 && z + CHUNK_M > b[1] - 6) ||
    STATIONS.some((s) => x < s.x + 14 && x + CHUNK_M > s.x - 14 && z < s.z + 14 && z + CHUNK_M > s.z - 14) ||
    [QUAD, PLAZA].some((b) => x < b[0] + b[2] && x + CHUNK_M > b[0] && z < b[1] + b[3] && z + CHUNK_M > b[1])
  CHUNKS.push({ i, j, x, z, emis })
}
