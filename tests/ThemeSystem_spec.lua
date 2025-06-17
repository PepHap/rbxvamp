local ThemeSystem = require("src.ThemeSystem")
local LocationSystem = require("src.LocationSystem")
local UITheme = require("src.UITheme")

describe("ThemeSystem", function()
    before_each(function()
        ThemeSystem.locationSystem = LocationSystem
        ThemeSystem.current = nil
        ThemeSystem.lastIndex = nil
        UITheme.colors.windowBackground = {r=0,g=0,b=0}
    end)

    it("applies theme colors", function()
        ThemeSystem:apply{windowBackground={r=1,g=2,b=3}}
        assert.are.same({r=1,g=2,b=3}, UITheme.colors.windowBackground)
    end)

    it("updates theme when location changes", function()
        LocationSystem.locations[1].theme = {windowBackground={r=1,g=1,b=1}}
        LocationSystem.locations[2].theme = {windowBackground={r=5,g=5,b=5}}
        LocationSystem.currentIndex = 1
        ThemeSystem:start(LocationSystem)
        assert.are.same({r=1,g=1,b=1}, UITheme.colors.windowBackground)
        LocationSystem.currentIndex = 2
        ThemeSystem:update()
        assert.are.same({r=5,g=5,b=5}, UITheme.colors.windowBackground)
    end)
end)
