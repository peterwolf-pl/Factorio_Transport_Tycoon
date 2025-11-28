-- prototypes/entities.lua
local util = require("util")

local MOD_NAME = "__factorio-transport-tycoon__"

local function icon(path)
  return MOD_NAME .. "/graphics/icons/" .. path
end

-- rover - klon bazowego car z minimalnymi zmianami
local base_car = util.table.deepcopy(data.raw["car"]["car"])
base_car.name = "sbt-cargo-rover"
base_car.icon = icon("rover.png")
base_car.icon_size = 64
base_car.minable = { mining_time = 0.5, result = "sbt-cargo-rover" }
base_car.flags = { "placeable-neutral", "player-creation" }
base_car.inventory_size = 60
base_car.equipment_grid = nil
base_car.guns = {}
base_car.order = "z[sbt]-a[rover]"

-- bug tradepost - pojemnik jak skrzynka z circuit network
local bug_tradepost = {
  type = "container",
  name = "sbt-bug-tradepost",
  icon = icon("credit.png"),
  icon_size = 64,
  flags = { "placeable-neutral", "player-creation" },
  max_health = 400,
  corpse = "small-remnants",
  collision_box = { { -0.7, -0.7 }, { 0.7, 0.7 } },
  selection_box = { { -1.0, -1.0 }, { 1.0, 1.0 } },
  inventory_size = 48,
  enable_inventory_bar = true,
  picture = {
    filename = MOD_NAME .. "/graphics/entity/bug_tradepost.png",
    priority = "high",
    width = 256,
    height = 256,
    scale = 0.5
  },
  open_sound = { filename = "__base__/sound/wooden-chest-open.ogg" },
  close_sound = { filename = "__base__/sound/wooden-chest-close.ogg" },

  -- circuit network
  circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
  circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
  circuit_wire_max_distance = 12
}

-- contract board - kontener z 1 slotem, kontrolowany w control.lua
local contract_board = {
  type = "container",
  name = "sbt-contract-board",
  icon = icon("contract_board.png"),
  icon_size = 64,
  flags = { "placeable-neutral", "player-creation" },
  selectable_in_game = true,
  max_health = 150,
  corpse = "small-remnants",
  collision_box = { { -0.6, -0.3 }, { 0.6, 0.3 } },
  selection_box = { { -2.5, -3.3 }, { 2.5, 1.0 } },
  inventory_size = 1,
  enable_inventory_bar = false,
  picture = {
    filename = MOD_NAME .. "/graphics/entity/contract_board.png",
    priority = "extra-high",
    width = 400,
    height = 600,
    scale = 0.5
  },
  open_sound = { filename = "__base__/sound/wooden-chest-open.ogg" },
  close_sound = { filename = "__base__/sound/wooden-chest-close.ogg" }
}

data:extend({
  base_car,
  bug_tradepost,
  contract_board
})