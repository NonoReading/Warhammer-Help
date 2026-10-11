import re,glob,sys,collections
DECL={'T0089':{'Minor Magic'},'T0088':{'Arcane Magic','Domain Magic','Ritual'},
'T0172':{'Chaos Magic','Arcane Magic'},'T0080':{'Miracle'},'T0012':{'Blessing'},
'HELFG-T0190':{'Domain Magic','Miracle','Blessing'}}
root='DATABASE/'+(sys.argv[1] if len(sys.argv)>1 else 'WFRP4')
files=glob.glob(root+'/*.[Xx]ml')
gen={}; sorts=[]; tals={}
for f in files:
    t=open(f,encoding='utf-8',errors='replace').read()
    for m in re.finditer(r'<Talent id="([^"]+)">(.*?)</Talent>',t,re.S):
        g=re.search(r'<Generique>"?([^"<]*)"?</Generique>',m.group(2))
        tals[m.group(1)]=f
        if g and g.group(1): gen[m.group(1)]=g.group(1).rstrip('*').rstrip('_')
    for m in re.finditer(r'<Sort id="([^"]+)">(.*?)</Sort>',t,re.S):
        b=m.group(2)
        ta=re.search(r'<Talent>"?([^"<]*)"?</Talent>',b); ty=re.search(r'<TypSpell>"?([^"<]*)"?</TypSpell>',b)
        d=re.search(r'<Description[^>]*>"?([^"<]*)',b)
        sorts.append((m.group(1),f.replace(chr(92),'/').split('/')[-1],ta.group(1) if ta else None,ty.group(1) if ty else None,d.group(1) if d else ''))
def root_of(c):
    c=c.rstrip('*').rstrip('_')
    return gen.get(c,c)
typeof={sid:ty for sid,f,ta,ty,d in sorts if ty}
def short(c): return c
bad=collections.defaultdict(list); stat=collections.Counter(); undeclared=collections.Counter()
for sid,f,ta,ty,d in sorts:
    if not ty: ty=typeof.get(sid)
    if not ta: stat['sans talent / '+str(ty)]+=1; continue
    for c in [x.strip() for x in ta.split(',') if x.strip()]:
        r=root_of(c)
        key=r if r in DECL else (r.split('-',1)[1] if r.split('-',1)[-1] in DECL else r)
        if key not in DECL: undeclared[(r,ty)]+=1; bad['TALENT NON DECLARE'].append((sid,f,c,r,ty)); continue
        if ty in DECL[key]: stat['ok']+=1
        else: bad['HORS FAMILLE'].append((sid,f,c,r,ty))
print(len(sorts),'sorts',dict(stat))
for k,v in bad.items():
    print('==',k,len(v))
    agg=collections.Counter((x[1],x[2],x[3],x[4]) for x in v)
    for a,n in agg.most_common(): print(n,a)
    for x in v[:8]: print('  ',x)
print('--- sans talent, par livre')
withtal={sid for sid,f,ta,ty,d in sorts if ta}
c=collections.Counter(); orph=[]
for sid,f,ta,ty,d in sorts:
    if not ta:
        c[f]+=1
        if sid not in withtal: orph.append((sid,f,ty or typeof.get(sid),d))
print(c)
print('ids sans talent nulle part:',len(orph))
oc=collections.Counter((f,t) for _,f,t,_ in orph); print(oc)
for o in orph:
    if o[2] not in ('Blessing',): print(o)
notype=[(sid,f) for sid,f,ta,ty,d in sorts if not ty and sid not in typeof]; print('sans type:',notype)
print('--- racines de talent par type')
rt=collections.defaultdict(collections.Counter)
for sid,f,ta,ty,d in sorts:
    ty=ty or typeof.get(sid)
    for c in [x.strip() for x in (ta or '').split(',') if x.strip()]: rt[root_of(c)][ty]+=1
for r,v in sorted(rt.items()): print(r,dict(v))
