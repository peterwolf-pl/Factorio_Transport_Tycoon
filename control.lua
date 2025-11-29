-- control.lua

local util = require("util")

-- constants
local BUG_FORCE      = "bugs-trade"
local BOARD_NAME     = "sbt-contract-board"
local TRADEPOST_NAME = "sbt-bug-tradepost"

-- board icon area inside selection_box
local BOARD_SEL_BOX = { left = -2.5, top = -3.3, right = 2.5, bottom = 1.0 }
local BOARD_MARGIN  = 0.35

-- sprite sizing
local ITEM_BASE_PX = 64
local PX_PER_TILE  = 32

-- forward declarations
local clear_board_icons
local draw_board_icons
local refresh_board_icons
local connect_colony_circuit
local get_colony_offers
local find_colony_by_tradepost
local find_colony_by_board
local create_or_get_colony_from_board
local open_trade_gui

-------------------------------------------------
-- helpers: nazwy kolonii
-------------------------------------------------

local function make_colony_name(kind, mode)
  if mode == "exchange_choc_to_alc" then return "Kantor Czekolada na Alkohol" end
  if mode == "exchange_alc_to_choc" then return "Kantor Alkohol na Czekolade" end
  if kind == "metal"      then return "Kolonia Metali" end
  if kind == "components" then return "Kolonia Komponentow" end
  if kind == "engines"    then return "Kolonia Silnikow" end
  if kind == "science"    then return "Kolonia Nauki" end
  return "Kolonia Handlowa"
end

local function get_colony_name(colony)
  local n = colony and colony.name or nil
  if type(n) == "string" then return n end
  return make_colony_name(colony.kind or "generic", colony.mode or "normal")
end

-------------------------------------------------
-- storage init i migracja
-------------------------------------------------

-------------------------------------------------
-- circuit network
-- sterowanie tylko z contract board
-------------------------------------------------

local function connect_colony_circuit(colony)
  if not (colony and colony.tradepost and colony.tradepost.valid and colony.board_entity and colony.board_entity.valid) then return end
  local connector_id = defines and defines.circuit_connector_id and defines.circuit_connector_id.container
  if not connector_id then return end

  pcall(function()
    colony.tradepost.connect_neighbour{
      wire = defines.wire_type.green,
      target_entity = colony.board_entity,
      source_circuit_id = connector_id,
      target_circuit_id = connector_id
    }
  end)
end

local function rebuild_entity_index()
  storage.entity_to_colony = {}
  for id, c in pairs(storage.colonies or {}) do
    if c.tradepost and c.tradepost.valid and c.tradepost.unit_number then
      storage.entity_to_colony[c.tradepost.unit_number] = id
    end
    if c.board_entity and c.board_entity.valid and c.board_entity.unit_number then
      storage.entity_to_colony[c.board_entity.unit_number] = id
    end
  end
end

local function migrate_colonies()
  if not storage.colonies then return end

  for _, c in pairs(storage.colonies) do
    if c.entity and not c.tradepost then
      if c.entity.valid then c.tradepost = c.entity end
      c.entity = nil
    end

    if c.tradepost and c.tradepost.valid then
      c.pos = c.pos or { x = c.tradepost.position.x, y = c.tradepost.position.y }
      c.surface_index = c.surface_index or c.tradepost.surface.index
    end

    c.enabled  = c.enabled  or {}
    c.partial  = c.partial  or {}
    c.rr_index = c.rr_index or 1
    c.active_requests = c.active_requests or nil
    c.active_request_tick = c.active_request_tick or nil

    if type(c.name) ~= "string" then
      c.name = make_colony_name(c.kind or "generic", c.mode or "normal")
    end

    connect_colony_circuit(c)
  end

  rebuild_entity_index()
end

