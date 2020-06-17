--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerIdleState = Class{__includes = EntityIdleState}

function PlayerIdleState:enter(params)
    -- render offset for spaced character sprite
    self.entity.offsetY = 5
    self.entity.offsetX = 0
    self.entity.objectCollided = false
end

function PlayerIdleState:update(dt)
    EntityIdleState.update(self, dt)
end

function PlayerIdleState:update(dt)
    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.entity:changeState('walk')
    end

    if love.keyboard.wasPressed('space') and not self.entity.carriedPot then
        self.entity:changeState('swing-sword')
    end

    -- if enter is pressed, check whether carrying pot or available for pickup
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        -- if already carrying pot, throw it
        if self.entity.carriedPot then
            self.entity.carriedPot.thrown = true
            self.entity.carriedPot = Nil
        -- if not carrying but one in range for pickup, pick it up
        elseif self.entity.pickablePot then
            self.entity.carriedPot = self.entity.pickablePot
            self.entity:changeState('pickup')
        end
    end
end