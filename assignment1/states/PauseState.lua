--[[
    PauseState Class
    Author: Gabor Meszaros
    reklam11@gmail.com
    Used when game is paused. Music stops playing, a pause symbol appears
    and the gameplay freezes. Game can be resumed by pressing 'p' again.
]]

PauseState = Class{__includes = BaseState}

-- Pause icon made by Pixel perfect from
-- https://www.flaticon.com/authors/pixel-perfect
local pauseIcon = love.graphics.newImage('pause.png')
local PAUSE_WIDTH = pauseIcon:getPixelWidth()
local PAUSE_HEIGHT = pauseIcon:getPixelHeight()
local PAUSE_SCALE = 1/8

function PauseState:init()
    self.paused = true
    -- initialize variable to save play state
    self.savedPlayState = {}
end

function PauseState:update(dt)
    -- listen for 'p', returns to PlayState when pressed
    -- passes the saved play state as parameter
    if love.keyboard.wasPressed('p') then
        gStateMachine:change('play', {
           currentPlayState = self.savedPlayState
        })
    end
end

function PauseState:render() 
    -- keep rendering the freezed gameplay
    self.savedPlayState:render()
    -- set active color to a translucent pale yellow
    love.graphics.setColor(255/255, 255/255, 191/255, 100/255)
    -- draw rectangle over window to fade gameplay
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    -- set color to black
    love.graphics.setColor(0, 0, 0, 1)
    -- draw pause icon and unpause text
    love.graphics.draw(pauseIcon, 
        (VIRTUAL_WIDTH / 2) - (PAUSE_WIDTH * PAUSE_SCALE / 2), 
        (VIRTUAL_HEIGHT / 2) - (PAUSE_HEIGHT * PAUSE_SCALE / 2),
        0, PAUSE_SCALE, PAUSE_SCALE
    )
    love.graphics.setFont(mediumFont)
    love.graphics.printf('Press P to unpause', 0, 70, VIRTUAL_WIDTH, 'center')
    -- set color back to white
    love.graphics.setColor(1, 1, 1)

end

--[[
    Called when this state is transitioned to from another state.
    Takes PlayState as parameter to save game progress
]]
function PauseState:enter(params)
    -- check for valid parameters to avoid crash
    if params and params.currentPlayState then
        -- save the passed play state in the instance variable
        self.savedPlayState = params.currentPlayState
    end
    groundScroll = 0
    -- pause music
    sounds['music']:pause()
    sounds['pause']:play()
end

--[[
    Called when this state changes to another state.
]]
function PauseState:exit()
    -- resume music
    sounds['music']:play()
end