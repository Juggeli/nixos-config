local function show_position_info()
    local time_pos = mp.get_property_number("time-pos")
    local estimated_frame_number = mp.get_property_number("estimated-frame-number")
    local duration = mp.get_property_number("duration")
    local fps = mp.get_property_number("estimated-vf-fps")
    
    if not time_pos then
        mp.osd_message("No video loaded")
        return
    end
    
    local hours = math.floor(time_pos / 3600)
    local minutes = math.floor((time_pos % 3600) / 60)
    local seconds = time_pos % 60
    
    local time_str = string.format("%02d:%02d:%06.3f", hours, minutes, seconds)
    local frame_str = estimated_frame_number and string.format("Frame: %d", math.floor(estimated_frame_number)) or "Frame: N/A"
    local fps_str = fps and string.format("FPS: %.3f", fps) or "FPS: N/A"
    
    local info_text = string.format("%s\n%s\n%s\nTime: %.3fs", time_str, frame_str, fps_str, time_pos)
    
    if duration then
        local progress = (time_pos / duration) * 100
        info_text = info_text .. string.format("\nProgress: %.1f%%", progress)
    end
    
    mp.osd_message(info_text, 3)
end

mp.add_key_binding("i", "show-position-info", show_position_info)