local function build_item_caches()
  storage.intermediate_items = {
    "iron-ore",
    "copper-ore",
    "iron-plate",
    "copper-plate",
    "steel-plate",
    "stone",
    "coal",
    "iron-gear-wheel",
    "electronic-circuit",
    "advanced-circuit",
    "processing-unit",
    "battery",
    "low-density-structure",
    "engine-unit",
    "electric-engine-unit"
  }

  storage.science_items = {
    "automation-science-pack",
    "logistic-science-pack",
    "military-science-pack",
    "chemical-science-pack",
    "production-science-pack",
    "utility-science-pack",
    "space-science-pack"
  }
end

local function init_storage()
  storage.players           = storage.players           or {}
  storage.colonies          = storage.colonies          or {}
  storage.next_colony_id    = storage.next_colony_id    or 1
  storage.board_render_objs = storage.board_render_objs or {}
  storage.saved_offers      = storage.saved_offers      or {}

  migrate_colonies()
  build_item_caches()
end

-------------------------------------------------
-- force robali
-------------------------------------------------

local function ensure_bug_force()
  if not game.forces[BUG_FORCE] then
    game.create_force(BUG_FORCE)
  end
  local force = game.forces[BUG_FORCE]

  if game.forces.player then
    game.forces.player.set_friend(BUG_FORCE, true)
    force.set_friend(game.forces.player, true)
  end
end

-------------------------------------------------
-- settings dla wymiany
-------------------------------------------------

local function get_exchange_values()
  local g = settings.global
  local choc_to_alc_input  = (g["ftt-exchange-choc-to-alc-input"]  and g["ftt-exchange-choc-to-alc-input"].value)  or 10
  local choc_to_alc_output = (g["ftt-exchange-choc-to-alc-output"] and g["ftt-exchange-choc-to-alc-output"].value) or 100
  local alc_to_choc_input  = (g["ftt-exchange-alc-to-choc-input"]  and g["ftt-exchange-alc-to-choc-input"].value)  or 10
  local alc_to_choc_output = (g["ftt-exchange-alc-to-choc-output"] and g["ftt-exchange-alc-to-choc-output"].value) or 100
  return {
    choc_to_alc_input   = choc_to_alc_input,
    choc_to_alc_output  = choc_to_alc_output,
    alc_to_choc_input   = alc_to_choc_input,
    alc_to_choc_output  = alc_to_choc_output
  }
end

local function get_offer_generosity()
  local g = settings.global
  local s = g["ftt-offer-generosity"]
  if not s then return 1.0 end
  local v = s.value or 3
  return math.max(1, math.min(10, v))
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if e.setting_type ~= "runtime-global" then return end
  if not e.setting:match("^ftt%-") then return end
end)

-------------------------------------------------
-- item pool dla kolonii
-------------------------------------------------

local function get_item_pool_for_colony(colony)
  local kind = colony.kind or "generic"
  if kind == "science" then
    return storage.science_items or {}
  end
  return storage.intermediate_items or {}
end

-------------------------------------------------
-- generowanie ofert (normalnych)
-------------------------------------------------

local function build_random_offers_for_normal_colony(colony)
  local offers = {}
  local pool = get_item_pool_for_colony(colony)
  if not pool or #pool == 0 then return offers end

  local currency = colony.currency or "sbt-alcohol"
  local generosity = get_offer_generosity()

  for _, item in ipairs(pool) do
    local base_amount = math.max(1, math.floor(50 * (0.5 + math.random() * 2.0)))
    base_amount = math.min(base_amount, 400)

    local cost_count = math.max(1, math.floor(base_amount / (generosity * 1.2)))

    table.insert(offers, {
      give = { name = item, count = base_amount },
      cost = { { name = currency, count = cost_count } }
    })
  end

  return offers
end

-------------------------------------------------
-- oferty z sejfem i trybami wymiany
-------------------------------------------------

