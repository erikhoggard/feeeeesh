pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
	
function _init()

--shooty stuff

 t=0
 anim_t=30
 fishingline_x=64

 segment = {
   waves={},
 }
 
 ship = {
  sp=1,
  x=60,
  y=100,
  h=4,
  p=0,
  t=0,
  imm=false,
  box = {x1=0,y1=0,x2=7,y2=7}
 }
 bullets = {}
 enemies = {}
 enemy_bullets = {}
 explosions = {}
 stars = {}
 
 for i=1,32 do
  add(stars,{
   sp=((rnd(5)>=2) and 48 or 49),
   x=rnd(128),
   y=rnd(128),
   s=rnd(1)+3
  })
 end 

 --overworld stuff
 make_ow_player()
 overworld_map_setup()
 
 start()
end

function create_segment(wave_count,difficulty) 
  for i=1,wave_count do
    add(segment.waves, create_wave(difficulty))
  end
end

function create_wave(difficulty) 
  -- TODO implement difficulty
  new_wave={}
  if rnd(100)<=50 then
    -- GREEN FISH, does not shoot
    local n = 3*flr(rnd(difficulty))+2
    for i=1,n do
      local d = -1
      if rnd(1)<0.5 then d=1 end
      add(new_wave,{
        hp=1,
        sp=16,
        y_speed=1.3,
        m_x=((i%6)*(128/8))+20,
        m_y=-16-i*4,
        d=d,
        x=-32,
        y=-32,
        r=12,
        move_x = function(self) self.x = self.r*sin(self.d*t/50) + self.m_x end,
        move_y = function(self) self.y = self.r*cos(t/50) + self.m_y end,
        shoot = function(self) end,
        box = {
          x1=0,y1=0,x2=7,y2=7
        }
      })
    end
  else
    -- RED FISH, DOES shoot
    local n = flr(rnd(difficulty))+2
    for i=1,n do
      local d = -1
      if rnd(1)<0.5 then d=1 end
      add(new_wave,{
        hp=1,
        sp=25,
        y_speed=1.3,
        m_x=((i%6)*(128/8))+20,
        m_y=-(flr(i/6)*16),
        d=1,
        x=-32,
        y=(flr(i/6)*16)-(16*(n/6))-8,
        r=4,
        move_x = function(self) self.x = self.r*sin(self.d*t/50) + self.m_x end,
        move_y = function(self) self.y+=1 end,
        shoot = function(self)
          -- if multiple enemies use this, genericize it
          if self.y>-4 and t%45==0 then
            add(enemy_bullets,{
              sp = 8,
              x = self.x,
              y = self.y,
              angle = atan2(ship.x-self.x, ship.y-self.y),
              move = function(self) 
                -- speed is 2
                -- for seeking, put the angle calc in here or lerp
                self.x+=3*cos(self.angle)
                self.y+=3*sin(self.angle)
              end,
              box = {
                x1=2,y1=2,x2=5,y2=5
              }
            })
          end
        end,

        box = {
          x1=0,y1=0,x2=7,y2=7
        }
      })
    end
  end
  return new_wave
end

function respawn()
  enemies=create_wave(8)
end



function start()
 _update = update_overworld
 _draw = draw_overworld
end

function game_over()
 _update = update_over
 _draw = draw_over
end

function update_over()

end

function draw_over()
 cls()
 print("game over",50,50,4)
end


function abs_box(s)
 local box = {}
 box.x1 = s.box.x1 + s.x
 box.y1 = s.box.y1 + s.y
 box.x2 = s.box.x2 + s.x
 box.y2 = s.box.y2 + s.y
 return box

end

function coll(a,b)

 local box_a = abs_box(a)
 local box_b = abs_box(b)
 
 if box_a.x1 > box_b.x2 or
    box_a.y1 > box_b.y2 or
    box_b.x1 > box_a.x2 or
    box_b.y1 > box_a.y2 then
    return false
 end
 return true 
end

function explode(x,y)
 add(explosions,{x=x,y=y,t=0})
end

function fire()
 local b = {
  sp=3,
  x=ship.x,
  y=ship.y,
  dx=0,
  dy=-3,
  box = {x1=2,y1=0,x2=5,y2=4}
 }
 add(bullets,b)
end

