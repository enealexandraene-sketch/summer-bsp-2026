--[[ draw shapes

function love.load()
  love.graphics.setBackgroundColor(225/255, 153/255, 0)
end

function love.draw()
  love.graphics.setColor(0, 0, 0)

  -- draw a circle
  love.graphics.circle("fill", 200, 300, 50)

  -- draw a rectangle
  love.graphics.rectangle("fill", 300, 300, 100, 100)

  -- draw an arc
  love.graphics.arc("fill", 450, 300, 100, math.pi/5, math.pi/2)
end





--ROTATING OBJECTS
--variables
local angle = 0
local width = 10
local height = 10
--draw a rectangle
function love.draw()

 -- rotate
 love.graphics.rotate(angle)
 -- draw a blue rectangle
 love.graphics.setColor(0,0,225)
 love.graphics.rectangle('fill', 300,
400, width, height)

end
--update
function love.update(dt)
---On pressing the 'd' key, rotate to the right
 if love.keyboard.isDown('d') then
  angle = angle + math.pi * dt
-- else if we press the 'a' key, rotate to the left
 elseif love.keyboard.isDown('a') then
   angle = angle - math.pi * dt
 end

end




--MOVING UP/DOWN/LEFT/RIGHT

function love.load()
  --- create a character table
  character = {}
  character.x = 300
  character.y = 400
  character.speed = 200
  love.graphics.setBackgroundColor(225, 153,0)
  love.graphics.setColor(0, 0, 225)
  end


  function love.draw()
   love.graphics.rectangle("fill", character.x, character.y, 100, 100)
  end


  function love.update(dt)

    if love.keyboard.isDown('d') then
   character.x = character.x + character.speed * dt

  elseif love.keyboard.isDown('a') then
   character.x = character.x - character.speed * dt

   end



   if love.keyboard.isDown('w') then
   character.y = character.y - character.speed * dt

  elseif love.keyboard.isDown('s') then
   character.y = character.y + character.speed * dt
   end
  
  end
]]