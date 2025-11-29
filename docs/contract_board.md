# Contract board trade signals

Trading now runs **only** from the circuit network. The contract board and tradepost are automatically linked with a green wire when either is placed; attach your own circuit source (for example a constant combinator) anywhere on that network to steer trades.

## Circuit rules
- Any non-zero **item signal** selects matching offers (`give.name`); the absolute value is used, so `100 iron-plate` and `-100 iron-plate` both request 100 plates.
- The worker compares live signals with the tradepost inventory. If the chest already holds enough of a signaled item to offset the request (e.g., `-100 iron-plate` signal plus 100 plates in the chest), trading pauses until the stock is removed.
- GUI checkboxes are ignored; only the wire filter decides which offers the round-robin worker will execute.
- Ensure the tradepost chest holds the currency listed in the offer cost.

## Wiring tips
- Use the built-in green wire link between the board and tradepost; connect your combinators directly to either end of that network.
- The signal item name must match the **prototype** (`iron-plate`, `steel-plate`, etc.), even on non-English clients.
- Multiple simultaneous item signals are allowed; the round-robin handler walks through each matching offer every second.

If trading does not start, double-check the prototype name and that sufficient currency exists in the tradepost inventory.