function update_shoot()
 t=t+1

  if(t%2==0) then
    if(fishingline_x > ship.x+4) then
      fishingline_x-=1
    end
    if(fishingline_x < ship.x+4) then
      fishingline_x+=1
    end
  end
 
 if ship.imm then
  ship.t += 1
  if ship.t >30 then
   ship.imm = false
   ship.t = 0
  end
 end
 
 
 for st in all(stars) do
  st.y += st.s
  if st.y >= 128 then
   st.y = 0
   st.x=rnd(128)
  end
 end
 
 for ex in all(explosions) do
  ex.t+=1
  if ex.t == 13 then
   del(explosions, ex)
  end
 end
 
 if #enemies <= 0 then
  respawn()
 end
 
 for e in all(enemies) do
  e.m_y += e.y_speed 
  e.move_x(e)
  e.move_y(e)
  e.shoot(e)
  if coll(ship,e) and not ship.imm then
    ship.imm = true
    ship.h -= 1
    if ship.h <= 0 then
     game_over()
    end
  end
  
  if e.y > 150 then
   del(enemies,e)
  end
 end

 for eb in all(enemy_bullets) do 
  eb.move(eb)
  if coll(ship,eb) and not ship.imm then
    ship.imm = true
    ship.h -= 1
    del(enemy_bullets,eb)
    if ship.h <= 0 then
     game_over()
    end
  end
 end
 
 for b in all(bullets) do
  b.x+=b.dx
  b.y+=b.dy
  if b.x < -8 or b.x > 128 or
   b.y < -8 or b.y > 128 then
   del(bullets,b)
  end
  for e in all(enemies) do
   if coll(b,e) then
    e.hp-=1
    del(bullets,b)
    if(e.hp<=0)then
      del(enemies,e)
      ship.p += 1
    end
    --TODO this is a temporary wincon
    if(ship.p >= 25) then
      _update=update_overworld
      _draw=draw_overworld
    end
    ---------------------------------
    explode(e.x,e.y)
   end
  end
 end
 if(t%6<3) then
  ship.sp=1
 else
  ship.sp=2
 end
 
 if btn(0) then ship.x-=1 end
 if btn(1) then ship.x+=1 end
 if btn(2) then ship.y-=1 end
 if btn(3) then ship.y+=1 end
 if btnp(4) then fire() end
end

function lv(v1,v2,t)
    return (1-t)*v1+t*v2
end

--Quadratic Bezier Curve Vector
function qbcvector(v1,v2,v3,t) 
    return  lv(lv(v1,v3,t), lv(v3,v2,t),t)
end
--draw Quadratic Bezier Curve
--x1,y1 = starting point 
--x2,y2 = end point
--x3,y3 = 3rd manipulating point 
--n = "amount of pixels in curve"(just put it higher than you expect)
--c = color
function drawqbc(x1,y1,x2,y2,x3,y3,n,c)
    for i = 1,n do 
        local t = i/n
       pset(qbcvector(x1,x2,x3,t),qbcvector(y1,y2,y3,t),c)
    end
end

-- cubic bezier curve vector
--x1,y1 = starting point 
--x2,y2 = end point
--x3,y3 = 3rd manipulating point 
--x4,y4 = 4th manipulating point 
--n = "amount of pixels in curve"(just put it higher than you expect)
--c = color
function cbcvector(v1,v2,v3,v4,t) 
    return  lv(qbcvector(v1,v2,v3,t), qbcvector(v1,v2,v4,t),t)
end
--draw cubic bezier curve
function drawcbc(x1,y1,x2,y2,x3,y3,x4,y4,n,c)
    for i = 1,n do 
        local t = i/n
        pset(cbcvector(x1,x2,x3,x4,t),cbcvector(y1,y2,y3,y4,t),c)
    end
end

function draw_shoot()
 cls(1)
 drawcbc(ship.x+4,ship.y+8, fishingline_x,148, ship.x,ship.y+32, fishingline_x,(128-(128-ship.y)/3), 200,7)
 for st in all(stars) do
  --pset(st.x,st.y,12)
  spr(st.sp,st.x,st.y)
 end
 
 print(ship.p.."/5",9)
 if not ship.imm or t%8 < 4 then
  spr(ship.sp,ship.x,ship.y)
  spr(17,ship.x,ship.y+8)
 end
 
 for ex in all(explosions) do
  circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
 end
  
 for b in all(bullets) do 
  spr(b.sp,b.x,b.y)
 end

 for eb in all(enemy_bullets) do 
  spr(eb.sp,eb.x,eb.y)
 end
 
 for e in all(enemies) do
  spr(e.sp,e.x,e.y)
 end
 
 for i=1,4 do
  if i<=ship.h then 
  spr(32,80+6*i,3)
  else
  spr(33,80+6*i,3)
  end
 end
end


-->8
--here be the overworld; 
--beware, ye who enter
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

function overworld_map_setup()
  --map tile settings
  --most of these will not be used
  wall=0
  key=1
  door=2
  anim1=3
  anim2=4
  enemy=5
  win=7

  cx,cy=0,0
  ow_p_trans_speed=.15
  transition_speed=.35

  map_init()
