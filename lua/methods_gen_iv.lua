function update_pointers()
    offset.party_count = mdword(0x021C489C) + 14
    offset.party_data = offset.party_count + 4

    offset.foe_count = mdword(0x21C5A08) + 0x729C
    offset.current_foe = offset.foe_count + 4

    offset.map_header = mdword(0x21C489C) + 0x11B2
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2
    local mem_shift = mdword(0x21C0794)
    offset.battle_state = mem_shift + 0x44878
    -- console.log()

    --console.log(string.format("%08X", offset.battle_state))
end

-----------------------
-- MISC. BOT ACTIONS
-----------------------

function save_game()
    console.log("Saving game...")
    hold_button("X")
    wait_frames(20)
    release_button("X")
    console.log("Starting Map Check...")
    -- SAVE button is at a different position before choosing starter
    if mword(offset.map_header) == 0156 then -- No dex (not a perfect fix)
        while mbyte(0x021C4C86) ~= 04 do
            press_sequence("Up", 10)
        end
    else
        console.log("Not on first route...")
        while mbyte(0x021C4C86) ~= 07 do
            press_sequence("Up", 10)
        end
    end
    press_sequence("A", 10)
    console.log("Pressing A")
    hold_button("B")
    console.log("Holding B")
    wait_frames(100)
    release_button("B")
    press_button("A")
    console.log("Pressing A")
    wait_frames(30)
    hold_button("B")
    console.log("Holding B")
    wait_frames(100)
    release_button("B")
    console.log("Starting to save")
    press_sequence("A", 800)

    --touch_screen_at(218, 60)

    --while mbyte(offset.save_indicator) ~= 0 do
    --  press_sequence("A", 12)
    --end
    console.log("Saving ram")
    client.saveram() -- Flush save ram to the disk	

    press_sequence("B", 10)
end

function skip_nickname()
    while game_state.in_battle do
        touch_screen_at(125, 140)
        wait_frames(20)
    end
    wait_frames(150)
    save_game()
end

function check_status()
    if #party == 0 or game_state.in_battle then -- Don't check party status if bot was started during a battle
        return nil
    end

    -- Check how many valid move uses the lead has remaining
    local lead_pp_sum = 0
    for i = 1, #party[1].moves, 1 do
        local pp = party[1].pp[i]
        local power = party[1].moves[i].power
        if pp ~= 0 and power ~= nil then
            lead_pp_sum = lead_pp_sum + pp
        end
    end

    if party[1].currentHP == 0 or (lead_pp_sum == 0 and config.battle_non_targets) then
        console.log("Lead Pokemon can no longer battle...")
        if config.cycle_lead_pokemon then
            console.log("Finding a suitable replacement")
        else
            if config.mode_heal_loop then
                go_to_pokecenter()
            else
                pause_bot("auto cycle off waiting for manual intervention")
            end
        end
    end
end

function move_vertically(target)
    local dz = target - game_state.trainer_z
    local button = dz > 0 and "Down" or "Up"
    while dz ~= 0 do
        console.log("dz: " .. dz)
        hold_button("B")
        hold_button(button)
        wait_frames(4)
        release_button("B")
        release_button(button)
        dz = target - game_state.trainer_z
        release_button("B")
        --dz = target - game_state.trainer_z
        button = dz > 0 and "Down" or "Up"
        wait_frames(10)
    end
end

function move_horizontally(target)
    local dx = target - game_state.trainer_x
    local button = dx > 0 and "Right" or "Left"
    while dx ~= 0 do
        console.log("dx: " .. dx)
        hold_button("B")
        hold_button(button)
        wait_frames(4)
        dx = target - game_state.trainer_x
        button = dx > 0 and "Right" or "Left"
        --wait_frames(2)
    end
    release_button("B")
    release_button(button)
end

function go_to_pokecenter()

end

-----------------------
-- BATTLE BOT ACTIONS
-----------------------

function flee_battle()
    while game_state.in_battle do
        touch_screen_at(125, 175) -- Run
        wait_frames(20)
    end
end

