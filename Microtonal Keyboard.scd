/*
===========================================
|                                         |
|      Hit Cmd+A to select all, then      |
|      Hit Cmd+return to boot up!         |
|                                         |
===========================================
*/

/*
TO DO:
IMPLEMENT SUSTAIN
fix the c7 piano note
*/
(
MIDIIn.connectAll;
s.waitForBoot({
	var centsDict, synths, win, group, sustain, freqsDict, bus, namesDict, nbDict, keys, noteOn, noteOff, octaveOffset, heldKeys, pianoBoard, volSl, vol, keyDisplays,updateOctaveOffset, letters, txt, blackWidth = 47, whiteWidth = 47, lineOneSpacer, topHeight = 124, guiLine = 1, freeAll, bottomHeight, noteRange = ("eb 0".namemidi.."c 7".namemidi), settingsDisplay, lineOneView;
	group = Group.new;
	centsDict = Dictionary.new;
	freqsDict = Dictionary.new;
	synths = Dictionary.new;
	namesDict = Dictionary.new;
	nbDict = Dictionary.new;
	keyDisplays = Dictionary.new;
	win = Window("Microtonal Keyboard",Rect(0,0,1419,635));
	win.view.decorator_(FlowLayout(win.bounds,2@2,0@0));
	bus = Bus.audio(s,2);
	keys = [ 97, 119, 115, 101, 100, 102, 116, 103, 121, 104, 117, 106, 107, 111, 108, 112, 59, 39, 93 ]; // unicode keys c through f# (8va * 1.5)
	letters = ["A","W","S","E","D","F","T","G","Y","H","U","J","K","O","L","P",";","'","]"];
	octaveOffset = 2;
	heldKeys = [];
	vol = -6;
	bottomHeight = topHeight * 0.3;

	updateOctaveOffset = {
		arg direction;
		//"octave offset".postln;
		freeAll.();
		octaveOffset = min(max(octaveOffset + direction,2),8);
		keyDisplays.keysValuesDo({
			arg k, v;
			var i;
			i = k - (octaveOffset * 12);
			if((i >= 0) && (i < letters.size),{
				v.string_(letters[i]);
			},{
				v.string_("");
			});
		});
	};

	freeAll = {
		noteRange.do({
			arg k;
			noteOff.(k);
		});
		group.set(\gate,0);
		synths.clear;
	};

	win.view.keyDownAction_({
		arg view, char, modifiers, unicode, keycode, key;
		//"key down".postln;
		[view, char, modifiers, unicode, keycode, key].postln;
		unicode.switch(
			122,{
				updateOctaveOffset.(-1);
			},
			120,{
				updateOctaveOffset.(1);
			},
			46,{
				//".".postln;
				freeAll.();
			},{
				if(keys.includes(unicode) && heldKeys.includes(unicode).not,{
					var note = keys.indexOf(unicode) + (octaveOffset * 12);
					heldKeys = heldKeys.add(unicode);
					//"it is a key".post; note.postln;
					if(synths.at(note).isNil,{
						//keys.indexOf(unicode).postln;
						noteOn.(note,100);
					});
				});
		});
		//octaveOffset.postln;
	});

	win.view.keyUpAction_({
		arg view, char, modifiers, unicode, keycode, key;
		if(keys.includes(unicode),{
			var note = keys.indexOf(unicode) + (octaveOffset * 12);
			heldKeys.remove(unicode);
			noteOff.(note);
		});
	});

	/*	lineOneSpacer = {
	arg height, boolean;
	var temp;
	boolean = boolean ? false;
	temp = CompositeView(win,Rect(
	0,
	0,
	(whiteWidth*5) + (blackWidth*6) + ((whiteWidth + (blackWidth * 0.5)) * 4) + 38,
	height
	));

	if(boolean,{settingsDisplay = temp});
	};

	lineOneSpacer.(topHeight, true);*/

	settingsDisplay = CompositeView(win,Rect(
		0,
		0,
		839,
		topHeight + bottomHeight
	));
	settingsDisplay.decorator_(FlowLayout(settingsDisplay.bounds));
	StaticText(settingsDisplay,Rect(0,0,settingsDisplay.bounds.width,65)).string_("Microtonal Keyboard").font_(Font("Helvetica",65));

	Button(settingsDisplay,Rect(0,0,100,40))
	.states_([["Save"]])
	.action_({
		arg b;
		Dialog.savePanel({
			arg p;
			var dict = Dictionary.new;
			dict.put(\centsDict,centsDict);
			//vol.postln;
			dict.put(\vol,vol);
			dict.put(\octaveOffset,octaveOffset);
			dict.writeArchive(p);
		});
	});

	Button(settingsDisplay,Rect(0,0,100,40))
	.states_([["Load"]])
	.action_({
		arg b;
		Dialog.openPanel({
			arg p;
			//p.postln;
			var dict = Object.readArchive(p);
			centsDict = dict.at(\centsDict);
			centsDict.keysValuesDo({
				arg k, v;
				nbDict.at(k).valueAction_(v);
			});
			octaveOffset = dict.at(\octaveOffset);
			updateOctaveOffset.(0);
			//dict.at(\vol).postln;
			volSl.valueAction_(dict.at(\vol));
		});
	});

	StaticText(settingsDisplay,Rect(0,0,270,40)).font_(Font("Helvetica",20)).string_(
		"  QWERTY Keyboard Keys in"
	);

	txt = StaticText(settingsDisplay,Rect(0,0,60,40)).font_(Font("Helvetica",20, true)).stringColor_(Color.cyan).string_(
		"BLUE"
	);

	StaticText(settingsDisplay,Rect(0,0,275,40)).font_(Font("Helvetica",10)).string_(
		"(Z) Octave Down (X) Octave Up (.) Stop All Notes \n(TAB) Advance Through \"Cts:\" Boxes"
	);

	settingsDisplay.decorator.nextLine;

	volSl = EZSlider(settingsDisplay,Rect(0,0,400,40),"Vol: ",\db.asSpec,{
		arg sl;
		//sl.value.postln;
		vol = sl.value;
		//vol.postln;
		pianoBoard.set(\vol,vol);
		txt.focus(true);
		//sl.sliderView.hasFocus(false);
		//win.bounds.postln;
	},vol,false,30,50);//.sliderView.canFocus_(false);

/*	StaticText(settingsDisplay,Rect(0,0,425,40)).font_(Font("Helvetica",10)).string_(
		"QWERTY Keyboard not working? \nHold 'command' and hit 'tab' until the you're over the 'exec' app. \nWant to quit? \n'command'+'tab' until you're over the 'Microtonal Keyboard App', then 'command + Q'"
	);*/

/*	StaticText(settingsDisplay,Rect(0,0,220,20))
	.string_("  (TAB) Advance Through \"Cts:\" Boxes").font_(Font("Helvetica",12));*/
	//.background_(Color.blue);
	//win.view.decorator.nextLine;

	SynthDef(\pianoString,{
		arg freq, vel, gate = 1, pan = 0, outBus;//sustain, , tune = 0.5;
		var sig;
		//sig = MdaPiano.ar(freq,gate,vel,tune:tune.poll,random:0,sustain:sustain);
		sig = OteyPianoStrings.ar(freq, vel.linlin(0,127,-30.dbamp,1),detune:0.0002);
		sig = Pan2.ar(sig,pan);
		sig = sig * EnvGen.kr(Env.asr(0,1,0.5),gate,doneAction:2);
		sig = sig * -11.dbamp;
		//sig = sig * AmpCompA.kr(freq);
		sig = sig * max(1,freq-880).explin(1,3500,1,20).dbamp;
		DetectSilence.ar(sig,doneAction:2);
		Out.ar(outBus,sig);
	}).add;

	pianoBoard = SynthDef(\pianoSoundBoard,{
		arg inBus, vol;
		var sig;
		sig = OteySoundBoard.ar(In.ar(inBus,2));
		sig = sig * -10.dbamp;
		sig = SelectX.ar(0.15,[sig,LPF.ar(GVerb.ar(sig,150,0.3,drylevel:0),20000)]);
		sig = MidEQ.ar(sig,554.4,14.42.reciprocal,-5);
		sig = sig * -12.dbamp;
		sig = sig * vol.dbamp;
		sig = Compander.ar(sig,sig,-10.dbamp,1,2.5.reciprocal);
		sig = Limiter.ar(sig,-3.dbamp);
		Out.ar(0,sig);
	}).play(group,[\inBus,bus,\vol,vol],\addAfter);

	lineOneView = CompositeView(win,Rect(
		0,
		0,
		(win.bounds.width-settingsDisplay.bounds.width)-6,
		topHeight + bottomHeight
	));
	lineOneView.decorator_(FlowLayout(lineOneView.bounds,0@0,0@0));
	CompositeView(lineOneView,Rect(0,0,1,topHeight)).background_(Color.black);

	//Font.setDefault(Font("Helvetica",10));
	noteRange.do({
		arg midi, i;
		var st,
		bgcol,
		txtcol,
		view,
		numberBox,
		width,
		newFreqDisp,
		centsNbOffset = 0,
		cents = 0,
		freq = midi.midicps,
		viewDestination;

		if(guiLine == 1,{
			viewDestination = lineOneView
		},{
			viewDestination = win;
		});
		centsDict.put(midi,cents);
		freqsDict.put(midi,freq);
		//synths.put(midi,Synth(\microtonalKeyboard,[\freq,freq,\vel,0,\sustain,0,\t_gate,0],group));

		if((midi % 12 == 1) ||
			(midi % 12 == 3) ||
			(midi % 12 == 6) ||
			(midi % 12 == 8) ||
			(midi % 12 == 10),{
				//"black background found".postln;
				bgcol = Color.black;
				txtcol = Color.white;
				width = blackWidth;
			},{
				bgcol = Color.white;
				txtcol = Color.black;
				width = whiteWidth;
		});

		if((midi % 12 == 0) ||
			(midi % 12 == 4) ||
			(midi % 12 == 5) ||
			(midi % 12 == 11),{
				width = whiteWidth + (blackWidth * 0.5);
				centsNbOffset = 12;
		});

		view = CompositeView(viewDestination,Rect(0,0,width,topHeight));
		view.decorator_(FlowLayout(view.bounds,0@2,0@0));
		st = StaticText(view,Rect(0,0,width,20));
		st.font_(Font("Helvetica",20));
		st.string_(midi.midiname);
		st.align_(\center);
		namesDict.put(midi,(nameDisplay:st, bgcol:bgcol, txtcol:txtcol));
		view.decorator.nextLine;
		StaticText(view,Rect(0,0,width,20))
		.string_(midi.midicps.round(0.1)+"Hz").font_(Font("Helvetica",10))
		.stringColor_(txtcol).align_(\center);

		view.background_(bgcol);
		st.stringColor_(txtcol);
		view.decorator.nextLine;
		StaticText(view,Rect(0,0,1,2));
		view.decorator.nextLine;
		numberBox = EZNumber(view,Rect(0,0,43+centsNbOffset,20),"Cts:",ControlSpec(-50,50),{
			arg nb;
			var col;//, txt;
			cents = nb.value;
			freq = midi.midicps * (2**(cents/1200));
			synths.at(midi) !? ({arg sy; sy.set(\freq,freq)});
			centsDict.put(midi,cents);
			freqsDict.put(midi,freq);
			newFreqDisp.string_(freq.round(0.1)+"Hz");
			newFreqDisp.focus(true);
			case
			{cents > 0}{
				col = Color.green(cents.linlin(0,50,0.5,1));
				//txt = Color.gray(1-cents.expexp(1,50,0.1,1));
			}
			{cents < 0}{
				col = Color.red(cents.linlin(-50,0,0.5,1));
				//txt = Color.gray(cents.neg.linlin(0,50,0,1));
			}
			{
				col = Color.clear;
				//txt = txtcol;
			};
			newFreqDisp.background_(col);
			//newFreqDisp.stringColor_(txt);
			/*midi.midiname.post;
			": ".post;
			cents.post;
			" cents".postln;*/
		},0,false,18,25).font_(Font("Helvetica",10));
		numberBox.setColors(stringColor:txtcol);//.numberView.canFocus_(false);

		nbDict.put(midi,numberBox);

		view.decorator.nextLine;
		StaticText(view,Rect(0,0,1,2));
		view.decorator.nextLine;

		StaticText(view,Rect(0,0,width,20)).string_("New Freq:")
		.stringColor_(txtcol).align_(\center).font_(Font("Helvetica",10));

		newFreqDisp = StaticText(view,Rect(0,0,width,20))
		.string_(midi.midicps.round(0.1)+"Hz").font_(Font("Helvetica",10));
		newFreqDisp.stringColor_(txtcol).align_(\center);

		view.decorator.nextLine;

		keyDisplays.put(midi,StaticText(view,Rect(0,0,width,20)).string_("")
			.stringColor_(Color.cyan).align_(\center).font_(Font("Helvetica",14,true));
		);

		if((i == 8) || (i == 32) || (i == 56)/* || (i == 80) || (i == 81)*/,{
			var numKeys = 14, endAdder = 4;
			// if we're at the end of a line:
			if(guiLine == 1,{
				viewDestination.decorator.nextLine;
			},{
				viewDestination.view.decorator.nextLine;
			});
			guiLine.switch(
				1,{
					//lineOneSpacer.(bottomHeight);
					endAdder = 1;
					numKeys = 5;
					CompositeView(viewDestination,Rect(0,0,(blackWidth/2) + 1,bottomHeight)).background_(Color.white);
					CompositeView(viewDestination,Rect(0,0,1,bottomHeight)).background_(Color.black);
				},
				4,{
					numKeys = 15
			});
			/*			{guiLine == 5}{
			//"fifth line".postln;
			numKeys = 0;
			CompositeView(win,Rect(
			0,
			0,
			whiteWidth + (blackWidth * 0.5),
			bottomHeight
			)).background_(Color.white);
			};*/

			numKeys.do({
				arg j;
				var adder = 0, privW;
				j.switch(
					2,{adder = 3},
					5,{adder = 4},
					7,{adder = 2},
					9,{adder = 1}
				);
				privW = whiteWidth + blackWidth + adder;
				//if(j == (numKeys-1),{privW = (blackWidth/2) + whiteWidth + 1});
				CompositeView(viewDestination,Rect(0,0,privW,bottomHeight)).background_(Color.white);
				if(j < (numKeys-1),{
					CompositeView(viewDestination,Rect(0,0,1,bottomHeight)).background_(Color.black);
				},{
					CompositeView(viewDestination,Rect(0,0,endAdder,bottomHeight)).background_(Color.white);
				});
			});

			win.view.decorator.nextLine;
			StaticText(win,Rect(0,0,1,8));
			win.view.decorator.nextLine;
			//guiLine.postln;
			guiLine = guiLine + 1;
		},{
			// if we're not at the end of a line:
			if(i != 81,{
				// but also it's not the very last C!
				StaticText(viewDestination,Rect(0,0,1,topHeight)).background_(Color.black);
			});
		});
	});

	win.bounds_(Rect(
		0,
		400,
		win.view.decorator.used.width,
		win.view.decorator.used.height
	));//postln;
	win.onClose_({
		s.quit;
		MIDIdef.freeAll;
		//"osascript -e 'quit app \"Microtonal Keyboard\"'".unixCmd;
	});

	noteOn = {
		arg note, vel;
		//"note on triggered".postln;
		if(centsDict.keys.includes(note),{
			synths.at(note) !? ({
				arg sy;
				// if there is a synth at this note in the dict (which there shouldn't be...)
				sy.set(\gate,0);
			});
			synths.put(note,Synth(\pianoString,[
				\freq,freqsDict.at(note),
				//\tune,centsDict.at(note).linlin(-50,50,0,1).postln;
				\vel,vel,
				//\sustain,sustain,
				\pan,note.linlin(0,127,-1,1),
				\outBus,bus
			],group).onFree({
				synths.removeAt(note);
			});
			);

			defer{namesDict.at(note).nameDisplay.background_(Color.yellow).stringColor_(Color.black)};
		});
	};

	MIDIdef.noteOn(\noteOn,{
		arg vel, note, chan, src;
		//[vel, note, chan, src].postln;
		noteOn.(note,vel);
	});

	noteOff = {
		arg note;
		var event;
		if(centsDict.keys.includes(note),{
			synths.at(note) !? ({arg sy; sy.set(\gate,0)});
			synths.removeAt(note);
			event = namesDict.at(note);
			defer{event.nameDisplay.background_(event.bgcol).stringColor_(event.txtcol)};
		});
	};

	MIDIdef.noteOff(\noteOff,{
		arg vel, note, chan, src;
		noteOff.(note);
	});

	updateOctaveOffset.(0);
	//win.view.center_(Window.availableBounds.center);
	win.front;
});
)