"""Seaside town masterplan generator.

Writes campus_terrain/scripts/road_layout.gd (road graph) and
campus_terrain/scripts/reference_blocks.gd (building plots), plus a plan image.
North is z=0 (the sea); the town climbs south toward the hills.
Run:  python tools/seaside_plan.py
"""
import json
import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = os.path.join(ROOT, "campus_terrain")
OUT_IMG = os.path.join(GAME, "screenshots", "seaside_masterplan.png")

# ------------------------------------------------------------------ road grid
# The plan is drawn in "design" metres (the original 1420 x 1000 m town); every output x is multiplied
# by KX (1000 x 1000 m town, cozy dense rescale 2026-11-20). Road widths are world metres
# (10 / 8 / 6.5 m); margins convert them to design metres per axis. Object sizes are not scaled.
KX = 1000.0 / 1420.0
KZ = 1.0
MAIN = 10.0
LOCAL = 8.0
LANE = 6.5
HILL_ROAD = 6.5
PLOT_GAP = 3.0           # design metres between neighbouring plots (world ~2.1 m east-west, 3 m north-south)
HOME_X = [60, 240]                  # home district north-south streets
DOWN_X = [430, 520, 700, 820]       # downtown / market / campus edge
HARB_X = [1000, 1150]
E_W = {235: MAIN, 320: LOCAL, 400: LOCAL, 480: LOCAL, 560: MAIN, 680: LOCAL, 800: LOCAL, 920: LOCAL}

CANALS = [  # (x0,z0,x1,z1) centre lines, used for plot clearance only
    (150, 240, 150, 560), (150, 540, 610, 540), (610, 200, 610, 540), (1080, 200, 1080, 600),
]
POND = (1050, 760, 30, 22)          # campus pond ellipse (cx, cz, rx, rz)
RESERVOIR = (210, 700, 55, 40)


def node_y(x, z):
    if z <= 235:
        return 2.5
    if x <= 390:
        return round(4 + 6 * min(max((z - 300) / 240, 0), 1), 2)
    if z <= 480:
        return 4.0
    if z <= 560:
        return 5.0
    return 6.0


nodes = {}
edges = []
widths = {}


def node(x, z, y=None):
    key = "n_%d_%d" % (x, z)
    if key not in nodes:
        nodes[key] = (x, node_y(x, z) if y is None else y, z)
    return key


def edge(a, b, w):
    if a == b:
        return
    pair = [a, b]
    if pair in edges or [b, a] in edges:
        return
    edges.append(pair)
    widths[tuple(pair)] = w


def line_x(x, z_values, w):
    keys = [node(x, z) for z in z_values]
    for a, b in zip(keys, keys[1:]):
        edge(a, b, w)


def line_z(z, x_values, w):
    keys = [node(x, z) for x in x_values]
    for a, b in zip(keys, keys[1:]):
        edge(a, b, w)


# East-west streets; home-side lines get a ramp node at x=390 before downtown (x=430).
line_z(235, [60, 240, 430, 520, 700, 820, 1000, 1150], MAIN)
for z in (320, 400, 480):
    line_z(z, [60, 240, 390], LANE)
    line_z(z, [390, 430], LANE)
    line_z(z, [430, 520, 700, 820, 1000, 1150], LOCAL)
line_z(560, [60, 240, 390], MAIN)
line_z(560, [390, 430, 520, 620, 700, 820, 1000, 1150], MAIN)
for z in (680, 800):
    line_z(z, [430, 620, 820], LOCAL)
line_z(920, [430, 620, 820, 1150], LOCAL)
# North-south streets.
for x in HOME_X:
    line_x(x, [235, 320, 400, 480, 560], LANE if x == 60 else LOCAL)
