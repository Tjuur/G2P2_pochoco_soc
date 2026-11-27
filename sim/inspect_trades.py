import sys
from backtest import load_prices, simulate, original

path = sys.argv[1] if len(sys.argv) > 1 else "sim/data/scenarios/lateral.csv"

prices = load_prices(path)
result = simulate(prices, original())

print(f"\nSerie: {path}")
print(f"Patrimonio final: ${result['wealth']:,.0f}")
print(f"Órdenes ejecutadas: {result['orders']}\n")

print(f"{'Tick':>6} {'Acción':>8} {'Precio':>8} {'Cantidad':>10} {'Efectivo':>12} {'Acciones':>10}")
print("-" * 65)

for tick, action, price, quantity, cash, shares in result["trades"][:40]:
    print(
        f"{tick:>6} {action:>8} ${price:>7}"
        f"{quantity:>10} ${cash:>11,.0f} {shares:>10}"
    )
