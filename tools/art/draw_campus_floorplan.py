"""Draw a dimensioned campus site plan directly as PNG and editable SVG."""
from pathlib import Path
from html import escape
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'plans'
OUT.mkdir(exist_ok=True)
BASE = 'campus_floorplan_20261118_01'
W, H = 1600, 1320
image = Image.new('RGB', (W, H), '#eef3f7')
d = ImageDraw.Draw(image)
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">', '<rect width="100%" height="100%" fill="#eef3f7"/>']
INK = '#203248'


def font(size, bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/' + ('segoeuib.ttf' if bold else 'segoeui.ttf'), size)


def rect(x, y, w, h, fill, stroke=None, width=1):
    d.rectangle((round(x), round(y), round(x+w), round(y+h)), fill=fill, outline=stroke, width=width)
    svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width}"/>')


def line(points, color, width=1):
    d.line(points, fill=color, width=width)
    svg.append(f'<polyline points="{" ".join(f"{x},{y}" for x,y in points)}" fill="none" stroke="{color}" stroke-width="{width}"/>')


def text(x, y, value, size=20, color=INK, bold=False, center=False):
    for row, content in enumerate(value.split('\n')):
        yy = y + row*(size+4)
        f = font(size, bold)
        xx = x-d.textlength(content, font=f)/2 if center else x
        d.text((xx, yy), content, font=f, fill=color)
        svg.append(f'<text x="{x if center else xx}" y="{yy+size}" font-family="Segoe UI, sans-serif" font-size="{size}" fill="{color}" font-weight="{700 if bold else 400}" text-anchor="{"middle" if center else "start"}">{escape(content)}</text>')


S, OX, OY = 3.2, 90, 200


def site_rect(x,y,w,h,fill,stroke=None,width=1):
    rect(OX+x*S, OY+y*S, w*S, h*S, fill, stroke, width)


def site_text(x,y,value,size=16,bold=False,color=INK):
    text(OX+x*S, OY+y*S,value,size,color,bold,True)


text(85, 35, 'CAMPUS SITE PLAN', 43, bold=True)
text(85, 94, '300 × 300 m  /  9 hectares  /  modern cyberpunk academy', 25)
text(85, 137, 'Concept layout · north up · dimensions in real metres · not a building-interior plan', 19, '#53687a')
rect(OX, OY, 960, 960, '#e4eedf', '#547261', 3)
for metre in range(0,301,25):
    x,y=OX+metre*S,OY+metre*S
    line([(x,OY),(x,OY+960)],'#d2dfd0')
    line([(OX,y),(OX+960,y)],'#d2dfd0')
    if metre%50==0:
        text(x,OY-26,str(metre),15,'#61756a',center=True)
        text(OX-36,y-9,str(metre),15,'#61756a')

# Vehicle access is wholly separate from the main pedestrian spine.
site_rect(270,18,16,282,'#8c9aa8')
site_rect(192,18,94,16,'#8c9aa8')
site_rect(262,62,8,18,'#8c9aa8')
site_rect(262,157,8,18,'#8c9aa8')
site_rect(202,86,60,26,'#a7b1ba','#7c8a96')
site_text(232,91,'SERVICE APRON',13)
for y in range(24,294,12):
    site_rect(277.5,y,1,6,'#e1e8ee')

# Connected 8 m pedestrian spine and 4 m cross-paths.
site_rect(101,18,8,282,'#d7dce4')
for x,y,w,h in [(80,77,49,4),(125,84,4,12),(109,35,7,4),
                 (60,177,49,4),(60,132,41,4),(84,222,25,4),
                 (109,210,11,4),(109,248,11,4),(109,162,73,4),
                 (45,249,60,4),(43,244,4,9)]:
    site_rect(x,y,w,h,'#d7dce4')
site_rect(76,112,60,40,'#bbd3ad','#6d9461',2)
site_rect(101,112,8,40,'#d7dce4')
site_rect(76,130,60,4,'#d7dce4')
site_rect(102,129,6,6,'#6e8898','#203248',2)
site_text(106,115,'CENTRAL QUAD',14,True)
site_text(106,139,'60 × 40 m',14)

# Pond, rain garden and quiet outdoor study space.
site_rect(28,115,32,42,'#80bbc5','#4c8792',2)
site_text(44,122,'POND',15,True)
site_text(44,145,'& garden',13)
site_rect(28,134,32,3,'#d7dce4')
site_rect(28,253,55,20,'#bed3b3','#6d9461')
site_text(55.5,255,'QUIET GARDEN',14,True)
site_text(55.5,263,'outdoor study',13)

structures = [
    ('Library',40,64,40,30,'#b7c9df','P1'),
    ('Pilot School',116,64,30,20,'#9dc9df','P0'),
    ('Main hall / admin',116,26,40,20,'#b7c9df','P1'),
    ('Clinic',40,169,20,16,'#c6d9dd','P1'),
    ('Residential college',44,204,40,40,'#b8bce3','P0'),
    ('Dining hall',120,204,36,16,'#e4c7a4','P1'),
    ('Student union',120,240,30,20,'#e4c7a4','P1'),
    ('Mech hangar',202,44,60,40,'#aabac6','P0'),
]
labels = {'Library':'LIBRARY\n40 × 30 m', 'Pilot School':'PILOT SCHOOL\n30 × 20 m',
          'Main hall / admin':'MAIN HALL\n40 × 20 m', 'Clinic':'CLINIC\n20 × 16 m',
          'Dining hall':'DINING HALL\n36 × 16 m', 'Student union':'STUDENT UNION\n30 × 20 m',
          'Mech hangar':'MECH HANGAR\n60 × 40 m'}
