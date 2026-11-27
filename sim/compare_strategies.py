import sys

from backtest_v2 import (
    load_prices,
    simulate,
    pochoco_23,
    pochoco_espino,
)


def compare(path, cooldown=16):
    prices = load_prices(path)

    a = simulate(
        prices,
        pochoco_23(cooldown=cooldown)
    )

    b = simulate(
        prices,
        pochoco_espino(cooldown=cooldown)
    )

    print(f"\nArchivo: {path}")
    print(f"Cooldown: {cooldown}\n")

    print("Pochoco 2.3:")
    print(f"  Patrimonio: ${a['wealth']:,}")
    print(f"  Órdenes: {a['orders']}")

    print("\nEspino:")
    print(f"  Patrimonio: ${b['wealth']:,}")
    print(f"  Órdenes: {b['orders']}")

    print("\nPrimeras diferencias entre operaciones:\n")

    trades_a = a["trades"]
    trades_b = b["trades"]

    differences = 0

    for i in range(max(len(trades_a), len(trades_b))):
        ta = trades_a[i] if i < len(trades_a) else None
        tb = trades_b[i] if i < len(trades_b) else None

        if ta != tb:
            print(f"Operación #{i + 1}")
            print(f"  Pochoco 2.3: {ta}")
            print(f"  Espino:      {tb}")
            print()

            differences += 1

            if differences >= 10:
                break

    if differences == 0:
        print("Las operaciones ejecutadas son idénticas.")


if __name__ == "__main__":
    path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else "sim/data/practica_meta.csv"
    )

    cooldown = (
        int(sys.argv[2])
        if len(sys.argv) > 2
        else 16
    )

    compare(path, cooldown)
