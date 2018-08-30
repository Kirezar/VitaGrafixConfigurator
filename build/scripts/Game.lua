Game = {}
Game.__index = Game

function Game:New(title, ids, framebuffer, internal, frameps)
    local this = 
    {
        name = title,
        id = ids,
        fb = framebuffer,
        ib = internal,
        fps = frameps,
        enabled = 1,
        osd = 0,
        default_fb = framebuffer,
        default_ib = internal,
        default_fps = frameps
    }

    setmetatable(this, Game)
    return this
end

function Game:GetName()
    return self.fb
end