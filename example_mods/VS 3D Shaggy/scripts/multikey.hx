import states.editors.ChartingState;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.StrumNote;
import backend.Song;
import haxe.format.JsonParser;
import lime.utils.Assets;
import lime.system.System;
import backend.StageData;
import backend.Highscore;
import backend.Difficulty;
import objects.NoteSplash;
import backend.ui.PsychUINumericStepper;
import backend.ui.PsychUIButton;
import states.editors.content.PsychJsonPrinter;
import String;
import Sys;
import Reflect;
import ValueType;

// import haxe.macro.Compiler;
// The current keycount.
var keyCount:Int = 4;

// Note Colors.
// We can just grab the player's colors for these.
var LEFT:Array<Int> = ClientPrefs.data.arrowRGB[0];
var DOWN:Array<Int> = ClientPrefs.data.arrowRGB[1];
var UP:Array<Int> = ClientPrefs.data.arrowRGB[2];
var RIGHT:Array<Int> = ClientPrefs.data.arrowRGB[3];
var SQUARE:Array<Int> = [0xFFCCCCCC, 0xFFFFFFFF, 0xFF3E3E3E];
var LEFT2:Array<Int> = [0xFFFFFF00, 0xFFFFFFFF, 0xFF993300];
var DOWN2:Array<Int> = [0xFF8B4AFF, 0xFFFFFFFF, 0xFF3B177D];
var UP2:Array<Int> = [0xFFFF0000, 0xFFFFFFFF, 0xFF660000];
var RIGHT2:Array<Int> = [0xFF0033FF, 0xFFFFFFFF, 0xFF000066];
var NONE:Array<Int> = [0x0, 0x0, 0x0];

// 2D Array of all the note colors.
// (Really its a 3D Array but I made it so you can edit it like a 2D Array)
var noteColors:Array<Array<Array<Int>>> = [
	[SQUARE, NONE, NONE, NONE], // I need to do this for less than 4 keys, otherwise the game will crash.
	[LEFT, RIGHT, NONE, NONE],
	[LEFT, SQUARE, RIGHT, NONE],
	[LEFT, DOWN, UP, RIGHT],
	[LEFT, DOWN, SQUARE, UP, RIGHT],
	[LEFT, UP, RIGHT, LEFT2, DOWN, RIGHT2],
	[LEFT, UP, RIGHT, SQUARE, LEFT2, DOWN, RIGHT2],
	[LEFT, DOWN, UP, RIGHT, LEFT2, DOWN2, UP2, RIGHT2],
	[LEFT, DOWN, UP, RIGHT, SQUARE, LEFT2, DOWN2, UP2, RIGHT2]
];

// Note variables.
var noteSizes:Array<Float> = [0.9, 0.85, 0.8, 0.7, 0.66, 0.6, 0.55, 0.5, 0.46];
var noteOffsetsX:Array<Float> = [-100, -75, -50, 0, 35, 45, 52, 57, 65];
var noteOffsetsY:Array<Float> = [0, 0, 0, 0, 10, 25, 25, 40, 40];
var strumOffsets:Array<Float> = [0, -30, -10, 0, 10, 20, 32, 40, 45];

var splashOffsets:Array<Arrat<Float>> = [
	[-100, -100],
	[-75, -90],
	[-75, -80],
	[-52, -48],
	[-40, -48],
	[-25, -25],
	[-20, -25],
	[0, 0],
	[0, 0],
];

