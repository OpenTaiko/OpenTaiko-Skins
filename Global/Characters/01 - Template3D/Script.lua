---@diagnostic disable: undefined-global, undefined-field, lowercase-global

local CANVAS_W, CANVAS_H = 660, 560     -- canvas size
local GROUND_ROW = 460                  -- canvas row of world y=0
local PX_PER_WORLD = 217                -- pixels per world unit
local FACING_YAW = -45                  -- model yaw
local POSE_FPS = 60                     -- re-render rate
local RS = 1.0                          -- render scale
local REF_H = 276                       -- 2D game frame height

-- animation type: clip, beat, fade start, gray range
local CLIP = {
	[CHARACTER.ANIM_GAME_NORMAL]            = { clip = 0,  beat = 2 };
	[CHARACTER.ANIM_GAME_CLEAR]             = { clip = 1,  beat = 1 };
	[CHARACTER.ANIM_GAME_MAX]               = { clip = 1,  beat = 1 };
	[CHARACTER.ANIM_GAME_GOGO]              = { clip = 2,  beat = 4 };
	[CHARACTER.ANIM_GAME_GOGO_MAX]          = { clip = 2,  beat = 4 };
	[CHARACTER.ANIM_GAME_MISS]              = { clip = 4,  beat = 1 };
	[CHARACTER.ANIM_GAME_MISS_DOWN]         = { clip = 5,  beat = 1 };
	[CHARACTER.ANIM_GAME_10COMBO]           = { clip = 8,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_10COMBO_MAX]       = { clip = 8,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_CLEARED]           = { clip = 19, beat = 1.5 };
	[CHARACTER.ANIM_GAME_FAILED]            = { clip = 20, beat = 1.5 };
	[CHARACTER.ANIM_GAME_CLEAR_OUT]         = { clip = 10, beat = 1.5 };
	[CHARACTER.ANIM_GAME_CLEAR_IN]          = { clip = 9,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_MAX_OUT]           = { clip = 10, beat = 1.5 };
	[CHARACTER.ANIM_GAME_MAX_IN]            = { clip = 9,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_MISS_IN]           = { clip = 6,  beat = 1 };
	[CHARACTER.ANIM_GAME_MISS_DOWN_IN]      = { clip = 7,  beat = 1 };
	[CHARACTER.ANIM_GAME_RETURN]            = { clip = 22, beat = 1.5 };
	[CHARACTER.ANIM_GAME_GOGOSTART]         = { clip = 3,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_GOGOSTART_CLEAR]   = { clip = 3,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_GOGOSTART_MAX]     = { clip = 3,  beat = 1.5 };
	[CHARACTER.ANIM_GAME_BALLOON_BREAKING]  = { clip = 11, beat = 0.25 };
	[CHARACTER.ANIM_GAME_BALLOON_BROKE]     = { clip = 12, beat = 2.0, fade = 0.57 };
	[CHARACTER.ANIM_GAME_BALLOON_MISS]      = { clip = 13, beat = 2.0, gray = { 0, 0.5 } };
	[CHARACTER.ANIM_GAME_KUSUDAMA_BREAKING] = { clip = 25, beat = 0.25 };
	[CHARACTER.ANIM_GAME_KUSUDAMA_BROKE]    = { clip = 12, beat = 2.0, fade = 0.57 };
	[CHARACTER.ANIM_GAME_KUSUDAMA_MISS]     = { clip = 26, beat = 2.0, gray = { 0.5, 0.72 } };
	[CHARACTER.ANIM_GAME_KUSUDAMA_IDLE]     = { clip = 24, beat = 1.0 };

	[CHARACTER.ANIM_MENU_WAIT]              = { clip = 15, beat = 1 };
	[CHARACTER.ANIM_MENU_START]             = { clip = 16, beat = 1 };
	[CHARACTER.ANIM_MENU_NORMAL]            = { clip = 14, beat = 4 };
	[CHARACTER.ANIM_MENU_SELECT]            = { clip = 17, beat = 2 };
	[CHARACTER.ANIM_ENTRY_NORMAL]           = { clip = 14, beat = 4 };
	[CHARACTER.ANIM_ENTRY_JUMP]             = { clip = 23, beat = 1 };

	[CHARACTER.ANIM_RESULT_NORMAL]          = { clip = 18, beat = 1 };
	[CHARACTER.ANIM_RESULT_CLEAR]           = { clip = 19, beat = 1 };
	[CHARACTER.ANIM_RESULT_FAILED_IN]       = { clip = 20, beat = 1 };
	[CHARACTER.ANIM_RESULT_FAILED]          = { clip = 21, beat = 1 };
}

