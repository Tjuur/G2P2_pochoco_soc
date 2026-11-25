import csv
import sys

INITIAL_CASH = 10000
COMMISSION = 5
MAX_ORDER = 63


def load_prices(path):
    with open(path, newline="") as f:
        prices = [int(row["price"]) for row in csv.DictReader(f)]

    if not prices or any(not 1 <= p <= 255 for p in prices):
        raise ValueError("La serie debe contener precios entre 1 y 255")

    return prices


def simulate(prices, strategy):
    cash = INITIAL_CASH
    shares = 0
    orders = 0
    commissions = 0
    peak = INITIAL_CASH
    max_drawdown = 0
    trades = []

    # La orden escrita después de un tick se ejecuta en el siguiente.
    pending_action = "hold"
    pending_quantity = 0

    for tick, price in enumerate(prices):

        # 1. El Master ejecuta la decisión anterior.
        if pending_action == "buy":
            quantity = min(
                pending_quantity,
                max(0, (cash - COMMISSION) // price)
            )

            if quantity > 0:
                cash -= quantity * price + COMMISSION
                shares += quantity
                orders += 1
                commissions += COMMISSION
                trades.append((tick, "BUY", price, quantity, cash, shares))

        elif pending_action == "sell":
            quantity = min(pending_quantity, shares)

            if quantity > 0:
                cash += quantity * price - COMMISSION
                shares -= quantity
                orders += 1
                commissions += COMMISSION
                trades.append((tick, "SELL", price, quantity, cash, shares))

        wealth = cash + shares * price
        peak = max(peak, wealth)
        max_drawdown = max(max_drawdown, peak - wealth)

        # 2. Espino recibe el precio y calcula la siguiente decisión.
        pending_action, pending_quantity = strategy(prices, tick)

    final_wealth = cash + shares * prices[-1]

    return {
        "wealth": final_wealth,
        "return": 100 * (final_wealth / INITIAL_CASH - 1),
        "orders": orders,
        "commissions": commissions,
        "drawdown": max_drawdown,
        "shares": shares,
        "trades": trades,
    }


def hold(prices, tick):
    return "hold", 0


def buy_and_hold(prices, tick):
    if tick == 0:
        return "buy", 63
    return "hold", 0


def original():
    # Reproduce el registro x9 del firmware original.
    position = False

    def strategy(prices, tick):
        nonlocal position

        if tick < 8:
            return "hold", 0

        delta = prices[tick] - prices[tick - 8]

        if not position and delta <= -4:
            position = True
            return "buy", 63

        if position and delta >= 4:
            position = False
            return "sell", 63

        return "hold", 0

    return strategy



def hybrid(quantity=30, stop_loss=8):
    position = False
    entry_price = 0

    def strategy(prices, tick):
        nonlocal position, entry_price

        if tick < 16:
            return "hold", 0

        price = prices[tick]

        short_momentum = price - prices[tick - 4]
        long_momentum = price - prices[tick - 16]

        if position:
            loss = entry_price - price

            if loss >= stop_loss or short_momentum <= -2:
                position = False
                return "sell", quantity

        else:
            if short_momentum >= 2 and long_momentum >= 4:
                position = True
                entry_price = price
                return "buy", quantity

        return "hold", 0

    return strategy



def protected_reversion(quantity=63, stop_loss=10, trend_limit=12):
    position = False
    entry_price = 0

    def strategy(prices, tick):
        nonlocal position, entry_price

        if tick < 32:
            return "hold", 0

        price = prices[tick]

        delta_short = price - prices[tick - 8]
        delta_long = price - prices[tick - 32]

        if position:
            if delta_short >= 4 or price <= entry_price - stop_loss:
                position = False
                return "sell", quantity

        else:
            if delta_short <= -4 and delta_long > -trend_limit:
                position = True
                entry_price = price
                return "buy", quantity

        return "hold", 0

    return strategy



def reversion_profit(quantity=63, min_profit=2):
    position = False
    entry_price = 0

    def strategy(prices, tick):
        nonlocal position, entry_price

        if tick < 8:
            return "hold", 0

        price = prices[tick]
        delta = price - prices[tick - 8]

        if not position:
            if delta <= -4:
                position = True
                entry_price = price
                return "buy", quantity

        else:
            if delta >= 4 and price >= entry_price + min_profit:
                position = False
                return "sell", quantity

        return "hold", 0

    return strategy



def reversion_timed(quantity=63, min_profit=2, max_hold=64):
    position = False
    entry_price = 0
    entry_tick = 0

    def strategy(prices, tick):
        nonlocal position, entry_price, entry_tick

        if tick < 8:
            return "hold", 0

        price = prices[tick]
        delta = price - prices[tick - 8]

        if not position:
            if delta <= -4:
                position = True
                entry_price = price
                entry_tick = tick
                return "buy", quantity

        else:
            profitable_exit = (
                delta >= 4
                and price >= entry_price + min_profit
            )

            timed_exit = (
                tick - entry_tick >= max_hold
                and delta >= 4
            )

            if profitable_exit or timed_exit:
                position = False
                return "sell", quantity

        return "hold", 0

    return strategy


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "sim/data/practica_meta.csv"
    prices = load_prices(path)

    strategies = {
        "No operar": hold,
        "Comprar y mantener": buy_and_hold,
        "Pochoco original": original(),
        "Hibrido 15": hybrid(15),
        "Hibrido 30": hybrid(30),
        "Hibrido 63": hybrid(63),
        "Reversion protegida": protected_reversion(),
        "Pochoco 2.0": reversion_profit(),
        "Pochoco 2.1 (32)": reversion_timed(max_hold=32),
        "Pochoco 2.1 (64)": reversion_timed(max_hold=64),
        "Pochoco 2.1 (128)": reversion_timed(max_hold=128),
    }

    print(f"\nSerie: {len(prices)} ticks")
    print(f"Precio inicial: ${prices[0]}")
    print(f"Precio final:   ${prices[-1]}\n")

    print(
        f"{'Estrategia':<22}"
        f"{'Patrimonio':>12}"
        f"{'Retorno':>12}"
        f"{'Ordenes':>10}"
        f"{'Comisiones':>13}"
        f"{'Drawdown':>12}"
    )

    print("-" * 81)

    for name, strategy in strategies.items():
        r = simulate(prices, strategy)

        print(
            f"{name:<22}"
            f"${r['wealth']:>11,.0f}"
            f"{r['return']:>11.2f}%"
            f"{r['orders']:>10}"
            f"${r['commissions']:>12}"
            f"${r['drawdown']:>11}"
        )


if __name__ == "__main__":
    main()
