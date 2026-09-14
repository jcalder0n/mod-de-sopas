local function check_fuego(pos)
    local node_below = core.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
    local name = node_below.name
    return name == "mcl_fire:fire" or name == "mcl_fire:soul_fire" or name == "mcl_nether:netherrack" or name == "mcl_campfires:campfire_lit"
end

local function servir_sopa(pos, clicker, itemstack, resultado_item)
    if itemstack:get_name() ~= "mcl_core:bowl" then
        return itemstack
    end

    local meta = core.get_meta(pos)
    local porciones = meta:get_int("porciones")
    if porciones <= 0 then porciones = 6 end

    porciones = porciones - 1
    meta:set_int("porciones", porciones)
    itemstack:take_item(1)

    local inv = clicker:get_inventory()
    local sopa_item = ItemStack(resultado_item)

    if inv:room_for_item("main", sopa_item) then
        inv:add_item("main", sopa_item)
    else
        core.add_item(clicker:get_pos(), sopa_item)
    end

    if porciones <= 0 then
        core.set_node(pos, {name = "mcl_cauldrons:cauldron"})
        core.chat_send_player(clicker:get_player_name(), "El caldero ha quedado vacío.")
    else
        core.chat_send_player(clicker:get_player_name(), "Porciones restantes: " .. porciones)
    end

    return itemstack
end

local function procesar_hervido_sopa(pos)
    if check_fuego(pos) then
        core.add_particlespawner({
            amount = 1,
            time = 1.0,
            minpos = {x = pos.x - 0.2, y = pos.y + 0.3, z = pos.z - 0.2},
            maxpos = {x = pos.x + 0.2, y = pos.y + 0.4, z = pos.z + 0.2},
            minvel = {x = -0.02, y = 0.2, z = -0.02},
            maxvel = {x = 0.02, y = 0.5, z = 0.02},
            minsize = 1.0,
            maxsize = 2.0,
            texture = "mcl_particles_smoke.png",
        })
        return true
    end
    return false
end

local caldero_nodebox = {
    type = "fixed",
    fixed = {
        {-0.375, -0.3125, -0.375, 0.375, -0.1875, 0.375}, -- Fondo interno del caldero
        {-0.5, -0.3125, -0.5, -0.375, 0.5, 0.5},         -- Pared Oeste
        {0.375, -0.3125, -0.5, 0.5, 0.5, 0.5},           -- Pared Este
        {-0.375, -0.3125, -0.5, 0.375, 0.5, -0.375},     -- Pared Norte
        {-0.375, -0.3125, 0.375, 0.375, 0.5, 0.5},       -- Pared Sur
        {-0.375, -0.1875, -0.375, 0.375, 0.3125, 0.375},  -- Bloque de líquido asentado correctamente
        {-0.5, -0.5, -0.5, -0.375, -0.3125, -0.375},     -- Pata SW
        {0.375, -0.5, -0.5, 0.5, -0.3125, -0.375},       -- Pata SE
        {-0.5, -0.5, 0.375, -0.375, -0.3125, 0.5},       -- Pata NW
        {0.375, -0.5, 0.375, 0.5, -0.3125, 0.5},         -- Pata NE
    },
}

local function registrar_caldero_sopa(name, description, textura_sopa, item_resultado)
    core.register_node(name, {
        description = description,
        tiles = {
            "mcl_cauldrons_cauldron_top.png^" .. textura_sopa,
            "mcl_cauldrons_cauldron_bottom.png",
            "mcl_cauldrons_cauldron_side.png",
            "mcl_cauldrons_cauldron_side.png",
            "mcl_cauldrons_cauldron_side.png",
            "mcl_cauldrons_cauldron_side.png"
        },
        drawtype = "nodebox",
        paramtype = "light",
        drop = "mcl_cauldrons:cauldron",
        groups = {cracky = 2, not_in_creative_inventory = 1},
        node_box = caldero_nodebox,

        on_construct = function(pos)
            local timer = core.get_node_timer(pos)
            timer:start(1.0)
        end,

        on_timer = function(pos, elapsed)
            return procesar_hervido_sopa(pos)
        end,

        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return servir_sopa(pos, clicker, itemstack, item_resultado)
        end
    })
