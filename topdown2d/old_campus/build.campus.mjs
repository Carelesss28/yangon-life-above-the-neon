// node build.mjs [--only name,name]  -> renders art with pxl, writes ../assets/*.png + ../assets/game_data.json
import * as D from "./campus_data.mjs"
import fs from "node:fs"
import path from "node:path"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"

const here = path.dirname(fileURLToPath(import.meta.url))
const PXL = process.env.PXL || "C:/Users/khant/AppData/Local/Temp/claude/89caa1553c4f1689/7863643e-9fa8-49f9-b79b-6b3ea279c19c/scratchpad/claude-pxl/claude-pxl-main/bin/pxl.js"
const only = process.argv.includes("--only") ? process.argv[process.argv.indexOf("--only") + 1] : null
const noart = process.argv.includes("--data-only")

const DATA = {
  U: D.U, OX: D.OX, OY: D.OY, SIZE: D.SIZE, BOUNDS: D.BOUNDS, BUILDINGS: D.BUILDINGS, TRAINING: D.TRAINING, QUAD: D.QUAD,
  CX: D.CX, PROM: D.PROM, PAVED: D.PAVED, ROADS: D.ROADS, STREAM: D.STREAM, INTERIORS: D.INTERIORS,
}
const outDir = path.join(here, "..", "assets")
fs.mkdirSync(outDir, { recursive: true })

// ---- game data for Godot
const interiors = {}
for (const [k, R] of Object.entries(D.INTERIORS)) {
  const col = [[0, 0, R.w, 3]]
  for (const f of R.f) {
    const [kind, x, z, w, d] = f
    if (["rug", "board", "menu", "poster", "screen", "holo", "toolwall"].includes(kind)) continue
    const lowOnly = ["student"].includes(kind)
    col.push([x, z + (lowOnly ? 0.4 : 0), w, d - (lowOnly ? 0.4 : 0)])
  }
  interiors[k] = { w: R.w, d: R.d, colliders: col, exit: [R.w / 2 - 1.5, R.d - 0.9, 3, 1.4], spawn: [R.w / 2, R.d - 1.6] }
}
const cols = D.colliders()
const game = {
  u: D.U, ox: D.OX, oy: D.OY, size: D.SIZE, bounds: D.BOUNDS,
  colliders: cols, doors: D.DOORS, trees: D.TREES, props: D.PROPS, interiors,
  carLoop: D.CAR_LOOP, npcEdges: D.EDGES, npcNodes: D.NPC_NODES,
  buildings: D.BUILDINGS.map((b) => ({ id: b[0], type: b[1], label: b[2], rect: [b[3], b[4], b[5], b[6]], floors: b[7] })),
  training: D.TRAINING, quad: D.QUAD, stream: D.STREAM,
}
fs.writeFileSync(path.join(outDir, "game_data.dat"), JSON.stringify(game))
console.log("game_data.json written:", cols.length, "colliders,", D.TREES.length, "trees,", D.PROPS.length, "props")
if (noart) process.exit(0)

// ---- art
const body = fs.readFileSync(path.join(here, "campus.art.js"), "utf8")
const gen = path.join(here, "_gen.px.js")
fs.writeFileSync(gen, `const DATA = ${JSON.stringify(DATA)}\n` + body)
const args = [PXL, "build", gen, "--out", path.join(here, "out"), "--no-preview"]
if (only) args.push("--only", only)
const r = spawnSync("node", args, { stdio: "inherit" })
if (r.status !== 0) process.exit(r.status)
// copy rendered pngs next to the game
for (const sub of ["sprites", "scenes"]) {
  const src = path.join(here, "out", sub)
  if (!fs.existsSync(src)) continue
  const dst = path.join(outDir, sub)
  fs.mkdirSync(dst, { recursive: true })
  for (const f of fs.readdirSync(src)) if (f.endsWith(".png")) fs.copyFileSync(path.join(src, f), path.join(dst, f.replace(".png", ".dat")))
}
console.log("assets copied to", outDir)