end


function draw_overworld_map()
  mapx=flr(op.x/16)*16
  mapy=flr(op.y/16)*16

  cx_diff=mapx*8-cx
  cy_diff=mapy*8-cy
  if (abs(cx_diff)<0.1) cx_diff=0
  if (abs(cy_diff)<0.1) cy_diff=0
  cx_diff*=transition_speed
  cy_diff*=transition_speed
  cx+=cx_diff
  cy+=cy_diff

  camera(round(cx),round(cy))

  map(0,0,0,0,128,64)
end

function update_ow_map()
  if(t%anim_t==0) then
    toggle_tiles()
  end
end

function draw_overworld()
  cls()
  draw_overworld_map()
  draw_ow_player()
  if(btn(❎)) show_inventory()
end

function update_overworld()
	t+=1
  update_ow_map()
  move_ow_player()
end

function make_ow_player()
  op={}
  op.x=3
  op.y=2
  op.sprite=80
  op.keys=0
end

flipy=false

function draw_ow_player()
		y_offset=0
		if t%anim_t==0 then
			flipy=not flipy
		end
		if flipy then
				y_offset=1
		end
  spr(op.sprite,op.x*8,(op.y*8)-y_offset)
end

function is_tile(tile_type,x,y)
  tile=mget(x,y)
  has_flag=fget(tile,tile_type)
  return has_flag
end

function can_move(x,y)
  return not is_tile(wall,x,y)
end

function swap_tile(x,y)
  tile=mget(x,y)
  mset(x,y,tile+1)
end

function unswap_tile(x,y)
  tile=mget(x,y)
  mset(x,y,tile-1)
end

function get_key(x,y)
  op.keys+=1
  swap_tile(x,y)
  sfx(1)
end

function open_door(x,y)
  op.keys-=1
  swap_tile(x,y)
  sfx(2)
end

--overworld interactions

function move_ow_player()
  newx=op.x
  newy=op.y

  if(btnp(⬅️)) newx-=1
  if(btnp(➡️)) newx+=1
  if(btnp(⬆️)) newy-=1
  if(btnp(⬇️)) newy+=1
  
  interact(newx,newy)
  
  if(can_move(newx,newy)) then
    op.x=mid(0,newx,127)
    op.y=mid(0,newy,63)
  else
    --play the sound
    sfx(0)
  end
end

function interact(x,y)
  if (is_tile(key,x,y)) then 
    get_key(x,y)
  elseif (is_tile(door,x,y) and op.keys>0) then
    open_door(x,y)
  elseif (is_tile(enemy,x,y)) then
    enter_combat(x,y)
  end
end

function enter_combat(x,y)
    mset(x,y,64)
    ship.p=0
    _update=update_shoot
    _draw=draw_shoot
    camera(0,0)
end

-->8
--menu
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

function show_inventory()
  invx=mapx*8+40
  invy=mapy*8+8

  rectfill(invx,invy,invx+48,invy+24,0)
  print("inventory",invx+7,invy+4,7)
  print("keys "..op.keys,invx+12,invy+14,9)
  print("cx "..cx,invx+17,invy+20,9)
end




-->8
--animation code
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function toggle_tiles()
  for x=mapx,mapx+15 do
    for y=mapy,mapy+15 do
      if(is_tile(anim1,x,y)) then
        swap_tile(x,y)
      elseif (is_tile(anim2,x,y)) then
        unswap_tile(x,y)
      end
    end
  end
end


-->8
--util
function round(num)
  return flr(num+0.5)
end


