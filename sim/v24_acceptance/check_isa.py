#!/usr/bin/env python3
"""Validate assembled RV32E against the unchanged Python oracle. No RTL timing claims."""
import argparse, ctypes as C, csv, subprocess, tempfile
from pathlib import Path
from statistics import mean
from acceptance import load, simulate, stress_cases

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--data',type=Path,default=Path('sim/data'));ap.add_argument('--hex',type=Path,default=Path('sw/trade.hex'));ap.add_argument('--cc',default='cc');ap.add_argument('--out',type=Path,default=Path('build/v24_acceptance/isa_report.csv'));ap.add_argument('--meta-only',action='store_true');args=ap.parse_args()
    root=Path(__file__).resolve().parents[2]
    with tempfile.TemporaryDirectory() as temp:
        so=Path(temp)/'isa.so';subprocess.run([args.cc,'-O3','-shared','-fPIC',str(root/'sw/v24/isa_check.c'),'-o',str(so)],check=True)
        lib=C.CDLL(str(so)); words=[int(x,16) for x in args.hex.read_text().split()]; assert len(words)<=1024
        lib.loadrom.argtypes=[C.POINTER(C.c_uint32),C.c_int];lib.loadrom((C.c_uint32*len(words))(*words),len(words));lib.tick.argtypes=[C.c_int,C.POINTER(C.c_int)]
        datasets={'META':load(args.data/'practica_meta.csv')}
        if not args.meta_only:
            paths=sorted((args.data/'pochoco_v16').rglob('*_real.csv'))+sorted((args.data/'pochoco_tests_20000').rglob('SINTETICO_*.csv'));assert len(paths)==51,len(paths)
            datasets.update({p.stem:load(p) for p in paths});datasets.update(stress_cases())
        report=[];out=(C.c_int*6)()
        for name,prices in datasets.items():
            oracle=simulate(prices); lib.restart(); assert lib.boot()==0
            ics=[]; cyc=[]
            for t,p,old,cash,shares,wealth,nxt in oracle['rows']:
                act=lib.tick(p,out)
                assert (act,out[0],out[1])==(nxt,cash,shares),(name,t,act,nxt,list(out),cash,shares)
                ics.append(out[2]);cyc.append(out[3])
            assert len(prices)==20000
            row=dict(name=name,ticks=len(prices),wealth=oracle['wealth'],orders=oracle['orders'],fees=oracle['fees'],dd_pct=oracle['dd_pct'],ic_mean=mean(ics),ic_max=max(ics),cycles_est_mean=mean(cyc),cycles_est_max=max(cyc));report.append(row)
            print('PASS ISA',name,'wealth',row['wealth'],'max IC',row['ic_max'],'estimated cycles',row['cycles_est_max'],flush=True)
        args.out.parent.mkdir(parents=True,exist_ok=True)
        with args.out.open('w') as f:
            w=csv.DictWriter(f,fieldnames=list(report[0]));w.writeheader();w.writerows(report)
        print('PASS ISA',sum(r['ticks'] for r in report),'ticks; actual RTL timing and synthesis not tested.')
if __name__=='__main__':main()
