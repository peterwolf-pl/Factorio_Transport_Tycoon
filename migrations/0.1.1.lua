-- migrations/0.1.1.lua
-- Usuwa stary item kredytowy jeśli istniał
for _, p in pairs(game.players) do
  if p and p.valid and p.get_main_inventory() then
    p.get_main_inventory().remove{name = "sbt-credit-note", count = 1000000}
    p.get_main_inventory().remove{name = "sbt-credit-token", count = 1000000}
  end
end