// 2D Array of all the sing animations for each keycount.
var singAnimations:Array<Array<String>> = [
	["singUP"],
	["singLEFT", "singRIGHT"],
	["singLEFT", "singUP", "singRIGHT"],
	["singLEFT", "singDOWN", "singUP", "singRIGHT"],
	["singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT"],
	["singLEFT", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singRIGHT"],
	["singLEFT", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singRIGHT"],
	[
		"singLEFT",
		"singDOWN",
		"singUP",
		"singRIGHT",
		"singLEFT",
		"singDOWN",
		"singUP",
		"singRIGHT"
	],
	[
		"singLEFT",
		"singDOWN",
		"singUP",
		"singRIGHT",
		"singUP",
		"singLEFT",
		"singDOWN",
		"singUP",
		"singRIGHT"
	]
];

// 2D Array for animations for the notes.
var noteAnimations:Array<Array<String>> = [
	["square"],
	["left", "right"],
	["left", "square", "right"],
	["left", "down", "up", "right"],
	["left", "down", "square", "up", "right"],
	["left", "up", "right", "left", "down", "right"],
	["left", "up", "right", "square", "left", "down", "right"],
	["left", "down", "up", "right", "left", "down", "up", "right"],
	["left", "down", "up", "right", "square", "left", "down", "up", "right"]
];

var colArray:Array<Array<String>> = [
	["square"],
	["purple", "red"],
	["purple", "square", "red"],
	["purple", "blue", "green", "red"],
	["purple", "blue", "square", "green", "red"],
	["purple", "green", "red", "purple", "blue", "red"],
	["purple", "green", "red", "square", "purple", "blue", "red"],
	["purple", "blue", "green", "red", "purple", "blue", "green", "red"],
	["purple", "blue", "green", "red", "square", "purple", "blue", "green", "red"]
];

function onCreate() {
	// P-Slice is not supported and never will be.
	if (Sys.programPath().toLowerCase().indexOf("pslice") != -1) {
		FlxG.stage.window.alert("P-Slice is not supported by the multikey script. Please use original Psych Engine (1.0.4).", "P-Slice detected!");
		return;
	}

	// Reload song with custom mania parsing.

	var songName = PlayState.SONG.song.toLowerCase();

	if (!PlayState.chartingMode) {
		PlayState.SONG = loadFromJson(songName + "-" + Difficulty.list[PlayState.storyDifficulty], songName);
	} else if (FlxG.save.data.lastKeyCount != null) {
		keyCount = FlxG.save.data.lastKeyCount;
	}

	if (PlayState.isPixelStage) {
		return;
	}

	// Setup colors

	if (FlxG.save.data.oldColors == null) {
		FlxG.save.data.oldColors = noteColors[3];
	}

	ClientPrefs.data.arrowRGB = noteColors[keyCount - 1];

	Note.colArray = colArray[keyCount - 1];
	Note.swagWidth = 160 * noteSizes[keyCount - 1];

	// Setup sing animations

	game.singAnimations = singAnimations[keyCount - 1];

	// Set this variable to match the keycount scale.

	// Keybinds

	var directions:Array<Array<Int>> = [
		[32],
		[70, 74],
		[70, 32, 74],
		[65, 83, 74, 75],
		[65, 83, 32, 75, 76],
		[65, 83, 68, 74, 75, 76],
		[83, 68, 70, 32, 74, 75, 76],
		[65, 83, 68, 70, 72, 74, 75, 76],
		[65, 83, 68, 70, 32, 72, 74, 75, 76]
	];

	for (i in 0...9) {
		for (j in 0...i + 1) {
			ClientPrefs.keyBinds.set(i + '_key_' + j, [directions[i][j]]);
		}
	}

	if (keyCount != 4) {
		game.keysArray = [
			for (i in 0...keyCount) {
				(keyCount - 1) + '_key_' + i;
			}
		];
	}

	/*var tempSplash:NoteSplash = new NoteSplash();
		tempSplash.destroy();
		tempSplash = null;

		for(config in NoteSplash.configs){
			for(animation in config.animations){
				trace(animation);
			}
	}*/

	// Chart editor stuff
	ChartingState.GRID_COLUMNS_PER_PLAYER = keyCount;
	FlxG.signals.postUpdate.removeAll();
	FlxG.signals.postUpdate.add(() -> {
		if (Std.isOfType(FlxG.state, ChartingState)) {
			try {
				for (group in [FlxG.state.curRenderedNotes.members, FlxG.state.behindRenderedNotes.members]) {
					for (note in group) {
						var color:Array<Int> = noteColors[keyCount - 1][note.noteData];

						note.rgbShader.r = color[0];
						note.rgbShader.g = color[1];
						note.rgbShader.b = color[2];
					}
				}
			} catch (e:Dynamic) {}
		}
	});
}

var noteTextures:Array<String> = [];

function onCreatePost() {
	if (PlayState.isPixelStage) {
		return;
	}
	if (keyCount != 4) {
		for(note in game.unspawnNotes){
			noteTextures.push(note.texture);
		}
		game.unspawnNotes = [];
		game.notes.clear();
		generateSong();
		for (script in game.luaArray){
			if(script.scriptName.toLowerCase().indexOf("custom_notetypes") != -1){
				script.call("onCreate", []);
				script.call("onCreatePost", []);
			}
		}
	}
	for (note in game.unspawnNotes) {
		note.scale.x = noteSizes[keyCount - 1];

		if (note.isSustainNote) {
			note.offsetX = Note.swagWidth / 2 - note.width / 2;
		}

		var color:Array<Int> = noteColors[keyCount - 1][note.noteData];

		note.rgbShader.r = color[0];
		note.rgbShader.g = color[1];
		note.rgbShader.b = color[2];

		note.noteSplashData.r = color[0];
		note.noteSplashData.g = color[1];
		note.noteSplashData.b = color[2];

		if (!note.isSustainNote || StringTools.endsWith(note?.animation?.curAnim?.name ?? "", "end")) {
			note.scale.y = noteSizes[keyCount - 1];
		}

		note.updateHitbox();
		note.centerOffsets();
	}
	Note.colArray = colArray[3];
}

function onDestroy() {
	if (PlayState.isPixelStage) {
		return;
	}
	FlxG.signals.postStateSwitch.addOnce(() -> {
		if (Std.isOfType(FlxG.state, ChartingState)) {
			FlxG.signals.preStateCreate.addOnce(() -> {
				ClientPrefs.data.arrowRGB = noteColors[3];
				Note.colArray = colArray[3];
			});

			// change keycount stuff
			var keyCountStepper:PsychUINumericStepper = new PsychUINumericStepper(150, 213, 1, keyCount, 1, 9);
			keyCountStepper.onValueChange = () -> {
				FlxG.save.data.lastKeyCount = ChartingState.GRID_COLUMNS_PER_PLAYER = keyCount = Std.int(keyCountStepper.value);
				Note.colArray = colArray[keyCount];
				ClientPrefs.data.arrowRGB = noteColors[keyCount - 1];
				FlxG.state.createGrids();

				FlxG.state.strumLineNotes.clear();

				var startX:Float = FlxG.state.gridBg.x;
				var startY:Float = FlxG.height / 2;

				for (i in 0...Std.int(ChartingState.GRID_PLAYERS * ChartingState.GRID_COLUMNS_PER_PLAYER)) {
					try {
						var note:StrumNote = new StrumNote(startX + (ChartingState.GRID_SIZE * i), startY, i % ChartingState.GRID_COLUMNS_PER_PLAYER, 0);
						note.animation.destroyAnimations();
						note.frames.addAtlas(Paths.getSparrowAtlas("noteSkins/square"));

						var noteAnim:String = noteAnimations[keyCount - 1][i % keyCount];

						if (noteAnim == null) {
							continue;
						}

						note.animation.addByPrefix('static', "arrow" + noteAnim.toUpperCase(), 24, false);
						note.animation.addByPrefix('pressed', noteAnim + ' press', 24, false);
						note.animation.addByPrefix('confirm', noteAnim + ' confirm', 24, false);

						var noteColor:Array<Int> = noteColors[keyCount - 1][i % keyCount];
						note.rgbShader.r = noteColor[0];
						note.rgbShader.g = noteColor[1];
						note.rgbShader.b = noteColor[2];

						note.scrollFactor.set();
						note.playAnim('static');
						note.alpha = 0.4;
						note.updateHitbox();
						if (note.width > note.height)
							note.setGraphicSize(ChartingState.GRID_SIZE);
						else
							note.setGraphicSize(0, ChartingState.GRID_SIZE);

						note.updateHitbox();
						note.x += (ChartingState.GRID_SIZE / 2 - note.width / 2) + ChartingState.GRID_SIZE;
						note.y += ChartingState.GRID_SIZE / 2 - note.height / 2;
						FlxG.state.strumLineNotes.add(note);
					} catch (e:Dynamic) {}
				}

				/*var columns:Int = 0;
					var iconX:Float = FlxG.state.gridBg.x;
					var iconY:Float = 50;
					if(ChartingState.SHOW_EVENT_COLUMN)
					{
						FlxG.state.eventIcon.x = iconX + (ChartingState.GRID_SIZE * 0.5) - FlxG.state.eventIcon.width/2;
						iconX += ChartingState.GRID_SIZE;

						columns++;
					}

					var gridStripes:Array<Int> = [];
					for (i in 0...ChartingState.GRID_PLAYERS)
					{
						if(columns > 0) gridStripes.push(columns);
						columns += ChartingState.GRID_COLUMNS_PER_PLAYER;
					}
					FlxG.state.prevGridBg.stripes = FlxG.state.nextGridBg.stripes = FlxG.state.gridBg.stripes = gridStripes; */

				FlxG.state.updateWaveform();

				FlxG.state.eventLockOverlay.x = FlxG.state.gridBg.x;
				FlxG.state.eventLockOverlay.scale.x = ChartingState.GRID_SIZE;
				FlxG.state.eventLockOverlay.updateHitbox();

				FlxG.state.timeLine.x = FlxG.state.gridBg.x;
				FlxG.state.timeLine.setGraphicSize(Std.int(FlxG.state.gridBg.width), 4);
				FlxG.state.timeLine.updateHitbox();
				FlxG.state.timeLine.screenCenter(0x10);

				FlxG.state.showOutput('Key Count changed to ' + keyCount + '.\nPlease restart the chart editor for changes to take full effect.');
			}
			FlxG.state.mainBox.getTab('Song').menu.add(keyCountStepper);
			FlxG.state.mainBox.getTab('Song').menu.add(new FlxText(keyCountStepper.x, keyCountStepper.y - 15, 100, 'Key Count:'));

			FlxG.state.strumLineNotes.clear();

			var startX:Float = FlxG.state.gridBg.x;
			var startY:Float = FlxG.height / 2;

			for (i in 0...Std.int(ChartingState.GRID_PLAYERS * ChartingState.GRID_COLUMNS_PER_PLAYER)) {
				var note:StrumNote = new StrumNote(startX + (ChartingState.GRID_SIZE * i), startY, i % ChartingState.GRID_COLUMNS_PER_PLAYER, 0);
				note.animation.destroyAnimations();
				note.frames.addAtlas(Paths.getSparrowAtlas("noteSkins/square"));

				var noteAnim:String = noteAnimations[keyCount - 1][i % keyCount];

				if (noteAnim == null) {
					continue;
				}

				note.animation.addByPrefix('static', "arrow" + noteAnim.toUpperCase(), 24, false);
				note.animation.addByPrefix('pressed', noteAnim + ' press', 24, false);
				note.animation.addByPrefix('confirm', noteAnim + ' confirm', 24, false);

				var noteColor:Array<Int> = noteColors[keyCount - 1][i % keyCount];
				note.rgbShader.r = noteColor[0];
				note.rgbShader.g = noteColor[1];
				note.rgbShader.b = noteColor[2];

				note.scrollFactor.set();
				note.playAnim('static');
				note.alpha = 0.4;
				note.updateHitbox();
				if (note.width > note.height)
					note.setGraphicSize(ChartingState.GRID_SIZE);
				else
					note.setGraphicSize(0, ChartingState.GRID_SIZE);

				note.updateHitbox();
				note.x += (ChartingState.GRID_SIZE / 2 - note.width / 2) + ChartingState.GRID_SIZE;
				note.y += ChartingState.GRID_SIZE / 2 - note.height / 2;
				FlxG.state.strumLineNotes.add(note);
			}

			// override save and save as functions

			for (member in FlxG.state.upperBox.getTab('File').menu.members) {
				if (!Std.isOfType(member, PsychUIButton)) {
					continue;
				}
				switch (member.label) {
					case '  Save as...':
						member.onClick = () -> {
							if (!FlxG.state.fileDialog.completed) {
								return;
							}
							FlxG.state.upperBox.isMinimized = true;
							FlxG.state.upperBox.bg.visible = false;

							saveChart(false);
						}
					case '  Save':
						member.onClick = () -> {
							if (!FlxG.state.fileDialog.completed) {
								return;
							}
							FlxG.state.upperBox.isMinimized = true;
							FlxG.state.upperBox.bg.visible = false;

							saveChart();
						}
				}
			}
		}
	});
	Note.swagWidth = 160 * noteSizes[3];
	if (Std.isOfType(FlxG.game._nextState, ChartingState)) {
		Note.colArray = colArray[keyCount - 1];
		FlxG.save.data.lastKeyCount = keyCount;
	} else {
		ClientPrefs.data.arrowRGB = FlxG.save.data.oldColors;
		Note.colArray = colArray[3];
	}
}

function goodNoteHit(note:Note) {
	if (PlayState.isPixelStage || keyCount == 4) {
		return;
	}
	/*var lastSpawnedSplash:NoteSplash = game.grpNoteSplashes.members[game.grpNoteSplashes.members.length - 1];
		var color:Array<Int> = noteColors[keyCount - 1][lastSpawnedSplash.noteData % keyCount];
			
		lastSpawnedSplash.rgbShader.shader.r.value = [(color[0] >> 16) & 0xff, (color[0] >> 8) & 0xff, (color[0]) & 0xff];
		lastSpawnedSplash.rgbShader.shader.g.value = [(color[1] >> 16) & 0xff, (color[1] >> 8) & 0xff, (color[1]) & 0xff];
		lastSpawnedSplash.rgbShader.shader.b.value = [(color[2] >> 16) & 0xff, (color[2] >> 8) & 0xff, (color[2]) & 0xff]; */
	/*var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset); 
		var firstSplash = game.grpNoteSplashes.members[game.grpNoteSplashes.members.length - 1];
		if(firstSplash.animation.curAnim == null || (firstSplash.animation.curAnim.curFrame == 0 && Conductor.judgeNote(game.ratingsData, noteDiff / playbackRate).image == "sick")){
			firstSplash.noteDataMap.clear();
			for(i in 0...keyCount * 2){
				firstSplash.noteDataMap.set(i, "red");
			}
			firstSplash.playDefaultAnim();
			firstSplash.shader = note.shader;
	}*/
	for (splash in game.grpNoteSplashes.members) {
		var scale:Float = splash.config.scale * (noteSizes[keyCount - 1] / 0.7);
		var offset:Array<Float> = splashOffsets[keyCount - 1];
		splash.scale.set(scale, scale);
		splash.centerOffsets();
		splash.offset.x += offset[0];
		splash.offset.y += offset[1];
	}
}

function onCountdownStarted() {
	if (PlayState.isPixelStage) {
		return;
	}
	playerStrums.clear();
	opponentStrums.clear();
	strumLineNotes.clear();
	generateStaticArrows(0);
	generateStaticArrows(1);
	for (i in 0...playerStrums.length) {
		game.setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
		game.setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
	}
	for (i in 0...opponentStrums.length) {
		game.setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
		game.setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
	}
}

function positionStrum(strum:StrumNote) {
	switch (keyCount - 1) {
		case 3:
			strum.x += (Note.swagWidth * strum.noteData);
		case 0 | 1 | 2:
			strum.x += strum.width * strum.noteData;
		default:
			strum.x += ((strum.width - strumOffsets[keyCount - 1]) * strum.noteData);
	}

	strum.x += 50;
	strum.x += ((FlxG.width / 2) * strum.player);
	strum.ID = strum.noteData;
	strum.x -= noteOffsetsX[keyCount - 1];
	strum.y += noteOffsetsY[keyCount - 1];
}

// copy of the function with support for custom keycounts.
function generateStaticArrows(player:Int):Void {
	var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
	var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
	for (i in 0...keyCount) {
		// FlxG.log.add(i);
		var targetAlpha:Float = 1;
		if (player < 1) {
			if (!ClientPrefs.data.opponentStrums)
				targetAlpha = 0;
			else if (ClientPrefs.data.middleScroll)
				targetAlpha = 0.35;
		}

		var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
		babyArrow.animation.destroyAnimations();
		babyArrow.frames.addAtlas(Paths.getSparrowAtlas("noteSkins/square"));

		var noteAnim:String = noteAnimations[keyCount - 1][i];

		babyArrow.animation.addByPrefix('static', "arrow" + noteAnim.toUpperCase(), 24, false);
		babyArrow.animation.addByPrefix('pressed', noteAnim + ' press', 24, false);
		babyArrow.animation.addByPrefix('confirm', noteAnim + ' confirm', 24, false);

		var noteColor:Array<Int> = noteColors[keyCount - 1][i];
		babyArrow.rgbShader.r = noteColor[0];
		babyArrow.rgbShader.g = noteColor[1];
		babyArrow.rgbShader.b = noteColor[2];

		babyArrow.playAnim("static", true);

		babyArrow.x = strumLineX;
		babyArrow.y = strumLineY;
		positionStrum(babyArrow);
		babyArrow.downScroll = ClientPrefs.data.downScroll;
		babyArrow.scale.set(noteSizes[keyCount - 1], noteSizes[keyCount - 1]);
		babyArrow.updateHitbox();
		if (!PlayState.isStoryMode && !skipArrowStartTween) {
			// babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
		} else {
			babyArrow.alpha = targetAlpha;
		}

		if (player == 1) {
			playerStrums.add(babyArrow);
		} else {
			if (ClientPrefs.data.middleScroll) {
				babyArrow.x += 310;
				if (i > Math.floor(keyCount / 2) - 1) { // Up and Right
					babyArrow.x += FlxG.width / 2 + 25;
				}
			}
			opponentStrums.add(babyArrow);
		}

		strumLineNotes.add(babyArrow);
	}
}

function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
{
	if (songJson.gfVersion == null) {
		songJson.gfVersion = songJson.player3;
		if (Reflect.hasField(songJson, 'player3'))
			Reflect.deleteField(songJson, 'player3');
	}

	if (songJson.keyCount != null) {
		songJson.mania = songJson.keyCount - 1;
		songJson.keyCount = null;
	}

	if (songJson.mania == null) {
		songJson.mania = 3;
	}

	if (songJson.events == null) {
		songJson.events = [];
		for (secNum in 0...songJson.notes.length) {
			var sec:Dynamic = songJson.notes[secNum];

			var i:Int = 0;
			var notes:Array<Dynamic> = sec.sectionNotes;
			var len:Int = notes.length;
			while (i < len) {
				var note:Array<Dynamic> = notes[i];
				if (note[1] < 0) {
					songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
					notes.remove(note);
					len = notes.length;
				} else
					i++;
			}
		}
	}

	if (songJson.splashSkin == null || songJson.splashSkin == "") {
		//	songJson.splashSkin = "noteSplashes/noteSplashes";
	}

	var sectionsData:Array<Dynamic> = songJson.notes;
	if (sectionsData == null)
		return;

	for (section in sectionsData) {
		var beats:Null<Float> = section.sectionBeats;
		if (beats == null || Math.isNaN(beats)) {
			section.sectionBeats = 4;
			if (Reflect.hasField(section, 'lengthInSteps'))
				Reflect.deleteField(section, 'lengthInSteps');
		}

		for (note in section.sectionNotes) {
			var gottaHitNote:Bool = (note[1] < songJson.mania + 1) ? section.mustHitSection : !section.mustHitSection;
			note[1] = (note[1] % songJson.mania + 1) + (gottaHitNote ? 0 : songJson.mania + 1);

			if (!Std.isOfType(note[3], String))
				note[3] = Note.defaultNoteTypes[note[3]]; // compatibility with Week 7 and 0.1-0.3 psych charts
		}
	}
}

var noteIndex:Int = 0;

function generateSong():Void {
	// FlxG.log.add(ChartParser.parse());
	songSpeed = PlayState.SONG.speed;

	var songData = PlayState.SONG;
	Conductor.bpm = songData.bpm;

	curSong = songData.song;

	var oldNote:Note = null;
	var sectionsData:Array<Dynamic> = PlayState.SONG.notes;
	var ghostNotesCaught:Int = 0;
	var daBpm:Float = Conductor.bpm;

	for (section in sectionsData) {
		if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
			daBpm = section.bpm;

		for (i in 0...section.sectionNotes.length) {
			final songNotes:Array<Dynamic> = section.sectionNotes[i];
			var gottaHitNote:Bool = section.mustHitSection;
			var spawnTime:Float = songNotes[0];
			var noteColumn:Int = Std.int(songNotes[1] % (keyCount));
			var holdLength:Float = songNotes[2];
			var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
			if (Math.isNaN(holdLength))
				holdLength = 0.0;

			if (keyCount != 4) {
				if (songNotes[1] > keyCount - 1) {
					gottaHitNote = !section.mustHitSection;
				}
			} else {
				gottaHitNote = (songNotes[1] < game.totalColumns);
			}
			if (i != 0) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnNotes) {
					var matches:Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
					if (matches && Math.abs(spawnTime - evilNote.strumTime) < FlxMath.EPSILON) {
						if (evilNote.tail.length > 0)
							for (tail in evilNote.tail) {
								tail.destroy();
								unspawnNotes.remove(tail);
							}
						evilNote.destroy();
						unspawnNotes.remove(evilNote);
						ghostNotesCaught++;
						// continue;
					}
				}
			}

			var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);

			swagNote.frames.addAtlas(Paths.getSparrowAtlas("noteSkins/square"));
			swagNote.animation.addByPrefix(Note.colArray[swagNote.noteData] + 'Scroll', Note.colArray[swagNote.noteData] + '0');
			swagNote.animation.play(swagNote.animName, true);

			var isAlt:Bool = section.altAnim && !gottaHitNote;
			swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
			swagNote.animSuffix = isAlt ? "-alt" : "";
			swagNote.mustPress = gottaHitNote;
			swagNote.sustainLength = holdLength;
			swagNote.noteType = noteType;

			swagNote.scrollFactor.set();

			swagNote.texture = noteTextures[noteIndex];
			noteIndex++;

			unspawnNotes.push(swagNote);


			var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
			final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
			if (roundSus > 0) {
				for (susNote in 0...roundSus) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, true);

					/*var prevNote:Note = oldNote;

						var animName:String = prevNote.isSustainNote ? colArray[prevNote.noteData % colArray.length] + 'hold' : colArray[prevNote.noteData % colArray.length] + 'holdend';

						sustainNote.animation.destroyAnimations(animName);
						sustainNote.attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
						sustainNote.animation.addByPrefix(colArray[noteColumn] + 'holdend', StringTools.replace(colArray[noteColumn], 'square', 'green') + ' hold end', 24, true);
						sustainNote.animation.addByPrefix(colArray[noteColumn] + 'hold', StringTools.replace(colArray[noteColumn], 'square', 'green') + ' hold piece', 24, true);
						sustainNote.animation.play(animName, true); */

					sustainNote.animSuffix = swagNote.animSuffix;
					sustainNote.mustPress = swagNote.mustPress;
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = swagNote.noteType;
					sustainNote.scrollFactor.set();
					sustainNote.parent = swagNote;

					sustainNote.texture = noteTextures[noteIndex];
					noteIndex++;

					unspawnNotes.push(sustainNote);
					swagNote.tail.push(sustainNote);

					sustainNote.correctionOffset = swagNote.height / 2;
					if (!PlayState.isPixelStage) {
						if (oldNote.isSustainNote) {
							oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}

						if (ClientPrefs.data.downScroll)
							sustainNote.correctionOffset = 0;
					} else if (oldNote.isSustainNote) {
						oldNote.scale.y /= playbackRate;
						oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
					}

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
					else if (ClientPrefs.data.middleScroll) {
						sustainNote.x += 310;
						if (noteColumn > 1) // Up and Right
							sustainNote.x += FlxG.width / 2 + 25;
					}
				}
			}

			if (swagNote.mustPress) {
				swagNote.x += FlxG.width / 2; // general offset
			} else if (ClientPrefs.data.middleScroll) {
				swagNote.x += 310;
				if (noteColumn > 1) // Up and Right
				{
					swagNote.x += FlxG.width / 2 + 25;
				}
			}

			oldNote = swagNote;
		}
	}
	unspawnNotes.sort(PlayState.sortByTime);
	generatedMusic = true;
}

