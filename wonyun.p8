pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- Project Wonyun
-- by Juno Nguyen

-- component entity system and utility functions

-- sfx note
-- 00 player fire
-- 01 explosion

c = {
	shadow_offset = 2,
	bounds_offset = 64,

	player_firerate = 5,

	spawnrate_min = 45, -- in ticks
	spawnrate_range = 45, -- in ticks
}

world = {}

function _has(e, ks)
	for c in all(ks) do
        if (not e[c]) then 
            return false
        end
    end
    return true
end

function system(ks, f)
    return function(system)
        for e in all(system) do
            if _has(e, ks) then
                f(e)
            end
        end
    end
end

function getid(_id)
    t = {}
    for e in all(world) do
		if (e.id) then
			if (e.id.class == _id) then
				add(t, e)
			end
        end
    end
    return t
end

-- basic AABB collision detection using pos and box components
function coll(e1, e2)
    if e1.pos.x < e2.pos.x + e2.box.w and
        e1.pos.x + e1.box.w > e2.pos.x and
        e1.pos.y < e2.pos.y + e2.box.h and
        e1.pos.y + e1.box.h > e2.pos.y then

        return true
    end
    return false
end

function palall(_color) -- switch all colors to target color
	for color=1, 15 do 
		pal(color, _color)
	end
end

-- switch all color to white (7) for a flashing effect when entity is damaged
function palforhitframe(_entity) 
	if (_entity.hitframe) then palall(7) end
end

fader = {
	time = 0,
	pos = 0, -- full black, according to the table
	projected_time_taken = 0,
	projected_velocity = 0,
	table= {
		-- position 15 is all black
		-- position 0 is all bright colors
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		{1,1,1,1,1,1,1,0,0,0,0,0,0,0,0},
		{2,2,2,2,2,2,1,1,1,0,0,0,0,0,0},
		{3,3,3,3,3,3,1,1,1,0,0,0,0,0,0},
		{4,4,4,2,2,2,2,2,1,1,0,0,0,0,0},
		{5,5,5,5,5,1,1,1,1,1,0,0,0,0,0},
		{6,6,13,13,13,13,5,5,5,5,1,1,1,0,0},
		{7,6,6,6,6,13,13,13,5,5,5,1,1,0,0},
		{8,8,8,8,2,2,2,2,2,2,0,0,0,0,0},
		{9,9,9,4,4,4,4,4,4,5,5,0,0,0,0},
		{10,10,9,9,9,4,4,4,5,5,5,5,0,0,0},
		{11,11,11,3,3,3,3,3,3,3,0,0,0,0,0},
		{12,12,12,12,12,3,3,1,1,1,1,1,1,0,0},
		{13,13,13,5,5,5,5,1,1,1,1,1,0,0,0},
		{14,14,14,13,4,4,2,2,2,2,2,1,1,0,0},
		{15,15,6,13,13,13,5,5,5,5,5,1,1,0,0}
	}
}

function fadein()
	fade(15, 0, 1)
end

function fadeout()
	fade(0, 15, 1)
end

function fade(_begin, _final, _durationinsecs)
	-- 30 ticks equal one second
	fader.projected_time_taken = _durationinsecs * 30
	-- elementary math of v = d/t
	fader.projected_velocity = (_final - _begin) / fader.projected_time_taken
	fader.pos = _begin
	fader.time = 0
	fader.status = "working"

end

function fade_update()
	-- TODO clean up and write something more optimal
	if (fader.time < fader.projected_time_taken) then
		fader.time +=1
		fader.pos += fader.projected_velocity
	end
end

function fade_draw(_position)
	-- for debug
	-- print(fader.pos)
	-- print(fader.projected_time_taken)
	-- print(fader.projected_velocity)
	-- print(fader.time)
	-- pal()
	for c=0,15 do
		if flr(_position+1)>=16 then
			pal(c,0)
		else
			pal(c,fader.table[c+1][flr(_position+1)],1)
		end
	end
end

function fadesettrigger(_trigger)
	if _trigger then
		fader.trigger = _trigger
		fader.triggerperformed = false
	end
end

-->8
-- primary game loops

gamestate = {}

-- each state is an object with loop functions

splashstate = {
	name = "splash",
	init = function()
		fadein()
		splashtimer =45
	end,
	update = function()
		if (splashtimer > 0) then
			splashtimer -= 1
		else
			transit(menustate)
		end
	end,
	draw = function()
		-- draw logo at sprite number 64
		spr(64, 32, 48, 64, 32)
	end
}

