local Organizer = Import('Organizer')


-- Regs
local BLACKPEARL = 0x0F7A
local BLOODMOSS = 0x0F7B
local NIGHTSHADE = 0x0F88
local GINSENG = 0x0F85
local GARLIC = 0x0F84
local SPIDERSILK = 0x0F8D
local SULPHASH = 0x0F8C
local MANDRAKE = 0x0F86

-- Pots
local CURE_POT = 0x0F07
local HEAL_POT = 0x0F0C
local AGILITY_POT = 0x0F08

-- Bandages
local BANDAGES = 0x0E21

local POT_SOURCE_CONTANER = 0x4422A028 -- Update to serial of your pot restock bag
local REGS_SOURCE_CONTAINER = 0x4422A028 -- Update to serial of your reg source bag
local BANDAGES_SOURCE_CONTAINER = 0x4422A028 -- Update to serial of your bandage source bag

local ALL_REGS = {BLACKPEARL, BLOODMOSS, NIGHTSHADE, GINSENG, GARLIC, SPIDERSILK, SULPHASH, MANDRAKE}
local ALL_POTS = {CURE_POT, HEAL_POT, AGILITY_POT}


local CharSerials = {
    MyTamer = 0x012301231,
    MyDexer = 0x042312424
}


if Player.Serial == CharSerials.MyTamer then
    Organizer.restock(ALL_REGS, 100, REGS_SOURCE_CONTAINER)
    Organizer.restock(ALL_POTS, 3, POT_SOURCE_CONTANER)
    Organizer.restock(BANDAGES, 150, BANDAGES_SOURCE_CONTAINER)
    Organizer.restock(BLACKPEARL, 300, REGS_SOURCE_CONTAINER)
    Organizer.restock(NIGHTSHADE, 300, REGS_SOURCE_CONTAINER)
elseif Player.Serial == CharSerials.MyDexer then
    Organizer.restock(ALL_REGS, 20, REGS_SOURCE_CONTAINER)
    Organizer.restock(CURE_POT, 5, POT_SOURCE_CONTANER)
    Organizer.restock(HEAL_POT, 5, POT_SOURCE_CONTANER)
    Organizer.restock(AGILITY_POT, 20, POT_SOURCE_CONTANER)
    Organizer.restock(BANDAGES, 200, BANDAGES_SOURCE_CONTAINER)
else
    Organizer.restock(ALL_REGS, 100, REGS_SOURCE_CONTAINER)
    Organizer.restock(ALL_POTS, 5, POT_SOURCE_CONTANER)
end