for name,x,y,w,h,color,priority in structures:
    assert x>=0 and y>=0 and x+w<=300 and y+h<=300
    site_rect(x,y,w,h,color,'#38536a',3 if priority=='P0' else 1)
    if name=='Residential college':
        site_rect(x+8,y+8,w-16,h-16,'#c5dbba','#718c6b')
        site_rect(x+17,y+h-8,6,8,'#d7dce4')
        site_text(x+w/2,y+10,'DORM',15,True)
        site_text(x+w/2,y+18,'COURTYARD',11)
        site_text(x+w/2,y+28,'40 × 40 m',13)
    else:
        size=12 if name in ('Clinic','Pilot School','Student union') else 14
        site_text(x+w/2,y+h/2-6,labels[name],size,True)

for a_index,a in enumerate(structures):
    for b in structures[a_index+1:]:
        _,ax,ay,aw,ah,*_=a
        _,bx,by,bw,bh,*_=b
        assert not (ax<bx+bw and ax+aw>bx and ay<by+bh and ay+ah>by), (a[0],b[0])

site_rect(182,132,80,60,'#bcc3cc','#536575',3)
site_text(222,136,'TRAINING GROUND',16,True)
site_text(222,145,'80 × 60 m',15)
for x in (195,211,227,243):
    site_rect(x,161,8,3,'#718599','#536575')
    site_rect(x,174,8,3,'#8597a5','#536575')
site_rect(183,181,12,8,'#95b9ca','#38536a',2)
site_text(222,183,'targets / obstacles / booth',11)
# A planted buffer separates classrooms and homes from the training zone.
site_rect(166,39,9,232,'#91b28a')
site_text(170.5,117,'BUFFER',10)

# Space reserved for later expansion, shown as allocation rather than buildings.
for x,y,w,h,label in [(28,26,52,20,'FUTURE ACADEMIC WING'),(182,216,80,48,'FUTURE SPORTS / LABS')]:
    site_rect(x,y,w,h,'#dae5dc','#8aa290')
    site_text(x+w/2,y+h/2-4,label,12)
site_rect(92,280,28,10,'#72bac5','#294b60',3)
site_text(106,283,'MAIN GATE',12,True)
site_rect(270,290,16,10,'#d2ac78','#755f42',2)
text(OX+278*S,OY+960+10,'SERVICE GATE',13,center=True)

# Dimension lines, north arrow and scale.
line([(OX,1194),(OX+960,1194)],'#526879',2)
for x in (OX,OX+960):line([(x,1187),(x,1201)],'#526879',2)
text(OX+480,1167,'300 m',19,bold=True,center=True)
line([(1084,270),(1084,205)],INK,3)
line([(1075,220),(1084,205),(1093,220)],INK,3)
text(1084,173,'N',23,bold=True,center=True)

LX=1130
text(LX,205,'LAYOUT LOGIC',27,bold=True)
sections=[
 ('STUDENT CORE','#9dc9df','Dorm → dining → quad → classes.\nShort, connected walking routes.'),
 ('MECH ZONE','#aabac6','Hangar, service apron and training\ncourse along the eastern edge.'),
 ('PEDESTRIAN PATHS','#d7dce4','8 m main promenade.\n4 m connecting paths.'),
 ('SERVICE ROAD','#8c9aa8','16 m wide, separate eastern gate.\nNo route through the student quad.'),
 ('GREEN SPACE','#bbd3ad','Rain trees, pond and quiet gardens.\nPlanted strip beside mech facilities.'),
 ('FUTURE RESERVE','#dae5dc','Allocation only. Keep unbuilt until\nthe first playable campus works.'),
]
for i,(heading,color,body) in enumerate(sections):
    yy=270+i*125
    rect(LX,yy+3,21,21,color,'#6a7b87')
    text(LX+34,yy,heading,19,bold=True)
    text(LX+34,yy+34,body,17,'#51677a')
text(LX,1040,'BUILD FIRST',21,bold=True)
text(LX,1081,'Gate · quad · dorm · Pilot School\nHangar · training ground',18)
text(LX,1151,'Bold outlines = first playable core.\nOther blocks are later supporting uses.',16,'#51677a')
for i in range(4):rect(90+i*80,1220,80,13,'#203248' if i%2==0 else '#c0ccd4')
text(90,1241,'0',15)
text(250,1241,'50',15,center=True)
text(410,1241,'100 m',15,center=True)
text(475,1212,'Planning dimensions are suggestions, not locked asset footprints.',18,'#51677a')
text(475,1245,'Game buildings can remain compressed; interiors load as separate rooms.',18,'#51677a')

png=OUT/(BASE+'.png')
vector=OUT/(BASE+'.svg')
image.save(png)
vector.write_text('\n'.join(svg+['</svg>']),encoding='utf-8')
data={'site_metres':[300,300], 'area_m2':90000, 'origin':'northwest',
      'axes':'x east, y south', 'status':'concept site plan, not locked game footprints',
      'structures':[dict(name=n,x=x,y=y,width=w,depth=h,priority=p) for n,x,y,w,h,c,p in structures],
      'training_ground':{'x':182,'y':132,'width':80,'depth':60},
      'service_road_width_m':16, 'main_promenade_width_m':8,'side_path_width_m':4}
(OUT/(BASE+'.json')).write_text(json.dumps(data,indent=2),encoding='utf-8')
(OUT/'campus_floorplan_20261118_prompt.txt').write_text('User brief: give me the floor plan for the 300 x 300 m modern cyberpunk campus.\nMethod: deterministic vector/raster site diagram with metre coordinates, north arrow, scale, paths, building allocations and separate mech service access.\nThis is a planning diagram, not isometric production art.\n',encoding='utf-8')
print(png)
print(vector)