line_x(430, [235, 320, 400, 480, 560, 680, 740, 800, 920], MAIN)
line_x(520, [235, 320, 400, 480, 560], LOCAL)
line_x(700, [235, 320, 400, 480, 560], LOCAL)
line_x(620, [560, 680, 800, 920], LOCAL)
line_x(820, [235, 320, 400, 480, 560, 680, 800, 920], MAIN)
line_x(1000, [235, 320, 400, 480, 560], LOCAL)
line_x(1150, [235, 320, 400, 480, 560, 920], LOCAL)
# Motor District (east of the harbour and campus): a ring road around the showrooms and test track,
# joined to the harbour street at z=560 and to the southern avenue at z=920.
line_z(560, [1150, 1220], LOCAL)
line_x(1220, [560, 630], LOCAL)
line_z(630, [1220, 1400], LOCAL)
line_x(1400, [630, 810], LOCAL)
line_z(810, [1220, 1400], LOCAL)
line_x(1220, [630, 810], LOCAL)
line_x(1220, [810, 920], LOCAL)
line_z(920, [1150, 1220], LOCAL)
# Winding hill road (graded into the slope by the terrain shoulder) around the reservoir.
hill = [("hill_gate", (430, 6.0, 740)), ("hill_climb", (378, 12.0, 770)), ("hill_dam", (300, 18.5, 790)),
        ("hill_reservoir", (225, 21.0, 800)), ("hill_ridge", (160, 25.0, 830)), ("hill_lookout", (100, 30.0, 880)),
        ("hill_west", (50, 24.0, 800)), ("hill_descent", (55, 16.0, 680)), ("hill_foot", (60, 10.0, 600))]
nodes["hill_gate"] = None  # placeholder, replaced below
del nodes["hill_gate"]
gate = node(430, 740)
named = {"hill_gate": gate}
for name, p in hill[1:]:
    nodes[name] = (p[0], p[1], p[2])
    named[name] = name
chain = [named[n] for n, _ in hill] + [node(60, 560)]
for a, b in zip(chain, chain[1:]):
    edge(a, b, HILL_ROAD)
MOUNTAIN = set(n for n, _ in hill[1:])

# ------------------------------------------------------------------ blocks and plots
xs_all = sorted(set(HOME_X + [390] + DOWN_X + HARB_X))


def half_width_at_x(x):
    return {60: LANE, 240: LOCAL, 430: MAIN, 520: LOCAL, 700: LOCAL, 820: MAIN, 1000: LOCAL, 1150: LOCAL, 390: 0, 620: LOCAL}.get(x, LOCAL) / 2 / KX


def half_width_at_z(z):
    return E_W.get(z, LOCAL) / 2 / KZ


def canal_hits(rect, clearance=6.0):
    x0, z0, x1, z1 = rect
    for cx0, cz0, cx1, cz1 in CANALS:
        if cx0 == cx1:  # north-south canal
            if x0 - clearance < cx0 < x1 + clearance and z1 > min(cz0, cz1) and z0 < max(cz0, cz1):
                return ("x", cx0)
        else:
            if z0 - clearance < cz0 < z1 + clearance and x1 > min(cx0, cx1) and x0 < max(cx0, cx1):
                return ("z", cz0)
    return None


def split_canal(rect):
    hit = canal_hits(rect)
    if not hit:
        return [rect]
    x0, z0, x1, z1 = rect
    axis, c = hit
    parts = []
    if axis == "x":
        parts = [(x0, z0, c - 6.5 / KX, z1), (c + 6.5 / KX, z0, x1, z1)]
    else:
        parts = [(x0, z0, x1, c - 6.5 / KZ), (x0, c + 6.5 / KZ, x1, z1)]
    out = []
    for p in parts:
        if p[2] - p[0] > 18 and p[3] - p[1] > 18:
            out.extend(split_canal(p))
    return out


def subdivide(rect, target_w, target_d, gap=PLOT_GAP):
    x0, z0, x1, z1 = rect
    w, d = x1 - x0, z1 - z0
    nx = max(1, round(w / target_w))
    nz = max(1, round(d / target_d))
    pw = (w - gap * (nx - 1)) / nx
    pd = (d - gap * (nz - 1)) / nz
    plots = []
    for i in range(nx):
        for j in range(nz):
            px = x0 + i * (pw + gap)
            pz = z0 + j * (pd + gap)
            plots.append((px, pz, px + pw, pz + pd))
    return plots


