--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Gabor Meszaros
    reklam11@gmail.com

    Represents a descends from the spawning point downwards to the player. 
    When collected by player (collided with paddle), two additional balls 
    will spawn.
]]

Powerup = Class{}

function Powerup:init(x, y, skin)

    -- size, position and speed variables

    self.width = 16
    self.height = 16

    self.dy = 17

    self.x = x
    self.y = y

    -- skin from parameters
    self.skin = skin
end

--[[
    Expects an argument with a bounding box, a paddle in this case,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function Powerup:update(dt)
    -- don't let key powerup leave the screen
    if self.skin == 'key' and self.y >= VIRTUAL_HEIGHT - 32 then
        return
    end
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
        self.x, self.y)
end