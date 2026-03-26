function onCreate()
    for i = 0,getProperty('unspawnNotes.length')-1 do
        if getPropertyFromGroup('unspawnNotes',i,'noteType') == 'Kill Note' then
            setPropertyFromGroup('unspawnNotes', i, 'texture', 'notes/tricky');
            setPropertyFromGroup('unspawnNotes',i,'ignoreNote',false);
            setPropertyFromGroup('unspawnNotes', i, 'lowPriority', true);
            if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
			setPropertyFromGroup('unspawnNotes', i, 'ignoreNote', true);
            end
        end
    end
end

function goodNoteHit(id, data, noteType, sus)
	if noteType == 'Kill Note' then
		setPropertyFromClass('GameOverSubstate', 'deathSoundName', 'notes/zoinks')
		setPropertyFromClass('GameOverSubstate', 'loopSoundName', '')

		setProperty('health', -2)
	end
end

function onUpdatePost()
	if inGameOver then
		setProperty('boyfriend.visible', false)
	end
end