#!/usr/bin/env python3
"""V24-T reference tests and RTL oracle, standard library only."""
import argparse,csv,json,random,hashlib
from pathlib import Path
from dataclasses import dataclass
from statistics import mean,median
from reference import candidate,v24
HOLD,BUY,SELL=0,0x7f,0xbf
@dataclass
class Ledger:
    cash:int=10000
    shares:int=0
    orders:int=0
    fees:int=0
    def execute(self,b,p):
        assert 0<=b<=255 and 1<=p<=255
        act,q=divmod(b,64)
        if act==1:
            q=min(q,max(0,(self.cash-5)//p))
            if q: self.cash-=q*p+5; self.shares+=q
        elif act==2:
            q=min(q,self.shares)
            if self.cash+q*p<5: q=0
            if q: self.cash+=q*p-5; self.shares-=q
        else: q=0
        if q: self.orders+=1; self.fees+=5
        assert self.cash>=0 and self.shares>=0
        return q
class CausalPrices:
    def __init__(self,prices): self.prices=prices; self.tick=-1
    def __getitem__(self,i):
        assert isinstance(i,int) and 0<=i<=self.tick,('noncausal read',i,self.tick)
        return self.prices[i]
    def __len__(self): return self.tick+1

def simulate(prices,factory=candidate):
    strategy,stats=factory(); pf=Ledger(); stream=CausalPrices(prices)
    pending=0; peak=10000; dd=0; dd_pct=0.; rows=[]; anomalies=[]
    for t,p in enumerate(prices):
        if pending>>6==1 and pf.shares: anomalies.append((t,'buy while holding'))
        before=pf.shares; q=pf.execute(pending,p)
        if pending>>6==2 and before and not q: anomalies.append((t,'sell rejected'))
        w=pf.cash+pf.shares*p; peak=max(peak,w); dd=max(dd,peak-w); dd_pct=max(dd_pct,100*(peak-w)/peak)
        stream.tick=t; act,q=strategy(stream,t,pf)
        assert act in ('hold','buy','sell') and isinstance(q,int) and 0<=q<=63
        assert (q==0)==(act=='hold')
        nxt={'hold':0,'buy':64,'sell':128}[act]|q
        rows.append((t,p,pending,pf.cash,pf.shares,w,nxt)); pending=nxt
    assert rows[0][2]==0 and all(a[6]==b[2] for a,b in zip(rows,rows[1:]))
    return dict(wealth=rows[-1][5],ret=(rows[-1][5]-10000)/100,orders=pf.orders,fees=pf.fees,dd=dd,dd_pct=dd_pct,rows=rows,stats=dict(stats),anomalies=anomalies)

def replay(rows):
    cash,shares,orders=10000,0,0
    for t,p,b,c,s,w,_ in rows:
        act,requested=divmod(b,64)
        if act==1:
            q=0
            while q<requested and (q+1)*p+5<=cash: q+=1
            if q: cash-=5+p*q; shares+=q; orders+=1
        elif act==2:
            q=min(shares,requested)
            if q and cash+p*q>=5: cash+=p*q-5; shares-=q; orders+=1
        assert (cash,shares,cash+shares*p)==(c,s,w),('ledger mismatch',t)
    return orders

def ledger_tests():
    a=Ledger(); assert a.execute(BUY,255)==39 and (a.cash,a.shares)==(50,39)
    assert a.execute(BUY,255)==0 and a.fees==5
    assert a.execute(SELL,100)==39 and (a.cash,a.shares,a.fees)==(3945,0,10)
    assert a.execute(SELL,100)==0 and a.fees==10
    a=Ledger(cash=4); assert a.execute(BUY,1)==0
    a=Ledger(cash=0,shares=4); assert a.execute(SELL,1)==0
    assert a.execute(0xc0,1)==0 and a.fees==0
    a=Ledger(cash=0,shares=5); assert a.execute(SELL,1)==5 and a.cash==0
    a=Ledger(cash=105); assert a.execute(BUY,100)==1 and a.cash==0
    print('PASS accounting edge cases')

def load(path):
    with path.open() as f: rows=list(csv.DictReader(f))
    p=[int(r['price']) for r in rows]; assert p and all(1<=x<=255 for x in p),path
    if 'tick' in rows[0]: assert all(int(r['tick'])==i for i,r in enumerate(rows)),path
    return p

def export(out,name,r):
    d=out/name; d.mkdir(parents=True,exist_ok=True)
    with (d/'expected.csv').open('w') as f:
        w=csv.writer(f); w.writerow(['tick','precio','decision','caja','acciones','patrimonio','next_decision'])
        for t,p,b,c,s,w0,n in r['rows']: w.writerow([t,p,f'{b:02x}',c,s,w0,f'{n:02x}'])
    for file,idx in [('prices.hex',1),('decisions.hex',2),('next.hex',6)]:
        (d/file).write_text(''.join(f'{r0[idx]:02x}\n' for r0 in r['rows']))
    (d/'summary.json').write_text(json.dumps({k:v for k,v in r.items() if k!='rows'},indent=2)+'\n')

def compare(expected,actual,limit=None):
    with open(expected) as f: a=list(csv.DictReader(f))
    with open(actual) as f: b=list(csv.DictReader(f))
    if limit is not None: a=a[:limit]
    assert len(a)==len(b),(len(a),len(b))
    for i,(x,y) in enumerate(zip(a,b)):
        for key in ('tick','precio','decision','caja','acciones','patrimonio','next_decision'):
            base=16 if key in ('decision','next_decision') else 10
            assert int(x[key],base)==int(y[key],base),f'tick {i}, {key}: expected {x[key]} actual {y[key]}'
    print(f'PASS RTL exact parity: {len(a)} ticks')

def stress_cases(n=20000):
    rng=random.Random(20261127)
    return {'constant_100':[100]*n,'constant_255':[255]*n,'alternating_100_255':[100 if i%2==0 else 255 for i in range(n)],'ramp_up':[100+min(155,i//100) for i in range(n)],'ramp_down':[255-min(155,i//100) for i in range(n)],'cliff_recovery':[220 if i<3000 else 100 if i<12000 else min(255,100+(i-12000)//30) for i in range(n)],'sawtooth':[100+(i%310 if i%310<=155 else 310-i%310) for i in range(n)],'random_full':[rng.randint(100,255) for _ in range(n)],'pdf_range_1_255':[rng.randint(1,255) for _ in range(n)],'pdf_range_cliff':[200 if i<1000 else 1 if i<10000 else 255 for i in range(n)]}

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--data',type=Path,default=Path('sim/data')); ap.add_argument('--out',type=Path,default=Path('build/v24_acceptance')); ap.add_argument('--compare',nargs=2); ap.add_argument('--limit',type=int); args=ap.parse_args()
    if args.compare: compare(*args.compare,limit=args.limit); return
    out=args.out; out.mkdir(parents=True,exist_ok=True); ledger_tests()
    meta=load(args.data/'practica_meta.csv'); assert len(meta)==20000
    histories=sorted((args.data/'pochoco_v16').rglob('*_real.csv')); synthetic=sorted((args.data/'pochoco_tests_20000').rglob('SINTETICO_*.csv')); assert (len(histories),len(synthetic))==(48,3)
    r=simulate(meta); assert r['wealth']==19239,r['wealth']; assert replay(r['rows'])==r['orders']; assert not r['anomalies']; assert simulate(meta)['rows']==r['rows']
    print('PASS META exact wealth, independent ledger, deterministic restart', {k:r[k] for k in ('wealth','orders','fees','dd','dd_pct')},flush=True)
    assert simulate(meta,lambda:v24(merit_trades=1))['wealth']==18245
    for cut in (1,8,64,128,512,1017,1329,5000,19999): assert simulate(meta[:cut])['rows']==r['rows'][:cut],('prefix',cut)
    rng=random.Random(24)
    for cut in (512,1329,5000,15000):
        modified=meta[:cut]+[rng.randint(100,255) for _ in meta[cut:]]; assert simulate(modified)['rows'][:cut]==r['rows'][:cut],('suffix',cut)
    print('PASS causal access, prefix and alternate suffix invariance',flush=True); export(out,'META',r)
    q0=min(63,(10000-5)//meta[0]); q1=min(63,(10000-5)//meta[1]); print('References: HOLD=10000; B&H max63 at tick0=',10000-5+q0*(meta[-1]-meta[0]),'; at tick1=',10000-5+q1*(meta[-1]-meta[1]))
    report=[]
    for path in histories+synthetic:
        p=load(path); assert len(p)==20000 and min(p)>=100,path
        x=simulate(p); assert replay(x['rows'])==x['orders']; assert not x['anomalies'],(path,x['anomalies']); export(out,path.stem,x)
        report.append({'name':path.stem,'group':'historical' if path in histories else 'synthetic', **{k:x[k] for k in ('wealth','ret','orders','fees','dd','dd_pct')}})
    hist=[x for x in report if x['group']=='historical']; rets=[x['ret'] for x in hist]; assert round(mean(rets),2)==16.29 and sum(x>0 for x in rets)==34 and min(rets)==-18.23,rets
    print('PASS historical exact metrics', {'mean':mean(rets),'median':median(rets),'positive':sum(x>0 for x in rets),'worst':min(rets),'best':max(rets),'mean_dd_pct':mean(x['dd_pct'] for x in hist)},flush=True)
    anomalies=[]
    for name,p in stress_cases().items():
        x=simulate(p); assert replay(x['rows'])==x['orders']; export(out,name,x)
        if x['anomalies']: anomalies.append((name,x['anomalies']))
        report.append({'name':name,'group':'stress',**{k:x[k] for k in ('wealth','ret','orders','fees','dd','dd_pct')}}); print('STRESS',name,'wealth',x['wealth'],'anomalies',len(x['anomalies']),flush=True)
    report.insert(0,{'name':'META','group':'practice',**{k:r[k] for k in ('wealth','ret','orders','fees','dd','dd_pct')}})
    with (out/'report.csv').open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(report[0])); w.writeheader(); w.writerows(report)
    (out/'manifest.json').write_text(json.dumps({'reference_sha256':hashlib.sha256(Path(__file__).with_name('reference.py').read_bytes()).hexdigest(),'data_sha256':{str(p.relative_to(args.data)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [args.data/'practica_meta.csv']+histories+synthetic},'stress_anomalies':anomalies},indent=2)+'\n')
    if anomalies: print('FAIL stress strategy invariants:',anomalies[:2]); raise SystemExit(1)
    print('PASS all Python acceptance gates; RTL/physical tests still required')
if __name__=='__main__': main()
