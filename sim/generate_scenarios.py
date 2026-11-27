import csv
import math
import random
from pathlib import Path

random.seed(42)

OUTPUT = Path("sim/data/scenarios")
OUTPUT.mkdir(parents=True, exist_ok=True)

N = 2000


def save(name, prices):
    path = OUTPUT / f"{name}.csv"

    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["tick", "price"])

        for tick, price in enumerate(prices):
            writer.writerow([tick, max(1, min(255, round(price)))])

    print(f"Generado: {path}")


# 1. Caída sostenida
save(
    "caida",
    [
        220 - 150 * t / (N - 1)
        for t in range(N)
    ]
)

# 2. Subida sostenida
save(
    "subida",
    [
        50 + 150 * t / (N - 1)
        for t in range(N)
    ]
)

# 3. Mercado lateral
save(
    "lateral",
    [
        150 + 12 * math.sin(t / 15)
        for t in range(N)
    ]
)

# 4. Crash y recuperación
save(
    "crash_recuperacion",
    [
        200 - 130 * t / 1000
        if t < 1000
        else 70 + 130 * (t - 1000) / 999
        for t in range(N)
    ]
)

# 5. Alta volatilidad
price = 150
volatile = []

for _ in range(N):
    price += random.randint(-8, 8)
    price = max(20, min(240, price))
    volatile.append(price)

save("volatilidad", volatile)
