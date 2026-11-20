"""Migrate the remaining legacy catalogue while preserving current 3D decisions."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'BuildingList.md'
s=p.read_text(encoding='utf-8-sig')
if 'Dimension migration:' in s:
    raise RuntimeError('Catalogue already migrated; do not convert dimensions twice')
s='\n'.join(re.sub(r'\b(\d+) x (\d+)\b',lambda m:f'{int(m[1])*2} x {int(m[2])*2}',line) if line.startswith('|') else line for line in s.splitlines())+'\n'
headers=[]
rows=[]
aliases={'main_gate':'yust_gate','dept_silt':'dept_alien_studies','bus_stop':'transit_stop'}
active_p0={'dept_pilot','yust_gate','tea_shop','convenience_store','transit_stop'}
for line in s.splitlines():
    if line.startswith('| Name |'):
        headers=[x.strip() for x in line.strip('|').split('|')]
    if line.startswith('|') and headers and not re.match(r'^\|[- :|]+$',line):
        cells=[x.strip() for x in line.strip('|').split('|')]
        old=cells[0]
        name=aliases.get(old,old)
        cells[0]=name
        if len(cells)==len(headers) and old!='Name':
            if 'Priority' in headers:
                j=headers.index('Priority')
                if cells[j]=='**P0**' and name not in active_p0:cells[j]='P1'
            if name=='tea_shop':cells[headers.index('Footprint')]='10 x 7'
            if name=='transit_stop':
                cells[headers.index('Footprint')]='12 x 4'
                cells[-1]='Bus or tram stop with holo timetable; canonical first-district model (legacy name: bus_stop)'
            if name=='yust_gate':cells[-1]='Modern steel-and-glass gateway, holo crest, guard booth and ID scanner; canonical model for the former main_gate entry'
            if name=='residential_college':
                cells[headers.index('Walk-in')]='Yes (shared dorm room, common room)'
                cells[-1]='Later student housing around a green courtyard; not the player starting home. Balconies, light strips and holo crest'
            if name=='player_flat':cells[-1]='Later owned apartment; an intermediate rental is proposed. The player starts at apartment_cafe'
            if name=='apartment_block':cells[-1]='Generic modern walk-up with balconies, key-on-string clips and AC units; apartment_cafe is the starting family building'
            if name=='dept_alien_studies':
                cells[headers.index('Department')]='**Alien Studies Institute** (proposed)'
                cells[-1]='Optional later research/story location about alien incursions; replaces the retired Silt-specific proposal'
            if name=='central_quad':cells[-1]='Expanded campus lawns, paths, trees, statue and benches; the first district needs only an entrance plaza'
            if name=='training_ground':cells[-1]='Later campus outdoor course; the first mecha prototype uses a contained training arena'
            if name=='mech_hangar':
                cells[headers.index('Storeys')]='1 tall hall (~15 m)'
                cells[-1]='Later steel-truss training hangar, composite panels, bay doors and gantries; provisional clear height for an 8-10 m Frame'
            line='| '+' | '.join(cells)+' |'
    rows.append(line)
s='\n'.join(rows)+'\n'
start=s.index('## 0. The Academy:')
intro='''# YANGON: Building and Location Catalogue (3D)

Long-term locations, grouped by what people use them for. The full city's extent remains open; the earlier 2 km x 2 km target is not a first-district requirement.
All dimensions use **real metres**, with **1 Godot unit = 1 m** and a typical storey about **3 m**, following [framework.md](framework.md) section 3.
Buildings are **3D models used directly in Godot**, not rendered into world sprites. Modular kits follow framework section 6; interiors section 5; delivery and review section 13.
Everything is modern sci-fi cyberpunk, with no colonial or traditional architecture (framework section 2).

**Dimension migration:** most catalogue footprints are provisional starting suggestions converted from the old compressed tile catalogue at 2 m per former footprint tile. They are not newly confirmed PDF measurements. The first-district model sizes in [FirstDistrict.md](FirstDistrict.md) take precedence; review each model before import.

**Priority**
- **P0**: supports the connected home-school-café first district. Build FirstDistrict.md's model list in its stated order.
- **P1**: expansion after the first district works.
- **P2**: extra depth, flavour and side activities.

**Walk-in**
- **Yes**: needs an interior scene when its activity is built (framework section 5).
- **No**: exterior/background or an object used from outside.
- **Kit**: assembled from modular 3D pieces (framework section 6).

---

'''
s=intro+s[start:]
s=s.replace("## 0. The Academy: Yangon University of Science (the player's university)",'## 0. YUST: Yangon University of Science and Technology')
s=re.sub(r'\*\*Campus size:\*\*.*', '**Campus size:** the earlier 300 x 300 m boundary remains a planning allocation, in metres. It is not a tile conversion or the first district size. Start with the entrance and one teaching space in [FirstDistrict.md](FirstDistrict.md); the full campus is later content. YUST and department names are provisional. The player starts in the family apartment with its rooftop café, not a dorm.',s)
gate_line=next(line for line in s.splitlines() if line.startswith('| yust_gate |'))
s=s.replace(gate_line,gate_line+'\n| yust_side_tower | 14 x 14 | 8 | Yes (skybridge landing/lobby) | **P0** | Other end of the first district pedestrian skybridge |')
s=s.replace('## 2. Housing\n','''## 2. Housing

| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| apartment_cafe | 18 x 12 | 6 | Yes (family apartment, rooftop café) | **P0** | Starting home: family space, player room, café counter, covered terrace, garden, stairs/lift and parking |

### Additional housing
''')
s=s.replace('| Footprint |','| Footprint (m) |')
s=s.replace('Mostly ground tiles and props','Terrain and separate 3D props')
s=s.replace('Each style is one modular kit (framework section 7)', 'Each style is one modular 3D kit (framework section 6)')
s=s.replace('These make up most of the 2 km city.', 'These support later city expansion.')
start=s.index('## First vertical slice (P0)')
s=s[:start]+'''## First vertical slice (P0)

[FirstDistrict.md](FirstDistrict.md) is the authoritative model queue and size list. Finish one connected district before expanding the campus or city.

1. **apartment_cafe**: family apartment, player room, rooftop café, covered seating and garden; starting home.
2. **skybridge** and its stairs/lift landings: connect the family tower with **yust_side_tower**.
3. **yust_gate**, an entrance plaza, **dept_pilot** with one teaching/simulator activity, and **mech_statue**.
4. **convenience_store**, **tea_shop**, **transit_stop**, one drivable car and a second destination parking point.
5. Garden/lake edge, slope, pedestrian stairs/alternate route, roads, signals, props and one animal species.
6. One classmate, one family member, one instructor and a small ambient crowd.
7. A separate contained training arena proves the school machine, one exercise and a friendly match. The full hangar and larger campus come after the district loop works.

The pipeline and budgets are in [framework.md](framework.md). FirstDistrict dimensions are real metres; no tile/sprite conversion applies. Canonical names `yust_gate` and `transit_stop` replace catalogue aliases `main_gate` and `bus_stop`; this document update does not rename existing code or assets. `dept_alien_studies` replaces the retired Silt-specific design proposal.

## Count and scope

This is a location catalogue, not a promised launch asset count. Towers may use several reusable parts; rooms need separate furniture; skybridges need connected landings. The earlier 13/109 building and 89-interior totals belonged to the campus-first sprite plan and are retired. Use FirstDistrict.md for the initial queue and count approved models after review.
'''
p.write_text(s,encoding='utf-8')
print('Migrated BuildingList.md to the current 3D district plan.')