var _lastPath:String;

function getChart(jsonInput:String, ?folder:String):Dynamic {
	if (folder == null)
		folder = jsonInput;
	var rawData:String = null;

	var formattedFolder:String = Paths.formatToSongPath(folder);
	var formattedSong:String = Paths.formatToSongPath(jsonInput);
	_lastPath = Paths.json(formattedFolder + '/' + formattedSong);

	if (FileSystem.exists(StringTools.replace(_lastPath, '-normal', '')) && !FileSystem.exists(_lastPath)) {
		_lastPath = StringTools.replace(_lastPath, '-normal', '');
	}

	// macro stuff doesnt work at runtime.. oof.
	if (/**Compiler.getDefine("MODS_ALLOWED") != null &&**/ FileSystem.exists(_lastPath))
		rawData = File.getContent(_lastPath);
	else
		rawData = Assets.getText(_lastPath);

	return rawData != null ? parseJSON(rawData, jsonInput) : null;
}

function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):Dynamic {
	var songJson = new JsonParser(rawData).doParse();
	if (Reflect.hasField(songJson, 'song')) {
		var subSong:Dynamic = Reflect.field(songJson, 'song');
		if (subSong != null && Type.typeof(subSong) == ValueType.TObject)
			songJson = subSong;
	}

	if (Reflect.hasField(songJson, 'keyCount')) {
		game.totalColumns = keyCount = songJson.keyCount;
	} else if (Reflect.hasField(songJson, 'mania')) {
		game.totalColumns = keyCount = songJson.mania + 1;
		Reflect.deleteField(songJson, 'mania');
	} else {
		game.totalColumns = keyCount = 4;
	}

	if (!Reflect.hasField(songJson, 'events')) {
		Reflect.setField(songJson, 'events', []);
	}

	game.setOnScripts('keyCount', keyCount);
	game.setOnScripts('mania', keyCount - 1);

	if (keyCount == 4) {
		return Song.parseJSON(rawData, nameForError, convertTo); // kinda hacky buy uhmm fuck you i dont care
	}

	if (convertTo != null && convertTo.length > 0) {
		var fmt:String = songJson.format;
		if (fmt == null)
			fmt = songJson.format = 'unknown';

		switch (convertTo) {
			case 'psych_v1':
				if (!fmt.startsWith('psych_v1')) // Convert to Psych 1.0 format
				{
					trace('converting chart $nameForError with format $fmt to psych_v1 format...');
					songJson.format = 'psych_v1_convert';
					convert(songJson);
				}
		}
	}

	if (Reflect.hasField(songJson, 'splashSkin')) {
		// songJson.splashSkin = "noteSplashes/" + ClientPrefs.data.splashSkin ;
	}

	return songJson;
}