programs = {
    "downtown": [
        ("CITY HALL / CIVIC DEFENCE", 6), ("CENTRAL HOSPITAL / CLINIC", 6), ("PUBLIC LIBRARY / BOOKSHOP", 3),
        ("POLICE STATION", 3), ("FIRE STATION", 2), ("SEAVIEW HOTEL TOWER", 10), ("NEON ARCADE", 3),
        ("ELECTRONICS / REPAIR", 2), ("DATA CENTRE", 4), ("OFFICE TOWER", 9), ("DEPARTMENT STORE / SHOPS", 4),
        ("CINEMA / KARAOKE", 3), ("TECH APARTMENTS", 7), ("TEA HOUSE", 1), ("CONVENIENCE SHOP", 1),
        ("POST OFFICE", 2), ("MECHA PARTS SHOP", 2), ("MAKER STUDIOS", 3), ("NOODLE / FOOD COURT", 2),
        ("DESIGN STUDIOS", 4), ("PHARMACY / SHOPS", 2), ("TOWER APARTMENTS", 8), ("BANK / OFFICES", 5),
        ("CAPSULE HOSTEL", 5), ("NOODLE SHOP", 1), ("SIM ARENA / ARCADE", 2),
    ],
    "home": [
        ("FAMILY HOME / ROOFTOP CAFE", 5), ("TEA / MOHINGA SHOP", 1), ("NEIGHBOURHOOD GROCERY", 1),
        ("GARDEN APARTMENTS", 4), ("LAUNDRY / LOCAL SHOPS", 2), ("TERRACE APARTMENTS", 4), ("COMMUNITY CENTRE / CAFE", 2),
        ("PRIMARY SCHOOL / CLASSROOMS", 2), ("NEIGHBOURHOOD CLINIC", 2), ("COURTYARD APARTMENTS", 3),
        ("BAKERY", 1), ("TAILOR / LOCAL SHOPS", 2), ("HILLSIDE APARTMENTS", 5), ("CANAL APARTMENTS", 4),
        ("CORNER SHOP", 1), ("STREET FOOD", 1), ("SHOPHOUSE APARTMENTS", 3),
    ],
    "harbour": [
        ("FISH MARKET / FOOD", 1), ("HARBOUR WAREHOUSE / DELIVERY", 2), ("HARBOUR OFFICE", 4), ("SEAFOOD RESTAURANTS / FOOD", 2),
        ("SHIPYARD / ROBOT WORKSHOP", 2), ("SAILORS HOSTEL / APARTMENTS", 5), ("COLD STORAGE / WHOLESALE", 2),
        ("HARBOUR WAREHOUSE B / DELIVERY", 2), ("HARBOUR TEA SHOP", 1), ("DOCKSIDE APARTMENTS", 6), ("CHANDLERY / SHOPS", 2),
        ("CUSTOMS / OFFICES", 3), ("MARINE REPAIR", 2), ("SEAFRONT APARTMENTS", 7),
    ],
    "market": [
        ("NIGHT MARKET ARCADE", 2), ("WHOLESALE / COLD STORAGE", 2), ("BUS DEPOT / DELIVERY", 1), ("MARKET APARTMENTS", 5),
        ("MARKET TEA HOUSE", 1), ("SPICE / LOCAL SHOPS", 2), ("METRO DEPOT / DELIVERY", 1), ("MARKET CLINIC", 2),
    ],
}
HALLS = [("PRODUCE / EVERYDAY MARKET", 5.8, 5.4), ("CLOTHING / CRAFTS", 6.6, 7.2), ("TEXTILES / DESIGN MARKET", 5.8, 5.0),
         ("FOOD QUARTER", 5.4, 5.5), ("TECH / ROBOT PARTS", 6.0, 5.6)]

plots = {"HOMES": [], "TECH": [], "LAKE": [], "MARKET": [], "CAMPUS": [], "HALLS": []}
parks = []
shoprows = []   # (rect, facing +1 south / -1 north, district)
ROW = 12.0      # shophouse strip depth


