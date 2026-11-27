import csv
import math
from pathlib import Path

OUTPUT = Path("sim/data/scenarios")
OUTPUT.mkdir(parents=True, exist_ok=True)

N = 2000


def clamp(value):
    return max(1, min(255, round(value)))


def save(name, prices):
    path = OUTPUT / f"{name}.csv"

    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["tick", "price"])

        for tick, price in enumerate(prices):
            writer.writerow([tick, clamp(price)])

    print(f"Generado: {path}")


# 1. Crash rápido sin recuperación.
prices = []

for t in range(N):
    if t < 500:
        price = 180
    elif t < 520:
        price = 180 - 100 * (t - 500) / 20
    else:
        price = 80

    prices.append(price)

save("crash_rapido", prices)


# 2. Crash seguido de recuperación parcial.
prices = []

for t in range(N):
    if t < 500:
        price = 180
    elif t < 520:
        price = 180 - 100 * (t - 500) / 20
    elif t < 700:
        price = 80 + 60 * (t - 520) / 180
    else:
        price = 140

    prices.append(price)

save("crash_rebote", prices)


# 3. Caídas escalonadas.
prices = []

for t in range(N):
    if t < 400:
        price = 200
    elif t < 450:
        price = 200 - 40 * (t - 400) / 50
    elif t < 600:
        price = 160 + 10 * (t - 450) / 150
    elif t < 650:
        price = 170 - 60 * (t - 600) / 50
    elif t < 800:
        price = 110 + 10 * (t - 650) / 150
    elif t < 850:
        price = 120 - 50 * (t - 800) / 50
    else:
        price = 70

    prices.append(price)

save("caidas_escalonadas", prices)


# 4. Mercado lateral interrumpido por crash.
prices = []

for t in range(N):
    base = 160 + 12 * math.sin(t / 15)

    if t < 900:
        price = base
    elif t < 920:
        price = base - 80 * (t - 900) / 20
    else:
        price = base - 80

    prices.append(price)

save("lateral_crash", prices)
