for _,p in pairs(game.players) do
  global.players = global.players or {}
  global.players[p.index] = global.players[p.index] or { credits=0 }
end
