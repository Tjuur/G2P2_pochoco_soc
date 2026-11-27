import csv
import sys
from dataclasses import dataclass


INITIAL_CASH = 10000
COMMISSION = 5
MAX_ORDER = 63


@dataclass
class Portfolio:
    cash: int = INITIAL_CASH
    shares: int = 0
    entry_price: int = 0
    entry_tick: int = 0
    orders: int = 0
    commissions: int = 0


def load_prices(path):
    with open(path, newline="") as f:
        prices = [int(row["price"]) for row in csv.DictReader(f)]

    if not prices or any(not 1 <= p <= 255 for p in prices):
        raise ValueError("Precios inválidos")

    return prices


def simulate(prices, strategy):
    portfolio = Portfolio()

    pending_action = "hold"
    pending_quantity = 0

    peak = INITIAL_CASH
    max_drawdown = 0
    max_drawdown_pct = 0

    trades = []

    for tick, price in enumerate(prices):

        # Ejecutar decisión del tick anterior.
        if pending_action == "buy":
            affordable = max(
                0,
                (portfolio.cash - COMMISSION) // price
            )

            quantity = min(
                pending_quantity,
                MAX_ORDER,
                affordable
            )

            if quantity > 0:
                previous_shares = portfolio.shares

                portfolio.cash -= quantity * price + COMMISSION
                portfolio.shares += quantity

                if previous_shares == 0:
                    portfolio.entry_price = price
                    portfolio.entry_tick = tick

                portfolio.orders += 1
                portfolio.commissions += COMMISSION

                trades.append((tick, "BUY", price, quantity))

        elif pending_action == "sell":
            quantity = min(
                pending_quantity,
                MAX_ORDER,
                portfolio.shares
            )

            if quantity > 0:
                portfolio.cash += quantity * price - COMMISSION
                portfolio.shares -= quantity

                portfolio.orders += 1
                portfolio.commissions += COMMISSION

                trades.append((tick, "SELL", price, quantity))

                if portfolio.shares == 0:
                    portfolio.entry_price = 0
                    portfolio.entry_tick = 0

        wealth = portfolio.cash + portfolio.shares * price

        peak = max(peak, wealth)

        drawdown = peak - wealth
        drawdown_pct = 100 * drawdown / peak

        max_drawdown = max(max_drawdown, drawdown)
        max_drawdown_pct = max(max_drawdown_pct, drawdown_pct)

        # Calcular siguiente decisión.
        pending_action, pending_quantity = strategy(
            prices,
            tick,
            portfolio
        )

    final_wealth = (
        portfolio.cash
        + portfolio.shares * prices[-1]
    )

    return {
        "wealth": final_wealth,
        "return": 100 * (final_wealth / INITIAL_CASH - 1),
        "orders": portfolio.orders,
        "commissions": portfolio.commissions,
        "drawdown": max_drawdown,
        "drawdown_pct": max_drawdown_pct,
        "shares": portfolio.shares,
        "trades": trades,
    }


def original(prices, tick, portfolio):
    if tick < 8:
        return "hold", 0

    delta = prices[tick] - prices[tick - 8]

    if portfolio.shares == 0 and delta <= -4:
        return "buy", 63

    if portfolio.shares > 0 and delta >= 4:
        return "sell", 63

    return "hold", 0


def pochoco_21(max_hold=64, min_profit=2):

    def strategy(prices, tick, portfolio):
        if tick < 8:
            return "hold", 0

        price = prices[tick]
        delta = price - prices[tick - 8]

        if portfolio.shares == 0:
            if delta <= -4:
                return "buy", 63

        else:
            profitable_exit = (
                delta >= 4
                and price >= portfolio.entry_price + min_profit
            )

            timed_exit = (
                tick - portfolio.entry_tick >= max_hold
                and delta >= 4
            )

            if profitable_exit or timed_exit:
                return "sell", 63

        return "hold", 0

    return strategy



def pochoco_22(stop_loss=16, max_hold=64, min_profit=2):

    def strategy(prices, tick, portfolio):
        if tick < 8:
            return "hold", 0

        price = prices[tick]
        delta = price - prices[tick - 8]

        if portfolio.shares == 0:
            if delta <= -4:
                return "buy", 63

        else:
            profitable_exit = (
                delta >= 4
                and price >= portfolio.entry_price + min_profit
            )

            timed_exit = (
                tick - portfolio.entry_tick >= max_hold
                and delta >= 4
            )

            emergency_exit = (
                price <= portfolio.entry_price - stop_loss
            )

            if profitable_exit or timed_exit or emergency_exit:
                return "sell", 63

        return "hold", 0

    return strategy