end

registrar_caldero_sopa("caldero_sopa:soup_mushroom", "Caldero con Sopa de Hongos", "sopa_hongos.png", "mcl_mushrooms:mushroom_stew")
registrar_caldero_sopa("caldero_sopa:soup_beetroot", "Caldero con Sopa de Remolacha", "sopa_remolacha.png", "mcl_farming:beetroot_soup")
registrar_caldero_sopa("caldero_sopa:soup_rabbit", "Caldero con Estofado de Conejo", "sopa_conejo.png", "mcl_mobitems:rabbit_stew")

if core.registered_nodes["mcl_cauldrons:cauldron_3r"] then
    local original_on_rightclick = core.registered_nodes["mcl_cauldrons:cauldron_3r"].on_rightclick

    core.override_item("mcl_cauldrons:cauldron_3r", {
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            local item_name = itemstack:get_name()
            local meta = core.get_meta(pos)

            local mapa_ingredientes = {
                ["mcl_farming:beetroot_item"]     = "remolacha",
                ["mcl_mushrooms:mushroom_red"]    = "hongo_rojo",
                ["mcl_mushrooms:mushroom_brown"]  = "hongo_marron",
                ["mcl_farming:potato_item"]       = "papa",
                ["mcl_farming:potato_item_baked"] = "papa",
                ["mcl_farming:carrot_item"]       = "zanahoria",
                ["mcl_mobitems:rabbit"]           = "conejo",
                ["mcl_mobitems:cooked_rabbit"]    = "conejo",
            }

            local tipo_ingrediente = mapa_ingredientes[item_name]

            if tipo_ingrediente then
                if not check_fuego(pos) then
                    core.chat_send_player(clicker:get_player_name(), "Necesitas encender fuego debajo del caldero para cocinar.")
                    return itemstack
                end

                local cantidad_actual = meta:get_int(tipo_ingrediente)
                meta:set_int(tipo_ingrediente, cantidad_actual + 1)
                itemstack:take_item(1)

                core.add_particlespawner({
                    amount = 10,
                    time = 0.5,
                    minpos = {x = pos.x - 0.2, y = pos.y + 0.2, z = pos.z - 0.2},
                    maxpos = {x = pos.x + 0.2, y = pos.y + 0.4, z = pos.z + 0.2},
                    minvel = {x = -0.1, y = 0.5, z = -0.1},
                    maxvel = {x = 0.1, y = 1.5, z = 0.1},
                    texture = "bubble.png",
                })

                local remolachas   = meta:get_int("remolacha")
                local hongos_rojos = meta:get_int("hongo_rojo")
                local hongos_mar   = meta:get_int("hongo_marron")
                local conejos      = meta:get_int("conejo")
                local papas        = meta:get_int("papa")
                local zanahorias   = meta:get_int("zanahoria")

                local nodo_objetivo = nil

                if remolachas >= 6 then
                    nodo_objetivo = "caldero_sopa:soup_beetroot"
                elseif hongos_rojos >= 3 and hongos_mar >= 3 then
                    nodo_objetivo = "caldero_sopa:soup_mushroom"
                elseif conejos >= 1 and papas >= 1 and zanahorias >= 1 and (hongos_rojos >= 1 or hongos_mar >= 1) then
                    nodo_objetivo = "caldero_sopa:soup_rabbit"
                end

                if nodo_objetivo then
                    core.set_node(pos, {name = nodo_objetivo})

                    local meta_soup = core.get_meta(pos)
                    meta_soup:set_int("porciones", 6)

                    local timer = core.get_node_timer(pos)
                    timer:start(1.0)

                    core.chat_send_player(clicker:get_player_name(), "¡La sopa está lista!")
                end

                return itemstack
            end

            if original_on_rightclick then
                return original_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
            end
        end
    })
end