-- offsets per context
local OFFSET_MODE_MENU = "menu"
local OFFSET_MODE_GAME = "game"
local OFFSET_MODE_GAME_BALLOON = "game_balloon"
local OFFSET_MODE_GAME_KUSUDAMA = "game_kusudama"

local chara_config = {
	resolution = VECTOR2:CreateVector2(1920, 1080);
	legacy_mode = true;
	heya_render_offset = VECTOR2:CreateVector2(0, 0);
	menu_offset = { pos = VECTOR2:CreateVector2(0, 0); mode = OFFSET_MODE_MENU; v1_scale = 1.0; };
	game_offset = { pos = VECTOR2:CreateVector2(0, 0); mode = OFFSET_MODE_GAME; v1_scale = 1.25; };
	game_balloon_offset = { pos = VECTOR2:CreateVector2(0, 0); mode = OFFSET_MODE_GAME_BALLOON; v1_scale = 1; };
	game_kusudama_offset = { pos = VECTOR2:CreateVector2(0, 0); mode = OFFSET_MODE_GAME_KUSUDAMA; v1_scale = 1; };
	result_offset = { pos = VECTOR2:CreateVector2(0, 0); mode = OFFSET_MODE_MENU; v1_scale = 1; };
	ai_positions_x = nil; ai_positions_y = nil;
}

local function load_config()
	local ini = INILOADER:LoadIni("CharaConfig.txt")
	local res = ini:GetIntArray("Chara_Resolution")
	if res.Length == 2 then chara_config.resolution = VECTOR2:CreateVector2(res[0], res[1]) end
	chara_config.legacy_mode = ini:GetBool("Chara_LegacyMode", chara_config.legacy_mode)

	local hro = ini:GetIntArray("Heya_Chara_Render_Offset")
	if hro.Length == 2 then chara_config.heya_render_offset = VECTOR2:CreateVector2(hro[0], hro[1]) end

	local gx = ini:GetIntArray("Game_Chara_X"); if gx.Length >= 1 then chara_config.game_offset.pos.X = gx[0] end
	local gy = ini:GetIntArray("Game_Chara_Y"); if gy.Length >= 1 then chara_config.game_offset.pos.Y = gy[0] end
	local bx = ini:GetIntArray("Game_Chara_Balloon_X"); if bx.Length >= 1 then chara_config.game_balloon_offset.pos.X = bx[0] end
	local by = ini:GetIntArray("Game_Chara_Balloon_Y"); if by.Length >= 1 then chara_config.game_balloon_offset.pos.Y = by[0] end
	local kx = ini:GetIntArray("Game_Chara_Kusudama_X"); if kx.Length >= 1 then chara_config.game_kusudama_offset.pos.X = kx[0] end
	local ky = ini:GetIntArray("Game_Chara_Kusudama_Y"); if ky.Length >= 1 then chara_config.game_kusudama_offset.pos.Y = ky[0] end
	local mo = ini:GetIntArray("Menu_Offset"); if mo.Length == 2 then chara_config.menu_offset.pos = VECTOR2:CreateVector2(mo[0], mo[1]) end
	chara_config.menu_offset.v1_scale = ini:GetDouble("Menu_Chara_Scale", chara_config.menu_offset.v1_scale)
	local ro = ini:GetIntArray("Result_Offset"); if ro.Length == 2 then chara_config.result_offset.pos = VECTOR2:CreateVector2(ro[0], ro[1]) end

	local ax = ini:GetIntArray("Game_Chara_X_AI")
	local ay = ini:GetIntArray("Game_Chara_Y_AI")
	if ax.Length >= 1 and ay.Length >= 1 then
		chara_config.ai_positions_x = ax
		chara_config.ai_positions_y = ay
	end
