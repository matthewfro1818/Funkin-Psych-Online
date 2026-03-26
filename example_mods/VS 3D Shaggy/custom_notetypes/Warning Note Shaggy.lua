function onCreate()
    for i = 0,getProperty('unspawnNotes.length')-1 do
        if getPropertyFromGroup('unspawnNotes',i,'noteType') == 'Warning Note Shaggy' then
            setPropertyFromGroup('unspawnNotes', i, 'texture', 'notes/warning');
            setPropertyFromGroup('unspawnNotes', i, 'lowPriority', true);
        end
    end
end

function noteMiss(id, noteData, noteType, isSustainNote)
	if noteType == "Warning Note Shaggy" then
		setProperty('health', -2)
	end
end
