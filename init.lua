-- watershed 0.1.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local YMIN = 6000
local YMAX = 8000
local TERCEN = 7008 -- Terrain centre
local YWAT = 7024 -- Sea level
local TERSCA = 512 -- Vertical terrain scale
local TSTONE = 0.02 -- Density threshold for stone
local TDIRT = 0.01 -- Density threshold for dirt
local BASAMP = 0.5 -- Base terrain amplitude
local BASEXP = 0.8 -- Base terrain exponent
local CANAMP = 0.5 -- Canyon terrain amplitude
local TRIV = -0.012 -- Maximum densitybase threshold for river water
local TSAND = -0.015 -- Maximum densitybase threshold for sand

-- 3D noise for rough terrain

local np_rough = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 6,
	persist = 0.6
}

-- 3D noise for smooth terrain

local np_smooth = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 593,
	octaves = 6,
	persist = 0.4
}

-- 2D noise for base terrain / riverbed height, terrain blend, river and river sand depth

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=4096, y=4096, z=4096},
	seed = 8890,
	octaves = 3,
	persist = 0.5
}

-- 2D noise for biomes

local np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -677772,
	octaves = 3,
	persist = 0.5
}

-- Stuff

watershed = {}

-- Nodes

minetest.register_node("watershed:grass", {
	description = "WS Grass",
	tiles = {"default_grass.png", "default_dirt.png", "default_grass.png"},
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
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("watershed:stone", {
	description = "WS Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("watershed:water", {
	description = "WS Water Source",
	inventory_image = minetest.inventorycube("default_water.png"),
	drawtype = "liquid",
	tiles = {
		{name="default_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}}
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
	liquid_alternative_flowing = "watershed:waterflow",
	liquid_alternative_source = "watershed:water",
	liquid_viscosity = WATER_VISC,
	liquid_renewable = false,
	liquid_range = 3,
	post_effect_color = {a=64, r=100, g=100, b=200},
	groups = {water=3, liquid=3, puts_out_fire=1},
})

minetest.register_node("watershed:waterflow", {
	description = "WS Flowing Water",
	inventory_image = minetest.inventorycube("default_water.png"),
	drawtype = "flowingliquid",
	tiles = {"default_water.png"},
	special_tiles = {
		{
			image="default_water_flowing_animated.png",
			backface_culling=false,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.8}
		},
		{
			image="default_water_flowing_animated.png",
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
	liquid_alternative_flowing = "watershed:waterflow",
	liquid_alternative_source = "watershed:water",
	liquid_viscosity = WATER_VISC,
	liquid_renewable = false,
	liquid_range = 3,
	post_effect_color = {a=64, r=100, g=100, b=200},
	groups = {water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=1},
})

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y < YMIN or maxp.y > YMAX then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[watershed] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	local c_dirt = minetest.get_content_id("default:dirt")
	
	local c_wswater = minetest.get_content_id("watershed:water")
	local c_wsstone = minetest.get_content_id("watershed:stone")
	local c_wsredstone = minetest.get_content_id("watershed:redstone")
	local c_wsgrass = minetest.get_content_id("watershed:grass")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}
	
	local nvals_rough = minetest.get_perlin_map(np_rough, chulens):get3dMap_flat(minposxyz)
	local nvals_smooth = minetest.get_perlin_map(np_smooth, chulens):get3dMap_flat(minposxyz)
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get2dMap_flat(minposxz)
	
	local nixyz = 1
	local nixz = 1
	local stable = {}
	for z = z0, z1 do -- for each xy plane progressing northwards
		for x = x0, x1 do
			local si = x - x0 + 1
			local nodename = minetest.get_node({x=x,y=y0-1,z=z}).name
			if nodename == "air"
			or nodename == "default:water_source" then
				stable[si] = 0
			else
				stable[si] = 2
			end
		end
		for y = y0, y1 do -- for each x row progressing upwards
			local vi = area:index(x0, y, z)
			for x = x0, x1 do -- for each node do
				local si = x - x0 + 1
				local grad = (TERCEN - y) / TERSCA
				local n_base = nvals_base[nixz]
				local terblen = math.max(1 - math.abs(n_base) ^ BASEXP, 0)
				local densitybase = terblen * BASAMP
				+ grad
				local triv = TRIV * (1 - terblen)
				local tsand = TSAND * (1 - terblen)
				local tstone = TSTONE -- by height not terblen
				local canexp = 1.2
				local density = densitybase
				+ math.abs(nvals_rough[nixyz] * terblen + nvals_smooth[nixyz] * (1 - terblen)) ^ canexp * CANAMP
				local n_biome = nvals_biome[nixz]
				
				if density >= tstone then -- stone
					if n_biome > 0.5 then
						data[vi] = c_wsredstone
					else
						data[vi] = c_wsstone
					end
					stable[si] = stable[si] + 1
				elseif density >= 0 and density < tstone and stable[si] >= 2 then -- fine materials
					if densitybase >= tsand or y <= YWAT + math.random(3) then
						data[vi] = c_sand -- riverbed, seabed
					else
						if n_biome > 0.5 then
							data[vi] = c_desand
						elseif density > TDIRT then
							data[vi] = c_dirt
						elseif n_biome < -0.5 then
							data[vi] = c_snowblock
						else
							data[vi] = c_wsgrass
						end
					end
				elseif y <= YWAT then -- sea level water
					data[vi] = c_water
					stable[si] = 0
				elseif densitybase >= triv then -- river water
					data[vi] = c_wswater
					stable[si] = 0
				else
					data[vi] = c_air
					stable[si] = 0
				end
				nixyz = nixyz + 1 -- increment 3D noise index
				nixz = nixz + 1 -- increment 2D noise index
				vi = vi + 1
			end
			nixz = nixz - 80 -- rewind 2D noise index by 80 nodes for next x row above
		end
		nixz = nixz + 80 -- fast-forward 2D noise index by 80 nodes for next northward xy plane
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[watershed] "..chugent.." ms")
end)