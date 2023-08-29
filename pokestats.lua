--Joseph Keller's Pokemon Gen4/5 PokeStats Display LUA script
--Based of a lua script by MKDasher
--Requires display 4.0.1 or higher.
local utils = {}

function utils.translatePath(path)
    local separator = package.config:sub(1, 1)
    local pathTranslated = string.gsub(path, "\\", separator)
    return pathTranslated == nil and path or pathTranslated
end

dofile(utils.translatePath("lua\\Memory.lua"))

require "include"

local pointer
local pidAddr
local pid = 0
local tid, sid
local shiftvalue
local prng = 0
local checksum
local nickname = {}
local inputs = {}
--BlockA
local pokedexID = 0
local heldItem = 0
local experience = 0
--BlockB
local ivspart, ivs = {}, ivs
local HPIV, ATKIV, DEFIV, SPAIV, SPDIV, SPEIV
local gender = 0
--BlockC
local nature = 0
--BlockD
local pkrs
--currentStats
local level, hpstat, atkstat, defstat, spastat, spdstat, spestat
--offsets
local BlockAoff, BlockBoff, BlockCoff, BlockDoff

if Memory.readbyte(0x02FFFE0F) == 0x45 then
    language = "USA"
    seedsOffset = 0xC00
end

BlockA = { 1, 1, 1, 1, 1, 1, 2, 2, 3, 4, 3, 4, 2, 2, 3, 4, 3, 4, 2, 2, 3, 4, 3, 4 }
BlockB = { 2, 2, 3, 4, 3, 4, 1, 1, 1, 1, 1, 1, 3, 4, 2, 2, 4, 3, 3, 4, 2, 2, 4, 3 }
BlockC = { 3, 4, 2, 2, 4, 3, 3, 4, 2, 2, 4, 3, 1, 1, 1, 1, 1, 1, 4, 3, 4, 3, 2, 2 }
BlockD = { 4, 3, 4, 3, 2, 2, 4, 3, 4, 3, 2, 2, 4, 3, 4, 3, 2, 2, 1, 1, 1, 1, 1, 1 }


local xfix = 10
local yfix = 10
function displaybox(a, b, c, d, e, f)
    gui.drawBox(a + xfix, b + yfix, c + xfix, d + yfix, e, f)
end

function display(a, b, c, d)
    gui.text(xfix + a, yfix + b, c, d)
end

function mult32(a, b)
    local c = (a >> 16)
    local d = a % 0x10000
    local e = (b >> 16)
    local f = b % 0x10000
    local g = (c * f + d * e) % 0x10000
    local h = d * f
    local i = g * 0x10000 + h
    return i
end

function getbits(a, b, d)
    return (a >> b) % (1 << d)
end

function gettop(a)
    return (a >> 16)
end

function getGameName()
    return "Platinum"
end

function getPointer()
    return Memory.readdword(0x02101D2C)
end

local mode = 1
function getPidAddr()
    enemyAddr = pointer + 0x352F4
    if mode == 1 then
        return pointer + 0x35AC4 --enemy pokemon location??
    elseif mode == 2 then
        return Memory.readdword(enemyAddr) + 0x7A0 + 0xB60
    elseif mode == 3 then
        return Memory.readdword(enemyAddr) + 0x7A0 + 0x5B0
    else
        return pointer + 0xD094 -- first position party pokemon
    end
end