-->8
--init
function map_init()

  x=0
  y=0
  --screen size
  width=128
  height=64
  --chance for tile to spawn
  wall_chance=0.5

  death_limit=3
  birth_limit=4

  --init random tiles
  function random_map()
    --cycle through screen
    for x=0,width do
      for y=0,height do
        if rnd() < wall_chance then
          --draw tiles
          mset(x,y,64)
        end
      end
    end
  end

  --make smoothing stage
  function make_step()
    --cycle through screen
    for x=0,width do
      for y=0,height do
        --# of bordering tiles
        local neighbor_tiles=count_neighbors(x,y)
        --kill alive cells
        if mget(x,y)==64 then
          if neighbor_tiles<death_limit then
            mset(x,y,67)
          else
            mset(x,y,64)
          end
        --birth dead cells
        elseif mget(x,y)==0 then
          if neighbor_tiles>birth_limit then
            mset(x,y,64)
          else
            mset(x,y,67)
          end
        end      
      end
    end
  end

  --looks at 8 neighbor cells
  function count_neighbors(x,y)
    --variable we want returned
    --(# of wall tiles found)
    local count=0

    for i=-1,1 do
      for j=-1,1 do
        --cycle through points
        local neighbor_x=x+i
        local neighbor_y=y+j
        --if at center point
        if i==0 and j==0 then
        --do nothing

        --if off edge of map
        elseif neighbor_x<0
            or neighbor_y<0
            or neighbor_x>=width
            or neighbor_y>=height then
          count+=1
        --normal point check
        elseif mget(neighbor_x,neighbor_y)==64 then
          count+=1
        end
      end
    end
    return count 
  end

  --create the cave
  function generate_map()
    --simulate random screen
    random_map()

    --make smoothing stage
    for i=1,4 do
      make_step()
    end

    for x=0,width do
      for y=0,height do
        if(mget(x,y==64) and rnd(100)>=99) then
          mset(x,y,98)
        end
      end
    end
  end

  --init cave
  generate_map()

end

__gfx__
000000000009900000099000000000000000600000000000000000000000000000000000b0b00000000000000000000000000000000000000000000000000000
00000000009c7900009c79000000000000000700000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000
00700700009cc900009cc90000099000060000700000000000000000000000000008800003000000000000000000000000000000000000000000000000000000
000770000699990006999900009aa900076000700000000000000000000000000086780003330000000000000000000000000000000000000000000000000000
000770006099990060999900009aa900060000700000000000000000000000000086680000b33300000000000000000000000000000000000000000000000000
0070070000099000000990000009900006000070000000000000000000000000000880000bbb3333000000000000000000000000000000000000000000000000
00000000000990000009900000000000006666000000000000000000000000000000000000033363000000000000000000000000000000000000000000000000
00000000000990000009900000000000000000000000000000000000000000000000000000000333000000000000000000000000000000000000000000000000
b0b00000000161000000600000067000000600000000000000000000000000000000000090900000000000000000000000000000000000000000000000000000
0b000000001117100000070060066006000600000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000
03000000016117100600007076067067000070000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000
03330000017617100760007060067006007007000000000000000000000000000000000008880000000000000000000000000000000000000000000000000000
00b33300016117100600007006600660060000700000000000000000000000000000000000988800000000000000000000000000000000000000000000000000
0bbb3333001661000600007000000000060000700000000000000000000000000000000009998888000000000000000000000000000000000000000000000000
00033363000110000066660000000000006666000000000000000000000000000000000000088868000000000000000000000000000000000000000000000000
00000333000000000000000000000000000000000000000000000000000000000000000000000888000000000000000000000000000000000000000000000000
08080000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888000555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08880000055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc000000c000000000000000000000000dddd000000000030033003000000000000000000000000000000000000000000000000000000000000000000000000
c07c0000c0c0000000000000000000000d2222d00000000003300330000000000000000000000000000000000000000000000000000000000000000000000000
c00c00000c0000000000000000000000d222222d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc00000000000000000000000666600d222222d0000000030033003000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006d6d6600d2772d00000000003300330000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000006d6dd6d60d2772d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000055555555ddd6666d0000000030033003000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000dddddd00dddddd00000000003300330000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccbbbbbbbbbbbbbbbb00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
cccccccccccccccccc555cccbbbbbbbbbbbbbbbb00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
cccccccccc7777ccc55655ccbbbbbbbbbbbbbb3b00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
ccccccccccccccccc565555cbbbbbbbbbb3bb33b00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
cccccccccccccccc15555551bbbbbbbbbb33b3bb00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
ccccccccc77c777cc155551cbbbbbbbbbbb3bbbb00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
cccccccccccccccccc1111ccbbbbbbbbbbbbbbbb00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccbbbbbbbbbbbbbbbb00000000000000000000000000000000cccccccc000000000000000000000000000000000000000000000000
00057000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00057700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00057770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02057777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
14444441000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999cccccccccccccccccccccccc77ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a999999cccccccccc1111ccc711117c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
999aa9a9ccccccccc111111cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaccacaccccccccc711117c7c1111c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccc7777ccc7cccc7c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccc7777cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4444a44a4aa4a4cccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4444a425299252cc4444cccc1111cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4444a422222222c444444cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaa99aaa22222222c114444cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2992a225222252c444444cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4444a44a4444a4c444464cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4444a44a4444a4c114444cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4444a44a4444a4c444444cc111111c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000200283000000000000000000000000003010500000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003205000000320000000000000160500000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000000000000002c0600000038060380603806038040380303801035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000007000070000700007002f75026750217501c750187501475012750127501175013750167401f730277202d7100070000700007000070000700007000070000700007000070000700007000070000700
