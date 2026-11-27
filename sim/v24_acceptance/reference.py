import csv
from pathlib import Path
from collections import deque, Counter
from statistics import mean, median


# ========================================
# MOTOR P12 ORIGINAL
# ========================================

def p12():
    position = pending = trailing = False
    entry = peak = entry_tick = blocked = 0

    def strategy(prices,t,pf):
        nonlocal position,pending,trailing
        nonlocal entry,peak,entry_tick,blocked

        p = prices[t]

        if pending:
            entry = peak = p
            entry_tick = t
            pending = trailing = False

        if t < 8:
            return "hold",0

        d8 = p-prices[t-8]

        if not position:
            if t >= blocked and d8 <= -4:
                position = pending = True
                return "buy",63

            return "hold",0

        if p <= entry-16:
            position = trailing = False
            blocked = t+16
            return "sell",63

        if trailing:
            peak = max(peak,p)

            if p <= max(entry,peak-12):
                position = trailing = False
                return "sell",63

            return "hold",0

        if d8 >= 4 and p >= entry+2:
            trailing = True
            peak = p
            return "hold",0

        if t-entry_tick >= 31 and d8 >= 4:
            position = False
            return "sell",63

        return "hold",0

    return strategy


# ========================================
# MOTOR V17.3-P
# ========================================

def v17():
    blocks = deque(maxlen=4)
    low,high,close = 255,0,0

    position = pending = panic = False
    pending_sell = None

    entry = peak = entry_tick = blocked = 0
    panic_low = 255

    resume_peak = None
    resume_until = 0

    def sell(reason,t,p,emergency=False):
        nonlocal position,pending_sell
        nonlocal panic,panic_low,blocked

        position = False
        pending_sell = reason
        blocked = t+(64 if emergency else 16)

        if emergency:
            panic = True
            panic_low = p

        return "sell",63

    def strategy(prices,t,pf):
        nonlocal low,high,close
        nonlocal position,pending,panic,panic_low
        nonlocal entry,peak,entry_tick
        nonlocal pending_sell,resume_peak,resume_until

        p = prices[t]

        if t > 0 and t % 128 == 0:
            blocks.append((low,high,close))
            low,high = 255,0

        low = min(low,p)
        high = max(high,p)
        close = p

        if pending_sell is not None:
            if (
                (pending_sell == "TRAIL" and p > entry)
                or
                (pending_sell == "PANIC" and p >= entry+2)
            ):
                resume_peak = peak
                resume_until = t+512
            else:
                resume_peak = None

            pending_sell = None

        if pending:
            entry = peak = p
            entry_tick = t
            pending = False

        if t < 64:
            return "hold",0

        d8 = p-prices[t-8]
        d64 = p-prices[t-64]

        regime = "UNKNOWN"

        if len(blocks) == 4:
            a,b,c,d = blocks

            ol = min(a[0],b[0])
            nl = min(c[0],d[0])
            oh = max(a[1],b[1])
            nh = max(c[1],d[1])
            delta = d[2]-a[2]

            if p <= min(ol,nl)-2:
                regime = "DOWN"

            elif nl >= ol+2 and nh >= oh+2 and delta >= 3:
                regime = "UP"

            elif nl <= ol-2 and nh <= oh-2 and delta <= -3:
                regime = "DOWN"

            elif (
                abs(nl-ol) <= 3
                and abs(nh-oh) <= 3
                and abs(delta) <= 4
                and max(oh,nh)-min(ol,nl) >= 10
            ):
                regime = "RANGE"

        if d8 <= -6 or d64 <= -8:
            if not panic:
                panic = True
                panic_low = p

            panic_low = min(panic_low,p)

        elif panic:
            panic_low = min(panic_low,p)

            if (
                p-panic_low >= 8
                and d8 >= 2
                and d64 >= 1
                and regime != "DOWN"
            ):
                panic = False

        if panic and position:
            return sell("PANIC",t,p,True)

        if position:
            peak = max(peak,p)
            gain = peak-entry

            if p <= entry-8:
                return sell("STOP",t,p,True)

            if regime == "DOWN" and d64 <= -2:
                return sell("DOWN",t,p,True)

            if gain >= 24:
                stop = max(entry,peak-5)
            elif gain >= 12:
                stop = max(entry,peak-8)
            elif gain >= 8:
                stop = max(entry,peak-12)
            elif gain >= 4:
                stop = max(entry-2,peak-12)
            else:
                stop = entry-8

            if p <= stop:
                return sell("TRAIL",t,p)

            if (
                t-entry_tick >= 256
                and p <= entry
                and d64 <= 0
            ):
                return sell("STALE",t,p)

            return "hold",0

        if panic or t < blocked or len(blocks) < 4:
            return "hold",0

        rebound = p-min(blocks[-1][0],low)
        recent_high = max(blocks[-1][1],blocks[-2][1])

        pullback = (
            3 <= rebound <= 10
            and d8 >= 2
            and d64 >= 1
            and p >= blocks[-1][2]-2
        )

        breakout = (
            p > recent_high
            and prices[t-1] <= recent_high
            and d8 >= 2
            and d64 >= 2
        )

        normal = regime == "UP" and (
            pullback or breakout
        )

        early = (
            regime == "UNKNOWN"
            and blocks[-1][0] >= blocks[-2][0]+1
            and breakout
            and d64 >= 4
        )

        resume = (
            resume_peak is not None
            and t <= resume_until
            and regime in ("UP","UNKNOWN")
            and blocks[-1][0] >= blocks[-2][0]
            and p > resume_peak
            and prices[t-1] <= resume_peak
            and d8 >= 2
            and d64 >= 2
        )

        if normal or early or resume:
            position = pending = True
            resume_peak = None
            return "buy",63

        return "hold",0

    return strategy