def carve(part, district):
    """Reserve shophouse strips along a block part's street edges; return the remaining core."""
    x0, z0, x1, z1 = part
    if x1 - x0 < 18:
        return part
    depth = z1 - z0
    if depth >= ROW * 2 + 50:
        shoprows.append(((x0, z1 - ROW, x1, z1), 1, district))
        shoprows.append(((x0, z0, x1, z0 + ROW), -1, district))
        return (x0, z0 + ROW + 6, x1, z1 - ROW - 6)
    if depth >= ROW + 22:
        shoprows.append(((x0, z1 - ROW, x1, z1), 1, district))
        return (x0, z0, x1, z1 - ROW - 6)
    shoprows.append(((x0, z1 - min(ROW, depth), x1, z1), 1, district))
    return None

used = {k: 0 for k in programs}


def take(district):
    lst = programs[district]
    i = used[district]
    used[district] += 1
    if i < len(lst):
        return lst[i]
    base = {"home": ("GARDEN APARTMENTS", 4), "downtown": ("TECH APARTMENTS", 6), "harbour": ("DOCKSIDE APARTMENTS", 5),
            "market": ("MARKET APARTMENTS", 4)}[district]
    return (base[0] if i % 3 else base[0].replace("APARTMENTS", "SHOPS") , base[1] if i % 3 else 2)


def block_list(xs, zs):
    for i in range(len(xs) - 1):
        for j in range(len(zs) - 1):
            yield xs[i], zs[j], xs[i + 1], zs[j + 1]


def inner(x0, z0, x1, z1, margin=4.5):
    # Pavement of about 4.5 world metres between kerb and building front.
    return (x0 + half_width_at_x(x0) + margin / KX, z0 + half_width_at_z(z0) + margin / KZ,
            x1 - half_width_at_x(x1) - margin / KX, z1 - half_width_at_z(z1) - margin / KZ)


# Home terraces (x 60..430, z 235..560).
for x0, z0, x1, z1 in block_list([60, 240, 430], [235, 320, 400, 480, 560]):
    r = inner(x0, z0, x1, z1)
    if x1 == 430:
        r = (r[0], r[1], 392 - 6, r[3])
    if (x0, z0) == (60, 480):
        parks.append(("HILLSIDE BOTANICAL GARDEN", r))
        continue
    for part in split_canal(r):
        part = carve(part, "home")
        if part is None or part[3] - part[1] < 18:
            continue
        for p in subdivide(part, 48, 70):
            if p[2] - p[0] < 20 or p[3] - p[1] < 18:
                continue
            title, floors = take("home")
            plots["HOMES"].append((p, title, floors))

# Downtown (x 430..820, z 235..560); central park block and the canal park strip.
for x0, z0, x1, z1 in block_list([430, 520, 700, 820], [235, 320, 400, 480, 560]):
    r = inner(x0, z0, x1, z1)
    if (x0, z0) == (430, 400):
        parks.append(("CENTRAL PARK", r))
        continue
    for part in split_canal(r):
        part = carve(part, "downtown")
        if part is None or part[3] - part[1] < 18:
            continue
        for p in subdivide(part, 55, 70):
            if p[2] - p[0] < 22 or p[3] - p[1] < 20:
                continue
            title, floors = take("downtown")
            plots["TECH"].append((p, title, floors))

# Harbour district (x 820..1150, z 235..560).
for x0, z0, x1, z1 in block_list([820, 1000, 1150], [235, 320, 400, 480, 560]):
    r = inner(x0, z0, x1, z1)
    for part in split_canal(r):
        part = carve(part, "harbour")
        if part is None or part[3] - part[1] < 18:
            continue
        for p in subdivide(part, 60, 70):
            if p[2] - p[0] < 22 or p[3] - p[1] < 20:
                continue
            title, floors = take("harbour")
            plots["LAKE"].append((p, title, floors))

