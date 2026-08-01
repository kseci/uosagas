# uosagas scripts

## Dependencies
Organizer: -- To use the organizer you need these files
- Organizer.lua
- Utils.lua
- Colors.lua
- Logger.lua
- Settings.lua -- rename Settings-EXAMPLE.lua to Settings.lua and fill inn values

## SETUP

### 1. Clone repo or copy the files needed.

If you are copying the files, you need all the files that 
is dependent on one another.

See on top of the files, which file it Imports.
local Logger = Import('Logger') <-- Needs Logger.lua

Or check the dependency list below if its updated

### 2. Copy Settings example

Copy Settings-EXAMPLE.lua and name it Settings.lua and fill in the values explained there.


### Usage

#### Organizer

restock function only supports filling mode currently.

In your scrips do:

```lua

local Organizer = Import('Organizer')

local mandrakeRootType = 0x0F86
local blackPearlType = 0x0F7A

local typesToRestock = {mandrakeRootType, blackPearlType}

local fillAmount = 12

Organizer.restock(typesToRestock, fillAmount)
```

Can also inline everything:
```lua
Organizer.restock({0x0F86, 0x0F7A}, 12)
```

Restock from spesific container
```lua
local specialContainerId = 123578834
Organizer.restock({0x0F86, 0x0F7A}, 12, specialContainerId)
```

Restock special hue (shadow ingots) from default container:
```lua
local ingotType = 0x1BF2
local shadowIngotHue = 0x0966
Organizer.restock({ingotType}, 10, nil, shadowIngotHue)
```

Restock regular ingots (No colored ingot) from default container. Use hue = 0
```lua
local ingotType = 0x1BF2
Organizer.restock({ingotType}, 32, nil, 0)
```

Offloading:
```lua
local itemsToOffload = {0x1BF2, 0x0423}
local numberOfItemsToKeepInInventory
Organizer.offload(itemsToOffload, numberOfItemsToKeepInInventory)
```

offload different values, call it multiple times

```lua
Organizer.offload({0x001, 0x0002}, 5)
Organizer.offload({0x003}, 10)
Organizer.offload({0x007}, 15)
```

Offload to non default container
```lua
local spesificContainer = 0x12312312
Organizer.offload({0x001}, 5, spesificContainer)
```

Restock from a sub container
```lua
local mainBag = 0x00001
local secondBag = 0x00002
local bagToRestockFrom = 0x00003

--- Remember the last bag is the container with the items
local bagPath = {mainBag, secondBag, bagToRestockFrom}

Organizer.restock({0x0001}, 50, bagPath)
```


Have different loadouts for different character:
```lua
local CharSerials = {
    MyMage = 0x0012312, -- SerialId of your mage
    MyDexer = 0x123123 --- Serial of dexer
}
-- Common restocking
Organizer.restock({0x0001, 0x123123, 0x42342, }, 50)
Organizer.restock({0x0024}, 10)
-- Char specific
if Player.Serial == CharSerials.MyDexer then
    Organizer.restock({0x00444}, 100)
elseif Player.Serial == CharSerials.MyMage then
    Organizer.restock({0x002323, 0x03222}, 50)
    Organizer.restock({0x002555}, 24)
end 
```



### Debugging 
```lua
DEBUG = true
---
--- ****  YOUR CODE HERE *********
--- 
--- remember to set DEBUG = false at end, or else it will stay true until you close your client
DEBUG = false
```