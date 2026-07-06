--print "hello world"

function love.draw()
  love.graphics.print("hello world!", 400, 300)
end

--use basic funtions

function love.load()
  
  local myfont =
  love.graphics.newFont(45)
  love.graphics.setFont(myfont)
  love.graphics.setColor(0,0,0,225)
  love.graphics.setBackgroundColor(1,0,1)

end


function love.update()
  
end


function love.draw()

love.graphics.print('hello world',200,200)
end