menustate = {
	name = "menu",
	init = function()
		fadein()
	end,
	update = function()
		if (btn(5)) then 
			transit(gameplaystate)
		end
	end,
	draw = function()
		print("project wonyun", 16, 16, 8)
		print("lives left: 47", 16, 32, 7)
		print("weapon level: 2", 16, 64, 7)
		print("armor level: 4", 16, 72, 7)
		print("press x to send another ship", 16, 120, 7)
		spr(1, 12, 12)
	end
}

gameplaystate = {
	name = "gameplay",
	init = function()
		fadein()
		world = {}
		player(64, 64)

		hammerhead(64, 32)
		hammerhead(32, 32)
		hammerhead(96, 32)
	
		timer(1, function()
			hammerhead(12, 12)
		end)
	end,
	update = function()
		spawner_update()
		screenshake_update()
		for key,system in pairs(updatesystems) do
			system(world)
		end

	end,
	draw = function()
		print(count(world))
		for system in all(drawsys) do
			system(world)
		end

		-- debug
		if (spawncooldown) then print(spawncooldown) end
	end
}

transitor = {
	timer = 0,
	destination_state,
}


transitstate = {
	name = "transit",
	init = function()

	end,
	update = function()
		if (transitor.timer > 0) then
			transitor.timer -=1
		else 
			gamestate = transitor.destination_state
			gamestate.init()
		end
	end,
	draw = function()

	end
}

function transit(_state)
	fadeout()
	gamestate = transitstate
	transitor.destination_state = _state
	transitor.timer = 28
end

function _init()
	gamestate = gameplaystate
	gamestate.init()
end

function _update()
	gamestate.update()
	fade_update()
end

function _draw()
	-- due to interference with fading
	if (gamestate.name ~= "transit") cls()

	gamestate.draw()
	fade_draw(fader.pos)
end

-->8
-- update system
updatesystems = {
	timersys = system ({"timer"},
		function(e)
			if (e.timer.lifetime > 0) then
				e.timer.lifetime -= 1
			else
				e.timer.trigger()
				del(world, e)
			end
		end
	),
	motionsys = system({"pos", "vel"},
		function(e) 
			e.pos.x += e.vel.x
			e.pos.y += e.vel.y
		end
	),
	animationsys = system({"ani"},
		function(e)
			if (e.ani.loop) then
				if (e.ani.frame < e.ani.framecount) then
					e.ani.frame += e.ani.framerate
				else
					e.ani.frame = 0
				end
			else
				if (e.ani.frame < e.ani.framecount - 1) then
					e.ani.frame += e.ani.framerate
				end
			end
			
		end
	),
	collisionsys = system({"id", "pos", "box"},
		function(e1)
			if (e1.id.class == "fbullet") then
				enemies = getid("enemy")
				for e2 in all(enemies) do
					if coll(e1, e2) then
						del(world, e1)
						e2.hp -= 1
						e2.hitframe = true
					end
				end
			end
		end
	),
	healthsys = system({"hp"},
		function(e)
			if e.hp == 0 then
				-- explosion(e.pos.x, e.pos.y)
				screenshake(7, 0.3)
				sfx(1)
				del(world, e)
			end
		end
	),
	playerweaponsystem = system({"playerweapon"},
		function(e)
			if (e.playerweapon.cooldown >0) then
				e.playerweapon.cooldown -= 1
			end
		end
	),
	keepinboundssys = system({"keepsinbounds"},
		function(e)
			e.pos.x = min(e.pos.x, 128)
			e.pos.x = max(e.pos.x, 0)
			e.pos.y = min(e.pos.y, 128)
			e.pos.y = max(e.pos.y, 0)
		end
	),
	outofboundsdestroysys = system({"outofboundsdestroy"},
		function(e)
			-- local bounds_offset = 64
			if (e.pos.x > 128 + c.bounds_offset)
				or (e.pos.x < 0 - c.bounds_offset)
				or (e.pos.y > 128 + c.bounds_offset)
				or (e.pos.y < 0 - c.bounds_offset) then
				
				del(world, e)
			end
		end
	),
	controlsys = system({"playercontrol"},
		function(e)
			-- local speed = 5

			local speed = (btn(4)) and 2 or 6

			e.vel.x, e.vel.y = 0, 0

			if (btn(0)) e.vel.x = -speed
			if (btn(1)) e.vel.x = speed
			if (btn(2)) e.vel.y = -speed
			if (btn(3)) e.vel.y = speed

			-- diagonal etiquette
			if (e.vel.x * e.vel.y ~= 0) then
				e.vel.x *= 0.707
				e.vel.y *= 0.707
			end

			if (btn(5)) then
				if (e.playerweapon.cooldown <=0) then
					sfx(0)
					fbullet(e.pos.x, e.pos.y-5)
					e.playerweapon.cooldown = c.player_firerate
					-- e.playerweapon.ammo -= 1
				end
			end
		end
	)
}
-->8
-- draw systems
drawsys = {
	-- draw shadow
	system({"draw", "shadow"},
		function(e)
			
			-- -- distance from object to shadow
			-- local offset = 2

			-- palall(1)
			-- if (e.id.class == "enemy") then
			-- 	if (e.id.subclass == "hammerhead") then
			-- 		spr(32, e.pos.x-3+offset, e.pos.y+offset, 2, 2)
			-- 		-- rect(0, 0, 10, 10)
			-- 	end
			-- elseif (e.id.class == "player") then
			-- 	spr(0, e.pos.x+offset, e.pos.y+offset, 1.2, 2)
			-- end

			-- pal()

			palall(1)
			e:draw(c.shadow_offset)
			pal()
		end
	),
	-- draw sprites
	system({"draw"},
		function(e)

			e:draw()
			
		end
	),
	-- draw collision boxes, for debug purposes
	system({"pos", "box"},
		function(e)
			-- rect(e.pos.x, e.pos.y, e.pos.x + e.box.w, e.pos.y+ e.box.h, 8)
		end
	),
}