# Market district (x 430..820, z 560..920): halls in the first two rows, shops behind.
hall_index = 0
for x0, z0, x1, z1 in block_list([430, 620, 820], [560, 680, 800, 920]):
    r = inner(x0, z0, x1, z1)
    if (z0 in (560, 680) or (z0, x0) == (800, 430)) and hall_index < len(HALLS):
        w = r[2] - r[0]
        if hall_index < len(HALLS):
            title, spring, rise = HALLS[hall_index]
            plots["HALLS"].append(((r[0], r[1], r[0] + w * 0.62, r[3]), title, spring, rise))
            hall_index += 1
            side = (r[0] + w * 0.62 + 8, r[1], r[2], r[3])
            for p in subdivide(side, 60, 45):
                title, floors = take("market")
                plots["MARKET"].append((p, title, floors))
        continue
    core = carve(r, "market")
    if core is None or core[3] - core[1] < 18:
        continue
    for p in subdivide(core, 55, 40):
        title, floors = take("market")
        plots["MARKET"].append((p, title, floors))
# Hall 5 sits in the last market block.
if hall_index < len(HALLS):
    pass

# YUST campus (x 820..1150, z 560..920): hand-planned, south-facing, a central quad.
C0X, C0Z = 836, 576
campus = [
    ((840, 584, 940, 640), "YUST ADMIN / MAIN GATE", 3),
    ((955, 584, 1075, 640), "PILOT SCHOOL", 4),
    ((1090, 584, 1140, 650), "CLASSROOMS A", 3),
    ((840, 655, 905, 735), "PUBLIC LIBRARY / BOOKSHOP YUST", 3),
    ((840, 750, 905, 815), "CLASSROOMS B", 3),
    ((852, 878, 878, 900), "YUST RESEARCH TOWER", 10),
    ((1090, 665, 1140, 720), "SIMULATOR CENTRE / ARCADE", 2),
    ((945, 830, 1010, 905), "STUDENT UNION / CAFE", 2),
    ((1025, 830, 1080, 905), "FOOD & COMMONS", 2),
    ((1095, 740, 1140, 800), "DORM A", 5),
    ((1095, 815, 1140, 860), "DORM B", 5),
    ((1095, 870, 1140, 912), "STUDENT CLUBS", 2),
]
for p, title, floors in campus:
    plots["CAMPUS"].append((p, title, floors))
LANDMARKS = {
    "launch_bay": (925, 735, 1010, 765),     # between the central quad and training field
    "engineering_hangar": (1015, 770, 1080, 815),
    "training_ground": (925, 770, 1005, 815),
    "motor_district": (1232, 642, 1388, 798),
}

# ------------------------------------------------------------------ skyline towers
# Mixed across every district: the largest ordinary plots become ~60 m towers, kept apart so the
# skyline reads as many peaks rather than one wall. Important civic/home plots never convert.
KEEP = ("FAMILY", "CITY HALL", "HOSPITAL", "LIBRARY", "POLICE", "FIRE", "TEA", "GROCERY", "SCHOOL", "CLINIC",
        "FISH MARKET", "COMMUNITY", "POST", "BANK", "CINEMA", "ARCADE", "WAREHOUSE", "COLD STORAGE", "DEPOT", "SHIPYARD")
TOWER_NAMES = {
    "TECH": ["NEON TOWER / OFFICES", "SKYLINE HOTEL TOWER", "DATA TOWER", "MEDIA TOWER", "TOWER APARTMENTS", "SKY TOWER / OFFICES", "TOWER APARTMENTS B"],
    "LAKE": ["HARBOUR TOWER", "SEAVIEW TOWER APARTMENTS", "SHIPPING TOWER / OFFICES", "MARINA TOWER"],
    "HOMES": ["TERRACE TOWER APARTMENTS", "CANAL TOWER APARTMENTS", "HILLVIEW TOWER APARTMENTS"],
    "MARKET": ["TRADE TOWER / OFFICES", "MARKET TOWER APARTMENTS"],
}
towers = [(885, 867)]  # campus research tower centre
import random
random.seed(20261120)
for key, names in TOWER_NAMES.items():
    candidates = []
    for i, (p, t, f) in enumerate(plots[key]):
        if any(k in t for k in KEEP):
            continue
        area = (p[2] - p[0]) * (p[3] - p[1])
        if (p[2] - p[0]) < 30 or (p[3] - p[1]) < 30:
            continue
        candidates.append((area + random.random() * 400, i))
    candidates.sort(reverse=True)
    picked = 0
    for _, i in candidates:
        if picked >= len(names):
            break
        p, t, f = plots[key][i]
        c = ((p[0] + p[2]) / 2, (p[1] + p[3]) / 2)
        if any(math.hypot(c[0] - o[0], c[1] - o[1]) < 120 for o in towers):
            continue
        plots[key][i] = (p, names[picked], random.randint(6, 10))
        towers.append(c)
        picked += 1
