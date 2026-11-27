/* V24-T integer port. Only current and previous prices influence output.
 * Virtual V17 accounting omitted: its score and PnL are never read by V24-T.
 * Virtual P12 equity = realized PnL + mark-to-market, less the buy fee.
 * Both transformations preserve decisions, verified against frozen Python. */
typedef struct { int lo, hi, close; } Block;
typedef struct {
    int t, hist[64], prev;
    int ps, pe, pp, pt, pb, trail, pa, pnl, snapshots[5], qualified, disabled;
    int vs, ve, vp, vt, vb, panic, paniclo, va, pending_reason, resume, until;
    Block blocks[4]; int low, high;
    int cash, shares, active, order, exit_engine, buy_cash, actual_pnl, re, rp;
} State;
static inline int min(int a,int b) { return a<b?a:b; }
static inline int max(int a,int b) { return a>b?a:b; }
static int times(int q,int p) {
    int result=0;
    for(int bit=1; bit<=q; bit+=bit,p+=p) if(q&bit) result+=p;
    return result;
}
/* Limit the buy to 63; binary decomposition uses additions, not division. */
static int buy(State *s,int p) {
    int cash=s->cash-5, q=0;
    int a=p+p,b=a+a,c=b+b,d=c+c,e=d+d;
    if(cash>=e){cash-=e;q+=32;}
    if(cash>=d){cash-=d;q+=16;}
    if(cash>=c){cash-=c;q+=8;}
    if(cash>=b){cash-=b;q+=4;}
    if(cash>=a){cash-=a;q+=2;}
    if(cash>=p){cash-=p;q++;}
    if(q){s->cash=cash;s->shares+=q;}
    return q;
}
static int p12(State *s,int p,int d8) {
    int t=s->t;
    if(s->pa==1){s->pe=s->pp=p;s->pt=t;s->trail=0;}
    if(t<8) return 0;
    if(!s->ps){if(t>=s->pb && d8<=-4){s->ps=1;return 1;}return 0;}
    if(p<=s->pe-16){s->ps=s->trail=0;s->pb=t+16;return 2;}
    if(s->trail){s->pp=max(s->pp,p);if(p<=max(s->pe,s->pp-12)){s->ps=s->trail=0;return 2;}return 0;}
    if(d8>=4 && p>=s->pe+2){s->trail=1;s->pp=p;return 0;}
    if(t-s->pt>=31 && d8>=4){s->ps=0;return 2;}
    return 0;
}
/* sell reasons: 1=TRAIL, 2=PANIC, 3=other emergency, 4=STALE. */
static int v_sell(State*s,int p,int reason) {
    s->vs=0;s->pending_reason=reason;
    int emergency=(reason==2 || reason==3);
    s->vb=s->t+(emergency?64:16);
    if(emergency){s->panic=1;s->paniclo=p;}
    return 2;
}
static int v17(State*s,int p,int d8,int d64) {
    int t=s->t;
    Block *a=s->blocks,*b=a+1,*c=a+2,*d=a+3;
    if(t && !(t&127)){
        *a=*b;*b=*c;*c=*d; d->lo=s->low;d->hi=s->high;d->close=s->prev;
        s->low=255;s->high=0;
    }
    s->low=min(s->low,p);s->high=max(s->high,p);
    if(s->pending_reason){
        if((s->pending_reason==1 && p>s->ve) || (s->pending_reason==2 && p>=s->ve+2)){
            s->resume=s->vp;s->until=t+512;
        }else s->resume=0;
        s->pending_reason=0;
    }
    if(s->va==1){s->ve=s->vp=p;s->vt=t;}
    if(t<64) return 0;
    int regime=0; /* unknown=0, up=1, down=2, range=3 */
    if(t>=512){
        int ol=min(a->lo,b->lo),nl=min(c->lo,d->lo),oh=max(a->hi,b->hi),nh=max(c->hi,d->hi),delta=d->close-a->close;
        if(p<=min(ol,nl)-2)regime=2;
        else if(nl>=ol+2 && nh>=oh+2 && delta>=3)regime=1;
        else if(nl<=ol-2 && nh<=oh-2 && delta<=-3)regime=2;
        else if(nl-ol<=3 && nl-ol>=-3 && nh-oh<=3 && nh-oh>=-3 && delta<=4 && delta>=-4 && max(oh,nh)-min(ol,nl)>=10)regime=3;
    }
    if(d8<=-6 || d64<=-8){if(!s->panic){s->panic=1;s->paniclo=p;}s->paniclo=min(s->paniclo,p);}
    else if(s->panic){s->paniclo=min(s->paniclo,p);if(p-s->paniclo>=8 && d8>=2 && d64>=1 && regime!=2)s->panic=0;}
    if(s->panic && s->vs)return v_sell(s,p,2);
    if(s->vs){
        s->vp=max(s->vp,p);int gain=s->vp-s->ve;
        if(p<=s->ve-8)return v_sell(s,p,3);
        if(regime==2 && d64<=-2)return v_sell(s,p,3);
        int stop;
        if(gain>=24)stop=max(s->ve,s->vp-5);
        else if(gain>=12)stop=max(s->ve,s->vp-8);
        else if(gain>=8)stop=max(s->ve,s->vp-12);
        else if(gain>=4)stop=max(s->ve-2,s->vp-12);
        else stop=s->ve-8;
        if(p<=stop)return v_sell(s,p,1);
        if(t-s->vt>=256 && p<=s->ve && d64<=0)return v_sell(s,p,4);
        return 0;
    }
    if(s->panic || t<s->vb || t<512)return 0;
    int rebound=p-min(d->lo,s->low), rh=max(c->hi,d->hi);
    int pull=(rebound>=3 && rebound<=10 && d8>=2 && d64>=1 && p>=d->close-2);
    int br=(p>rh && s->prev<=rh && d8>=2 && d64>=2);
    if((regime==1 && (pull||br)) || (regime==0 && d->lo>=c->lo+1 && br && d64>=4) ||
       (s->resume && t<=s->until && (regime==1 || regime==0) && d->lo>=c->lo && p>s->resume && s->prev<=s->resume && d8>=2 && d64>=2)){
        s->vs=1;s->resume=0;return 1;
    }
    return 0;
}
void reset(State*s){
    for(unsigned i=0;i<sizeof(*s)/sizeof(int);i++) ((int*)s)[i]=0;
    s->cash=10000;s->low=255;s->paniclo=255;
}
int step(State*s,int p){
    int t=s->t, d8=0,d64=0;
    if(t>=8)d8=p-s->hist[(t-8)&63];
    if(t>=64)d64=p-s->hist[t&63];
    s->hist[t&63]=p;
    /* Official ledger executes previous instruction at current price. */
    if(s->order==127){
        buy(s,p);
        if(!s->shares)s->active=0;
        else s->re=s->rp=p;
    }else if(s->order==191){
        int q=min(s->shares,63), value=times(q,p);
        if(q && s->cash+value>=5){s->cash+=value-5;s->shares-=q;}
        if(s->exit_engine==1){s->actual_pnl+=s->cash-s->buy_cash;if(s->actual_pnl<=-750)s->disabled=1;}
    }
    /* P12 equity before new signal, exactly as Shadow.step. */
    if(s->pa==2)s->pnl+=32*(p-s->pe)-10;
    if(s->pa==1)s->pe=p;
    int equity=s->pnl+(s->ps?32*(p-s->pe)-5:0);
    if(t && !(t&127)){
        s->snapshots[0]=s->snapshots[1];s->snapshots[1]=s->snapshots[2];s->snapshots[2]=s->snapshots[3];s->snapshots[3]=s->snapshots[4];s->snapshots[4]=equity;
    }
    int score=equity-s->snapshots[0];
    if(s->pnl>=128)s->qualified=1;
    s->pa=p12(s,p,d8);s->va=v17(s,p,d8,d64);
    s->prev=p;s->t=t+1;
    int order=0;
    if(s->active){
        s->rp=max(s->rp,p);
        int sell=0;
        if(s->active==1){
            if(s->actual_pnl+s->cash+times(s->shares,p)-(s->shares?5:0)-s->buy_cash<=-750){s->disabled=1;sell=1;}
            if(s->pa==2)sell=1;
            int gain=s->rp-s->re;
            if((gain>=24 && p<=s->rp-5) || (gain>=12 && gain<24 && p<=s->rp-8))sell=1;
        }else if(s->va==2)sell=1;
        if(sell){s->exit_engine=s->active;s->active=0;order=191;}
    }else{
        if(s->qualified && !s->disabled && s->pa==1 && score>=-128)s->active=1;
        else if(s->va==1)s->active=2;
        if(s->active){s->buy_cash=s->cash;order=127;}
    }
    return s->order=order;
}
#ifdef EMBEDDED
__attribute__((noreturn)) void firmware(void){
    State*s=(State*)0x10000000;
    volatile unsigned*spi=(volatile unsigned*)0x80010000;
    reset(s);spi[2]=0;
    for(;;){while(!(spi[0]&1)){} unsigned p=spi[1];spi[2]=step(s,p);}
}
#endif
