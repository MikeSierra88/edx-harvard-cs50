--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    
    -- level-specific variables
    self.powerups = {}
    self.lockedBrickInPlay = false
    self.keySpawned = false
    self.keyFound = params.keyFound or false
    self.powerupFound = false

    self.growPaddleThreshold = 15000
    self.growPaddlePoints = 0
    self.recoverPoints = 5000

    -- give balls random starting velocity
    for k, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    for k, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end

        -- detect collision across all bricks with all balls
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score: 5000 if opening a locked brick 
                -- or the usual calculation
                local scoreIncrement = (brick.isLocked and self.keyFound) and 5000 or (brick.tier * 200 + brick.color * 25)
                self.score = self.score + scoreIncrement
                self.growPaddlePoints = self.growPaddlePoints + scoreIncrement

                -- trigger the brick's hit function, which removes it from play
                brick:hit({
                    keyFound = self.keyFound
                })

                -- chance to spawn key powerup if
                -- there is a locked brick and no key spawned yet, or no powerup was found
                if math.random(100) < 15 and ((self.lockedBrickInPlay and not self.keySpawned) or not self.powerupFound) then
                    -- powerup spawn position and type
                    local pUpX = brick.x + brick.width / 2 - 8
                    local pUpY = brick.y + brick.height
                    local pUpType = ''
                    -- if key was not found yet, spawn key, 
                    -- else spawn extraballs
                    if self.lockedBrickInPlay and not self.keySpawned then
                        pUpType = 'key'
                        self.keySpawned = true
                    else
                        pUpType = 'extraballs'
                        self.powerupFound = true
                    end
                    -- insert new powerup into table
                    table.insert(self.powerups, Powerup(pUpX, pUpY, pUpType))
                end

                -- if we gained enough points, grow the paddle by one size
                if self.growPaddlePoints > self.growPaddleThreshold then
                    if self.paddle.size < 4 then
                        self.paddle.size = self.paddle.size + 1
                        self.paddle.width = self.paddle.width + 32
                        self.growPaddlePoints = 0
                    end
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        balls = self.balls,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end

        end
        -- a ball goes below bounds
        for k, ball in pairs(self.balls) do
            if  ball.y >= VIRTUAL_HEIGHT then
                -- check if it's the last ball
                -- revert to serve state and decrease health
                if table.getn(self.balls) < 2 then
                    self.health = self.health - 1
                    gSounds['hurt']:play()
                    -- reduce paddle size
                    if self.paddle.size > 1 then
                        self.paddle.size = self.paddle.size - 1
                        self.paddle.width = self.paddle.width - 32
                    end
                    if self.health == 0 then
                        gStateMachine:change('game-over', {
                            score = self.score,
                            highScores = self.highScores
                        })
                    else
                        gStateMachine:change('serve', {
                            paddle = self.paddle,
                            bricks = self.bricks,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            level = self.level,
                            keyFound = self.keyFound,
                            recoverPoints = self.recoverPoints
                        })
                    end
                -- if there are more balls left, remove the one below screen
                else
                    table.remove(self.balls, k)
                end
            end
        end
    end

    -- update powerups, check for collision,
    -- trigger proper mechanism, remove if collided or below screen
    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
        if powerup:collides(self.paddle) then
            -- change proper 'found' variable to true
            if powerup.skin == 'key' then
                self.keyFound = true
            else
                -- spawn 2 extra balls above paddle, start them in random direction
                for i = 1, 2 do
                    table.insert(self.balls, Ball())
                    newBallNum = table.getn(self.balls)
                    self.balls[newBallNum].x = self.paddle.x + self.paddle.width/2
                    self.balls[newBallNum].y = self.paddle.y - 8
                    self.balls[newBallNum].dx = math.random(-200, 200)
                    self.balls[newBallNum].dy = math.random(-50, -60)
                    self.balls[newBallNum].skin = math.random(7)
                end
            end
            -- despawn powerup
            table.remove(self.powerups, k)
            break
        end
        -- despawn powerup if left field of view
        if powerup.y > VIRTUAL_HEIGHT + powerup.height then
            table.remove(self.powerups, k)
        end
    end

    -- for rendering particle systems and locked brick mechanism
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
        -- check if there is a locked brick in play
        if brick.isLocked then
            self.lockedBrickInPlay = true
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    -- render all balls
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    -- render all powerups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end
    -- despawn extra balls in case of victory
    for k, ball in pairs(self.balls) do
        if k > 1 then
            table.remove(self.balls, k)
        end
    end
    return true
end