# ========================================
# PORTAFOLIO VIRTUAL
# ========================================

class Shadow:

    def __init__(self,strategy):
        self.strategy = strategy
        self.cash = 10000
        self.shares = 0
        self.pending = "hold"

        self.entry = 0
        self.realized = 0
        self.closed = 0

        self.snapshots = deque([10000],maxlen=5)

    def step(self,prices,t):
        p = prices[t]

        if self.pending == "buy":
            self.shares = 32
            self.entry = p
            self.cash -= 32*p+5

        elif self.pending == "sell":
            self.realized += self.shares*(p-self.entry)-10
            self.closed += 1
            self.cash += self.shares*p-5
            self.shares = 0

        equity = self.cash+self.shares*p

        if t > 0 and t % 128 == 0:
            self.snapshots.append(equity)

        score = equity-self.snapshots[0]

        action,_ = self.strategy(prices,t,self)
        self.pending = action

        return action,score


# ========================================
# V24: TRADE QUALITY
# ========================================

def v24(
    merit_trades=1,
    early_failure=False,
    dynamic_trail=False
):

    engines = {
        "P12": Shadow(p12()),
        "V17": Shadow(v17())
    }

    active = None
    pending_exit = None
    pending_buy = False

    buy_cash = 0

    p12_realized = 0
    p12_disabled = False
    qualified = False

    real_entry = real_peak = real_tick = 0

    # Comparacion con salida virtual original
    watch = None

    stats = Counter()

    def strategy(prices,t,pf):
        nonlocal active,pending_exit,pending_buy
        nonlocal buy_cash,p12_realized,p12_disabled
        nonlocal qualified,watch
        nonlocal real_entry,real_peak,real_tick

        p = prices[t]

        shadow = engines["P12"]

        natural_sale = shadow.pending == "sell"

        signals = {}
        scores = {}

        for name,engine in engines.items():
            signals[name],scores[name] = engine.step(
                prices,t
            )

        # Comparar venta anticipada con la
        # posterior venta original de P12.

        if watch is not None and natural_sale:

            reason,early_price,q = watch

            improvement = q*(early_price-p)

            stats["CF_"+reason] += improvement
            stats["MATCHED_"+reason] += 1

            if improvement > 0:
                stats["BETTER_"+reason] += 1

            watch = None

        # CONTABILIDAD REAL

        if pending_exit is not None:

            engine,reason,q = pending_exit
            profit = pf.cash-buy_cash

            stats["PNL_"+engine] += profit
            stats["CLOSED_"+engine] += 1
            stats["EXIT_PNL_"+reason] += profit
            stats["EXIT_COUNT_"+reason] += 1

            if engine == "P12":

                p12_realized += profit

                if p12_realized <= -750:
                    p12_disabled = True

                if reason in ("FAILURE","DYNAMIC"):
                    watch = (reason,p,q)

            pending_exit = None

        if pending_buy:
            pending_buy = False

            if pf.shares == 0:
                stats["UNFILLED"] += 1
                active = None

            else:
                real_entry = real_peak = p
                real_tick = t

        # ACTIVACION POR MERITO ORIGINAL

        if (
            not qualified
            and shadow.closed >= merit_trades
            and shadow.realized >= 128
        ):
            qualified = True

            stats["QUALIFIED"] += 1
            stats["FIRST_ACTIVATION"] = t

        if p12_disabled:
            stats["DISABLED_TICKS"] += 1

        if pf.shares > 0:
            stats["EXPOSURE"] += 1

        # GESTION DE POSICION REAL

        if active is not None:

            real_peak = max(real_peak,p)

            reason = None

            if active == "P12":

                wealth = (
                    pf.cash+pf.shares*p
                    -(5 if pf.shares else 0)
                )

                unrealized = wealth-buy_cash

                # Presupuesto original

                if p12_realized+unrealized <= -750:

                    p12_disabled = True
                    reason = "BUDGET"

            # Prioridad a salida original

            if reason is None and signals[active] == "sell":
                reason = "ORIGINAL_"+active

            # NUEVAS SALIDAS EXCLUSIVAS P12

            if reason is None and active == "P12":

                age = t-real_tick
                gain = real_peak-real_entry
                d8 = p-prices[t-8] if t >= 8 else 0

                # La compra nunca demuestra
                # una recuperacion significativa.

                if (
                    early_failure
                    and age >= 64
                    and gain < 2
                    and p <= real_entry-4
                    and d8 <= 0
                ):
                    reason = "FAILURE"

                # Proteger beneficios acumulados.

                if reason is None and dynamic_trail:

                    if gain >= 24:
                        stop = real_peak-5

                    elif gain >= 12:
                        stop = real_peak-8

                    else:
                        stop = None

                    if stop is not None and p <= stop:
                        reason = "DYNAMIC"

            if reason is not None:

                pending_exit = (
                    active,reason,pf.shares
                )

                active = None

                stats["SELL_"+reason] += 1

                return "sell",63

            return "hold",0

        # SELECCION ORIGINAL

        if (
            qualified
            and not p12_disabled
            and signals["P12"] == "buy"
            and scores["P12"] >= -128
        ):
            chosen = "P12"

        elif signals["V17"] == "buy":
            chosen = "V17"

        else:
            return "hold",0

        active = chosen
        buy_cash = pf.cash
        pending_buy = True

        stats["BUY_"+chosen] += 1

        return "buy",63

    return strategy,stats


def candidate():
    """Frozen V24-T: original shadow engines, dynamic trailing on actual P12."""
    return v24(merit_trades=1, early_failure=False, dynamic_trail=True)
