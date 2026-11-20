"""Render an elevation/landscape variant without changing the approved building positions."""
from pathlib import Path

HERE = Path(__file__).resolve().parent
source = (HERE / 'draw_campus_floorplan.py').read_text(encoding='utf-8')
source = source.replace("BASE = 'campus_floorplan_20261118_01'", "BASE = 'campus_terrain_plan_20261118_01'")
source = source.replace("'CAMPUS SITE PLAN'", "'CAMPUS TERRAIN + LANDSCAPE'")
source = source.replace("'Concept layout · north up · dimensions in real metres · not a building-interior plan'", "'Relative ground levels · existing building positions retained · campus gameplay layout'")
source = source.replace("'LAYOUT LOGIC'", "'TERRAIN + ROUTES'")

zones = '''
# Coloured terrain terraces beneath the unchanged structures and paths.
site_rect(20,18,140,82,'#d2d9ea')
site_rect(20,100,140,92,'#c6deba')
site_rect(20,192,140,86,'#e4eedf')
'''
source = source.replace('# Vehicle access is wholly separate', zones+'\n# Vehicle access is wholly separate')

overlay = '''
# Elevation boundaries with openings for stairs and ramps.
def wall(x1,y1,x2,y2):
    line([(OX+x1*S,OY+y1*S),(OX+x2*S,OY+y2*S)],'#62758b',4)
for a,b in [(20,101),(109,146),(152,160)]: wall(a,100,b,100)
for a,b in [(20,88),(94,101),(109,160)]: wall(a,192,b,192)
wall(160,18,160,162)
wall(160,166,160,192)

def stair(x,y,w,run,label,rise):
    site_rect(x,y,w,run,'#efc58e','#805d38',2)
    for i in range(1,7):
        yy=y+run*i/7
        line([(OX+x*S,OY+yy*S),(OX+(x+w)*S,OY+yy*S)],'#8d6a43',1)
    if label!='S3': site_text(x+w+7,y+1,label,12,True)
stair(101,96,8,8,'S2',2)
stair(101,188,8,8,'S1',2)
stair(43,250,4,5,'S3',1)

# Three 40 m ramp runs, each allowing a 2 m level change.
site_rect(146,80,6,40,'#c6b9df','#79658e',2)
site_rect(88,172,6,40,'#c6b9df','#79658e',2)
site_rect(136,162,40,4,'#c6b9df','#79658e',2)
site_text(149,107,'R1',12,True)
site_text(91,198,'R2',12,True)
site_text(151,166,'R3',12,True)
for x,y,w,h in [(146,78,3,4),(136,118,13,4),(88,172,17,4),(94,210,11,4)]:
    site_rect(x,y,w,h,'#d7dce4')
# Repaint continuous ramp over its connecting landings.
site_rect(146,80,6,40,'#c6b9df','#79658e',2)
site_text(149,107,'R1',12,True)

def badge(x,y,label):
    xx,yy=OX+x*S,OY+y*S
    d.ellipse((xx-13,yy-13,xx+13,yy+13),fill='#203248',outline='white',width=1)
    svg.append(f'<circle cx="{xx}" cy="{yy}" r="13" fill="#203248" stroke="white"/>')
    text(xx,yy-9,label,12,'white',True,True)

def circle(x,y,r,fill,stroke,width=2):
    xx,yy,rr=OX+x*S,OY+y*S,r*S
    d.ellipse((xx-rr,yy-rr,xx+rr,yy+rr),fill=fill,outline=stroke,width=width)
    svg.append(f'<circle cx="{xx}" cy="{yy}" r="{rr}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')

# Water descends through a planted rill to the pond, then along the west swale.
site_rect(69,95,3,50,'#68afb9','#3b7b89')
site_rect(60,143,12,3,'#68afb9','#3b7b89')
for yy in (99,101,103):
    line([(OX+69*S,OY+yy*S),(OX+72*S,OY+yy*S)],'#e8f5f7',2)
site_rect(28,157,3,98,'#8bbbc0')
line([(OX+44*S,OY+156*S),(OX+29.5*S,OY+166*S)],'#68afb9',4)
site_rect(67,130,7,4,'#c3a57d','#755f45',2)
for xx in (68,70,72):
    line([(OX+xx*S,OY+130*S),(OX+xx*S,OY+134*S)],'#755f45',1)

# A separate fountain does not obstruct the statue or the central crossing.
circle(125,122,4,'#e7edf1','#5e798b',2)
circle(125,122,2.8,'#74bdc8','#4b8c98',1)
circle(125,122,0.8,'#def7fa','#def7fa',1)
badge(114,130,'01')
badge(138,122,'02')
badge(75,104,'03')
badge(78,137,'04')

# Lower rain garden with logs; water and circulation remain visible.
site_rect(28,253,55,20,'#c2dad5','#69968f',2)
site_text(58,254,'RAIN GARDEN -1 m',11,True)
site_text(61,248,'S3',11,True)
for x,y in [(35,263),(46,267),(62,264)]:
    line([(OX+x*S,OY+y*S),(OX+(x+4)*S,OY+(y+1)*S)],'#8f7257',7)
    line([(OX+x*S,OY+(y-0.4)*S),(OX+(x+4)*S,OY+(y+0.6)*S)],'#c4a480',2)
badge(77,267,'05')

# Low modern stepped seating on the middle terrace.
for y,w in [(180,20),(183,18),(186,16)]:
    site_rect(119,y,w,1.5,'#a4aeba','#65788c')
badge(143,184,'06')

# Small planting and seating symbols outside the important clear routes.
for x,y in [(87,116),(143,145),(133,263),(156,60),(196,118)]:
    circle(x,y,2.5,'#8eb584','#587c59',1)
for x,y in [(79,151),(132,153),(34,247)]:
    site_rect(x,y,5,1.5,'#a58565','#695c50')

for x,y,label in [(41,20,'ACADEMIC +4 m'),(43,104,'QUAD +2 m'),
                  (47,194,'RESIDENTIAL 0 m'),(224,119,'MECH ZONE 0 m')]:
    site_text(x,y,label,12,True)
site_text(44,151,'water +1 m',10)
'''
source = source.replace('# Dimension lines, north arrow and scale.',overlay+'\n# Dimension lines, north arrow and scale.')
start = source.index('sections=[')
end = source.index('\nfor i,(heading,color,body)',start)
source = source[:start]+'''sections=[
 ('HIGH TERRACE +4 m','#d2d9ea','Main hall, library and Pilot School.\\nConnected by S2 stairs and R1 ramp.'),
 ('MIDDLE TERRACE +2 m','#c6deba','Quad, fountain plaza and clinic.\\nLow retaining walls frame the paths.'),
 ('LOW GROUND 0 m','#e4eedf','Dorm, dining and all mech facilities.\\nKeep the service road flat.'),
 ('STAIRS S1 / S2 / S3','#efc58e','S1 and S2 each change level by 2 m.\\nS3 descends 1 m into the rain garden.'),
 ('RAMP LINKS R1 / R2 / R3','#c6b9df','Each changes 2 m over a 40 m run.\\nAlternate routes beside the stair paths.'),
 ('WATER + REST','#74bdc8','Pond water +1 m; rain garden -1 m.\\nCascade, footbridge and log seating.'),
]'''+source[end:]
source = source.replace("text(LX,1040,'BUILD FIRST',21,bold=True)","text(LX,1040,'LANDSCAPE KEY',21,bold=True)")
source = source.replace("text(LX,1081,'Gate · quad · dorm · Pilot School\\nHangar · training ground',18)","text(LX,1081,'01 Mech statue   ·   02 Fountain\\n03 Cascade        ·   04 Footbridge\\n05 Log seating   ·   06 Stepped seating',17)")
source = source.replace("text(LX,1151,'Bold outlines = first playable core.\\nOther blocks are later supporting uses.',16,'#51677a')", "text(LX,1190,'Levels are relative to the entry datum.',15,'#51677a')")
source = source.replace("'Planning dimensions are suggestions, not locked asset footprints.'","'Retaining walls, stairs and ramps make the campus levels readable in game.'")
source = source.replace("'Game buildings can remain compressed; interiors load as separate rooms.'","'Stairs change routes; full building footprints and flat mech access remain intact.'")
source = source.replace("(OUT/(BASE+'.json')).write_text",'''data.update({'relative_levels_m': {'academic':4,'quad':2,'residential':0,'mech_zone':0,'pond_water':1,'rain_garden':-1},
             'stairs': [{'id':'S1','rise_m':2,'x':101,'y':188}, {'id':'S2','rise_m':2,'x':101,'y':96}, {'id':'S3','rise_m':1,'x':43,'y':250}],
             'ramps': [{'id':'R1','rise_m':2,'run_m':40,'x':146,'y':80}, {'id':'R2','rise_m':2,'run_m':40,'x':88,'y':172}, {'id':'R3','rise_m':2,'run_m':40,'x':136,'y':162}],
             'landscape': ['mech statue','fountain','cascade','footbridge','log seating','stepped seating'],
             'validation': 'Original structure locations unchanged; no overlapping structure footprints. Relative landscape levels only, not a construction or drainage design.'})
(OUT/(BASE+'.json')).write_text''')
source = source.replace("'campus_floorplan_20261118_prompt.txt'", "'campus_terrain_plan_20261118_prompt.txt'")
source = source.replace("User brief: give me the floor plan for the 300 x 300 m modern cyberpunk campus.","User brief: add high and low terrain, staircases, logs, water fountain and statue to the existing campus map.")
exec(compile(source, str(HERE / 'draw_campus_floorplan.py'), 'exec'), {'__file__':str(HERE / 'draw_campus_floorplan.py'),'__name__':'__main__'})
