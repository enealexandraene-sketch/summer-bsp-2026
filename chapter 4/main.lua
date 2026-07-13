--loading the libraries
local sti = require("sti")
local bump = require("bump")
local anim8 = require("anim8")

--declare the variables
local bg
local gameMap
local world
local bgSound

local blocks = {}

local player
local playerSprite

--track the current game state
local gameWon = false
local lives = 3
local gameOver = false

--creates the replay button
local replayButton = {
    x = 0,
    y = 0,
    w = 180,
    h = 50
}

--objects hitbox and sprite scale
local playerScale = 0.5
local playerW = 26
local playerH = 40

local spawnX = 100
local spawnY = 300


local enemies = {}
local enemySprite


local enemyScale = 1.5
local enemyW = 24
local enemyH = 40
local enemySpeed = 40
local enemySpawnOffsetY = 16

local coins = {}
local coinSprite
local score = 0

local coinScale = 1.5
local coinW = 16
local coinH = 30

local coinGrid
local coinAnimation

local diamonds = {}
local diamondSprite

local diamondScale = 1.5
local diamondW = 16
local diamondH = 30

local diamondGrid
local diamondAnimation

local livesItems = {}
local lifeSprite

local lifeScale = 0.06
local lifeW = 50
local lifeH = 40

local lifeGrid
local lifeAnimation

local gravity = 900
local jumpSpeed = -400

function love.load()

    --reset the background sound
    if bgSound then
        bgSound:stop()
    end

    --resets the tables
    coins = {}
    diamonds = {}
    livesItems = {}
    enemies = {}
    blocks = {}

    --resets the game
    score = 0
    lives = 3
    gameOver = false
    gameWon = false

    
    --keeps sprites from getting blurry
    love.graphics.setDefaultFilter("nearest", "nearest")

    --loads the map
    bg = love.graphics.newImage("sky-background copy.jpg")
    gameMap = sti("map-updated.lua")

    -- hide object layer so sti does not try to draw it
    if gameMap.layers["Characters"] then
        gameMap.layers["Characters"].visible = false
    end

    --creates bump collision world
    world = bump.newWorld(32)

    loadSolidTiles()

    --loads sprite images
    playerSprite = love.graphics.newImage("sprite.png")
    enemySprite = love.graphics.newImage("enemy.png")
    coinSprite = love.graphics.newImage("coin.png")
    diamondSprite = love.graphics.newImage("diamond.png")
    lifeSprite = love.graphics.newImage("life.png")

--coin animation
local coinFrameW = coinSprite:getWidth() / 15
local coinFrameH = coinSprite:getHeight()

--creates anim8 grid of sprite sheet division
coinGrid = anim8.newGrid(
    coinFrameW,
    coinFrameH,
    coinSprite:getWidth(),
    coinSprite:getHeight()
)

coinAnimation = anim8.newAnimation(coinGrid("1-15", 1), 0.08)

--diamomnd animation
local diamondFrameW = diamondSprite:getWidth() / 8
local diamondFrameH = diamondSprite:getHeight()

diamondGrid = anim8.newGrid(
    diamondFrameW,
    diamondFrameH,
    diamondSprite:getWidth(),
    diamondSprite:getHeight()
)

diamondAnimation = anim8.newAnimation(diamondGrid("1-8", 1), 0.10)

--life animation
local lifeFrameW = lifeSprite:getWidth() /2
local lifeFrameH = lifeSprite:getHeight() /2

lifeGrid = anim8.newGrid(
    lifeFrameW,
    lifeFrameH,
    lifeSprite:getWidth(),
    lifeSprite:getHeight()
)

lifeAnimation = anim8.newAnimation(lifeGrid("1-2", 1), 0.40)

--background music settings
bgSound = love.audio.newSource("bgsound.mp3", "stream")
bgSound:setVolume(0.2)
bgSound:setLooping(true)
bgSound:play()

loadCharacters()

end

function love.update(dt)
    --if the game is over/won stop the function
    if gameOver or gameWon then return end

    --updates sti map
    gameMap:update(dt)

    PlayerMovement(dt)
    EnemyUpdate(dt)

    coinAnimation:update(dt)
    diamondAnimation:update(dt)
    lifeAnimation:update(dt)

    --check every frame if the level is completed
    CheckGameWon()