# Cozy scale: ordinary buildings 1-4 floors; only the landmark towers (about 10 in all) go higher.
LANDMARK_TOWERS = 10
kept = 1   # the campus research tower
for key in ("TECH", "LAKE", "HOMES", "MARKET", "CAMPUS"):
    out = []
    for p, t, f in plots[key]:
        if t == "YUST RESEARCH TOWER":
            out.append((p, t, 10))
        elif "TOWER" in t and kept < LANDMARK_TOWERS and f > 4:
            kept += 1
            out.append((p, t, max(6, min(f, 10))))
        else:
            out.append((p, t.replace(" TOWER", "").replace("TOWER ", "") if "TOWER" in t else t, min(f, 4)))
    plots[key] = out
print("landmark towers", kept)

# ------------------------------------------------------------------ compact footprints
# Oversized plots shrink to a sensible footprint; the freed land becomes a separate functional
# cyberpunk building (its own entrance, interior and street front). Towers, halls and campus stay.
CYBER = ["CHARGING HUB / SHOP", "DRONE PORT / DELIVERY", "VR NET CAFE", "CYBERNETICS CLINIC", "ROBOT REPAIR WORKSHOP",
         "CAPSULE HOTEL APARTMENTS", "BATTERY SWAP / SHOP", "HOLO CINEMA", "MECHA GARAGE / REPAIR", "DATA CAFE",
         "SIM ARENA / ARCADE", "AUGMENT SHOP", "VENDING HALL / SHOP", "NOODLE BAR / FOOD", "SYNTH MUSIC STUDIOS"]
SMALL = ("TEA", "GROCERY", "BAKERY", "STREET FOOD", "NOODLE", "CONVENIENCE", "CORNER", "LAUNDRY", "TAILOR",
         "PHARMACY", "POST", "SPICE", "CHANDLERY", "MARKET SHOPS", "DOCKSIDE SHOPS", "LOCAL SHOPS", "CLINIC", "MECHA PARTS")


def footprint(t):
    if "TOWER" in t:
        return 18.0 / KX, 18.0          # slim landmark tower, about 18 x 18 m
    if any(k in t for k in SMALL):
        return 24.0, 20.0
    return 36.0, 28.0


cyber_i = 0
split_count = 0
for key in ["TECH", "HOMES", "LAKE", "MARKET"]:
    out = []
    for p, t, f in plots[key]:
        x0, z0, x1, z1 = p
        if "FAMILY" in t:
            out.append((p, t, f))
            continue
        fw, fd = footprint(t)
        z0 = max(z0, z1 - fd)                     # shallower, kept on the street front
        out.append(((x0, z0, min(x1, x0 + fw), z1), t, f))
        # Fill the freed frontage with cyberpunk buildings, each with its own street door.
        x = x0 + fw + PLOT_GAP
        while x1 - x >= 18.0:
            w = min(26.0, x1 - x)
            if x1 - (x + w) < 18.0:
                w = x1 - x
            out.append(((x, z1 - 22.0, x + w, z1), CYBER[cyber_i % len(CYBER)], [2, 3, 4, 3][cyber_i % 4]))
            cyber_i += 1
            split_count += 1
            x += w + PLOT_GAP
    plots[key] = out
# Market halls: compact square halls; the rest of each hall block becomes a cyber building.
halls2 = []
for p, t, sp, ri in plots["HALLS"]:
    x0, z0, x1, z1 = p
    size = min(70.0, x1 - x0, z1 - z0)
    halls2.append(((x0, z1 - size, x0 + size, z1), t, sp, ri))
    if x1 - (x0 + size + PLOT_GAP) >= 18:
        plots["MARKET"].append(((x0 + size + PLOT_GAP, z1 - 24, x1, z1), CYBER[cyber_i % len(CYBER)], 3))
        cyber_i += 1
        split_count += 1
