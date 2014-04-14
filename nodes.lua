minetest.register_node("watershed:appleleaf", {
	description = "WS Appletree Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"default_leaves.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, flammable=2, leaves=1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("watershed:acacialeaf", {
	description = "WS Acacia Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"watershed_acacialeaf.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, flammable=2, leaves=1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("watershed:acaciatree", {
	description = "WS Acacia Tree",
	tiles = {"watershed_acaciatreetop.png", "watershed_acaciatreetop.png", "watershed_acaciatree.png"},
	paramtype2 = "facedir",
	groups = {tree=1,choppy=2,oddly_breakable_by_hand=1,flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("watershed:needles", {
	description = "WS Pine Needles",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"watershed_needles.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("watershed:pinetree", {
	description = "WS Pine Tree",
	tiles = {"watershed_pinetreetop.png", "watershed_pinetreetop.png", "watershed_pinetree.png"},
	paramtype2 = "facedir",
	groups = {tree=1,choppy=2,oddly_breakable_by_hand=1,flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("watershed:jungleleaf", {
	description = "WS Jungletree Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"default_jungleleaves.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, flammable=2, leaves=1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("watershed:dirt", {
	description = "WS Dirt",
	tiles = {"default_dirt.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("watershed:grass", {
	description = "WS Grass",
	tiles = {"default_grass.png", "default_dirt.png", "default_dirt.png^default_grass_side.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

minetest.register_node("watershed:redstone", {
	description = "WS Red Stone",
	tiles = {"default_desert_stone.png"},
	is_ground_content = false,
	groups = {cracky=3},
	drop = "watershed:redcobble",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("watershed:redcobble", {
	description = "WS Red Cobblestone",
	tiles = {"watershed_redcobble.png"},
	is_ground_content = false,
	groups = {cracky=3, stone=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("watershed:stone", {
	description = "WS Stone",
	tiles = {"default_stone.png"},
	is_ground_content = false,
	groups = {cracky=3},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("watershed:cactus", {
	description = "WS Cactus",
	tiles = {"default_cactus_top.png", "default_cactus_top.png", "default_cactus_side.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy=1,choppy=3,flammable=2},
	drop = "default:cactus",
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("watershed:goldengrass", {
	description = "Golden Grass",
	drawtype = "plantlike",
	tiles = {"watershed_goldengrass.png"},
	inventory_image = "watershed_goldengrass.png",
	wield_image = "watershed_goldengrass.png",
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	is_ground_content = false,
	groups = {snappy=3,flammable=3,flora=1,attached_node=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
	},
})

minetest.register_node("watershed:drygrass", {
	description = "WS Dry Grass",
	tiles = {"watershed_drygrass.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})

minetest.register_node("watershed:permafrost", {
	description = "WS Permafrost",
	tiles = {"watershed_permafrost.png"},
	is_ground_content = false,
	groups = {crumbly=2},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("watershed:vine", {
	description = "WS Jungletree Vine",
	drawtype = "airlike",
	paramtype = "light",
	walkable = false,
	climbable = true,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	groups = {not_in_creative_inventory=1},
})

minetest.register_node("watershed:freshice", {
	description = "WS Fresh Ice",
	tiles = {"watershed_freshice.png"},
	is_ground_content = false,
	paramtype = "light",
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("watershed:cloud", {
	description = "WS Cloud",
	drawtype = "glasslike",
	tiles = {"watershed_cloud.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	post_effect_color = {a=23, r=241, g=248, b=255},
})

minetest.register_node("watershed:luxoreoff", {
	description = "WS Lux Ore Off",
	tiles = {"watershed_luxore.png"},
	light_source = 14,
	groups = {cracky=3},
	drop = "watershed:luxcrystal 8",
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("watershed:luxoreon", {
	description = "WS Lux Ore On",
	tiles = {"watershed_luxore.png"},
	light_source = 14,
	groups = {cracky=3},
	drop = "watershed:luxcrystal 8",
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("watershed:light", {
	description = "WS Light",
	tiles = {"watershed_light.png"},
	light_source = 14,
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("watershed:freshwater", {
	description = "WS Fresh Water Source",
	inventory_image = minetest.inventorycube("watershed_freshwater.png"),
	drawtype = "liquid",
	tiles = {
		{
			name="watershed_freshwateranim.png",
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=2.0}
		}
	},
	special_tiles = {
		{
			name="watershed_freshwateranim.png",
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=2.0},
			backface_culling = false,
		}
	},
	alpha = WATER_ALPHA,
	paramtype = "light",
	is_ground_content = false,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "watershed:freshwaterflow",
	liquid_alternative_source = "watershed:freshwater",
	liquid_viscosity = WATER_VISC,
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a=64, r=100, g=100, b=200},
	groups = {water=3, liquid=3, puts_out_fire=1},
})

minetest.register_node("watershed:freshwaterflow", {
	description = "WS Fresh Flowing Water",
	inventory_image = minetest.inventorycube("watershed_freshwater.png"),
	drawtype = "flowingliquid",
	tiles = {"watershed_freshwater.png"},
	special_tiles = {
		{
			image="watershed_freshwaterflowanim.png",
			backface_culling=false,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.8}
		},
		{
			image="watershed_freshwaterflowanim.png",
			backface_culling=true,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.8}
		},
	},
	alpha = WATER_ALPHA,
	paramtype = "light",
	paramtype2 = "flowingliquid",
	is_ground_content = false,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "watershed:freshwaterflow",
	liquid_alternative_source = "watershed:freshwater",
	liquid_viscosity = WATER_VISC,
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a=64, r=100, g=100, b=200},
	groups = {water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=1},
})

minetest.register_node("watershed:lava", {
	description = "WS Lava Source",
	inventory_image = minetest.inventorycube("default_lava.png"),
	drawtype = "liquid",
	tiles = {
		{name="default_lava_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=3.0}}
	},
	special_tiles = {
		{
			name="default_lava_source_animated.png",
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=3.0},
			backface_culling = false,
		}
	},
	paramtype = "light",
	light_source = 14,
	is_ground_content = false,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "watershed:lavaflow",
	liquid_alternative_source = "watershed:lava",
	liquid_viscosity = LAVA_VISC,
	liquid_renewable = false,
	liquid_range = 2,
	damage_per_second = 8,
	post_effect_color = {a=192, r=255, g=64, b=0},
	groups = {lava=3, liquid=2, hot=3, igniter=1},
})

minetest.register_node("watershed:lavaflow", {
	description = "WS Flowing Lava",
	inventory_image = minetest.inventorycube("default_lava.png"),
	drawtype = "flowingliquid",
	tiles = {"default_lava.png"},
	special_tiles = {
		{
			image="default_lava_flowing_animated.png",
			backface_culling=false,
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=3.3}
		},
		{
			image="default_lava_flowing_animated.png",
			backface_culling=true,
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=3.3}
		},
	},
	paramtype = "light",
	paramtype2 = "flowingliquid",
	light_source = 14,
	is_ground_content = false,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "watershed:lavaflow",
	liquid_alternative_source = "watershed:lava",
	liquid_viscosity = LAVA_VISC,
	liquid_renewable = false,
	liquid_range = 2,
	damage_per_second = 8,
	post_effect_color = {a=192, r=255, g=64, b=0},
	groups = {lava=3, liquid=2, hot=3, igniter=1, not_in_creative_inventory=1},
})

-- Items

minetest.register_craftitem("watershed:luxcrystal", {
	description = "WS Lux Crystal",
	inventory_image = "watershed_luxcrystal.png",
})

-- Crafting

minetest.register_craft({
	type = "cooking",
	output = "default:desert_stone",
	recipe = "watershed:redcobble",
})

minetest.register_craft({
    output = "watershed:light",
    recipe = {
        {"default:glass"},
        {"watershed:luxcrystal"},
    },
})

-- Buckets

bucket.register_liquid(
	"watershed:freshwater",
	"watershed:freshwaterflow",
	"watershed:bucket_freshwater",
	"watershed_bucketfreshwater.png",
	"WS Fresh Water Bucket"
)

bucket.register_liquid(
	"watershed:lava",
	"watershed:lavaflow",
	"watershed:bucket_lava",
	"bucket_lava.png",
	"WS Lava Bucket"
)

-- Fuel

minetest.register_craft({
	type = "fuel",
	recipe = "watershed:bucket_lava",
	burntime = 60,
	replacements = {{"watershed:bucket_lava", "bucket:bucket_empty"}},
})