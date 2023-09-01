
-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	offset.party_count = mdword(0x021BF65C) + 18
	offset.party_data = offset.party_count + 4

	offset.foe_count = mdword(0x21C07DC) + 0x7304
	offset.current_foe = offset.foe_count + 4

	offset.map_header = mdword(0x21C0794) + 0x1294
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2

	local mem_shift = mdword(0x21C0794)
    offset.battle_state = mem_shift + 0x44878 --01 is FIGHT menu, 04 is Move Select, 08 is Bag, 0A is POkemon menu
	offset.current_pokemon = mem_shift + 0x475B8
	
	--console.log(string.format("%08X", offset.battle_state))
end
