function onCreate()
    for i = 0,getProperty('unspawnNotes.length')-1 do
        if getPropertyFromGroup('unspawnNotes',i,'noteType') == 'Warning Note' then
		setPropertyFromGroup('unspawnNotes', i, 'noAnimation', true)
            setPropertyFromGroup('unspawnNotes', i, 'texture', 'notes/warning');
            setPropertyFromGroup('unspawnNotes', i, 'lowPriority', true);
		if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
			setPropertyFromGroup('unspawnNotes', i, 'noAnimation', false);
		end
        end
    end
end

function noteMiss(id, noteData, noteType, isSustainNote)
	if noteType == "Warning Note" then
		setPropertyFromClass('GameOverSubstate', 'deathSoundName', 'notes/bell')
		setPropertyFromClass('GameOverSubstate', 'loopSoundName', '')

		setProperty('health', -2)
	end
end