end
load_config()

local animation_offsets = {}
do
	local g, b, k, m, r = chara_config.game_offset, chara_config.game_balloon_offset,
		chara_config.game_kusudama_offset, chara_config.menu_offset, chara_config.result_offset
	local map = {
		[CHARACTER.ANIM_GAME_BALLOON_BREAKING] = b; [CHARACTER.ANIM_GAME_BALLOON_BROKE] = b;
		[CHARACTER.ANIM_GAME_BALLOON_MISS] = b;
		[CHARACTER.ANIM_GAME_KUSUDAMA_BREAKING] = k; [CHARACTER.ANIM_GAME_KUSUDAMA_BROKE] = k;
		[CHARACTER.ANIM_GAME_KUSUDAMA_MISS] = k; [CHARACTER.ANIM_GAME_KUSUDAMA_IDLE] = k;
		[CHARACTER.ANIM_MENU_WAIT] = m; [CHARACTER.ANIM_MENU_START] = m;
		[CHARACTER.ANIM_MENU_NORMAL] = m; [CHARACTER.ANIM_MENU_SELECT] = m;
		[CHARACTER.ANIM_ENTRY_NORMAL] = m; [CHARACTER.ANIM_ENTRY_JUMP] = m;
		[CHARACTER.ANIM_RESULT_NORMAL] = r; [CHARACTER.ANIM_RESULT_CLEAR] = r;
		[CHARACTER.ANIM_RESULT_FAILED_IN] = r; [CHARACTER.ANIM_RESULT_FAILED] = r;
	}
	for t in pairs(CLIP) do animation_offsets[t] = map[t] or g end
end

-- 3D scene shared by all clips
local scene, model, modelObj
local lastClip, lastTime = -1, -1
local drawLogged = false
-- render-rate cap
local wallT, lastRenderW = 0.0, -1.0

local function ensure_scene()
	if scene ~= nil then return scene ~= false end
	debugLog("[CHARA3D] creating scene...")
	scene = SCENE3D:CreateScene(math.floor(CANVAS_W * RS), math.floor(CANVAS_H * RS))
	scene:SetLighting(false)
	scene:SetOutline(0, 0, 0, 12 * RS)
	scene:SetFog(false, 0, 0, 0, 0, 0)
	-- camera: PX_PER_WORLD scale, world y=0 on GROUND_ROW
	local fov = 30
	local camZ = CANVAS_H / PX_PER_WORLD / (2 * math.tan(math.rad(fov / 2)))
	local camY = (GROUND_ROW - CANVAS_H / 2) / PX_PER_WORLD
	scene:SetCameraPosition(0, camY, camZ)
	scene:SetCameraAngles(180, 0)
	scene:SetCameraFov(fov)
	model = MODEL and MODEL:Load("model.glb") or nil
	if not model then
		debugLog("[CHARA3D] model.glb FAILED to load")
		scene = false
		return false
	end
	model:Register(scene)
	model:SetSmoothShading(true)           -- lighting from the model normals
	debugLog("[CHARA3D] model.glb loaded + registered, clip0 dur=" .. tostring(model:Duration(0)))
	modelObj = scene:NewObject()
	scene:ObjSetPass(modelObj, 0, 0, 0, 0, 255)
	scene:ObjSetLit(modelObj, false)
	return true
end

-- animation state per type
local AnimationData = {}
local animationdata_array = {}
local avaiable_animations = {}

local function create_clip_animation(animationType)
	local def = CLIP[animationType]
	if def == nil or not ensure_scene() then return nil end
	return {
		duration = 1000; beat = def.beat; value = 0.0; clip = def.clip; fade = def.fade; gray = def.gray;
		offset = animation_offsets[animationType];
		update = function(self, delta, looping)
			local speed = 1000 / self.duration / self.beat
			self.value = self.value + (speed * delta)
			if looping then
				self.value = self.value - math.floor(self.value)
				return false
			else
				self.value = math.min(self.value, 1)
				return self.value >= 1
			end
		end;
		dispose = function(self) end;
	}
