-- data.lua
require("prototypes.items")
require("prototypes.entities")
require("prototypes.recipes")
require("prototypes.early-rail")
require("prototypes.technologies")


-- Dodatkowe moduły nie są obowiązkowe
pcall(require, "prototypes.signals")
pcall(require, "prototypes.styles")
