# Contract board trade signals

Trades are processed automatically using the round-robin handler that runs every second. No manual toggle or setting is required to start the exchange cycle.

### Trading without a selected GUI offer
- You can leave every offer unchecked in the GUI; connecting wires and sending item signals is enough.
- Round-robin still runs automatically and will only consider offers whose `give.name` matches the negative item signals.
- At least one negative item signal must be present; otherwise the board falls back to the GUI selection mode.
- Verify the tradepost inventory contains the needed currency for those matching offers.

### Troubleshooting circuit-only trades
- The circuit value **must be negative** (e.g., `-1 steel-plate`). A positive value will not trigger the filter or any trade.
- Wire the signal directly to the **contract board**, not the tradepost chest.
- The signaled item has to match the offer's **internal prototype name** (English `steel-plate`, `iron-plate`, etc.), even on non-English clients.
- Ensure the tradepost has the correct currency items inserted for the matching offer.
- If multiple items are signaled, round-robin will step through each matching offer automatically without extra configuration.

To target specific offers via the circuit network:
- Connect wires directly to the **contract board** entity.
- Send **negative item signals** (`count < 0`) matching the internal item prototype name of the offered item (e.g., `iron-plate`).
- When signals are present, GUI toggles are ignored and only offers that match the signaled item names are eligible for processing.

If trading does not start, verify that the signal uses the exact prototype name and that the tradepost inventory contains the required currency for the selected offer.
