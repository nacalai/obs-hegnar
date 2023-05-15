obs = obslua

mediaSourceName = ""
textSourceName = ""

last_text = ""

function timer_callback()
    mediaSource = obs.obs_get_source_by_name(mediaSourceName)
    if mediaSource ~= nil then
        local time = obs.obs_source_media_get_time(mediaSource)
        local duration = obs.obs_source_media_get_duration(mediaSource);
        local timeLeft = duration - time;

        local seconds = string.sub('0'..(math.floor(timeLeft / 1000) % 60), -2)
        local minutes = string.sub('0'..math.floor(timeLeft / 1000 / 60) % 60, -2)
        local hours = math.floor(timeLeft / 1000 / 60 / 60)
        local text = '-'..hours..':'..minutes..':'..seconds

        if text ~= last_text then
            local source = obs.obs_get_source_by_name(textSourceName)
            if source ~= nil then
                local settings = obs.obs_data_create()
                obs.obs_data_set_string(settings, "text", text)
                obs.obs_source_update(source, settings)
                obs.obs_data_release(settings)
                obs.obs_source_release(source)
            end
        end
    
        last_text = text
    end
    obs.obs_source_release(mediaSource)
end

function media_started(param, data)
    obs.timer_add(timer_callback, 1000)
end

function media_ended(param, data)
    obs.timer_remove(timer_callback)
end

function source_activated(cd)
    local source = obs.calldata_source(cd, "source")
	activate_source(source, true)
end

function source_deactivated(cd)
    local source = obs.calldata_source(cd, "source")
	activate_source(source, false)
end

function activate_source(source, activating)
    if (source ~= nil) then
        local sourceId = obs.obs_source_get_id(source);
        if(sourceId == 'ffmpeg_source' or sourceId == 'vlc_source') then
            local sh = obs.obs_source_get_signal_handler(source)

            if activating then
                mediaSourceName = obs.obs_source_get_name(source)
                obs.signal_handler_connect(sh, "media_started", media_started)
                obs.signal_handler_connect(sh, "media_stopped", media_ended)

                if(obs.obs_source_media_get_state(source) == 1) then
                    obs.timer_add(timer_callback, 1000)
                end
            else
                obs.signal_handler_disconnect(sh, "media_started", media_started)
                obs.signal_handler_disconnect(sh, "media_stopped", media_ended)
            end

        end
    end
end

----------------------------------------------------------------------------------------------

function script_load(settings)
    log(300, 'started')

    local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
    obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

    local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == 'ffmpeg_source' or source_id == 'vlc_source' then
                if(obs.obs_source_active(source)) then
                    activate_source(source, true)
                end
			end
		end
	end
	obs.source_list_release(sources)
end

function script_unload()
    log(300, 'ended')
end

function script_description()
	return "Sets a text source to act as a media countdown timer when a media source is active.\n\nMade by Luuk Verhagen"
end

function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	return props
end

function script_update(settings)
	textSourceName = obs.obs_data_get_string(settings, "source")
end

function script_defaults(settings)
end

----------------------------------------------------------------------------------------------


function log(level, string)
    if string ~= nil then
        obs.blog(level, "[stage-timer]: "..string)
    else
        obs.blog(level, "[stage-timer]: nill")
    end
end

function debug(string)
    log(300, string)
end