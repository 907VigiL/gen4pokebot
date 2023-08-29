-- Source: https://github.com/mkdasher/PokemonBizhawkLua/blob/master/pkmgen3/Memory.lua

Memory = {}

function Memory.read(addr, size)
    if size == 1 then
        return memory.read_u8(addr)
    elseif size == 2 then
        return memory.read_u16_le(addr)
    elseif size == 3 then
        return memory.read_u24_le(addr)
    else
        return memory.read_u32_le(addr)
    end
end

function Memory.readdword(addr)
    return Memory.read(addr, 4)
end

function Memory.readword(addr)
    return Memory.read(addr, 2)
end

function Memory.readbyte(addr)
    return Memory.read(addr, 1)
end