end

function love.draw()
    --draws the imagewith the correct colours
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(bg, 0, 0)
    gameMap:draw()

    DrawCoins()
    DrawPlayer()
    DrawEnemy()
    DrawDiamonds()
    DrawLivesItems()


    --score and lives text
    love.graphics.setColor(0, 0, 0)
love.graphics.print("Score: " .. score, 20, 20, 0, 2, 2)
love.graphics.print("Lives: " .. lives, 20, 50, 0, 2, 2)

--game won screen
if gameWon then
    love.graphics.setColor(0, 1, 0)

    local text = "GAME WON"
    local scale = 3
    local font = love.graphics.getFont()
    local textW = font:getWidth(text) * scale

    love.graphics.print(
        text,
        love.graphics.getWidth() / 2 - textW / 2,
        love.graphics.getHeight() / 2 - 80,
        0,
        scale,
        scale
    )

    DrawReplayButton()
end

--game over screen
if gameOver then
    love.graphics.setColor(1, 0, 0)

    local text = "GAME OVER"
    local scale = 3
    local font = love.graphics.getFont()
    local textW = font:getWidth(text) * scale

    love.graphics.print(
        text,
        love.graphics.getWidth() / 2 - textW / 2,
        love.graphics.getHeight() / 2 - 80,
        0,
        scale,
        scale
    )

    DrawReplayButton()
end

end

function loadSolidTiles()
    --gets the platform layer
    local layer = gameMap.layers["platform"]

    if not layer then
        print("No platform layer found")
        return
    end

    --gets the map size
    local tileW = gameMap.tilewidth
    local tileH = gameMap.tileheight

    --check every tile
    for y = 1, layer.height do
        for x = 1, layer.width do
            local tile = layer.data[y][x]
            
            --for each non empty tile create a rectangle
            if tile then
                local block = {
                    x = (x - 1) * tileW,
                    y = (y - 1) * tileH,
                    w = tileW,
                    h = tileH
                }

                table.insert(blocks, block)--store the rectangle
                world:add(block, block.x, block.y, block.w, block.h)--add rectangle to collision system
            end
        end
    end
end

function loadCharacters()
    --gets the characters layer
    local layer = gameMap.layers["Characters"]

    if not layer then
        PlayerSpawn(100, 300)
        return
    end

    --loops through every object and spawns it
    for i, obj in ipairs(layer.objects) do
        local objectType = obj.type or obj.class or obj.name

        if objectType == "player" or objectType == "Player" then
            PlayerSpawn(obj.x, obj.y)
        end

        if objectType == "enemy" or objectType == "Enemy" then
            local dir = obj.properties.dir or -1
            EnemySpawn(obj.x, obj.y, dir)
        end

        if objectType == "coin" or objectType == "Coin" then
            CoinSpawn(obj.x, obj.y)
        end
        if objectType == "diamond" or objectType == "Diamond" then
            DiamondSpawn(obj.x, obj.y)
        end
        if objectType == "life" or objectType == "Life" then
            LifeSpawn(obj.x, obj.y)
        end
    end

    --checks again if the player spawned
    if not player then
        PlayerSpawn(100, 300)
    end
    
end

function PlayerSpawn(x, y)
    --x and y from tiled are the spawn point
    spawnX = x
    spawnY = y

    player = {
        name = "player",

        -- hitbox
        x = x - playerW / 2,
        y = y - playerH,

        w = playerW,
        h = playerH,

        vY = 0,
        dir = 1,
        speed = 150,
        onGround = false
    }

    --animate player
    local frameW = playerSprite:getWidth() / 9
    local frameH = playerSprite:getHeight() / 3

    local grid = anim8.newGrid(
        frameW,
        frameH,
        playerSprite:getWidth(),
        playerSprite:getHeight()
    )

    player.frameW = frameW
    player.frameH = frameH

    player.animations = {}

    player.animations.idleRight = anim8.newAnimation(grid(1, 1), 0.2)
    player.animations.walkRight = anim8.newAnimation(grid("1-4", 2), 0.12)

    player.animations.idleLeft = anim8.newAnimation(grid(1, 1), 0.2):flipH()
    player.animations.walkLeft = anim8.newAnimation(grid("1-4", 2), 0.12):flipH()

    player.animation = player.animations.idleRight

    world:add(player, player.x, player.y, player.w, player.h)--adds player hitbox to bump collision world
