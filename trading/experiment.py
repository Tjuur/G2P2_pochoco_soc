from itertools import product
from backtest import load_prices, backtest, DATA_PATH


def strategy_factory(window, threshold, quantity):

    def strategy(history, cash, shares):
        if len(history) < window + 1:
            return 0, 0

        current = history[-1]
        previous = history[-2]

        average = sum(history[-window:]) // window

        recovering = current > previous
        falling = current < previous

        if current <= average - threshold and recovering:
            return 1, quantity

        if current >= average + threshold and falling:
            return 2, quantity

        return 0, 0

    return strategy


def main():
    prices = load_prices(DATA_PATH)

    train = prices[:10000]
    test = prices[10000:]

    results = []

    for window, threshold, quantity in product(
        [8, 16, 32],
        [2, 4, 6, 8],
        [10, 20, 40, 63]
    ):
        strategy = strategy_factory(
            window, threshold, quantity
        )

        train_result = backtest(train, strategy)
        test_result = backtest(test, strategy)

        results.append({
            "window": window,
            "threshold": threshold,
            "quantity": quantity,
            "train": train_result["wealth"],
            "test": test_result["wealth"],
            "orders": test_result["orders"],
            "drawdown": test_result["drawdown"],
        })

    results.sort(
        key=lambda x: x["train"],
        reverse=True
    )

    print("\nTOP 10 CONFIGURACIONES SEGUN ENTRENAMIENTO\n")

    print(
        f"{'Ventana':>8}"
        f"{'Umbral':>9}"
        f"{'Cantidad':>10}"
        f"{'Train':>12}"
        f"{'Test':>12}"
        f"{'Ordenes':>10}"
        f"{'Drawdown':>12}"
    )

    print("-" * 73)

    for r in results[:10]:
        print(
            f"{r['window']:>8}"
            f"{r['threshold']:>9}"
            f"{r['quantity']:>10}"
            f"{r['train']:>12}"
            f"{r['test']:>12}"
            f"{r['orders']:>10}"
            f"{r['drawdown']:>11.2f}%"
        )


if __name__ == "__main__":
    main()
