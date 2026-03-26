--========================================================--
--  Psych Engine Note Glow Shader (noteGlow.frag)          --
--  Uses uniforms: float strength; vec3 glowColor;         --
--========================================================--

local SHADER_NAME = "noteGlow"

-- tweakables
local basePulse = 0.12      -- idle glow amount (0..?)
local beatBoost = 0.35      -- how much beat adds
local hitBoost  = 0.85      -- how much note hits add
local decaySpeed = 8.0      -- higher = faster fade

-- glow color (0..1)
local glowR, glowG, glowB = 0.35, 0.85, 1.0

-- runtime
local flash = 0.0

local function clamp(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

function onCreatePost()
	-- Make sure the shader exists in mods/shaders/noteGlow.frag
	initLuaShader(SHADER_NAME)

	runHaxeCode([[
		// Create ONE shared shader instance for all notes/strums.
		game._noteGlowShader = game.createRuntimeShader("]] .. SHADER_NAME .. [[");

		// Default uniforms
		game._noteGlowShader.setFloat("strength", 0.0);
		game._noteGlowShader.setFloatArray("glowColor", [0.35, 0.85, 1.0]);

		// Apply to strums (both sides)
		for (s in game.playerStrums.members) if (s != null) s.shader = game._noteGlowShader;
		for (s in game.opponentStrums.members) if (s != null) s.shader = game._noteGlowShader;

		// Apply to currently spawned notes
		for (n in game.notes.members) if (n != null) n.shader = game._noteGlowShader;

		// Apply to unspawned notes (future notes)
		for (u in game.unspawnNotes) if (u != null) u.shader = game._noteGlowShader;

		// Optional: apply to note splashes if you use them
		if (game.grpNoteSplashes != null)
			for (sp in game.grpNoteSplashes.members) if (sp != null) sp.shader = game._noteGlowShader;
	]])
end

-- If notes/splashes are created later, keep re-applying
function onSpawnNote(noteIndex)
	runHaxeCode([[
		if (game._noteGlowShader != null && game.notes != null) {
			var n = game.notes.members[]] .. tostring(noteIndex) .. [[];
			if (n != null) n.shader = game._noteGlowShader;
		}
	]])
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	flash = math.max(flash, hitBoost)
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
	flash = math.max(flash, hitBoost * 0.9)
end

function onBeatHit()
	flash = math.max(flash, beatBoost)
end

function onUpdate(elapsed)
	-- decay flash
	flash = flash - (elapsed * decaySpeed)
	if flash < 0 then flash = 0 end

	-- subtle pulse synced to song position
	local t = getSongPosition() / 1000.0
	local pulse = (math.sin(t * (math.pi * 2) * 2.0) + 1.0) * 0.5 -- 0..1
	local strength = basePulse + flash + (pulse * 0.10)

	strength = clamp(strength, 0.0, 3.0)

	-- update shader uniforms once per frame
	runHaxeCode([[
		if (game._noteGlowShader != null) {
			game._noteGlowShader.setFloat("strength", ]] .. tostring(strength) .. [[);
			game._noteGlowShader.setFloatArray("glowColor", [ ]] .. glowR .. [[, ]] .. glowG .. [[, ]] .. glowB .. [[ ]);
		}
	]])
end

-- Optional: change color mid-song from events or other scripts
function setNoteGlowColor(r, g, b)
	glowR, glowG, glowB = r, g, b
end
