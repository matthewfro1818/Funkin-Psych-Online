local shadname = "glitchEffect";

function onCreate()
    initLuaShader(shadname)

	makeLuaSprite('sprite1', 'background', -762, -531);
	scaleObject('sprite1', 10,10,true)
    setProperty('sprite1.antialiasing', false)
	setSpriteShader('sprite1', shadname)

	makeLuaSprite('sprite3', 'pyramids', -409, -254);
	scaleObject('sprite3', 4,4,true)
    setProperty('sprite3.antialiasing', false)
	setSpriteShader('sprite3', shadname)

	makeLuaSprite('van', 'the_meme', 0, 0);
    setProperty('van.antialiasing', false)
	scaleObject('van', 2.5,2.5,true)

	makeLuaSprite('bg', 'hills', -1310, 561);
    setProperty('bg.antialiasing', false)
	scaleObject('bg', 2.5,2.5,true)

	makeLuaSprite('hud', 'thing', 965, 0);
    setObjectCamera('hud', "other")

    setProperty('hud.antialiasing', false)

        addLuaSprite('sprite1');
        addLuaSprite('sprite3');
	addLuaSprite('bg');
        addLuaSprite('hud', true);

	setShaderFloat('sprite1', 'uWaveAmplitude', 0.1)
	setShaderFloat('sprite1', 'uFrequency', 5)
	setShaderFloat('sprite1', 'uSpeed', 2)
	setShaderFloat('sprite3', 'uWaveAmplitude', 0.1)
	setShaderFloat('sprite3', 'uFrequency', 5)
	setShaderFloat('sprite3', 'uSpeed', 2)
end
function onUpdatePost(elapsed)
	setShaderFloat('sprite1', 'uTime', os.clock())
	setShaderFloat('sprite3', 'uTime', os.clock())
end
function onUpdate()
	songPos = getSongPosition()
	currentBeat = (songPos/1000)*(bpm/80)
	setProperty("van.scale.x",0.3)
	setProperty("van.scale.y",0.3)
	setProperty("van.y",150+math.sin(currentBeat*math.pi/16)*200)
	setProperty("van.x",-1500+math.fmod(currentBeat*100,3300))
	setProperty("van.angle",currentBeat*10)
end