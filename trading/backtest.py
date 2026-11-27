import csv
from pathlib import Path

INITIAL_CASH = 10000
COMMISSION = 5
MAX_ORDER = 63
DATA_PATH = Path("sim/data/practica_meta.csv")


def load_prices(path):
    with open(path, newline="") as file:
        reader = csv.reader(file)
        next(reader)
        return [int(row[1]) for row in reader if row]


def hold(history, cash, shares):
    return 0, 0


def buy_and_hold(history, cash, shares):
    if len(history) == 1:
        return 1, MAX_ORDER
    return 0, 0


def momentum(history, cash, shares):
    if len(history) < 9:
        return 0, 0

    change = history[-1] - history[-9]

    if change >= 3:
        return 1, MAX_ORDER

    if change <= -3:
        return 2, MAX_ORDER

    return 0, 0


def mean_reversion(history, cash, shares):
    if len(history) < 16:
        return 0, 0

    current = history[-1]
    average = sum(history[-16:]) // 16

    if current <= average - 3:
        return 1, MAX_ORDER

    if current >= average + 3:
        return 2, MAX_ORDER

    return 0, 0


def moving_average(history, cash, shares):
    if len(history) < 16:
        return 0, 0

    fast = sum(history[-4:])
    slow = sum(history[-16:])

    if fast * 4 > slow + 16:
        return 1, MAX_ORDER

    if fast * 4 < slow - 16:
        return 2, MAX_ORDER

    return 0, 0


def backtest(prices, strategy):
    cash = INITIAL_CASH
    shares = 0
    orders = 0
    commissions = 0

    peak = INITIAL_CASH
    max_drawdown = 0

    history = []
    pending_action = 0
    pending_quantity = 0

    for price in prices:
        action = pending_action
        quantity = pending_quantity

        if action == 1:
            quantity = min(
                quantity,
                MAX_ORDER,
                max(0, (cash - COMMISSION) // price)
            )

            if quantity > 0:
                cash -= quantity * price + COMMISSION
                shares += quantity
                orders += 1
                commissions += COMMISSION

        elif action == 2:
            quantity = min(quantity, MAX_ORDER, shares)

            if quantity > 0:
                cash += quantity * price - COMMISSION
                shares -= quantity
                orders += 1
                commissions += COMMISSION

        wealth = cash + shares * price
        peak = max(peak, wealth)
        max_drawdown = max(
            max_drawdown,
            (peak - wealth) / peak
        )

        history.append(price)

        pending_action, pending_quantity = strategy(
            history, cash, shares
        )

    return {
        "wealth": wealth,
        "orders": orders,
        "commissions": commissions,
        "drawdown": max_drawdown * 100,
    }


def main():
    prices = load_prices(DATA_PATH)

    strategies = {
        "No operar": hold,
        "Comprar y mantener": buy_and_hold,
        "Momentum": momentum,
        "Reversion a la media": mean_reversion,
        "Medias moviles": moving_average,
    }

    print(f"\nPrecios cargados: {len(prices)}")
    print(f"Precio inicial: {prices[0]}")
    print(f"Precio final: {prices[-1]}\n")

    print(
        f"{'Estrategia':<24}"
        f"{'Patrimonio':>12}"
        f"{'Ordenes':>10}"
        f"{'Comisiones':>12}"
        f"{'Drawdown':>12}"
    )

    print("-" * 70)

    for name, strategy in strategies.items():
        result = backtest(prices, strategy)

        print(
            f"{name:<24}"
            f"{result['wealth']:>12}"
            f"{result['orders']:>10}"
            f"{result['commissions']:>12}"
            f"{result['drawdown']:>11.2f}%"
        )


if __name__ == "__main__":
    main()