function get_nature()
    pidAddr = getPidAddr()
    pid = Memory.readdword(pidAddr)
    nature = pid % 25
    if nature == 0 then
        natureName = "Hardy"
    elseif nature == 1 then
        natureName = "Lonely"
    elseif nature == 2 then
        natureName = "Brave"
    elseif nature == 3 then
        natureName = "Adamant"
    elseif nature == 4 then
        natureName = "Naughty"
    elseif nature == 5 then
        natureName = "Bold"
    elseif nature == 6 then
        natureName = "Docile"
    elseif nature == 7 then
        natureName = "Relaxed"
    elseif nature == 8 then
        natureName = "Impish"
    elseif nature == 9 then
        natureName = "Lax"
    elseif nature == 10 then
        natureName = "Timid"
    elseif nature == 11 then
        natureName = "Hasty"
    elseif nature == 12 then
        natureName = "Serious"
    elseif nature == 13 then
        natureName = "Jolly"
    elseif nature == 14 then
        natureName = "Naive"
    elseif nature == 15 then
        natureName = "Modest"
    elseif nature == 16 then
        natureName = "Mild"
    elseif nature == 17 then
        natureName = "Quiet"
    elseif nature == 18 then
        natureName = "Bashful"
    elseif nature == 19 then
        natureName = "Rash"
    elseif nature == 20 then
        natureName = "Calm"
    elseif nature == 21 then
        natureName = "Gentle"
    elseif nature == 22 then
        natureName = "Sassy"
    elseif nature == 23 then
        natureName = "Careful"
    elseif nature == 24 then
        natureName = "Quirky"
    end
end

function read_adressess()
    pointer = getPointer()
    pidAddr = getPidAddr()
    pid = Memory.readdword(pidAddr)
    p1 = Memory.readword(pidAddr)
    p2 = Memory.readdword(pidAddr + 2)
    prng = Memory.readword(pidAddr + 6)
    shiftvalue = ((((pid & 0x3E000)) >> 0xD)) % 24

    BlockAoff = (BlockA[shiftvalue + 1] - 1) * 32
    BlockBoff = (BlockB[shiftvalue + 1] - 1) * 32
    BlockCoff = (BlockC[shiftvalue + 1] - 1) * 32
    BlockDoff = (BlockD[shiftvalue + 1] - 1) * 32

    -- Block A
    checksum = prng
    for i = 1, BlockA[shiftvalue + 1] - 1 do
        checksum = mult32(checksum, 0x5F748241) + 0xCBA72510 -- 16 cycles
    end

    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    pokedexID = (Memory.readword(pidAddr + BlockAoff + 8) ~ gettop(checksum))
    if pokedexID > 65000 then
        pokedexID = pokedexID - 65536
    end
    pokemonName = pokemon[pokedexID]

    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    heldItem = (Memory.readword(pidAddr + BlockAoff + 2 + 8) ~ gettop(checksum))

    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    ability = (Memory.readword(pidAddr + BlockAoff + 12 + 8) ~ gettop(checksum))
    ability = getbits(ability, 8, 8)

    -- Block B
    checksum = prng
    for i = 1, BlockB[shiftvalue + 1] - 1 do
        checksum = mult32(checksum, 0x5F748241) + 0xCBA72510 -- 16 cycles
    end

    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073

    ivspart[1] = (Memory.readword(pidAddr + BlockBoff + 16 + 8) ~ gettop(checksum))
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    ivspart[2] = (Memory.readword(pidAddr + BlockBoff + 18 + 8) ~ gettop(checksum))
    ivs = ivspart[1] + (ivspart[2] << 16)
    HPIV = getbits(ivs, 0, 5)
    ATKIV = getbits(ivs, 5, 5)
    DEFIV = getbits(ivs, 10, 5)
    SPAIV = getbits(ivs, 20, 5)
    SPDIV = getbits(ivs, 25, 5)
    SPEIV = getbits(ivs, 15, 5)

    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073

    local genderByte = (Memory.readword(pidAddr + BlockBoff + 24 + 8) ~ gettop(checksum))
    local isGenderless = getbits(genderByte, 2, 3)
    local genderStatus = getbits(genderByte, 1, 2)

    gender = genderStatus + 1


    -- Block C
    checksum = prng
    for i = 1, BlockC[shiftvalue + 1] - 1 do
        checksum = mult32(checksum, 0x5F748241) + 0xCBA72510 -- 16 cycles
    end
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    for i = 0, 11 do
        nickname[i + 1] = (Memory.readword(pidAddr + BlockCoff + (i * 2) + 8) ~ gettop(checksum))
        checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    end

    -- Block D
    checksum = prng
    for i = 1, BlockD[shiftvalue + 1] - 1 do
        checksum = mult32(checksum, 0x5F748241) + 0xCBA72510 -- 16 cycles
    end

    checksum = mult32(checksum, 0xCFDDDF21) + 0x67DBB608 -- 8 cycles
    checksum = mult32(checksum, 0xEE067F11) + 0x31B0DDE4 -- 4 cycles
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    pkrs = (Memory.readword(pidAddr + BlockDoff + 0x1A + 8) ~ gettop(checksum))
    pkrs = getbits(pkrs, 0, 8)

    -- Current stats
    checksum = pid
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    statusConditions = getbits((Memory.readbyte(pidAddr + 0x88) ~ gettop(checksum)), 0, 8)
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    level = getbits((Memory.readword(pidAddr + 0x8C) ~ gettop(checksum)), 0, 8)
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    hpstat = Memory.readword(pidAddr + 0x90) ~ gettop(checksum)
    if hpstat > 65000 then
        hpstat = hpstat - 65536
    end
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    atkstat = Memory.readword(pidAddr + 0x92) ~ gettop(checksum)
    if atkstat > 65000 then
        atkstat = atkstat - 65536
    end
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    defstat = Memory.readword(pidAddr + 0x94) ~ gettop(checksum)
    if defstat > 65000 then
        defstat = defstat - 65536
    end
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    spestat = Memory.readword(pidAddr + 0x96) ~ gettop(checksum)
    if spestat > 65000 then
        spestat = spestat - 65536
    end
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    spastat = Memory.readword(pidAddr + 0x98) ~ gettop(checksum)
    if spastat > 65000 then
        spastat = spastat - 65536
    end
    checksum = mult32(checksum, 0x41C64E6D) + 0x6073
    spdstat = Memory.readword(pidAddr + 0x9A) ~ gettop(checksum)
    if spdstat > 65000 then
        spdstat = spdstat - 65536
    end