get_colony_offers = function(colony)
  local mode = colony.mode or "normal"

  if mode == "exchange_choc_to_alc" then
    local ex = get_exchange_values()
    return {
      {
        give = { name = "sbt-alcohol", count = ex.choc_to_alc_output },
        cost = { { name = "sbt-chocolate", count = ex.choc_to_alc_input } }
      }
    }
  end

  if mode == "exchange_alc_to_choc" then
    local ex = get_exchange_values()
    return {
      {
        give = { name = "sbt-chocolate", count = ex.alc_to_choc_output },
        cost = { { name = "sbt-alcohol", count = ex.alc_to_choc_input } }
      }
    }
  end

  storage.saved_offers = storage.saved_offers or {}

  local pool = get_item_pool_for_colony(colony)
  local function covers_pool(offers)
    if not (offers and pool) then return false end
    local names = {}
    for _, off in ipairs(offers) do
      if off and off.give and off.give.name then
        names[off.give.name] = true
      end
    end
    for _, item in ipairs(pool) do
      if not names[item] then return false end
    end
    return true
  end

  if colony.offers and covers_pool(colony.offers) then
    return colony.offers
  end

  if colony.id and storage.saved_offers[colony.id] and covers_pool(storage.saved_offers[colony.id]) then
    colony.offers = storage.saved_offers[colony.id]
    return colony.offers
  end

  local offers = build_random_offers_for_normal_colony(colony)
  colony.offers = offers
  if colony.id then
    storage.saved_offers[colony.id] = offers
  end
  return offers
end

-------------------------------------------------
-- renderowanie ikon na tablicy
-------------------------------------------------

local function safe_draw_sprite(params, store)
  local ok, obj = pcall(rendering.draw_sprite, params)
  if ok and obj then
    table.insert(store, obj)
  end
end

clear_board_icons = function(colony)
  if not colony then return end
  if not storage.board_render_objs then return end
  local bag = storage.board_render_objs[colony.id]
  if not bag then return end

  for _, obj in pairs(bag) do
    if obj and obj.valid then
      pcall(function() obj.destroy() end)
    end
  end

  storage.board_render_objs[colony.id] = nil
end