end

-- live 3D preview
local function create_preview3d()
	if not ensure_scene() then return nil end
	return {
		duration = 1000; beat = 4; value = 0; clip = 14; preview3d = true;
		update = function(self, delta, looping)
			self.value = (self.value + delta * 0.25) % 1.0
			return false
		end;
		dispose = function(self) end;
	}
end

local function create_render_like(anchored)
	local tex = nil
	if STORAGE:FileExists("Render.png") then tex = TEXTURE:CreateTexture("Render.png") end
	return {
		render = tex; duration = 1000; beat = 1; value = 0;
		update = function(self) return false end;
		draw = function(self, x, y, scaleX, scaleY, opacity, color, overrideOffset, anchor)
			if self.render == nil then return end
			local tr = THEME:GetResolution()
			local s = tr.Y / chara_config.resolution.Y
			self.render:SetScale(scaleX * s, scaleY * s)
			self.render:SetOpacity(opacity / 255.0)
			self.render:SetColor(color)
			if anchored then self.render:DrawAtAnchor(x, y, anchor or "center") else self.render:Draw(x, y) end
			self.render:SetOpacity(1.0)
		end;
		dispose = function(self) if self.render then self.render:Dispose() end end;
	}
end

function avaialbeAnimation(animationType)
	return avaiable_animations[animationType] == true
end

function loadAnimation(animationType)
	local data
	if animationType == CHARACTER.ANIM_PREVIEW then data = create_preview3d()
	elseif animationType == CHARACTER.ANIM_RENDER then data = create_render_like(false)
	else data = create_clip_animation(animationType) end
	animationdata_array[animationType] = data
	if data ~= nil then avaiable_animations[animationType] = true
	else debugLog("[CHARA3D] loadAnimation '" .. tostring(animationType) .. "' -> UNAVAILABLE") end
end

function disposeAnimation(animationType)
	local data = animationdata_array[animationType]
	if data ~= nil then data:dispose() end
	avaiable_animations[animationType] = false
end

function setAnimationDuration(animationType, duration)
	local data = animationdata_array[animationType]
	if data ~= nil then data.duration = duration end
end

function resetAnimationCounter(animationType)
	local data = animationdata_array[animationType]
	if data ~= nil then data.value = 0 end
end

-- voices
local voices = {}
local voice_files = {
	[CHARACTER.VOICE_END_FAILED] = "Sounds/Clear/Failed.ogg";
	[CHARACTER.VOICE_END_CLEAR] = "Sounds/Clear/Clear.ogg";
	[CHARACTER.VOICE_END_FULLCOMBO] = "Sounds/Clear/FullCombo.ogg";
	[CHARACTER.VOICE_END_ALLPERFECT] = "Sounds/Clear/AllPerfect.ogg";
	[CHARACTER.VOICE_MENU_SONGSELECT] = "Sounds/Menu/SongSelect.ogg";
	[CHARACTER.VOICE_MENU_SONGDECIDE] = "Sounds/Menu/SongDecide.ogg";
	[CHARACTER.VOICE_MENU_DIFFSELECT] = "Sounds/Menu/DiffSelect.ogg";
}
function loadVoice(voiceType)
	if voice_files[voiceType] ~= nil and STORAGE:FileExists(voice_files[voiceType]) then
		voices[voiceType] = SOUND:CreateVoice(voice_files[voiceType])
	end
end
function disposeVoice(voiceType)
	if voices[voiceType] ~= nil then voices[voiceType]:Dispose(); voices[voiceType] = nil end
end
function playVoice(voiceType)
	if voices[voiceType] ~= nil then voices[voiceType]:Play() end
end

function update(delta, animationType, looping)
	wallT = wallT + (delta or 0)
	if not avaialbeAnimation(animationType) then return false end
	local data = animationdata_array[animationType]
	if data ~= nil then return data:update(delta, looping) end
	return false
end