def pochoco_23(stop_loss=24, cooldown=64, max_hold=64, min_profit=2):
    blocked_until = 0

    def strategy(prices, tick, portfolio):
        nonlocal blocked_until

        if tick < 8:
            return "hold", 0

        price = prices[tick]
        delta = price - prices[tick - 8]

        if portfolio.shares == 0:
            if tick < blocked_until:
                return "hold", 0

            if delta <= -4:
                return "buy", 63

        else:
            profitable_exit = (
                delta >= 4
                and price >= portfolio.entry_price + min_profit
            )

            timed_exit = (
                tick - portfolio.entry_tick >= max_hold
                and delta >= 4
            )

            emergency_exit = (
                price <= portfolio.entry_price - stop_loss
            )

            if emergency_exit:
                blocked_until = tick + cooldown
                return "sell", 63

            if profitable_exit or timed_exit:
                return "sell", 63

        return "hold", 0

    return strategy



def pochoco_espino(stop_loss=24, cooldown=16, max_hold=64, min_profit=2):
    position = False
    entry_price = 0
    entry_tick = 0
    blocked_until = 0

    def strategy(prices, tick, portfolio):
        nonlocal position, entry_price, entry_tick, blocked_until

        if tick < 8:
            return "hold", 0

        price = prices[tick]
        delta = price - prices[tick - 8]

        if not position:
            if tick < blocked_until:
                return "hold", 0

            if delta <= -4:
                position = True
                entry_price = price
                entry_tick = tick
                return "buy", 63

        else:
            profitable_exit = (
                delta >= 4
                and price >= entry_price + min_profit
            )

            timed_exit = (
                tick - entry_tick >= max_hold
                and delta >= 4
            )

            emergency_exit = (
                price <= entry_price - stop_loss
            )

            if emergency_exit:
                position = False
                blocked_until = tick + cooldown
                return "sell", 63

            if profitable_exit or timed_exit:
                position = False
                return "sell", 63

        return "hold", 0

    return strategy



def pochoco_espino_v2(stop_loss=24, cooldown=16, max_hold=64, min_profit=2):
    position = False
    entry_price = 0
    entry_tick = 0
    blocked_until = 0
    pending_buy = False

    def strategy(prices, tick, portfolio):
        nonlocal position, entry_price, entry_tick
        nonlocal blocked_until, pending_buy

        price = prices[tick]

        # La compra solicitada anteriormente se ejecuta
        # al comienzo de este tick.
        if pending_buy:
            entry_price = price
            entry_tick = tick
            pending_buy = False

        if tick < 8:
            return "hold", 0

        delta = price - prices[tick - 8]

        if not position:
            if tick < blocked_until:
                return "hold", 0

            if delta <= -4:
                position = True
                pending_buy = True
                return "buy", 63

        else:
            profitable_exit = (
                delta >= 4
                and price >= entry_price + min_profit
            )

            timed_exit = (
                tick - entry_tick >= max_hold
                and delta >= 4
            )

            emergency_exit = (
                price <= entry_price - stop_loss
            )

            if emergency_exit:
                position = False
                blocked_until = tick + cooldown
                return "sell", 63

            if profitable_exit or timed_exit:
                position = False
                return "sell", 63

        return "hold", 0

    return strategy


def main():
    path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else "sim/data/practica_meta.csv"
    )

    prices = load_prices(path)

    strategies = {
        "Original V2": original,
        "Pochoco 2.1 (32)": pochoco_21(32),
        "Pochoco 2.1 (64)": pochoco_21(64),
        "Pochoco 2.1 (128)": pochoco_21(128),
        "Pochoco 2.2 SL8": pochoco_22(8),
        "Pochoco 2.2 SL16": pochoco_22(16),
        "Pochoco 2.2 SL24": pochoco_22(24),
        "Pochoco 2.2 SL32": pochoco_22(32),
        "Pochoco 2.3 CD16": pochoco_23(cooldown=16),
        "Pochoco 2.3 CD32": pochoco_23(cooldown=32),
        "Pochoco 2.3 CD64": pochoco_23(cooldown=64),
        "Pochoco 2.3 CD128": pochoco_23(cooldown=128),
        "Espino CD16": pochoco_espino(cooldown=16),
        "Espino CD32": pochoco_espino(cooldown=32),
        "Espino V2 CD16": pochoco_espino_v2(cooldown=16),
        "Espino V2 CD32": pochoco_espino_v2(cooldown=32),
    }

    print(f"\nSerie: {path}")
    print(f"Ticks: {len(prices)}\n")

    print(
        f"{'Estrategia':<22}"
        f"{'Patrimonio':>12}"
        f"{'Retorno':>11}"
        f"{'Ordenes':>9}"
        f"{'DD %':>10}"
    )

    print("-" * 64)

    for name, strategy in strategies.items():
        r = simulate(prices, strategy)

        print(
            f"{name:<22}"
            f"${r['wealth']:>11,.0f}"
            f"{r['return']:>10.2f}%"
            f"{r['orders']:>9}"
            f"{r['drawdown_pct']:>9.2f}%"
        )


if __name__ == "__main__":
    main()