-->8
-- spawner

spawncooldown = 0

function spawner_update()
	if spawncooldown > 0 then
		spawncooldown -= 1
	else 
		spawn()
		spawn_cooldown_reset()
	end
end

function spawn_cooldown_reset()
	spawncooldown = c.spawnrate_min + flr(rnd(c.spawnrate_range))
end

function spawn()
	local die = ceil(rnd(6))

	hammerhead(rnd(128), -rnd(60))
	spawn_cooldown_reset()
end

screenshake_timer = 0
screenshake_mag = 0

function screenshake(_magnitude, _lengthinseconds)
	screenshake_timer = _lengthinseconds * 30
	screenshake_mag = _magnitude
end

function screenshake_update()
	if (screenshake_timer>0) then
		screenshake_timer -= 1
		camera(rnd(screenshake_mag),rnd(screenshake_mag))
	else
		camera()
	end
end
 
-->8
-- entity constructors

function player(_x, _y)

    add(world, {
        id = {
            class = "player"
        },
        pos = {
            x=_x,
            y=_y,
        },
        vel = {
            x=0,
            y=0,
        },
        box = {
            w = 4,
            h = 12,
		},
		hp = 4,
		playerweapon = {
			ammo = 4,
			cooldown = 0
		},
		playercontrol = true,
		keepsinbounds = true,
		shadow = true,
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0

			spr(0, self.pos.x-2, self.pos.y, 1.2, 2)
				
			-- left gauge, hp
			for i=1,(self.hp) do
				circ(self.pos.x-5, self.pos.y + 14 - i*2, 0, 11)
			end
		end
	})
end

function hammerhead(_x, _y)

    add(world, {
        id = {
            class = "enemy",
            subclass = "hammerhead"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=1
        },
        box = {
            w = 9,
            h = 16
		},
		hitframe = false,
		hp = 6,
		weapon = true,
		shadow = true,
		outofboundsdestroy = true,
		draw = function(self, _offset)
			_offset = (_offset) and _offset or 0

			palforhitframe(self) 
			spr(32, self.pos.x-3+_offset, self.pos.y+_offset, 2, 2)
			self.hitframe = false
			pal()

			-- left gauge, hp
			for i=1,(self.hp) do
				circ(self.pos.x-5, self.pos.y + 16 - i*2, 0, 11)
			end
		end
    })
end

-- friendly bullet
function fbullet(_x, _y)

	local speed = -12
	-- local speed = -3

    add(world, {
        id = {
            class = "fbullet"
        },
        pos = {
            x=_x,
            y=_y
        },
        vel = {
            x=0,
            y=speed
        },
        box = {
            w = 5,
            h = 6
		},
		ani = {
			frame = 0, -- determining which frame of the animation is being displayed
			framerate = 1, -- how fast the frame rotates, 1 is one frame per one tick
			framecount = 2, -- 
			loop = false,
		},
		outofboundsdestroy = true,
		draw = function(self)
			if (flr(self.ani.frame) == 0) then
				spr(18, self.pos.x, self.pos.y, 1, 1)
			elseif (flr(self.ani.frame) == 1) then
				spr(19, self.pos.x, self.pos.y, 1, 1)
			end

			if (self.ani.frame) then print(self.ani.frame) end
		end
    })