function loadFromJson(jsonInput:String, ?folder:String):Dynamic {
	folder ??= jsonInput;
	PlayState.SONG = getChart(jsonInput, folder);
	return PlayState.SONG;
}

function saveChart(canQuickSave:Bool = true) {
	FlxG.state.updateChartData();
	var dataShit:Dynamic = PlayState.SONG;
	dataShit.keyCount = keyCount;
	var chartData:String = PsychJsonPrinter.print(dataShit, ['sectionNotes', 'events']);
	if (canQuickSave && Song.chartPath != null) {
		File.saveContent(Song.chartPath, chartData);
		FlxG.state.showOutput('Chart saved successfully to: ${Song.chartPath}');
	} else {
		var chartName:String = Paths.formatToSongPath(PlayState.SONG.song) + '.json';
		if (Song.chartPath != null)
			chartName = StringTools.trim(Song.chartPath.substr(Song.chartPath.lastIndexOf('/')));
		FlxG.state.fileDialog.save(chartName, chartData, () -> {
			var newPath:String = FlxG.state.fileDialog.path;
			Song.chartPath = newPath.replace('\\', '/');
			FlxG.state.reloadNotesDropdowns();
			FlxG.state.showOutput('Chart saved successfully to: $newPath');
		}, null, () -> {
			showOutput('Error on saving chart!', true);
		});
	}
}