end

function debugScreen()
    idsPointer = 0x021BFB94 + seedsOffset
    ids        = Memory.readdword(Memory.readdword(idsPointer) + 0x8C) --reading from 0227E17C
    sid        = math.floor(ids / 0x10000)                             --003D = 61
    tid        = ids % 0x10000                                         --0045 = 69
    shinyValue = tid ~ sid ~ p1 ~ p2
    console.log("TID: " .. tid)
    console.log("SID: " .. sid)
    console.log("pokedexID: " .. pokedexID)
    console.log("Species: " .. pokemonName)
    console.log("PID : " .. pid)
    console.log("Item: " .. heldItem)
    console.log("Level: " .. level)
    console.log("Shiny Value: " .. shinyValue)
    console.log("Nature: " .. natureName)
    console.log("HP(IV): " .. hpstat .. "(" .. HPIV .. ")")
    console.log("ATK(IV): " .. atkstat .. "(" .. ATKIV .. ")")
    console.log("DEF(IV): " .. defstat .. "(" .. DEFIV .. ")")
    console.log("SPA(IV): " .. spastat .. "(" .. SPAIV .. ")")
    console.log("SPD(IV): " .. spdstat .. "(" .. SPDIV .. ")")
    console.log("SPE(IV): " .. spestat .. "(" .. SPEIV .. ")")
end

read_adressess()
get_nature()
debugScreen()
function getEmu()
    local emu_data = {
        frameCount = emu.framecount(),
        fps = client.get_approx_framerate(),
    }

    return emu_data
end

while true do
    emu_data = getEmu()
    for i = 0, 1, 1 do
        joypad.set({ Touch = true })
        emu.frameadvance()
    end
    for j = 0, 1, 1 do
        joypad.set({ Touch = false })
        emu.frameadvance()
    end
    emu.frameadvance()
end