-- gray fade (miss clips)
local GRAY_STEPS = 8
local GRAY_MAPS = nil
local function gray_map(data)
	if data.gray == nil then return nil end
	local u = (data.value - data.gray[1]) / math.max(1e-6, data.gray[2] - data.gray[1])
	local i = math.floor(math.min(1, math.max(0, u)) * GRAY_STEPS + 0.5)
	if i <= 0 then return nil end
	if GRAY_MAPS == nil then
		GRAY_MAPS = {}
		for k = 1, GRAY_STEPS do
			GRAY_MAPS[k] = GRADIENT:Create({ { 0, 0, 0, 0 }, { 0.3, 118, 118, 118 } }, k / GRAY_STEPS)
		end
	end
	return GRAY_MAPS[i]
end

-- palette or gray fade, on the final blit only
local active_map = nil
local function blit(x, y, sx, sy, opacity, color, anchor)
	if active_map ~= nil then GRADIENT:SetActive(active_map) end
	scene:DrawScaled(x, y, sx, sy, opacity, color.R / 255.0, color.G / 255.0, color.B / 255.0, anchor)
	if active_map ~= nil then GRADIENT:ClearActive() end
end

local draw_animation

function draw(animationType, x, y, scaleX, scaleY, opacity, color, contextType, anchor, clip_w, clip_h, clip_x, clip_y, rotation, blendMode, wrapMode, gradientMap)
	if not avaialbeAnimation(animationType) then return end
	local data = animationdata_array[animationType]
	if data == nil then return end
	active_map = gradientMap or gray_map(data)
	draw_animation(data, animationType, x, y, scaleX, scaleY, opacity, color, contextType, anchor)
	active_map = nil
end

draw_animation = function(data, animationType, x, y, scaleX, scaleY, opacity, color, contextType, anchor)
	-- Render.png
	if data.render ~= nil or data.draw ~= nil then
		local overrideOffset = nil
		if contextType ~= nil and contextType ~= animationType then overrideOffset = animation_offsets[contextType] end
		if active_map ~= nil then GRADIENT:SetActive(active_map) end
		data:draw(x, y, scaleX, scaleY, opacity, color, overrideOffset, anchor)
		if active_map ~= nil then GRADIENT:ClearActive() end
		return
	end

	if not ensure_scene() then return end

	-- live 3D preview
	if data.preview3d then
		data.value = (data.value + (fps and fps.deltaTime or 0.016) * 0.25) % 1.0
		local t0 = data.value * (model:Duration(data.clip) or 1)
		t0 = math.floor(t0 * POSE_FPS) / POSE_FPS
		wallT = wallT + (fps and fps.deltaTime or 0.016)
		if (data.clip ~= lastClip or t0 ~= lastTime)
			and (lastRenderW < 0 or wallT - lastRenderW >= 1.0 / (POSE_FPS * 1.5)) then
			scene:Clear(0, 0, 0, 0)
			model:Pose(scene, modelObj, data.clip, t0, 0, 0, 0, FACING_YAW, 1.0)
			scene:Render()
			scene:Upload()
			lastClip, lastTime = data.clip, t0
			lastRenderW = wallT
		end
		local tr0 = THEME:GetResolution()
		local bs0 = tr0.Y / chara_config.resolution.Y
		blit(math.floor(x), math.floor(y), scaleX * bs0 / RS, scaleY * bs0 / RS, opacity / 255.0, color, anchor or "center")
		return
	end

	if not drawLogged then
		drawLogged = true
		debugLog("[CHARA3D] first 3D draw: type=" .. tostring(animationType) .. " x=" .. tostring(x) .. " y=" .. tostring(y) ..
			" sx=" .. tostring(scaleX) .. " op=" .. tostring(opacity) .. " anchor=" .. tostring(anchor))
	end

	-- pose + render on a new pose time
	local t = data.value * (model:Duration(data.clip) or 1)
	t = math.floor(t * POSE_FPS) / POSE_FPS
	if (data.clip ~= lastClip or t ~= lastTime)
		and (lastRenderW < 0 or wallT - lastRenderW >= 1.0 / (POSE_FPS * 1.5)) then
		scene:Clear(0, 0, 0, 0)
		model:Pose(scene, modelObj, data.clip, t, 0, 0, 0, FACING_YAW, 1.0)
		scene:Render()
		scene:Upload()
		lastClip, lastTime = data.clip, t
		lastRenderW = wallT
	end

	-- 2D placement
	local tr = THEME:GetResolution()
	local baseScale = tr.Y / chara_config.resolution.Y
	local sx, sy = scaleX * baseScale, scaleY * baseScale
	local offset = data.offset or chara_config.game_offset
	if contextType ~= nil and contextType ~= animationType and animation_offsets[contextType] then
		offset = animation_offsets[contextType]
	end
	if chara_config.legacy_mode then
		sx = sx * offset.v1_scale
		sy = sy * offset.v1_scale
	end
	local offsetX = offset.pos.X * (tr.X / chara_config.resolution.X)
	local offsetY = offset.pos.Y * (tr.Y / chara_config.resolution.Y)

	-- fade-out (balloon / kusudama broke)
	if data.fade ~= nil and data.value > data.fade then
		opacity = opacity * math.max(0, 1 - (data.value - data.fade) / (1 - data.fade))
	end

	if anchor ~= nil then
		blit(math.floor(x + offsetX), math.floor(y + offsetY), sx / RS, sy / RS, opacity / 255.0, color, anchor)
	else
		if chara_config.legacy_mode then
			-- legacy 2D offsets
			local modeC = nil
			if offset.mode == OFFSET_MODE_GAME then
				offsetX = offsetX + (((CANVAS_W / 2.0) - (0.13020833333 * chara_config.resolution.X)) * sx)
				modeC = 0.25555555555 * chara_config.resolution.Y
			elseif offset.mode == OFFSET_MODE_GAME_BALLOON then
				offsetX = offsetX + (((CANVAS_W / 2.0) - (0.27216666666 * chara_config.resolution.X)) * sx)
				modeC = 0.26296296296 * chara_config.resolution.Y
			elseif offset.mode == OFFSET_MODE_GAME_KUSUDAMA then
				offsetX = offsetX + (((CANVAS_W / 2.0) - (0.2555 * chara_config.resolution.X)) * sx)
				modeC = 0.2555 * chara_config.resolution.Y
			end
			if modeC ~= nil then
				offsetY = offsetY + (((CANVAS_H - GROUND_ROW) + (REF_H - modeC)) * sy)
			end
		end
		blit(math.floor(x + offsetX), math.floor(y + offsetY), sx / RS, sy / RS, opacity / 255.0, color, "bottom")
	end
