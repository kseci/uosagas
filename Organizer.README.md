# HOW TO USE ORGANIZER 

## Dependencies
- Settings.lua -- rename Settings-EXAMPLE.lua to Settings.lua and fill inn values


## 1. Copy Organizer.lua

Copy the Organizer.lua file to your UOSagas script.

The file path should be places like this:
./[SagasFolder]/ClassicUO/Data/Profiles/Scripts/Organizer.lua

Or check the dependency list above.

## 2. Copy Settings example

Copy Settings-EXAMPLE.lua to the same folder and rename it to Settings.lua.

Update all the variables with your preferences.


### Usage

Create your new script or update an old one.

Idea is that you import the organizer into your scripts, so you can
use it wherever you like

#### Organizer 1.0

NOTE: Restock function only supports filling mode currently.

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
local Organizer = Import('Organizer')
Organizer.restock({0x0F86, 0x0F7A}, 12)
```

Restock from spesific container
```lua
local Organizer = Import('Organizer')
local specialContainerId = 123578834
Organizer.restock({0x0F86, 0x0F7A}, 12, specialContainerId)
```

Restock special hue (shadow ingots) from default container:
```lua
local Organizer = Import('Organizer')
local ingotType = 0x1BF2
local shadowIngotHue = 0x0966
Organizer.restock({ingotType}, 10, nil, shadowIngotHue)
```

Restock regular ingots (No colored ingot) from default container. Use hue = 0
```lua
local Organizer = Import('Organizer')
local ingotType = 0x1BF2
Organizer.restock({ingotType}, 32, nil, 0)
```

Restock from a sub container
```lua
local Organizer = Import('Organizer')
local mainBag = 0x00001
local secondBag = 0x00002
local bagToRestockFrom = 0x00003

--- Remember the last bag is the container with the items
local bagPath = {mainBag, secondBag, bagToRestockFrom}

Organizer.restock({0x0001}, 50, bagPath)
```

Have different loadouts for different character:
```lua
local Organizer = Import('Organizer')
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

Offloading:
```lua
local Organizer = Import('Organizer')
local itemsToOffload = {0x1BF2, 0x0423}
local numberOfItemsToKeepInInventory
Organizer.offload(itemsToOffload, numberOfItemsToKeepInInventory)
```

offload different values, call it multiple times

```lua
local Organizer = Import('Organizer')
Organizer.offload({0x001, 0x0002}, 5)
Organizer.offload({0x003}, 10)
Organizer.offload({0x007}, 15)
```

Offload to non default container
```lua
local Organizer = Import('Organizer')
local spesificContainer = 0x12312312
Organizer.offload({0x001}, 5, spesificContainer)
```

### Organizer 2.0
This are the parameters
```lua
---@field restock2 fun (types: integer|integer[], amount: integer, sources: integer|integer[]|NestedBag|NestedBag[], options: RestockOptions)

---@class NestedBag
---@field serial number
---@field path number[]

---@class RestockOptions
---@field fill? boolean -- Default: true
---@field hue? number -- Default: all hues
---@field targetBag? NestedBag -- Default: Your main backpack

```

All scripts should start with these two lines
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- SET THIS TO YOUR LATENCY (PING) TO THE SERVER. DEFAULT IS 200!!
```
#### Restocking examples
NB! For a full loadout per char script. Look at [loadout-EXAMPLE](loadout-EXAMPLE.lua)

Simple restock from root of a container to you main bag
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local containerSerial = 0x4422A028
Organizer.restock2(mandrakeType, amount, containerSerial)
```

Restock multiple types with same amount
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local typesToRestock = {0x0F86, 0x0322, 0x42323}
local amount = 100
local containerSerial = 0x4422A028
Organizer.restock2(mandrakeType, typesToRestock, containerSerial)
```

Restock multiple types with different amount. Call the function multiple times.
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local blackPearlType = 0x0F7A
local containerSerial = 0x4422A028
Organizer.restock2(mandrakeType, 100, containerSerial)
Organizer.restock2(blackPearlType, 150, containerSerial)
```

Restock by hue
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local containerSerial = 0x4422A028
Organizer.restock2(mandrakeType, amount, containerSerial, {hue = 0})
```

Restock the specified amount
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local containerSerial = 0x4422A028
Organizer.restock2(mandrakeType, amount, containerSerial, {fill = false})
```

Restock from multiple containers
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local containerSerials = {0x4422A028, 0x44223123, 0x42424333}
Organizer.restock2(mandrakeType, amount, containerSerials)
```

Restock from a nested bag
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local sourceBag = {
    serial = 0x4422A028, -- This is the container to restock from
    path = {0x44223123, 0x42424333} -- This is the serial id of containers leading up to the restock bag
}

Organizer.restock2(mandrakeType, amount, sourceBag)
```

Restock to a nested bag
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local sourceBagId = 0x00223344
local targetBag = {
    serial = 0x44332243, -- This is the container to restock to
    path = {0x44223123, 0x42424333} -- This is the serial id of the containers leading up to your target bag
}

Organizer.restock2(mandrakeType, amount, sourceContainerId, { targetBag = targetBag })
```

Restock from multiple nested bags
```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local amount = 100
local sourceBag1 = {
    serial = 0x4422A028, -- This is the container to restock from
    path = {0x44223123, 0x42424333} -- This is the serial id of containers leading up to the restock bag
}
local sourceBag2 = {
    serial = 0x7777A028, -- This is the container to restock from
    path = {0x44777723, 0x4299333} -- This is the serial id of containers leading up to the restock bag
}

Organizer.restock2(mandrakeType, amount, {sourceBag1, sourceBag2})
```

Complex example
Restock full amount of multiple types from multiple nested bags with hue to a nested bag

```lua
local Organizer = Import('Organizer')
SERVER_LATENCY = 100 -- your server latency (ping)

local mandrakeType = 0x0F86
local blackPearlType = 0x0F7A
local itemsToRestock = {mandrakeType, blackPearlType}
local amount = 100
local sourceBag1 = {
    serial = 0x4422A028, -- This is the container to restock from
    path = {0x44223123, 0x42424333} -- This is the serial id of containers leading up to the restock bag
}
local sourceBag2 = {
    serial = 0x7777A028, -- This is the container to restock from
    path = {0x44777723, 0x4299333} -- This is the serial id of containers leading up to the restock bag
}
local targetBag = {
    serial = 0x44332243, -- This is the container to restock to
    path = {0x44223123, 0x42424333} -- This is the serial id of the containers leading up to your target bag
}

Organizer.restock2(
    itemsToRestock,
    amount, 
    { sourceBag1, sourceBag2}, 
    { targetBag = targetBag, fill = false, hue = 0x4232}
)

--- This can also be inlined like this:
Organizer.restock2(
    {0x0F86, 0x0F7A}, 
    100, 
    {
        { serial = 0x4422A028, path = {0x44223123, 0x42424333} },
        { serial = 0x7777A028, path = {0x44223123, 0x42424333} }
    }, 
    { 
        fill = false, 
        hue = 0x4232, 
        targetBag = {
            serial = 0x44332243, 
            path = {0x44223123, 0x42424333}
        }
    }
)
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