function do_battle()
    local best_move = pokemon.find_best_move(party[1], foe[1])

    if best_move then
        -- Press B until battle state has advanced
        local battle_state = 0
        --console.log("Pokemon in memory: " .. offset.current_pokemon)
        while game_state.in_battle and battle_state == 0 do
            press_sequence("B", 5)
            battle_state = mbyte(offset.battle_state) --should set to 01
        end
        local current_hp = mword(offset.current_pokemon + 0x4C)
        local move1_pp = mbyte(offset.current_pokemon + 0x2C)
        local move2_pp = mbyte(offset.current_pokemon + 0x2D)
        local move3_pp = mbyte(offset.current_pokemon + 0x2E)
        local move4_pp = mbyte(offset.current_pokemon + 0x2F)

        --console.log("My current pokemon HP: " ..  mword(offset.current_pokemon + 0x4C))
        console.log("Move1 pp: " .. move1_pp)
        console.log("Move2 pp: " .. move2_pp)
        console.log("Move3 pp: " .. move3_pp)
        --.log("Updated pp1 in pokemon: " .. party[1].pp[1])
        if not game_state.in_battle then                      -- Battle over
            return
        elseif current_hp == 0 or foe[1].current_hp == 0 then -- Fainted or learning new move
            console.log("Pokemon fainted or is learning new moves skipping text...")
            while game_state.in_battle do
                wait_frames(400)
                touch_screen_at(125, 135)    -- RUN or KEEP OLD MOVES
                wait_frames(300)
                if game_state.in_battle then --if hit with can't flee message
                    console.log("Could not flee battle reseting...")
                    press_button("Power")
                end
                press_sequence("B", 5)
            end
            return
        end
        --checks if move has pp and is a damaging move
        if (best_move.power > 0) then
            console.debug("Best move against foe is " ..
                best_move.name .. " (Effective base power is " .. best_move.power .. ")")
            wait_frames(30)
            touch_screen_at(128, 90) -- FIGHT
            wait_frames(30)
            console.log("Touching Screen at location: (" ..
                (80 * (best_move.index - 1) % 2 + 1) .. ", " .. 50 * (((best_move.index - 1) // 2) + 1))
            touch_screen_at(80 * ((best_move.index - 1) % 2 + 1), 50 * (((best_move.index - 1) // 2) + 1)) -- Select move slot
            console.log("Attacking now...")
            wait_frames(30)
            party[1].pp[1] = move1_pp -- update moves pp for find_best_move function
            party[1].pp[2] = move2_pp
            party[1].pp[3] = move3_pp
            party[1].pp[4] = move4_pp
            --do_battle()
        else
            console.log("Lead Pokemon has no valid moves left to battle! Fleeing...")

            while game_state.in_battle do
                touch_screen_at(125, 175) -- Run
                wait_frames(5)
            end
        end
        --do_battle()
    else
        -- Wait another frame for valid battle data
        wait_frames(1)
    end
end

function catch_pokemon()
    if config.auto_catch then
        console.log("Attempting to catch pokemon now...")
        local battle_state = 0
        while game_state.in_battle and battle_state == 0 do
            press_sequence("B", 5)
            battle_state = mbyte(offset.battle_state) --should set to 01
        end
        ::retry::
        wait_frames(100)
        touch_screen_at(40, 170)
        wait_frames(50)
        touch_screen_at(190, 45)
        wait_frames(20)
        touch_screen_at(60, 30)
        wait_frames(20)
        touch_screen_at(100, 170)
        wait_frames(750)
        if mbyte(0x02101DF0) == 0x01 then
            console.log("Pokemon caught!!!")
            skip_nickname()
        else
            console.log("Failed catch trying again...")
            goto retry
        end
    else
        pause_bot("Wild Pokemon meets target specs!")
    end
end

function catch_pokemon()
    if config.auto_catch then
        console.log("Attempting to catch pokemon now...")
        local battle_state = 0
        while game_state.in_battle and battle_state == 0 do
            press_sequence("B", 5)
            battle_state = mbyte(offset.battle_state) --should set to 01
        end
        ::retry::
        wait_frames(100)
        touch_screen_at(40, 170)
        wait_frames(50)
        touch_screen_at(190, 45)
        wait_frames(20)
        touch_screen_at(60, 30)
        wait_frames(20)
        touch_screen_at(100, 170)
        wait_frames(750)
        if mbyte(0x02101DF0) == 0x01 then
            console.log("Pokemon caught!!!")
            skip_nickname()
        else
            console.log("Failed catch trying again...")
            goto retry
        end
    else
        pause_bot("Wild Pokemon meets target specs!")
    end
end

function process_wild_encounter()
    -- Check all foes in case of a double battle in Eterna Forest
    local foe_is_target = false
    for i = 1, #foe, 1 do
        foe_is_target = pokemon.log(foe[i]) or foe_is_target
    end

    wait_frames(30)

    if foe_is_target then
        console.log("Wild " .. foe[1].name .. " was a target!!! Catching Now")
        catch_pokemon()
    else
        while game_state.in_battle do
            if config.battle_non_targets then
                console.log("Wild " .. foe[1].name .. " was not a target, and battle non tartgets is on. Battling!")
                do_battle()
            else
                console.log("Wild " .. foe[1].name .. " was not a target, fleeing!")
                flee_battle()
            end
        end
    end
end

-----------------------
-- BOT ENCOUNTER MODES
-----------------------

function mode_starters_DP(starter)
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            skip_dialogue()
        end
    end

    hold_button("Up") -- Enter Lake Verity
    console.log("Waiting to reach briefcase...")

    -- Skip through dialogue until starter select
    while not (mdword(offset.starters_ready) > 0) do
        skip_dialogue()
    end

    release_button("Up")

    -- Highlight and select target
    console.log("Selecting starter...")

    while mdword(offset.selected_starter) < starter do
        press_sequence("Right", 5)
    end

    while #party == 0 do
        press_sequence("A", 6)
    end

    if not config.hax then
        console.log("Waiting to see starter...")

        for i = 0, 86, 1 do
            press_button("A")
            clear_unheld_inputs()
            wait_frames(6)
        end
    end

    mon = party[1]
    local was_target = pokemon.log(mon)

    if was_target then
        pause_bot("Starter meets target specs!")
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(180)
    end
end

function mode_starters(starter)                          --starters for platinum
    local selected_starter = mdword(0x2101DEC) + 0x203E8 -- 0: Turtwig, 1: Chimchar, 2: Piplup
    local starters_ready = selected_starter + 0x84       -- 0 before hand appears, A94D afterwards
    --console.log("selected_starter: " .. selected_starter)
    --console.log("starters_ready: " .. starters_ready)
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while mbyte(offset.battle_indicator) ~= 0xFF do
            skip_dialogue()
            if mbyte(offset.battle_indicator) == 0xFF then
                break
            end
        end
    end --]]
    --we can save right in front of the bag in platinum so all we have to do is open and select are starter

    -- Open briefcase and skip through dialogue until starter select
    console.log("Skipping dialogue to briefcase")
    local selected_starter = mdword(0x2101DEC) + 0x203E8 -- 0: Turtwig, 1: Chimchar, 2: Piplup
    local starters_ready = selected_starter + 0x84       -- 0 before hand appears, A94D afterwards

    while not (mdword(starters_ready) > 0) do
        press_button("B")
        wait_frames(2)
    end

    --[[for i = 0x022BF900, 0x022BFA9E, 0x02 do
        --console.log("i = " .. i)
        --console.log("word at i = " .. mword(i))
        if mword(i) == 0xA94D then
            offset.starters_ready = i
            console.log("starter ready value: " .. offset.starters_ready)
            break
        end
    end]]
    --

    -- Need to wait for hand to be visible to find offset
    console.log("Selecting starter...")

    -- Highlight and select target
    while mdword(selected_starter) < starter do
        press_sequence("Right", 10)
    end

    while #party == 0 do
        press_sequence("A", 6)
    end

    console.log("Waiting to see starter...")
    if config.hax then
        mon = party[1]
        local was_target = pokemon.log(mon)
        if was_target then
            pause_bot("Starter meets target specs!")
        else
            press_button("Power")
        end
    else
        while not game_state.in_starter_battle do
            skip_dialogue()
        end
        console.log(game_state.in_starter_battle)
        local battle_state = 0
        while game_state.in_starter_battle and battle_state == 0 do
            press_sequence("B", 5)
            --console.log("Battle State: " .. mbyte(offset.battle_state))
            battle_state = mbyte(offset.battle_state) --should set to 01
        end
        wait_frames(50)
        mon = party[1]
        local was_target = pokemon.log(mon)
        if was_target then
            pause_bot("Starter meets target specs!")
        else
            console.log("Starter was not a target, resetting...")
            selected_starter = 0
            starters_ready = 0
            press_button("Power")
        end
    end
end

function mode_random_encounters_running()
    console.log("Attempting to start a battle...")

    local tile_frames = frames_per_move() - 2
    local dir1 = config.move_direction == "Horizontal" and "Left" or "Up"
    local dir2 = config.move_direction == "Horizontal" and "Right" or "Down"

    while not foe and not game_state.in_battle do
        hold_button("B")
        hold_button(dir1)
        wait_frames(tile_frames)
        release_button(dir1)
        --release_button("B")
        press_button("A")
        --hold_button("B")
        hold_button(dir2)
        wait_frames(tile_frames)
        release_button(dir2)
        release_button("B")
    end

    release_button(dir2)

    process_wild_encounter()
end

function mode_spin_to_win()
    console.log("Attempting to start a battle... and Spinning!")
    while not foe and not game_state.in_battle do
        press_sequence("Up", "Left", "Down", "Right")
    end

    process_wild_encounter()
end

function mode_heal_loop()
    --use spin to win then check status after every battle, if status bad return player to pokecenter to heal
    for i = 1, 10, 1 do
        move_horizontally(184)
        move_vertically(843)
        move_vertically(829)
        move_horizontally(180)
        --mode_spin_to_win()
        --check_status()
    end
end