end

function getDrawSize(animationType)
	if not avaialbeAnimation(animationType) then return 0, 0 end
	local data = animationdata_array[animationType]
	if data == nil then return 0, 0 end
	local tr = THEME:GetResolution()
	local baseScale = tr.Y / chara_config.resolution.Y
	if data.render ~= nil then
		return data.render.Width * baseScale, data.render.Height * baseScale
	end
	return CANVAS_W * baseScale, CANVAS_H * baseScale
end

function getHeyaRenderOffset()
	local tr = THEME:GetResolution()
	return chara_config.heya_render_offset.X * (tr.X / chara_config.resolution.X),
		chara_config.heya_render_offset.Y * (tr.Y / chara_config.resolution.Y)
end

function getAIBattlePosition(player, charaScale)
	if chara_config.ai_positions_x == nil or chara_config.ai_positions_y == nil then return nil end
	if chara_config.ai_positions_x.Length <= player or chara_config.ai_positions_y.Length <= player then return nil end
	charaScale = charaScale or 1.0
	local tr = THEME:GetResolution()
	local rx, ry = tr.X / chara_config.resolution.X, tr.Y / chara_config.resolution.Y
	local final_x = chara_config.ai_positions_x[player] * rx
	local final_y = chara_config.ai_positions_y[player] * ry
	local offset_x = chara_config.game_offset.pos.X * rx
	local offset_y = chara_config.game_offset.pos.Y * ry
	if chara_config.legacy_mode then
		local h = CANVAS_H * (tr.Y / chara_config.resolution.Y)
		local legacy_y = (h - 0.25555555555 * tr.Y) * charaScale
		offset_y = offset_y + legacy_y
	end
	return final_x - offset_x, final_y - offset_y
end