end

function PlayerMovement(dt)
    if not player then return end

    local goalX = player.x
    local goalY = player.y

    --player movement to left and right
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        goalX = goalX - player.speed * dt
        player.dir = -1
        player.animation = player.animations.walkLeft

    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        goalX = goalX + player.speed * dt
        player.dir = 1
        player.animation = player.animations.walkRight

    else--runs when player is not moving
        if player.dir == -1 then
            player.animation = player.animations.idleLeft
        else
            player.animation = player.animations.idleRight
        end
    end

    --jump
    if (love.keyboard.isDown("up") or love.keyboard.isDown("space")) and player.onGround then
        player.vY = jumpSpeed
        player.onGround = false
    end

    --gravity
    player.vY = player.vY + gravity * dt
    goalY = goalY + player.vY * dt

    --move with bump
    local actualX, actualY, cols, len = world:move(player, goalX, goalY)

    player.x = actualX
    player.y = actualY

    --keep the player inside the screen
    if player.x < 0 then
        player.x = 0
       world:update(player, player.x, player.y, player.w, player.h)
    end

    if player.x + player.w > love.graphics.getWidth() then
        player.x = love.graphics.getWidth() - player.w
        world:update(player, player.x, player.y, player.w, player.h)
    end

    player.onGround = false

    
    
    for i = 1, len do
        local col = cols[i]
    
        --player touched coin
        if IsCoin(col.other) then
            RemoveCoin(col.other)
    
        --player touched diamond
        elseif IsDiamond(col.other) then
            RemoveDiamond(col.other)
    
        --player touched life 
        elseif IsLife(col.other) then
            RemoveLife(col.other)
    
        --player touched enemy
        elseif IsEnemy(col.other) then
    
            --player jumped on enemy
            if col.normal.y == -1 and player.vY > 0 then
                RemoveEnemy(col.other)
                player.vY = -250
    
            --player touched enemy from side/bottom
            else
                LoseLife()
            end
    
        else
            --player landed on platform
            if col.normal.y == -1 then
                player.onGround = true
                player.vY = 0
    
            --player hit ceiling
            elseif col.normal.y == 1 then
                player.vY = 0
            end
        end
    end
    player.animation:update(dt)
end

function Die()
    --moves the player to the spawn point
    player.x = spawnX - playerW / 2
    player.y = spawnY - playerH
    player.vY = 0

    world:update(player, player.x, player.y, player.w, player.h)
end

function DrawPlayer()
    if not player then return end

    love.graphics.setColor(1, 1, 1)

    --center sprite on hitbox
    local drawX = player.x + player.w / 2 - (player.frameW * playerScale) / 2

    --put sprite feet at bottom of hitbox
    local drawY = player.y + player.h - (player.frameH * playerScale)

    player.animation:draw(
        playerSprite,
        drawX,
        drawY,
        0,
        playerScale,
        playerScale
    )
end

function EnemySpawn(x, y, dir)
    local enemy = {
        name = "enemy",
    
        x = x - enemyW / 2,
        y = y - enemyH + enemySpawnOffsetY,
    
        w = enemyW,
        h = enemyH,
    
        dir = dir or -1,
        speed = enemySpeed,
        vY = 0,
        dead = false
    }

    --enemy animation
    local frameW = enemySprite:getWidth() / 10
    local frameH = enemySprite:getHeight() /5

    local grid = anim8.newGrid(
        frameW,
        frameH,
        enemySprite:getWidth(),
        enemySprite:getHeight()
    )

    enemy.frameW = frameW
    enemy.frameH = frameH

    enemy.animations = {}
    
    enemy.animations.right = anim8.newAnimation(grid("1-4", 2), 0.15)
    enemy.animations.left = anim8.newAnimation(grid("1-4", 2), 0.15):flipH()
    
    --choose starting animation
    if enemy.dir == 1 then
        enemy.animation = enemy.animations.right
    else
        enemy.animation = enemy.animations.left
    end

    table.insert(enemies, enemy)--adds enemy to enemies table
    world:add(enemy, enemy.x, enemy.y, enemy.w, enemy.h)--adds enemy hitbox to bump collision world
