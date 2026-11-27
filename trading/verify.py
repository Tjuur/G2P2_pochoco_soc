import csv
from pathlib import Path

PRICE_FILE = Path("sim/data/practica_meta.csv")
DECISION_FILE = Path("decisiones.csv")


def load_prices():
    with PRICE_FILE.open(newline="") as file:
        reader = csv.DictReader(file)
        return [int(row["price"]) for row in reader]


def generated_decisions(prices):
    history = [0] * 8
    index = 0
    count = 0
    position = 0

    generated = []

    for price in prices:
        old_price = history[index]
        history[index] = price
        index = (index + 1) & 7

        decision = 0

        if count >= 8:
            change = price - old_price

            if position == 0 and change <= -4:
                decision = 0x7F
                position = 1

            elif position == 1 and change >= 4:
                decision = 0xBF
                position = 0
        else:
            count += 1

        generated.append(decision)

    return generated


def main():
    prices = load_prices()

    with DECISION_FILE.open(newline="") as file:
        rows = list(csv.DictReader(file))

    generated = generated_decisions(prices)

    expected = [0] + generated[:-1]

    mismatches = []

    for tick, row in enumerate(rows):
        actual = int(row["decision"], 16)

        if actual != expected[tick]:
            mismatches.append(
                (tick, actual, expected[tick])
            )

    print(f"Ticks comparados: {len(rows)}")
    print(f"Diferencias: {len(mismatches)}")

    for tick, actual, expected_value in mismatches[:20]:
        print(
            f"Tick {tick}: "
            f"Espino=0x{actual:02X}, "
            f"Python=0x{expected_value:02X}"
        )

    if not mismatches:
        print("PASS: Python y Espino coinciden")
    else:
        print("FAIL: Existen diferencias")


if __name__ == "__main__":
    main()
