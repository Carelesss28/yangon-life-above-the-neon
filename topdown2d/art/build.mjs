// node build.mjs [--data-only] [--only a,b]  -> renders the world with pxl into ../assets (.dat = raw PNG bytes) + game_data.dat
import * as D from "./world_data.mjs"
import fs from "node:fs"
import path from "node:path"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"

const here = path.dirname(fileURLToPath(import.meta.url))
const PXL = process.env.PXL || "C:/Users/khant/AppData/Local/Temp/claude/89caa1553c4f1689/7863643e-9fa8-49f9-b79b-6b3ea279c19c/scratchpad/claude-pxl/claude-pxl-main/bin/pxl.js"
const only = process.argv.includes("--only") ? process.argv[process.argv.indexOf("--only") + 1] : null
const outDir = path.join(here, "..", "assets")
fs.mkdirSync(outDir, { recursive: true })

// ---- interiors: colliders + free spots for the people who live there
const SOLID_SKIP = new Set(["rug", "board", "menu", "poster", "screen", "holo", "toolwall"])
const interiors = {}
for (const [k, R] of Object.entries(D.INTERIORS)) {
  const col = [[0, 0, R.w, 3]]
  for (const f of R.f) { const [kind, x, z, w, d] = f; if (SOLID_SKIP.has(kind)) continue; const low = kind === "student"; col.push([x, z + (low ? 0.4 : 0), w, d - (low ? 0.4 : 0)]) }
  const people = D.INTERIOR_NPCS.byType[k] || []
  const spots = []
  for (let z = 3.8; z < R.d - 1.8; z += 0.9) for (let x = 1.4; x < R.w - 1.4; x += 0.9) {
    if (col.some((q) => x > q[0] - 0.9 && x < q[0] + q[2] + 0.9 && z > q[1] - 1.0 && z < q[1] + q[3] + 0.7)) continue
    if (Math.abs(x - R.w / 2) < 1.8 && z > R.d - 3.2) continue      // keep the doorway clear
    spots.push([x, z, Math.hypot(x - R.w / 2, (z - R.d * 0.55) * 1.4)])
  }
  spots.sort((a, b) => a[2] - b[2])
  const npcs = []
  for (const p of people) { const s = spots.find((s) => npcs.every((n) => Math.hypot(n.x - s[0], n.z - s[1]) > 2.6)); if (s) npcs.push({ ...p, x: +s[0].toFixed(1), z: +s[1].toFixed(1) }) }
  interiors[k] = { w: R.w, d: R.d, colliders: col, exit: [R.w / 2 - 1.5, R.d - 0.9, 3, 1.4], spawn: [R.w / 2, R.d - 1.6], npcs }
}
const game = {
  u: D.U, ox: D.OX, oy: D.OY, wm: D.WM, hm: D.HM, chunkM: D.CHUNK_M,
  chunks: D.CHUNKS.map((c) => ({ i: c.i, j: c.j, emis: c.emis })), land: D.LAND,
  colliders: D.colliders(), doors: D.DOORS, trees: D.TREES, props: D.PROPS, interiors,
  carLoops: D.CAR_LOOPS, navNodes: D.NAV_NODES, navEdges: D.NAV_EDGES, catHomes: D.CAT_HOMES, birdHomes: D.BIRD_HOMES,
  stations: D.STATIONS, cityLine: D.CITY_LINE, marketLine: D.MARKET_LINE,
  ambient: D.AMBIENT, names: D.NAMES, start: [150, 169],
}
fs.writeFileSync(path.join(outDir, "game_data.dat"), JSON.stringify(game))
console.log("game_data:", game.colliders.length, "colliders,", game.trees.length, "trees,", game.props.length, "props,", game.navNodes.length, "nav nodes,", game.chunks.length, "chunks")
if (process.argv.includes("--data-only")) process.exit(0)

// ---- art
const DATA = { U: D.U, OX: D.OX, OY: D.OY, CHUNK_M: D.CHUNK_M, LAND: D.LAND, ROADS: D.ROADS, BUILDINGS: D.BUILDINGS, HALLS: D.HALLS, SHELTERS: D.SHELTERS,
  TRAINING: D.TRAINING, QUAD: D.QUAD, PLAZA: D.PLAZA, OPEN_PLOTS: D.OPEN_PLOTS, CX: D.CX, PROM: D.PROM, PAVED: D.PAVED, STREAM: D.STREAM,
  CHANNELS: D.CHANNELS, TRAILS: D.TRAILS, FORESTS: D.FORESTS, POOL: D.POOL, LAKE: D.LAKE, STATIONS: D.STATIONS, CITY_LINE: D.CITY_LINE,
  MARKET_LINE: D.MARKET_LINE, INTERIORS: D.INTERIORS, CHUNKS: D.CHUNKS }
const gen = path.join(here, "_gen.px.js")
fs.writeFileSync(gen, `const DATA = ${JSON.stringify(DATA)}\n` + fs.readFileSync(path.join(here, "world.art.js"), "utf8"))
const args = [PXL, "build", gen, "--out", path.join(here, "out"), "--no-preview"]
if (only) args.push("--only", only)
const r = spawnSync("node", ["--max-old-space-size=8192", ...args], { stdio: "inherit" })
if (r.status !== 0) process.exit(r.status)
const cp = (srcDir, dstDir, filter) => {
  if (!fs.existsSync(srcDir)) return
  fs.mkdirSync(dstDir, { recursive: true })
  for (const f of fs.readdirSync(srcDir)) if (f.endsWith(".png") && filter(f)) fs.copyFileSync(path.join(srcDir, f), path.join(dstDir, f.replace(".png", ".dat")))
}
cp(path.join(here, "out", "sprites"), path.join(outDir, "sprites"), () => true)
cp(path.join(here, "out", "scenes"), path.join(outDir, "chunks"), (f) => /^[be]_\d+_\d+\.png$/.test(f))
cp(path.join(here, "out", "scenes"), path.join(outDir, "scenes"), (f) => f.startsWith("int_"))
console.log("assets copied to", outDir)
