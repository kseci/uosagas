local Settings = {
    MainRestockContainerId = 0x4422A028, -- Update to serial of main restock bag
    MainOffloadContainerId = 0x4422A028, -- Update to serial of main offload bag (can be same as restock bag)
    ServerGCD = 500, -- Should stay at 500
    ServerLatency = 50, -- Update this to your latency (ping) to the server
    IgnoredOffloadingContainers = {0x0041241, 0x12512312} -- Fill in list of bags the offloader should ignore from offloading
}

return Settings