end

function timer(_lifetimeinsec, _f) 
    add(world, {
        timer = {
            -- 30 frames take up one second
            lifetime = _lifetimeinsec * 30,
            trigger = _f
        }
    })
end

__gfx__
0000c00000000000ccccc000cccc0000000000000000000000000000000000000000000000000000000000800000000000088000000000000000000000000000
000ccc0000000000ccccc000cccc0000000000000000000000000000000000000000000000000000000008880000000000888800000880000000000000000000
000ccc0000000000ccccc000ccccc000000000000000888888888888888888888888000000000000000088888000000008800880008888000008800000000000
000ccc0000000000cc0c0000c00cc000000000000000088888888888888888888880000000000000000888088800000088000088088008800088880000088000
00ccccc000000000c000000000000000000000000000008888888888888888888800000000000000008880008880000088000088088008800088880000088000
00ccccc0000000000000000000000000000000000000000888888888888888888000000000000000088800000888000008800880008888000008800000000000
00ccccc0000000000000000000000000000000000000000688888888888888886000000000000000888000000088800000888800000880000000000000000000
0ccccccc000000000000000000000000000000000000006668888888888888866600000000000000088800000888000000088000000000000000000000000000
0ccc6ccc000000000aaa0000bbbbb000000000000000066666888888888888666660000000000000008880008880000000000000000000000000000000000000
0cc666cc00000000aaaaa000bbbbb000000000000000666666688888888886666666000000000000000888088800000000000000000000000000000000000000
ccc666ccc0000000aaaaa000bbbbb000000000000006666666668888888866666666600000000000000088888000000000000000000000000000000000000000
ccc666ccc0000000aaaaa000bbbbb000000000000066666666666888888666666666660000000000000008880000000000000000000000000000000000000000
0006660000000000aaaaa000bbbbb000000000000666666666666688886666666666666000000000000000800000000000000000000000000000000000000000
0000000000000000aaaaa000bbbbb000000000006666666666666668866666666666666600000000000000000000000000000000000000000000000000000000
0000000000000000aaaaa000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000aaa0000b000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050005500050006000000000600000600000000000000660000000000000060000000000000000000000080000000000000000800000000000000000000000
00555065560555006600000006600000660000000000006666000000000000660000000000000000000000888000000000000008080000000000000000000000
00055566665550006660050066600000666000000000066666600000000006660000000000000000000008808800000000000080008000000000000000000000
00005556655500000666555666000000666600000000666666660005500066660000000000000000000088000880000000000800000800000000000000000000
00000556655000000066656660000000666660055006666666666055550666660000000000000000000880000088000000008000000080000000000000000000
00000656656000000006656600000000066666655666666066666555555666660000000000000000008800000008800000080000000008000000000000000000
00000066660000000008656800000000086666555566668066666558855666660000000000000000088000000000880000800000000000800000000000000000
00000086680000000088858880000000088666555566688066666558855666660000000000000000880000000000088008000000000000080000000000000000
00000886688000000888555888000000088866555566888006666558855666600000000000000000088000000000880080000000000000800000000000000000
00000886688000000880000088000000008886555568880000666558855666000000000000000000008800000008800008000000000008000000000000000000
00000086680000000800000008000000000888555588800060066588885660060000000000000000000880000088000000800000000080000000000000000000
00000066660000000000000000000000000088855888000066056585585650660000000000000000000088000880000000080000000800000000000000000000
00000556655000000000000000000000000008888880000006655585585556600000000000000000000008808800000000008000008000000000000000000000
00066665566660000000000000000000000000888800000000665555555566000000000000000000000000888000000000000800080000000000000000000000
00866665566668000000000000000000000000088000000000066558855660000000000000000000000000080000000000000080800000000000000000000000
00866688886668000000000000000000000000000000000000006658856600000000000000000000000000000000000000000008000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000077777770077777077777077777007777707777707077077777770000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707700070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007777707000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070070007070007070007007000007000707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000070070070077707070007077707007000007770707000070070070000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000c0510c0510c0510c0510c0510c0510c0513a0013900134001320012d001250011f0011d0011d0011f001210010000125001260012200100001000010000100001000010000100001000010000100001
0101000024157281572b15731157311572f1572915725157211571c1571b1571b1571b1571b1571e15723157281572f1573915700107001070010700107001070010700107001070010700107001070010700107