draw_board_icons = function(colony)
  if not colony then return end
  if not colony.board_entity or not colony.board_entity.valid then return end

  local surf = colony.board_entity.surface
  if not surf or not surf.valid then return end

  local offers = get_colony_offers(colony)
  if not offers or #offers == 0 then return end

  storage.board_render_objs = storage.board_render_objs or {}
  storage.board_render_objs[colony.id] = storage.board_render_objs[colony.id] or {}
  local store = storage.board_render_objs[colony.id]

  local inner_left   = BOARD_SEL_BOX.left   + BOARD_MARGIN
  local inner_top    = BOARD_SEL_BOX.top    + BOARD_MARGIN
  local inner_right  = BOARD_SEL_BOX.right  - BOARD_MARGIN
  local inner_bottom = BOARD_SEL_BOX.bottom - BOARD_MARGIN
  local inner_w      = inner_right - inner_left
  local inner_h      = inner_bottom - inner_top

  local function layout_grid(count, cols)
    local rows = math.ceil(count / cols)
    local cell_w = inner_w / cols
    local cell_h = inner_h / rows
    return function(i)
      local idx = i - 1
      local row = math.floor(idx / cols)
      local col = idx % cols
      local cx = colony.board_entity.position.x + inner_left + cell_w * (col + 0.5)
      local cy = colony.board_entity.position.y + inner_top  + cell_h * (row + 0.5)
      return cx, cy, cell_w, cell_h
    end
  end

  local max_offers = math.min(#offers, 16)
  local grid = layout_grid(max_offers, 4)

  for i = 1, max_offers do
    local off = offers[i]
    local cx, cy, cell_w, cell_h = grid(i)
    local scale = (ITEM_BASE_PX / PX_PER_TILE) * math.min(cell_w, cell_h) / 2

    safe_draw_sprite({
      sprite  = "item/" .. off.give.name,
      surface = surf,
      target  = { x = cx, y = cy },
      x_scale = scale,
      y_scale = scale
    }, store)
  end
end

refresh_board_icons = function(colony)
  clear_board_icons(colony)
  draw_board_icons(colony)
end

local function scan_circuit_network(net, requested, seen)
  if not net then return requested, false end
  local id = net.network_id
  if id and seen and seen[id] then return requested, false end
  if id and seen then seen[id] = true end

  local signals = net.signals
  if not signals then return requested, false end

  local found = false
  for _, s in pairs(signals) do
    if s.signal and s.signal.type == "item" and s.count ~= 0 then
      requested[s.signal.name] = (requested[s.signal.name] or 0) + s.count
      found = true
    end
  end

  return requested, found
end

local function get_network(ent, wire_type)
  if not (ent and ent.valid) then return nil end

  local connector_id = defines and defines.circuit_connector_id and defines.circuit_connector_id.container
  if connector_id then
    local net = ent.get_circuit_network(wire_type, connector_id)
    if net then return net end
  end

  return ent.get_circuit_network(wire_type)
end

local function read_requests_from_entity(ent, requested, seen_networks)
  local has_network = false
  local has_signal = false
  requested = requested or {}

  local red = get_network(ent, defines.wire_type.red)
  local green = get_network(ent, defines.wire_type.green)

  has_network = has_network or (red ~= nil) or (green ~= nil)

  local found = false
  requested, found = scan_circuit_network(red, requested, seen_networks)
  has_signal = has_signal or found

  requested, found = scan_circuit_network(green, requested, seen_networks)
  has_signal = has_signal or found

  return requested, has_network, has_signal
end

local function get_requested_items_for_colony(colony)
  if not colony then return nil end

  local raw_signals = {}
  local seen_networks = {}
  local has_network = false
  local has_signal = false

  local req, net, sig = read_requests_from_entity(colony.board_entity, raw_signals, seen_networks)
  raw_signals, has_network, has_signal = req, (has_network or net), (has_signal or sig)

  req, net, sig = read_requests_from_entity(colony.tradepost, raw_signals, seen_networks)
  raw_signals, has_network, has_signal = req, (has_network or net), (has_signal or sig)

  if not has_signal then
    if not has_network then
      colony.active_requests = nil
      colony.active_request_tick = nil
      return nil
    end
    return colony.active_requests
  end

  local inv = (colony.tradepost and colony.tradepost.valid) and colony.tradepost.get_inventory(defines.inventory.chest) or nil
  local requested = {}
  for name, count in pairs(raw_signals) do
    local available = (inv and inv.valid) and inv.get_item_count(name) or 0
    local desired = count
    if desired < 0 then desired = -desired end

    local deficit = desired - available
    if deficit > 0 then
      requested[name] = deficit
    end
  end

  if next(requested) then
    colony.active_requests = requested
    colony.active_request_tick = game.tick
    return requested
  end

  colony.active_requests = nil
  colony.active_request_tick = nil
  return nil
end

-------------------------------------------------
-- przetwarzanie handlu
-------------------------------------------------

local function process_colony_trade_round_robin(colony)
  local ent = colony.tradepost
  if not (ent and ent.valid) then return end

  local inv = ent.get_inventory(defines.inventory.chest)
  if not (inv and inv.valid) then return end

  local requested = get_requested_items_for_colony(colony)
  if not (requested and next(requested)) then return end

  local offers = get_colony_offers(colony)
  if not offers or #offers == 0 then return end

  colony.rr_index = colony.rr_index or 1

  local idxs = {}
  for i = 1, #offers do
    local off = offers[i]
    local give_name = off and off.give and off.give.name
    if give_name and requested[give_name] and requested[give_name] > 0 then
      table.insert(idxs, i)
    end
  end

  if #idxs == 0 then return end

  local function can_apply(off)
    if not off or not off.give or not off.cost then return false end
    if not (requested[off.give.name] and requested[off.give.name] > 0) then return false end
    if not inv.can_insert({ name = off.give.name, count = off.give.count }) then return false end

    for _, c in ipairs(off.cost) do
      if inv.get_item_count(c.name) < c.count then
        return false
      end
    end

    return true
  end

  local start = colony.rr_index
  if start < 1 or start > #idxs then start = 1 end

  for step = 1, #idxs do
    local idx = idxs[((start - 1 + step - 1) % #idxs) + 1]
    local off = offers[idx]
    local trades = 0

    while can_apply(off) do
      for _, c in ipairs(off.cost) do
        inv.remove({ name = c.name, count = c.count })
      end

      inv.insert({ name = off.give.name, count = off.give.count })
      requested[off.give.name] = math.max(0, (requested[off.give.name] or 0) - off.give.count)
      if requested[off.give.name] == 0 then
        requested[off.give.name] = nil
      end
      trades = trades + 1

      if trades >= 50 then break end
    end
  end

  colony.rr_index = ((start) % #idxs) + 1
  colony.active_requests = next(requested) and requested or nil
end

script.on_nth_tick(60, function()
  for _, colony in pairs(storage.colonies or {}) do
    process_colony_trade_round_robin(colony)
  end
end)

-------------------------------------------------
-- lookup helpers
-------------------------------------------------

local function is_same_pos(a, b, radius_sq)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return (dx * dx + dy * dy) <= (radius_sq or 1)
end

find_colony_by_tradepost = function(ent)
  if not (ent and ent.valid) then return nil end
  local unit = ent.unit_number
  if unit and storage.entity_to_colony and storage.entity_to_colony[unit] then
    local id = storage.entity_to_colony[unit]
    return storage.colonies and storage.colonies[id] or nil
  end

  local pos = ent.position
  local surf = ent.surface
  if not (pos and surf) then return nil end

  for _, c in pairs(storage.colonies or {}) do
    if c.surface_index == surf.index and c.pos and is_same_pos(c.pos, pos, 9) then
      return c
    end
  end
  return nil
end

find_colony_by_board = function(ent)
  if not (ent and ent.valid) then return nil end
  local unit = ent.unit_number
  if unit and storage.entity_to_colony and storage.entity_to_colony[unit] then
    local id = storage.entity_to_colony[unit]
    return storage.colonies and storage.colonies[id] or nil
  end

  local pos = ent.position
  local surf = ent.surface
  if not (pos and surf) then return nil end

  for _, c in pairs(storage.colonies or {}) do
    if c.surface_index == surf.index and c.board_pos and is_same_pos(c.board_pos, pos, 9) then
      return c
    end
  end
  return nil
end

-------------------------------------------------
-- rejestracja kolonii
-------------------------------------------------

local function register_colony(surface, tradepost, board, kind, currency, mode)
  if not (surface and surface.valid and tradepost and tradepost.valid) then return nil end

  local id = storage.next_colony_id or 1
  storage.next_colony_id = id + 1

  local colony = {
    id            = id,
    pos           = { x = tradepost.position.x, y = tradepost.position.y },
    board_pos     = board and { x = board.position.x, y = board.position.y } or nil,
    surface_index = surface.index,
    tradepost     = tradepost,
    board_entity  = board,
    enabled       = {},
    partial       = {},
    rr_index      = 1,
    active_requests = nil,
    active_request_tick = nil,
    kind          = kind or "generic",
    mode          = mode or "normal",
    currency      = currency or "sbt-alcohol"
  }

  colony.name = get_colony_name(colony)

  storage.colonies[id] = colony
  storage.entity_to_colony = storage.entity_to_colony or {}
  if tradepost.unit_number then
    storage.entity_to_colony[tradepost.unit_number] = id
  end
  if board and board.valid and board.unit_number then
    storage.entity_to_colony[board.unit_number] = id
  end

  connect_colony_circuit(colony)
  refresh_board_icons(colony)
  return colony
end

local function make_default_colony(surface, pos)
  local tradepost = surface.create_entity{
    name = TRADEPOST_NAME,
    position = pos,
    force = BUG_FORCE,
    create_build_effect_smoke = false
  }
  if not tradepost then return nil end

  local board = surface.create_entity{
    name = BOARD_NAME,
    position = { x = pos.x, y = pos.y - 2 },
    force = BUG_FORCE,
    create_build_effect_smoke = false
  }

  local kinds = { "metal", "components", "engines", "science" }
  local kind = kinds[math.random(1, #kinds)]
  local currency = (math.random() < 0.5) and "sbt-chocolate" or "sbt-alcohol"

  return register_colony(surface, tradepost, board, kind, currency, "normal")
end

create_or_get_colony_from_board = function(board)
  if not (board and board.valid) then return nil end

  local existing = find_colony_by_board(board)
  if existing then
    existing.board_entity = board
    existing.board_pos = { x = board.position.x, y = board.position.y }
    connect_colony_circuit(existing)
    refresh_board_icons(existing)
    return existing
  end

  local surface = board.surface
  if not surface or not surface.valid then return nil end

  local near_list = surface.find_entities_filtered{
    name = TRADEPOST_NAME,
    position = board.position,
    radius = 6
  }
  local near = near_list[1]
  if not (near and near.valid) then
    return nil
  end

  local colony = find_colony_by_tradepost(near)
  if colony then
    colony.board_entity = board
    colony.board_pos = { x = board.position.x, y = board.position.y }
    if board.unit_number then
      storage.entity_to_colony[board.unit_number] = colony.id
    end
    connect_colony_circuit(colony)
    refresh_board_icons(colony)
    return colony
  end

  return register_colony(surface, near, board, "generic", "sbt-alcohol", "normal")
end

-------------------------------------------------
-- startowe kolonie i paczka
-------------------------------------------------

local function create_start_colonies()
  local surf = game.surfaces[1]
  if not surf then return end

  local center = { x = 0, y = 0 }

  local pos1 = surf.find_non_colliding_position(TRADEPOST_NAME, { x = center.x + 20, y = center.y }, 16, 1)
  local pos2 = surf.find_non_colliding_position(TRADEPOST_NAME, { x = center.x - 20, y = center.y }, 16, 1)

  if pos1 then make_default_colony(surf, pos1) end
  if pos2 then make_default_colony(surf, pos2) end
end

local function give_start_pack(player)
  if not player or not player.valid then return end
  pcall(function()
    player.insert({ name = "sbt-chocolate",   count = 300 })
    player.insert({ name = "sbt-alcohol",     count = 200 })
  end)
end

-------------------------------------------------
-- dynamiczny spawn kolonii
-------------------------------------------------

local function get_dynamic_spawn_config()
  local chance = 0.02
  local tries  = 1
  return chance, tries
end

script.on_event(defines.events.on_chunk_generated, function(e)
  init_storage()

  local surface = e.surface
  if not surface or not surface.valid then return end

  ensure_bug_force()

  local chance, tries = get_dynamic_spawn_config()

  for _ = 1, tries do
    if math.random() < chance then
      local center = { x = (e.position.x + 0.5) * 32, y = (e.position.y + 0.5) * 32 }
      local pos = surface.find_non_colliding_position(TRADEPOST_NAME, center, 16, 1)
      if pos then
        make_default_colony(surface, pos)
      end
    end
  end
end)

-------------------------------------------------
-- GUI
-------------------------------------------------

local function get_player_state(pindex)
  storage.players = storage.players or {}
  local st = storage.players[pindex]
  if not st then
    st = {}
    storage.players[pindex] = st
  end
  return st
end

open_trade_gui = function(player, colony)
  if not player or not player.valid then return end
  if not colony then return end

  local gui = player.gui.screen
  if gui.sbt_trade_frame then
    gui.sbt_trade_frame.destroy()
  end

  local frame = gui.add{
    type      = "frame",
    name      = "sbt_trade_frame",
    direction = "vertical",
    caption   = colony.name
  }
  frame.auto_center = true

  local flow = frame.add{ type = "flow", direction = "vertical" }

  local header = flow.add{ type = "flow", direction = "horizontal" }
  header.add{ type = "label", caption = "Oferta" }
  header.add{ type = "label", caption = "Waluta" }

  local spacer = header.add{ type = "empty-widget" }
  spacer.style.horizontally_stretchable = true

  header.add{
    type = "button",
    name = "sbt_uncheck_all_offers",
    caption = "✕",
    tooltip = "Odznacz wszystkie oferty"
  }

  local offers = get_colony_offers(colony) or {}

  for i, off in ipairs(offers) do
    local row = flow.add{ type = "flow", direction = "horizontal", name = "sbt_offer_row_" .. i }
    local chk = row.add{
      type    = "checkbox",
      name    = "sbt_offer_enable_" .. i,
      state   = colony.enabled[i] ~= false,
      caption = ""
    }
    chk.style.width = 24

    local give = off.give or {}
    local cost = off.cost or {}

    row.add{ type = "sprite", sprite = "item/" .. (give.name or "iron-plate") }
    row.add{ type = "label", caption = "x" .. (give.count or 1) }

    local cost_flow = row.add{ type = "flow", direction = "horizontal" }
    for _, c in ipairs(cost) do
      cost_flow.add{ type = "sprite", sprite = "item/" .. (c.name or "coin") }
      cost_flow.add{ type = "label", caption = "x" .. (c.count or 1) .. " " }
    end
  end

  local btn_flow = frame.add{ type = "flow", direction = "horizontal" }
  btn_flow.add{
    type    = "button",
    name    = "sbt_trade_close",
    caption = "Zamknij"
  }

  local st = get_player_state(player.index)
  st.open_colony_id = colony.id
  player.opened = frame
end

local function close_trade_gui(player)
  if not player or not player.valid then return end
  local gui = player.gui.screen
  if gui.sbt_trade_frame then
    gui.sbt_trade_frame.destroy()
  end
end

local function open_board_gui_from_event(player, ent)
  if not player or not ent or not ent.valid then return end
  if ent.name ~= BOARD_NAME then return end
  local colony = create_or_get_colony_from_board(ent)
  if not colony then return end

  player.opened = nil
  refresh_board_icons(colony)
  open_trade_gui(player, colony)
end

-------------------------------------------------
-- events: init, config
-------------------------------------------------

local function on_init()
  init_storage()
  ensure_bug_force()
end

local function on_load()
end

local function on_configuration_changed()
  init_storage()
  ensure_bug_force()
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)

-------------------------------------------------
-- events: player, budowa, usuniecie
-------------------------------------------------

script.on_event(defines.events.on_player_created, function(e)
  init_storage()
  ensure_bug_force()
  create_start_colonies()
  local player = game.get_player(e.player_index)
  give_start_pack(player)
end)

script.on_event(defines.events.on_built_entity, function(e)
  init_storage()
  local ent = e.created_entity or e.entity
  if not (ent and ent.valid) then return end

  if ent.name == BOARD_NAME then
    local colony = create_or_get_colony_from_board(ent)
    if colony then
      local player = game.get_player(e.player_index)
      if player then
        open_trade_gui(player, colony)
      end
    end
  elseif ent.name == TRADEPOST_NAME then
    local colony = find_colony_by_tradepost(ent)
    if not colony then
      local surface = ent.surface
      local boards = surface.find_entities_filtered{
        name = BOARD_NAME,
        position = ent.position,
        radius = 6
      }
      local board = boards[1]
      if board then
        colony = register_colony(surface, ent, board, "generic", "sbt-alcohol", "normal")
      else
        colony = register_colony(ent.surface, ent, nil, "generic", "sbt-alcohol", "normal")
      end
    else
      colony.tradepost = ent
      colony.pos = { x = ent.position.x, y = ent.position.y }
      colony.surface_index = ent.surface.index
      if ent.unit_number then
        storage.entity_to_colony[ent.unit_number] = colony.id
      end
      connect_colony_circuit(colony)
      refresh_board_icons(colony)
    end
  end
end)

script.on_event(defines.events.on_robot_built_entity, function(e)
  init_storage()
  local ent = e.created_entity or e.entity
  if not (ent and ent.valid) then return end

  if ent.name == BOARD_NAME then
    create_or_get_colony_from_board(ent)
  elseif ent.name == TRADEPOST_NAME then
    local colony = find_colony_by_tradepost(ent)
    if not colony then
      register_colony(ent.surface, ent, nil, "generic", "sbt-alcohol", "normal")
    else
      colony.tradepost = ent
      colony.pos = { x = ent.position.x, y = ent.position.y }
      colony.surface_index = ent.surface.index
      if ent.unit_number then
        storage.entity_to_colony[ent.unit_number] = colony.id
      end
      connect_colony_circuit(colony)
      refresh_board_icons(colony)
    end
  end
end)

local function on_entity_removed(ent)
  if not (ent and ent.valid) then return end

  if ent.name == BOARD_NAME then
    local colony = find_colony_by_board(ent)
    if colony then
      colony.board_entity = nil
      colony.board_pos = nil
      if ent.unit_number and storage.entity_to_colony then
        storage.entity_to_colony[ent.unit_number] = nil
      end
      clear_board_icons(colony)
    end
  elseif ent.name == TRADEPOST_NAME then
    local colony = find_colony_by_tradepost(ent)
    if colony and colony.id then
      if colony.tradepost and colony.tradepost.valid and colony.tradepost.unit_number then
        storage.entity_to_colony[colony.tradepost.unit_number] = nil
      end
      if colony.board_entity and colony.board_entity.valid and colony.board_entity.unit_number then
        storage.entity_to_colony[colony.board_entity.unit_number] = nil
      end
      clear_board_icons(colony)
      storage.colonies[colony.id] = nil
    end
  end
end

script.on_event(defines.events.on_entity_died, function(e) on_entity_removed(e.entity) end)
script.on_event(defines.events.on_pre_player_mined_item, function(e) on_entity_removed(e.entity) end)
script.on_event(defines.events.on_robot_mined_entity, function(e) on_entity_removed(e.entity) end)

-------------------------------------------------
-- events: GUI
-------------------------------------------------

script.on_event(defines.events.on_gui_checked_state_changed, function(e)
  local element = e.element
  if not (element and element.valid) then return end
  if not element.name:match("^sbt_offer_enable_") then return end

  local player = game.get_player(e.player_index)
  if not player then return end
  local st = get_player_state(player.index)
  local colony_id = st.open_colony_id
  if not colony_id then return end

  local colony = storage.colonies and storage.colonies[colony_id]
  if not colony then return end

  local offer_index = tonumber(element.name:match("_(%d+)$"))
  if not offer_index then return end
  colony.enabled = colony.enabled or {}
  colony.enabled[offer_index] = element.state
end)

script.on_event(defines.events.on_gui_click, function(e)
  local element = e.element
  if not (element and element.valid) then return end
  local player = game.get_player(e.player_index)
  if not player then return end

  if element.name == "sbt_trade_close" then
    close_trade_gui(player)
    return
  end

  if element.name == "sbt_uncheck_all_offers" then
    local st = get_player_state(player.index)
    local colony_id = st.open_colony_id
    if not colony_id then return end

    local colony = storage.colonies and storage.colonies[colony_id]
    if not colony then return end

    local frame = player.gui.screen.sbt_trade_frame
    if not (frame and frame.valid) then return end

    local flow = frame.children[1]
    if not (flow and flow.valid) then return end

    local offers = get_colony_offers(colony) or {}
    colony.enabled = colony.enabled or {}

    for i = 1, #offers do
      local row = flow["sbt_offer_row_" .. i]
      if row and row.valid then
        local chk = row["sbt_offer_enable_" .. i]
        if chk and chk.valid then
          chk.state = false
        end
      end
      colony.enabled[i] = false
    end

    return
  end
end)

script.on_event(defines.events.on_gui_opened, function(e)
  if e.gui_type ~= defines.gui_type.entity then return end
  local player = game.get_player(e.player_index)
  local ent = e.entity
  if not player or not ent or not ent.valid then return end
  if ent.name ~= BOARD_NAME then return end
  open_board_gui_from_event(player, ent)
end)
