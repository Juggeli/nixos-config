local utils = require 'mp.utils'

local original_brightness = nil
local fullscreen_brightness = 100
local is_fullscreen = false

function get_current_brightness()
    local result = utils.subprocess({
        args = {"ddcutil", "getvcp", "10"},
        capture_stdout = true,
        capture_stderr = true
    })
    
    if result.status == 0 then
        local brightness = result.stdout:match("current value =%s*(%d+)")
        if brightness then
            return tonumber(brightness)
        end
    end
    return nil
end

function set_brightness(value, blocking)
    local params = {
        args = {"ddcutil", "setvcp", "10", tostring(value)},
        capture_stdout = true,
        capture_stderr = true
    }
    
    if blocking then
        utils.subprocess(params)
    else
        utils.subprocess_detached(params)
    end
end

function on_fullscreen_change()
    local new_fullscreen = mp.get_property_bool("fullscreen")
    
    if new_fullscreen and not is_fullscreen then
        original_brightness = get_current_brightness()
        if original_brightness then
            set_brightness(fullscreen_brightness)
        end
        is_fullscreen = true
    elseif not new_fullscreen and is_fullscreen then
        if original_brightness then
            set_brightness(original_brightness)
            original_brightness = nil
        end
        is_fullscreen = false
    end
end

mp.observe_property("fullscreen", "bool", on_fullscreen_change)

mp.add_hook("on_unload", 50, function()
    if original_brightness then
        os.execute(string.format("ddcutil setvcp 10 %d", original_brightness))
    end
end)

mp.add_key_binding("Ctrl+WHEEL_UP", "increase-fullscreen-brightness", function()
    if is_fullscreen then
        fullscreen_brightness = math.min(100, fullscreen_brightness + 5)
        set_brightness(fullscreen_brightness)
        mp.osd_message("Fullscreen brightness: " .. fullscreen_brightness, 1)
    end
end)

mp.add_key_binding("Ctrl+WHEEL_DOWN", "decrease-fullscreen-brightness", function()
    if is_fullscreen then
        fullscreen_brightness = math.max(0, fullscreen_brightness - 5)
        set_brightness(fullscreen_brightness)
        mp.osd_message("Fullscreen brightness: " .. fullscreen_brightness, 1)
    end
end)