plots["HALLS"] = halls2
# Campus: admin and pilot school no longer sprawl across the whole frontage.
plots["CAMPUS"] = [((p[0], p[1], p[0] + min(p[2] - p[0], 70.0), p[1] + min(p[3] - p[1], 44.0)), t, f) if t in ("YUST ADMIN / MAIN GATE", "PILOT SCHOOL") else (p, t, f)
                   for p, t, f in plots["CAMPUS"]]
print("compacted plots, new cyberpunk buildings:", split_count)

# ------------------------------------------------------------------ outputs
def fmt(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


def write_roads():
    lines = ["extends RefCounted", "## GENERATED by tools/seaside_plan.py: seaside town road graph. Edit the generator, not this file.",
             "## North (z=0) is the sea; every vehicle-road endpoint is a shared graph vertex.", "const NODES={"]
    items = []
    for k, (x, y, z) in nodes.items():
        items.append(' "%s":Vector3(%s,%s,%s)' % (k, fmt(x * KX), fmt(y), fmt(z * KZ)))
    lines.append(",\n".join(items))
    lines.append("}")
    lines.append("const EDGES=[")
    lines.append(",\n".join(' ["%s","%s"]' % (a, b) for a, b in edges))
    lines.append("]")
    lines.append("const WIDTHS={")
    lines.append(",\n".join(' "%s|%s":%s' % (a, b, fmt(w)) for (a, b), w in widths.items()))
    lines.append("}")
    lines.append("const MOUNTAIN_NODES=%s" % json.dumps(sorted(MOUNTAIN)))
    with open(os.path.join(ROOT, "tools", "road_layout_template.txt"), encoding="utf-8") as f:
        lines.append(f.read())
    with open(os.path.join(GAME, "scripts", "road_layout.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


def rect_gd(p):
    return "Rect2(%s,%s,%s,%s)" % (fmt(p[0] * KX), fmt(p[1] * KZ), fmt((p[2] - p[0]) * KX), fmt((p[3] - p[1]) * KZ))


def write_blocks():
    out = ["extends RefCounted", "## GENERATED by tools/seaside_plan.py: building plots for the seaside town.",
           "## Front doors face south (+z) toward the street or plaza; plots are building footprints."]
    for key in ["CAMPUS", "TECH", "HOMES", "LAKE", "MARKET"]:
        out.append("const %s = [" % key)
        out.append(",\n".join(' [%s,"%s",%d]' % (rect_gd(p), t, f) for p, t, f in plots[key]))
        out.append("]")
    out.append("const HALLS = [")
    out.append(",\n".join(' [%s,"%s",%s,%s]' % (rect_gd(p), t, fmt(s), fmt(r)) for p, t, s, r in plots["HALLS"]))
    out.append("]")
    out.append("const PARKS = [")
    out.append(",\n".join(' ["%s",%s]' % (t, rect_gd(r)) for t, r in parks))
    out.append("]")
    out.append("const SHOPROWS = [")
    out.append(",\n".join(' [%s,%d,"%s"]' % (rect_gd(r), f, d) for r, f, d in shoprows))
    out.append("]")
    out.append("const LANDMARKS = {")
    out.append(",\n".join(' "%s":%s' % (k, rect_gd(v)) for k, v in LANDMARKS.items()))
    out.append("}")
    with open(os.path.join(GAME, "scripts", "reference_blocks.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")


def check():
    problems = []
    every = [(p, t) for k in ["CAMPUS", "TECH", "HOMES", "LAKE", "MARKET"] for p, t, _ in plots[k]]
    every += [(p, t) for p, t, _, _ in plots["HALLS"]]
    every += [(v, k) for k, v in LANDMARKS.items()]
    every += [(r, "SHOPROW") for r, _, _ in shoprows]
    for a, b in edges:
        ax, _, az = nodes[a]
        bx, _, bz = nodes[b]
        w = widths[(a, b)] / 2 + 2.0
        for p, t in every:
            # Distance from road segment to rectangle (sampled).
            for s in range(0, 41):
                u = s / 40
                x = ax + (bx - ax) * u
                z = az + (bz - az) * u
                dx = max(p[0] - x, 0, x - p[2])
                dz = max(p[1] - z, 0, z - p[3])
                if math.hypot(dx * KX, dz * KZ) < w:
                    problems.append("road %s-%s hits %s" % (a, b, t))
                    break
    for p, t in every:
        if canal_hits(p, 4.0):
            problems.append("canal hits %s" % t)
    for i, (p, t) in enumerate(every):
        for q, u in every[i + 1:]:
            if p[0] < q[2] and q[0] < p[2] and p[1] < q[3] and q[1] < p[3]:
                problems.append("overlap %s / %s" % (t, u))
    return problems


def draw():
    scale = 0.8
    img = Image.new("RGB", (int(1420 * scale), int(1000 * scale)), (196, 214, 170))
    d = ImageDraw.Draw(img)
    for x in range(0, 1420, 4):
        shore = 185 + 14 * math.sin(x * 0.009) + 8 * math.sin(x * 0.023 + 1)
        d.rectangle([x * scale, 0, (x + 4) * scale, shore * scale], fill=(92, 168, 196))
        d.rectangle([x * scale, (shore - 30) * scale, (x + 4) * scale, shore * scale], fill=(230, 214, 160))
    d.rectangle([0, 600 * scale, 400 * scale, 1000 * scale], fill=(150, 175, 120))
    d.ellipse([(210 - 55) * scale, (700 - 40) * scale, (210 + 55) * scale, (700 + 40) * scale], fill=(92, 168, 196))
    d.ellipse([(1050 - 30) * scale, (760 - 22) * scale, (1050 + 30) * scale, (760 + 22) * scale], fill=(92, 168, 196))
    for _, r in parks:
        d.rectangle([r[0] * scale, r[1] * scale, r[2] * scale, r[3] * scale], fill=(120, 190, 110))
    for x0, z0, x1, z1 in CANALS:
        d.line([x0 * scale, z0 * scale, x1 * scale, z1 * scale], fill=(60, 140, 200), width=4)
    for a, b in edges:
        ax, _, az = nodes[a]
        bx, _, bz = nodes[b]
        d.line([ax * scale, az * scale, bx * scale, bz * scale], fill=(70, 70, 80), width=max(2, int(widths[(a, b)] * scale)))
    colours = {"CAMPUS": (150, 110, 200), "TECH": (230, 120, 90), "HOMES": (240, 190, 120), "LAKE": (110, 150, 200), "MARKET": (220, 170, 70)}
    for key, col in colours.items():
        for p, t, f in plots[key]:
            d.rectangle([p[0] * scale, p[1] * scale, p[2] * scale, p[3] * scale], fill=col, outline=(40, 40, 40))
    for r, f, dist in shoprows:
        d.rectangle([r[0] * scale, r[1] * scale, r[2] * scale, r[3] * scale], fill=(250, 120, 160), outline=(40, 40, 40))
    for p, t, s, r in plots["HALLS"]:
        d.rectangle([p[0] * scale, p[1] * scale, p[2] * scale, p[3] * scale], fill=(200, 80, 80), outline=(40, 40, 40))
    for k, v in LANDMARKS.items():
        d.rectangle([v[0] * scale, v[1] * scale, v[2] * scale, v[3] * scale], fill=(90, 60, 140), outline=(255, 220, 0))
    os.makedirs(os.path.dirname(OUT_IMG), exist_ok=True)
    img.save(OUT_IMG)


if __name__ == "__main__":
    problems = check()
    write_roads()
    write_blocks()
    draw()
    counts = {k: len(v) for k, v in plots.items()}
    print("nodes", len(nodes), "edges", len(edges), "plots", counts, "parks", len(parks), "shoprows", len(shoprows))
    print("problems", len(problems), "towers", len(towers))
    for p in problems[:30]:
        print("  ", p)