end

function EnemyUpdate(dt)
    --loops through the enemies
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]

        local goalX = enemy.x + enemy.dir * enemy.speed * dt

        --enemy gravity
        enemy.vY = enemy.vY + gravity * dt
        local goalY = enemy.y + enemy.vY * dt

        local actualX, actualY, cols, len = world:move(enemy, goalX, goalY, EnemyFilter)

        enemy.x = actualX
        enemy.y = actualY

        --keep enemy inside screen 
        if enemy.x < 0 then
            enemy.x = 0
            enemy.dir = 1
            world:update(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
        end

        if enemy.x + enemy.w > love.graphics.getWidth() then
            enemy.x = love.graphics.getWidth() - enemy.w
            enemy.dir = -1
            world:update(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
        end
        
        --check collision
        for j = 1, len do
            local col = cols[j]

            -- ignore coins
            if IsCoin(col.other) then
                --do nothing

            --ignore diamonds 
            elseif IsDiamond(col.other) then
                --do nothing

        --enemy touches player then player respawns
        elseif col.other == player then
            LoseLife()
            break

            --enemy hits wall then turn around
            elseif col.normal.x ~= 0 then
                enemy.dir = enemy.dir * -1

            --enemy lands on ground
            elseif col.normal.y == -1 then
                enemy.vY = 0

            --enemy hits ceiling
            elseif col.normal.y == 1 then
                enemy.vY = 0
            end
        end

        --animation update
        if world:hasItem(enemy) then
            if enemy.dir == 1 then
                enemy.animation = enemy.animations.right
            else
                enemy.animation = enemy.animations.left
            end

            enemy.animation:update(dt)
        end
    end
end

function RemoveEnemy(enemy)
    if not enemy then return end

    --remove from bump collision world
    if world:hasItem(enemy) then
        world:remove(enemy)
    end

    --remove from enemies table
    for i = #enemies, 1, -1 do
        if enemies[i] == enemy then
            table.remove(enemies, i)
            break
        end
    end
    CheckGameWon()
end

function DrawEnemy()
    for i, enemy in ipairs(enemies) do
        love.graphics.setColor(1, 1, 1)

        local drawX = enemy.x + enemy.w / 2 - (enemy.frameW * enemyScale) / 2
        local drawY = enemy.y + enemy.h - (enemy.frameH * enemyScale)

        enemy.animation:draw(
            enemySprite,
            drawX,
            drawY,
            0,
            enemyScale,
            enemyScale
        )
    end
end

function IsEnemy(item) 
    for i, enemy in ipairs(enemies) do
        if item == enemy then
            return true
        end
    end

    return false
end

function CoinSpawn(x, y)
    local coin = {
        name = "coin",

        x = x - coinW / 2,
        y = y - coinH,

        w = coinW,
        h = coinH
    }

    table.insert(coins, coin)--adds coins to the table
    world:add(coin, coin.x, coin.y, coin.w, coin.h)--adds coins to obump
end

function DrawCoins()
    love.graphics.setColor(1, 1, 1)

    for i, coin in ipairs(coins) do
        coinAnimation:draw(
            coinSprite,
            coin.x,
            coin.y,
            0,
            coinScale,
            coinScale
        )
    end
end

function IsCoin(item)
    for i, coin in ipairs(coins) do
        if item == coin then
            return true
        end
    end

    return false
end

function RemoveCoin(coin)
    if not coin then return end

    if world:hasItem(coin) then
        world:remove(coin)
    end

    for i = #coins, 1, -1 do
        if coins[i] == coin then
            table.remove(coins, i)
            break
        end
    end

    score = score + 1
end

function DiamondSpawn(x, y)
    local diamond = {
        name = "diamond",

        x = x - diamondW / 2,
        y = y - diamondH,

        w = diamondW,
        h = diamondH
    }

    table.insert(diamonds, diamond)
    world:add(diamond, diamond.x, diamond.y, diamond.w, diamond.h)
end

function DrawDiamonds()
    love.graphics.setColor(1, 1, 1)

    for i, diamond in ipairs(diamonds) do
        diamondAnimation:draw(
            diamondSprite,
            diamond.x,
            diamond.y,
            0,
            diamondScale,
            diamondScale
        )
    end
end

function IsDiamond(item)
    for i, diamond in ipairs(diamonds) do
        if item == diamond then
            return true
        end
    end

    return false
end

function RemoveDiamond(diamond)
    if not diamond then return end

    if world:hasItem(diamond) then
        world:remove(diamond)
    end

    for i = #diamonds, 1, -1 do
        if diamonds[i] == diamond then
            table.remove(diamonds, i)
            break
        end
    end

    score = score + 5
end


function EnemyFilter(item, other)
    --allow enemy to pass through object
    if IsCoin(other) then
        return "cross"
    end

    if IsDiamond and IsDiamond(other) then
        return "cross"
    end

    if IsLife and IsLife(other) then
        return "cross"
    end

    if other == player then
        return "cross"
    end

    return "slide"
end


function LifeSpawn(x, y)
    local life = {
        name = "life",

        x = x - lifeW / 2,
        y = y - lifeH,

        w = lifeW,
        h = lifeH
    }

    table.insert(livesItems, life)
    world:add(life, life.x, life.y, life.w, life.h)
end

function DrawLivesItems()
    love.graphics.setColor(1, 1, 1)

    for i, life in ipairs(livesItems) do
        lifeAnimation:draw(
            lifeSprite,
            life.x,
            life.y,
            0,
            lifeScale,
            lifeScale
        )
    end
end

function IsLife(item)
    for i, life in ipairs(livesItems) do
        if item == life then
            return true
        end
    end

    return false
end

function RemoveLife(life)
    if not life then return end

    if world:hasItem(life) then
        world:remove(life)
    end

    for i = #livesItems, 1, -1 do
        if livesItems[i] == life then
            table.remove(livesItems, i)
            break
        end
    end

    lives = lives + 1
    --limit health at 3 lives
    if lives > 3 then
        lives = 3
    end
end

function LoseLife()
    if gameWon then return end

    lives = lives - 1

    --if player has 0 lives then end game
    if lives <= 0 then
        lives = 0
        gameOver = true
        gameWon = false
    else
        Die()
    end
end

function PlayerFilter(item, other)
    --allows player to pass through objects
    if IsCoin(other) then
        return "cross"
    end

    if IsDiamond and IsDiamond(other) then
        return "cross"
    end

    if IsLife and IsLife(other) then
        return "cross"
    end

    if IsEnemy(other) then
        return "cross"
    end

    return "slide"
end

function CheckGameWon()
    if gameOver or gameWon then return end

    --if no enemies and coins/diamonds on the map then the game is won
    if #enemies == 0 and #coins == 0 and #diamonds == 0 then
        gameWon = true
        gameOver = false
    end
end

function RestartGame()
    --restarts the game
    love.load()
end

function DrawReplayButton()
    replayButton.w = 220
    replayButton.h = 60

    --center the button
    replayButton.x = love.graphics.getWidth() / 2 - replayButton.w / 2
    replayButton.y = love.graphics.getHeight() / 2 + 60

    --make button purple
    love.graphics.setColor(0.75, 0.55, 1.0)
    love.graphics.rectangle("fill", replayButton.x, replayButton.y, replayButton.w, replayButton.h)

    --black border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", replayButton.x, replayButton.y, replayButton.w, replayButton.h)

    --black text
    love.graphics.setColor(0, 0, 0)

    local text = "REPLAY"
    local scale = 2
    local font = love.graphics.getFont()

    local textW = font:getWidth(text) * scale
    local textH = font:getHeight() * scale

    love.graphics.print(
        text,
        replayButton.x + replayButton.w / 2 - textW / 2,
        replayButton.y + replayButton.h / 2 - textH / 2,
        0,
        scale,
        scale
    )
end

function love.mousepressed(x, y, button)
    --checks if lmb is pressed on the button and restarts game 
    if button == 1 and (gameOver or gameWon) then
        if x >= replayButton.x and x <= replayButton.x + replayButton.w
        and y >= replayButton.y and y <= replayButton.y + replayButton.h then
            RestartGame()
        end
    end
end