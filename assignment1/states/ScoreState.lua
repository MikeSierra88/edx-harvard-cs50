--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

-- Medal image data

    -- Gold vector created by macrovector - www.freepik.com
    -- https://www.freepik.com/free-photos-vectors/gold
local goldMedal = love.graphics.newImage('gold.png')
local silverMedal = love.graphics.newImage('silver.png')
local bronzeMedal = love.graphics.newImage('bronze.png')

local MEDAL_WIDTH = goldMedal:getPixelWidth()
local MEDAL_HEIGHT = goldMedal:getPixelHeight()
local MEDAL_SCALE = 1/2
local awardedMedal = {}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 52, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 88, VIRTUAL_WIDTH, 'center')

    -- Draw appropriate medal image
    love.graphics.draw(awardMedal(self.score), 
        (VIRTUAL_WIDTH / 2) - (MEDAL_WIDTH * MEDAL_SCALE / 2), 
        (VIRTUAL_HEIGHT / 2) - (MEDAL_HEIGHT * MEDAL_SCALE / 2),
        0, MEDAL_SCALE, MEDAL_SCALE
    )

    love.graphics.printf('Press Enter to Play Again!', 0, 200, VIRTUAL_WIDTH, 'center')
end

--[[
    Returns drawable medal image according to score.
]]
function awardMedal(score)
    if score > 5 then
        return goldMedal
    elseif score > 2 then
        return silverMedal
    else
        return bronzeMedal
    end
end
        