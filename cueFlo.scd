(
//******Instructions
// 1. Connect MIDI pedal before opening supercollider.
// 2. Put the cursor here, hold Command and press Enter!
// 3. After a few seconds, you will be able to see a GUI window- details about how to use the GUI window are written in the front page of the score.

Server.default.options.inDevice_("Scarlett 2i2 USB");
Server.default.options.outDevice_("Scarlett 2i2 USB");

ServerOptions.inDevices;
ServerOptions.outDevices;

MIDIIn.connectAll;
Buffer.freeAll;
Window.closeAll;
s.options.memSize = 8192*128;
o = Server.default.options;
o.numOutputBusChannels = 4;

s.waitForBoot({
	~loadSynths = {
		(
			SynthDef.new(\micIn, {
				arg in = 0, out = 0, amp = 1, ampLag = 0, ampKBus, mix = 0.0;
				var sig, sig0, sig1;
				sig = SoundIn.ar(in);
				// sig1 = SoundIn.ar(in1);
				// rawSig = inSig*rawAmp;
				// filtSig = BLowShelf.ar(inSig, 700)*filtAmp;
				// sig = XFade2.ar(sig0, sig1, mix);
				// sig = rawSig + filtSig;
				sig = sig*amp;
				amp = amp.lag(ampLag);
				Out.kr(ampKBus, amp);
				Out.ar(out, sig);
				// Out.kr(ampOut, amp);
			}).add;
		);

		(
			SynthDef.new(\reverb, {
				arg in,
				hiCut = 3310, rs = 0.5,
				mix = 0, room = 100, revTime = 3, damp = 0.5,
				mixLag = 3, roomLag = 2, dampLag = 2,
				dryAmp = 1.2, wetAmp = 1, amp = 1, dryLevel = 1,
				dampKBus, timeKBus, mixKBus,
				out = 0;
				var sig, dry, wet;
				mix = mix.lag(mixLag);
				room = room.lag(roomLag);
				damp = damp.lag(dampLag);
				dry = In.ar(in, 2);
				wet = In.ar(in, 2);
				wet = BHiShelf.ar(wet, hiCut, rs);
				wet = GVerb.ar(wet, room, revTime, damp, drylevel:dryLevel);
				wet = LPF.ar(wet, 1500);
				dry = dry*dryAmp;
				wet = wet*wetAmp;
				sig = XFade2.ar(wet, dry, mix);
				sig = sig*amp;
				Out.kr(dampKBus, damp);
				Out.kr(timeKBus, revTime);
				Out.kr(mixKBus, mix);
				Out.ar(out, sig);
			}).add;
		);

		(
			SynthDef.new(\pan, {
				arg in, pos, out = 0, amp = 1, panLag = 0.5, panKBus;
				var sig;
				pos = pos.lag(panLag);
				sig = In.ar(in, 1);
				sig = sig*amp;
				sig = Pan2.ar(sig, pos);
				Out.kr(panKBus, pos);
				Out.ar(out, sig);
			}).add;
		);


		(
			SynthDef.new(\delay, {
				arg in = 0, out = 0, bandwidth = 4, decay = 10, amp = 1, mul0 = 1, mul1 = 1, mul2= 1, decayOut;
				var sig, inSig, sigL, sigR, sigLR;
				amp = amp.lag(2);
				inSig = In.ar(in, 1);
				sigL = BPF.ar(inSig, 704, bandwidth);
				sigL = CombN.ar(sigL, 10, 0.165*mul0, decay*0.21)*1.26;
				sigR = BPF.ar(inSig, 918, bandwidth);
				sigR = CombN.ar(sigR, 10, 0.477*mul1, decay*0.46)*2;
				sigLR = BPF.ar(inSig, 449, bandwidth);
				sigLR = CombN.ar(sigLR, 10, 1*mul2, decay*0.24)/1.26;
				sig = [sigL+sigLR, sigR+sigLR];
				sig = sig+(inSig/1.52);
				sig = sig*amp;
				sig = sig*0.2;
				// Out.kr(decayOut, decay);
				Out.ar(out, sig);
			}).add;
		);

		(
			SynthDef.new(\grain, {
				arg in, out = 0, density = 10, rand = 1, dur = 0.01, mix = 1,
				dordKBus, durKBus;
				var sig, dry, wet, sigL, sigR;
				dry = In.ar(in, 2);
				sigL = GrainIn.ar(1, Impulse.kr(density*LFNoise1.kr(rand).range(0.8, 1.2)), dur, dry[0], -1);
				sigR = GrainIn.ar(1, Impulse.kr(density*LFNoise1.kr(rand).range(0.8, 1.2)), dur, dry[1], 1);
				wet = [sigL, sigR];
				sig = XFade2.ar(dry, wet, mix);
				Out.kr(dordKBus, density);
				Out.kr(durKBus, dur);
				Out.ar(out, sig);
			}).add;
		);

		(
			SynthDef.new(\eq, {
				arg in, hiFreq = 1200, midFreq = 600, lowFreq = 300, hidB = 0, middB = 0, lodB = 0, out = 0,
				hiLag = 2, midLag = 2, loLag = 2,
				hiKBus, midKBus, loKBus;
				var sig;
				sig = In.ar(in, 2);
				// db = db.lag(2);
				hidB = hidB.lag(hiLag);
				middB = middB.lag(midLag);
				lodB = lodB.lag(loLag);
				sig = MidEQ.ar(sig, hiFreq, rq: 4, db:hidB);
				sig = MidEQ.ar(sig, midFreq, rq: 4, db:middB);
				sig = MidEQ.ar(sig, lowFreq, rq: 4, db:lodB);
				Out.kr(hiKBus, hidB);
				Out.kr(midKBus, middB);
				Out.kr(loKBus, lodB);
				Out.ar(out, sig);
			}).add;
		);

		(
			SynthDef.new(\playBuf, {
				arg buf, rate = 1, amp = 1,
				startPos = 0, endPos = 1, numFrames,
				ampLag,
				ampKBus,
				out = 0;
				var sig, pos;
				sig = PlayBuf.ar(2, buf, rate*BufRateScale.ir(buf), startPos:startPos.linlin(0, 1, 0, numFrames), doneAction:2);
				// pos = Line.ar(startPos, endPos, (abs(numFrames/s.sampleRate*(endPos-startPos)/rate)), doneAction:2);
				sig = sig * amp;
				amp = amp.lag(ampLag);
				Out.kr(ampKBus, amp);
				// Out.kr(ctrlOut, pos);
				Out.ar(out, sig);
			}).add;
		);

		(
			SynthDef.new(\recordBuf, {
				arg in0, in1, buf, amp = 1;
				var sig;
				amp = amp.lag(2);
				sig = XFade2.ar(In.ar(in0, 1), In.ar(in1, 1), 0);
				sig = sig*amp;
				RecordBuf.ar(sig!2, buf);
			}).add;
		);

		(
			SynthDef.new(\mainAmp, {
				arg in, amp = 1, ampLag = 0, ctrlOut;
				var sig, out = 0, ampOut;
				amp = amp.lag(ampLag);
				sig = In.ar(in, 2);
				// ampOut = XLine.kr();
				sig = sig * amp;
				sig = Limiter.ar(sig);
				Out.kr(ctrlOut, amp);
				Out.ar(out, sig);
			}).add;
		)
	};
	~loadSynths.();
	1.wait;
	~init = {
		~bufGroup = Group.new(addAction:'addToHead');
		~inputGroup = Group.new(addAction:'addToHead');
		~effectGroup = Group.new(addAction:'addToTail');
		~outputGroup = Group.new(addAction:'addToTail');
		~reverbBus = Bus.audio(s, 2);
		~grainBus = Bus.audio(s, 2);
		~delayBus = Bus.audio(s, 1);
		~panBus = Bus.audio(s, 1);
		~voxEQBus = Bus.audio(s, 2);
		~eqBus = Bus.audio(s, 2);
		~outBus = Bus.audio(s, 2);

		~micAmpBus = Bus.control(s, 1);
		~bufAmpBus = Bus.control(s, 1);
		~revTimeBus = Bus.control(s, 1);
		~revDampBus = Bus.control(s, 1);
		~grainDordBus = Bus.control(s, 1);
		~grainDurBus = Bus.control(s, 1);

		~ampCtrlBus = Bus.control(s, 1);
		~nPlayBus = Bus.control(s, 1);
		~panCtrlBus = Bus.control(s, 1);

		// ~recBuf = Buffer.alloc(s, 5*s.sampleRate, 2);
		// ~decayBus0 = Bus.control(s, 1);
		// ~decayBus1 = Bus.control(s, 1);
		// ~decayBus;
		// ~timeBus = Bus.control(s, 1);
		// ~mixBus = Bus.control(s, 1);
		~delayStatus = 1;
		~grainStatus = 0;
		~delayAmp = 1;
		~micAmp = 1.dbamp;
		~bufAmp = -12.dbamp;
		~mainAmp = 0.dbamp;
		~ampMin = -30;
		~ampMax = 12;

		~bufIndex = -1;

		// ~revTime = 2;
		~revTime = 3.5;
		// ~revTime = 1;
		// ~revDamp = 0.7;
		~revDamp = 0.3;
		// ~revDamp = 0;
		~roomSize = 100;
		//(Revert to old values for mvt. 1 if necessary, mix = 0.5)
		//reverb, 0.2 time, 0 damp
		~grainDord = 9;
		~grainDur = 0.01;
		~grainRand = 3;
		~echoMul = 1;
		// ~counter = 0;
		~hidB = 0;
		~middB = 0;
		~lodB = 0;


		~voxHidB = 0;
		~voxMiddB = 0;
		~voxLodB = 0;

		~panVal = 0;

		~mvt = 0;

		~nPosValue = 0;

		~buttonColor = Color.fromHexString("#2185b0");

		~in = Synth(\micIn, [\amp, ~micAmp, \out, ~voxEQBus], target:~inputGroup);

		~delay0 = Synth(\delay, [
			\in, ~delayBus,
			\out, ~grainBus,
			//mess with the decay value to play with decay times. higher = more echoes.
			\decay, 3,
			//change bandwdith here if you need but it should be okay as is.
			\bandwidth, 4,
			\amp, 1,
			// \decayOut, ~decayBus0,
		], target:~effectGroup, addAction:'addToTail');
		~delay1 = Synth(\delay, [
			\in, ~delayBus,
			\out, ~grainBus,
			//mess with the decay value to play with decay times. higher = more echoes.
			\decay, 3,
			//change bandwdith here if you need but it should be okay as is.
			\bandwidth, 4,
			\amp, 0,
			// \decayOut, ~decayBus1,
		], target:~effectGroup, addAction:'addToTail');

		~pan = Synth(\pan, [
			\in, ~panBus,
			\out, ~grainBus,
			\panKBus, ~panCtrlBus
		], target:~effectGroup, addAction:'addToTail');

		~grain = Synth(\grain, [
			\in, ~grainBus,
			\out, ~reverbBus,
			\mix, -1,
			\density, ~grainDord,
			\dur, ~grainDur,
			\rand, ~grainRand,
		], target:~effectGroup, addAction:'addToTail');

		~reverb = Synth(\reverb, [
			\in, ~reverbBus,
			\out, ~voxEQBus,
			// \revTime, 4.34,
			\mix, 0.3,
			\revTime, ~revTime,
			\damp, ~revDamp,
			\room, ~roomSize,
			// \timeOut, ~timeBus,
			// \mixOut, ~mixBus,
		], target:~effectGroup, addAction:'addToTail');

		~voxEQ = Synth(\eq, [
			\in, ~voxEQBus,
			\out, ~outBus,
		], target:~effectGroup, addAction:'addToTail');

		~eq = Synth(\eq, [
			\in, ~eqBus,
			\out, ~outBus,
		], target:~effectGroup, addAction:'addToTail');

		~mainOut = Synth(\mainAmp, [
			\in, ~outBus,
			\ctrlOut, ~ampCtrlBus,
			\out, 0,
		], target:~outputGroup, addAction:'addToTail');
	};
	~init.();
	~paths1 = PathName("Cue-files".resolveRelative).entries.collect({ |n|
		n.fullPath;
	});

	// ~paths2 = PathName("Emile_Mov#2_Cues".resolveRelative).entries.collect({ |n|
	// 	n.fullPath;
	// });

	~loadBufs = {
		b = ~paths1.collect({ |n|
			Buffer.read(s, n);
		});

		// c = ~paths2.collect({ |n|
		// 	Buffer.read(s, n);
		// });

		s.sync;


		e = b.collect({ |n, i|
			~bufIndex = i;
			(
				playfn: {
					// ~buf = { PlayBuf.ar(2, b[i].bufnum, BufRateScale.ir(b[i].bufnum), doneAction: 2)*(~bufAmp) };
					~buf = Synth(\playBuf, [\buf, b[i].bufnum, \amp, ~bufAmp, \numFrames, b[i].numFrames, \out, ~eqBus, \ctrlOut, ~nPlayBus], target:~bufGroup);
					// ~buf.play(target:~bufGroup, fadeTime:0);
				},

				file: PathName(b[i].path).fileNameWithoutExtension,

				prevfile: if(
					b[i-1].notNil,
					{ PathName(b[i-1].path).fileNameWithoutExtension },
					{ "nil" }
				),

				nextfile: if(
					b[i+1].notNil,
					{ PathName(b[i+1].path).fileNameWithoutExtension },
					{ "nil" }
				),
				number: i+1,
				ctrlfn: {
					~cues[0][i+1].();
				}
			);
			// ~bufIndex = ~bufIndex + 1;
		});

		// f = c.collect({ |n, i|
		//
		// 	(
		// 		playfn: {
		// 			// ~buf = { PlayBuf.ar(2, c[i].bufnum, BufRateScale.ir(c[i].bufnum), doneAction: 2)*(~bufAmp) };
		// 			// ~buf.play(target:~bufGroup, fadeTime:0);
		// 			~buf = Synth(\playBuf, [\buf, c[i].bufnum, \amp, ~bufAmp, \out, ~eqBus], target:~bufGroup);
		// 		},
		//
		// 		file: PathName(c[i].path).fileNameWithoutExtension,
		//
		// 		prevfile: if(
		// 			c[i-1].notNil,
		// 			{ PathName(c[i-1].path).fileNameWithoutExtension },
		// 			{ "nil" }
		// 		),
		//
		// 		nextfile: if(
		// 			c[i+1].notNil,
		// 			{ PathName(c[i+1].path).fileNameWithoutExtension },
		// 			{ "nil" }
		// 		),
		// 		number: i+1,
		// 		ctrlfn: {
		// 			~cues[1][i+1].();
		// 		}
		//
		// 	)
		//
		// });
		//
		~files = e;

		~seq = Pseq(e).asStream;
	};
	~loadBufs.();

	s.sync;

	~randLo = 0.3;
	~randHi = 1.6;

	~cleanBoxInput = {
		arg input = "nil";
		var array = [$0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $., $-, $+], isNumber = true;
		input.do({
			arg i, j;
			if(array.includes(i) == false, {
				isNumber = false;
			});
		});
		isNumber;
	};

	~change = Routine.new({
		{
			var mul0, mul1, mul2, mul3, mul4, mul5, mulAmp;
			mulAmp = ~echoMul;
			mul0 = rrand(~randLo, ~randHi)*mulAmp;
			mul1 = rrand(~randLo, ~randHi)*mulAmp;
			mul2 = rrand(~randLo, ~randHi)*mulAmp;
			mul3 = rrand(~randLo, ~randHi)*mulAmp;
			mul4 = rrand(~randLo, ~randHi)*mulAmp;
			mul5 = rrand(~randLo, ~randHi)*mulAmp;
			~delay0.set(\amp, 0);
			~delay1.set(\amp, 1*~delayAmp);
			// ~decayBus = ~decayBus1;
			// "switch1".postln;
			1.wait;
			// ~delay0.set(\mul0, rrand(0.3, 1.6), \mul1, rrand(0.3, 1.6), \mul2, rrand(0.3, 1.6));
			~delay0.set(\mul0, mul0, \mul1, mul1, \mul2, mul2);
			// "change1".postln;

			rrand(0.4,2).wait;
			~delay0.set(\amp, 1*~delayAmp);
			~delay1.set(\amp, 0);
			// ~decayBus = ~decayBus0;
			// "switch0".postln;
			1.wait;
			// ~delay1.set(\mul0, rrand(0.3, 1.6), \mul1, rrand(0.3, 1.6), \mul2, rrand(0.3, 1.6));

			~delay1.set(\mul0, mul3, \mul1, mul4, \mul2, mul5);
			// "change0".postln;
			rrand(0.4, 2).wait;


		}.loop;
	}).play;

	~panning = Routine.new({
		{
			var left, right, seq;
			left = rrand(-1.0, -0.8);
			right = rrand(0.8, 1.0);
			seq = [[left, right], [right, left]].choose;
			// seq.postln;
			seq.do({
				arg i;
				~pan.set(\pos, i);
				rrand(0.1,0.3).wait;
			});
			~pan.set(\pos, 0);
			rrand(2, 5).wait;
		}.loop;
	});

	~slowPan = Routine.new({
		{
			var pan;
			pan = ~panVal * -1;
			pan = pan * (rrand(0.9, 1.1));
			pan = pan.clip(-1, 1);
			~panVal = pan;
			// pan.postln;
			~pan.set(\pos, pan, \panLag, rrand(0.5, 5));
			rrand(2, 5).wait;
		}.loop;
	});

	~delayOn = {
		arg print = true;
		if (print == true, {
			"Delay on".postln;
		});
		~in.set(\out, ~delayBus);
		~delayStatus = 1;
		~delayButton.value_(~delayStatus);
	};

	~delayOff = {
		arg print = true;
		if (print == true, {
			"Delay off".postln;
		});
		~in.set(\out, ~panBus);
		~delayStatus = 0;
		~delayButton.value_(~delayStatus);
	};

	~grainOn = {
		arg print = true;
		if (print == true, {
			"Grains on".postln;
		});
		~grain.set(\mix, 1);
		~grainStatus = 1;
		~grainButton.value_(~grainStatus);
	};

	~grainOff = {
		arg print = true;
		if (print == true, {
			"Grains off".postln;
		});
		~grain.set(\mix, -1);
		~grainStatus = 0;
		~grainButton.value_(~grainStatus);
	};

	~nPlay = Routine.new({
		{
			var pos;
			pos = ~nPlayBus.getSynchronous;
			~nPosValue = pos;

			// pos.postln;
			if(~nPosValue.round(0.001) == 1, {
				// "reset".postln;
				// ~controlSet.(~nPosControl, 0, \slider);
				~playSlider.value_(0);
				~nPosValue = 0;
				~nPlayBus.setSynchronous(0);
				// ~nPlayBus.getSynchronous.postln;
				~setButtonState.(~nPlayButtonControls, 1);

			}, {
				// pos.postln;
				~playSlider.value_(pos);
				// ~controlSet.(~nPosControl, pos.round(0.001), \box);
			}
			);
			0.01.wait;
		}.loop;
	});

	// ~setMicSlider = Routine.new({
	// 	var amp;
	// });

	~setAmpSlider = Routine.new({
		{
			var amp;
			amp = ~ampCtrlBus.getSynchronous;
			~mainAmpValue = amp;
			~mainAmpBoxValue = ~mainAmpValue.ampdb.round(0.1);
			// ~setMainAmp.(amp);
			~mainAmpSlider.value_(amp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
			if(~mainAmpBoxValue >= 0, {
				~mainAmpBoxString = "+" ++ ~mainAmpBoxValue.asString;
			}, {
				~mainAmpBoxString = ~mainAmpBoxValue.asString;
			}
			);
			~mainAmpBox.value_(~mainAmpBoxString + "dB");

			0.01.wait;
		}.loop;
	});

	~setMicPanSlider = Routine.new({
		{
			var pan;
			pan = ~panCtrlBus.getSynchronous;
			~panVal = pan;
			~micPanSlider.value_(pan.linlin(-1, 1, 0, 1));
			0.01.wait;
		}.loop;
	});


	~mvt1 = {
		~seq = Pseq(e).asStream;
		~bufGroup.freeAll;
		~seq.reset;
		~files = e;
		~cueSelect.items_((1..~files.size).collect(_.asSymbol));
		~curtext.string_("nil");
		~nexttext.string_(e[0].file);
		~mvtSelect.value_(0);
		~cueSelect.value_(0);
		~delayOff.(false);
		~grainOff.(false);
		~bufAmp = -4.dbamp;
		~micAmp = -6.dbamp;
		~mainAmp = 0.dbamp;
		~setBufAmp.(~bufAmp);
		~setMainAmp.(~mainAmp);
		// ~reverb.set(\revTime, ~revTime, \damp, ~damp);
		// ~delay0.set(\decay, 3);
		// ~delay1.set(\decay, 3);
		// ~reverb.set(\revTime, 1, \mix, -1, \damp, 0.7);
		// ~setReverbParams.(time:1, damp:0.7);
		// ~effectGroup.set(\amp, 1);
		~mvt = 0;
		"Preset: Movt. 1".postln;
	};

	~playSeq = [~mvt1];

	// ~delay.set(\amp, 1);


	// MIDIdef.cc(\pedal, { |val|
	// 	if(val == 127) { defer{ ~nextbtn.valueAction_(0) } };
	//
	// }).permanent_(true);

	~cueSelect = PopUpMenu().items_((1..~files.size).collect(_.asSymbol)).canFocus_(false)
	.allowsReselection_(true)
	.background_(Color.fromHexString("#a3bdc6"))
	.mouseDownAction_({
		~bufGroup.freeAll;
		defer{ ~curtext.string_("nil"); }; })
	.font_(Font(size: 18))
	.action_({ |n|
		~seq.reset;
		(n.value).do({
			var next;
			next = ~seq.next;
			// next.postln;
			next[\ctrlfn].();

		});
		~nexttext.string_(~files[n.value].file);
		~cueSelect.value_(n.value);
	});

	~mvtSelect = PopUpMenu().items_(["Movt. 1"]).canFocus_(false)
	.allowsReselection_(true)
	.background_(Color.fromHexString("#a3bdc6"))
	.mouseDownAction_({
		// ~bufGroup.freeAll;
		defer{ ~curtext.string_("nil"); }; })
	.font_(Font(size: 18))
	.action_({ |n|
		// n.value.postln;
		if(n.value == 0) {
			~mvt1.();
		};
		if(n.value == 1) {
			~mvt2.();
		};
		~seq.reset;
	});

	~advanceCue = {
		var ev;
		ev = ~seq.next;
		// ~updateVals.();
		if (ev == nil) {
			if(~mvt == 1, {
				~bufGroup.freeAll;
				~effectGroup.set(\amp, 0);
				~change.stop;
				~panning.stop;
			});
			if(~mvt < 1, {
				~playSeq[(~mvt+1)].();
			});
		};
		if(ev.notNil) {
			~playStop.value_(0);
			~effectGroup.set(\amp, 1);
			~curtext.string_(ev[\file]);
			~nexttext.string_(ev[\nextfile]);
			if(~nexttext.string == "nil", {
				~nexttext.string_("End of Piece");
				// if (~mvt == 0, {
				// 	~nexttext.string_("Press NEXT to load Movt. 2");
				// });
				// if (~mvt == 1, {
				// 	~nexttext.string_("End of piece");
				// });
			});
			~cueSelect.value_(ev[\number]);
			if(~mvtSelect.value == 0) {
			};
			if(~mvtSelect.value == 1) {
			};
			// ~cues[~mvtSelect.value][ev.number].();
			ev[\ctrlfn].();
			ev[\playfn].();
		};

	};

	~cues = [
		(
			1: {
				~panVal = rrand(0, 0.2);
				~slowPan.play;
				// ~setMicAmp.(-6.0.dbamp);
				~setMicAmp.(1.0.dbamp);
				~setBufAmp.(-4.0.dbamp);
			},
			5: {
				~panVal = rrand(0.7, 0.8);
			},
			7: {
				~delayOn.();
			},
			8: {
				~delayOff.();
			},
			9: {
				// ~setMicAmp.(-3.0.dbamp);
				~setMicAmp.(4.5.dbamp);
			},
			11: {
				// ~setMicAmp.(-2.0.dbamp);
				~setMicAmp.(5.5.dbamp);
			},
			12: {
				// ~setMicAmp.(-3.0.dbamp);
				~setMicAmp.(4.5.dbamp);
			},
			15: {
				~panVal = rrand(0, 0.1);
			}
		),
	];


	~inChoice = "(default)";
	~inList = ServerOptions.inDevices.insert(0, ~inChoice);
	~inSelect = PopUpMenu().items_(~inList).canFocus_(false)
	.allowsReselection_(true)
	.background_(Color.fromHexString("#a3bdc6"))
	.font_(Font(size: 18))
	.action_({ |n|
		~inChoice = ~inList[n.value];
		// ~inChoice.postln;
		// n[n.value].postln;
		// s.quit;
		// s.waitForBoot({~init.()});
	});
	~outChoice = "(default)";
	~outList = ServerOptions.outDevices.insert(0, ~outChoice);
	~outSelect = PopUpMenu().items_(~outList).canFocus_(false)
	.allowsReselection_(true)
	.background_(Color.fromHexString("#a3bdc6"))
	.font_(Font(size: 18))
	.action_({ |n|
		~outChoice = ~outList[n.value];
		// ~outChoice.postln;
		// s.quit;
		// s.waitForBoot({~init.()});
	});

	~micBoxValue = ~micAmp.ampdb.round(0.1);
	~ampBoxValue = ~bufAmp.ampdb.round(0.1);
	~mainAmpBoxValue = ~mainAmp.ampdb.round(0.1);
	if(~micBoxValue >= 0, {
		~micBoxString = "+" ++ ~micBoxValue.asString;
	}, {
		~micBoxString = ~micBoxValue.asString;
	}
	);

	if(~ampBoxValue >= 0, {
		~ampBoxString = "+" ++ ~ampBoxValue.asString;
	}, {
		~ampBoxString = ~ampBoxValue.asString;
	}
	);

	if(~mainAmpBoxValue >= 0, {
		~mainAmpBoxString = "+" ++ ~ampBoxValue.asString;
	}, {
		~mainAmpBoxString = ~mainAmpBoxValue.asString;
	});

	~setMicAmp = {
		arg amp, lag = 2;
		~micAmp = amp;
		~micSlider.value_(amp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
		~micBoxValue = amp.ampdb.round(0.1);
		if(~micBoxValue >= 0, {
			~micBoxString = "+" ++ ~micBoxValue.asString;
		}, {
			~micBoxString = ~micBoxValue.asString;
		}
		);
		~in.set(\amp, amp, \ampLag, lag);
		~micBox.value_(~micBoxString + "dB");
	};

	~micSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(70)
	.background_(Color.gray(0.8, 0.1))
	.value_(~micAmp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
	.action_({
		~micAmp = ~micSlider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
		~micBoxValue = ~micAmp.ampdb.round(0.1);
		if(~micBoxValue >= 0, {
			~micBoxString = "+" ++ ~micBoxValue.asString;
		}, {
			~micBoxString = ~micBoxValue.asString;
		}
		);
		~in.set(\amp, ~micAmp);
		~micBox.value_(~micBoxString + "dB");
	})
	.orientation_(\vertical);
	~micBox = TextField(w)
	.mouseDownAction_({
		~micBox.value_("");
	})
	.value_(~micBoxString + "dB")
	.action_({
		// ~ampBoxValue = ~ampValue.ampdb.round(0.1);
		var input, outString, diff, lag;
		if(~micBox.value == "", {
			~micBox.value_(~micAmp.round(0.1));
		});
		if(~cleanBoxInput.(~micBox.value) == false, {
			~micBox.value_(~micAmp.round(0.1));
		});
		input = ~micBox.value.asFloat;
		input = input.clip(-40, 15);
		// lag = input.dbamp.expexp(0.01, 100, 0.2, 200);
		// diff = input-~ampValue.ampdb;
		// if (diff > 0, {
		// 	lag = diff.linexp(0, 40, 0.2, 100);
		// });
		// if (diff <= 0, {
		// 	lag = 0.2;
		// });
		// lag = diff.expexp(0.2, 10, 0.
		// input = input.clip(-40, 18);
		// input.postln;
		~micSlider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
		~micAmp = input.dbamp;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		}
		);
		~micBox.value_(outString);
		~in.set(\amp, ~micAmp);
		w.focus;
		// lag.postln;
		// ~ampValue.postln;

	});

	~micPanSlider = Slider.new(w)
	.canFocus_(false)
	.orientation_(\horizontal)
	.background_(Color.gray(0.8, 0.1))
	.value_(~panVal.linlin(-1, 1, 0, 1))
	.action_({
		var pan;
		pan = ~micPanSlider.value.linlin(0, 1, -1, 1);
		~panVal = pan;
		~pan.set(\pos, pan, \panLag, 0);
	});

	~setBufAmp = {
		arg amp;
		~bufAmp = amp;
		~ampSlider.value_(amp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
		~ampBoxValue = amp.ampdb.round(0.1);
		if(~ampBoxValue >= 0, {
			~ampBoxString = "+" ++ ~ampBoxValue.asString;
		}, {
			~ampBoxString = ~ampBoxValue.asString;
		}
		);
		~bufGroup.set(\amp, amp);
		~ampBox.value_(~ampBoxString + "dB");
	};

	~ampSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(70)
	.background_(Color.gray(0.8, 0.1))
	.value_(~bufAmp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
	.action_({
		~bufAmp = ~ampSlider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
		~ampBoxValue = ~bufAmp.ampdb.round(0.1);
		if(~ampBoxValue >= 0, {
			~ampBoxString = "+" ++ ~ampBoxValue.asString;
		}, {
			~ampBoxString = ~ampBoxValue.asString;
		}
		);
		~bufGroup.set(\amp, ~bufAmp);
		~ampBox.value_(~ampBoxString + "dB");
	})
	.orientation_(\vertical);
	~ampBox = TextField(w)
	.mouseDownAction_({
		~ampBox.value_("");
	})
	.value_(~ampBoxString + "dB")
	.action_({
		// ~ampBoxValue = ~ampValue.ampdb.round(0.1);
		var input, outString, diff, lag;
		if(~ampBox.value == "", {
			~ampBox.value_(~bufAmp.round(0.1));
		});
		if(~cleanBoxInput.(~ampBox.value) == false, {
			~ampBox.value_(~bufAmp.round(0.1));
		});
		input = ~ampBox.value.asFloat;
		input = input.clip(-40, 15);
		// lag = input.dbamp.expexp(0.01, 100, 0.2, 200);
		// diff = input-~ampValue.ampdb;
		// if (diff > 0, {
		// 	lag = diff.linexp(0, 40, 0.2, 100);
		// });
		// if (diff <= 0, {
		// 	lag = 0.2;
		// });
		// lag = diff.expexp(0.2, 10, 0.
		// input = input.clip(-40, 18);
		// input.postln;
		~ampSlider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
		~bufAmp = input.dbamp;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "dB";
		}
		);
		~ampBox.value_(outString);
		~bufGroup.set(\amp, ~bufAmp);
		w.focus;
		// lag.postln;
		// ~ampValue.postln;

	});

	~setMainAmp = {
		arg amp, lag;
		~mainAmp = amp;
		// ~mainAmpSlider.value_(amp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
		~mainAmpBoxValue = amp.ampdb.round(0.1);
		if(~mainAmpBoxValue >= 0, {
			~mainAmpBoxString = "+" ++ ~mainAmpBoxValue.asString;
		}, {
			~mainAmpBoxString = ~mainAmpBoxValue.asString;
		}
		);
		~mainOut.set(\amp, amp, \ampLag, 0);
		~mainAmpBox.value_(~mainAmpBoxString + "dB");
	};

	~mainAmpSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(70)
	.background_(Color.gray(0.8, 0.1))
	.value_(~mainAmp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
	.action_({
		~mainAmp = ~mainAmpSlider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
		~mainAmpBoxValue = ~mainAmp.ampdb.round(0.1);
		if(~mainAmpBoxValue >= 0, {
			~mainAmpBoxString = "+" ++ ~mainAmpBoxValue.asString;
		}, {
			~mainAmpBoxString = ~mainAmpBoxValue.asString;
		}
		);
		~mainOut.set(\amp, ~mainAmp, \ampLag, 0);
		~mainAmpBox.value_(~mainAmpBoxString + "dB");
	})
	.orientation_(\vertical);
	~mainAmpBox = TextField(w)
	.mouseDownAction_({
		~setAmpSlider.stop;
		~mainAmpBox.value_("");
	})
	.value_(~mainAmpBoxString + "dB")
	.action_({
		// ~ampBoxValue = ~ampValue.ampdb.round(0.1);
		var input, outString, diff, lag;
		~setAmpSlider.reset;
		AppClock.play(~setAmpSlider);
		if(~mainAmpBox.value == "", {
			~mainAmpBox.value_(~mainAmp.round(0.1));
		});
		if(~cleanBoxInput.(~masterBox.value) == false, {
			~mainAmpBox.value_(~mainAmp.round(0.1));
		});
		input = ~mainAmpBox.value.asFloat;
		input = input.clip(-40, 15);
		// lag = input.dbamp.expexp(0.01, 100, 0.2, 200);
		// diff = input-~ampValue.ampdb;
		// if (diff > 0, {
		// 	lag = diff.linexp(0, 40, 0.2, 100);
		// });
		// if (diff <= 0, {
		// 	lag = 0.2;
		// });
		// lag = diff.expexp(0.2, 10, 0.
		// input = input.clip(-40, 18);
		// input.postln;
		~mainAmpSlider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
		~mainAmp = input.dbamp;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "dB";
		}
		);
		~mainAmpBox.value_(outString);
		~mainOut.set(\amp, ~mainAmp, \ampLag, 0);
		w.focus;
		// lag.postln;
		// ~ampValue.postln;

	});

	~setReverbParam = {
		arg time = 1, damp = 0.7;
		~revTime = time;
		~revDamp = damp;
		~revTimeSlider.value_(~revTime.linlin(0.2, 8, 0, 1));
		~revTimeBox.value_(~revTime);
		~dampSlider.value_(~revDamp);
		~dampBox.value_(~revDamp);
		~reverb.set(\revTime, ~revTime, \revDamp, ~revDamp);
	};

	~revTimeSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.background_(Color.gray(0.8, 0.1))
	.value_(~revTime.linlin(0.2, 8, 0, 1))
	.action_({
		~revTime = ~revTimeSlider.value.linlin(0, 1, 0.2, 8);
		~revTimeBox.value_(~revTime.round(0.1));
		~reverb.set(\revTime, ~revTime);
	});
	~revTimeBox = TextField.new(w)
	.fixedWidth_(40)
	.value_(~revTime)
	.mouseDownAction_({
		~revTimeBox.value_("");
	})
	.action_({
		~revTime = ~revTimeBox.value.asFloat;
		~revTimeSlider.value_(~revTime.linlin(0.2, 8, 0, 1));
		~reverb.set(\revTime, ~revTime);
		w.focus;
	});

	~dampSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.background_(Color.gray(0.8, 0.1))
	.value_(~revDamp)
	.action_({
		~revDamp = ~dampSlider.value;
		~dampBox.value_(~revDamp.round(0.01));
		~reverb.set(\damp, ~revDamp);
	});
	~dampBox = TextField.new(w)
	.fixedWidth_(40)
	.value_(~revDamp)
	.mouseDownAction_({
		~dampBox.value_("");
	})
	.action_({
		~revDamp = ~dampBox.value.asFloat;
		~dampSlider.value_(~revDamp);
		~reverb.set(\damp, ~revDamp);
		w.focus;
	});

	~setGrainParam = {
		arg dord = 9, dur = 0.01;
		~grainDord = dord;
		~grainDur = dur;
		~dordSlider.value_(~grainDord.linlin(4, 20, 0, 1));
		~dordBox.value_(~grainDord.round(0.1));
		~durSlider.value_(~grainDur.linlin(0.01, 0.05, 0, 1));
		~durBox.value_(~grainDur.round(0.001));
		~grain.set(\dur, ~grainDur);
	};

	~dordSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.background_(Color.gray(0.8, 0.1))
	.value_(~grainDord.linlin(4, 20, 0, 1))
	.action_({
		~grainDord = ~dordSlider.value.linlin(0, 1, 4, 20);
		~dordBox.value_(~grainDord.round(0.1));
		~grain.set(\density, ~grainDord);
	});
	~dordBox = TextField.new(w)
	.fixedWidth_(40)
	.value_(~grainDord)
	.mouseDownAction_({
		~dordBox.value_("");
	})
	.action_({
		~grainDord = ~dordBox.value.asFloat;
		~dordSlider.value_(~grainDord.linlin(4, 20, 0, 1));
		~reverb.set(\density, ~grainDord);
		w.focus;
	});

	~durSlider = Slider.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.background_(Color.gray(0.8, 0.1))
	.value_(~grainDur.linlin(0.01, 0.05, 0, 1))
	.action_({
		~grainDur = ~durSlider.value.linlin(0, 1, 0.01, 0.05);
		~durBox.value_(~grainDur.round(0.001));
		~grain.set(\dur, ~grainDur);
	});
	~durBox = TextField.new(w)
	.fixedWidth_(40)
	.value_(~grainDur)
	.mouseDownAction_({
		~durBox.value_("");
	})
	.action_({
		~grainDur = ~durBox.value.asFloat;
		~durSlider.value_(~grainDur.linlin(0.01, 0.05, 0, 1));
		~reverb.set(\dur, ~grainDur);
		w.focus;
	});

	~setVoxHiEQ = {
		arg db;
		~voxHidB = db;
		~voxHiKnob.value_(db.linlin(-6, 6, 0, 1));
		~voxHiBoxValue = ~voxHidB.round(0.1);
		if(~voxHiBoxValue >= 0, {
			~voxHiBoxString = "+" ++ ~voxHiBoxValue.asString;
		}, {
			~voxHiBoxString = ~voxHiBoxValue.asString;
		});
		~voxHiBox.value_(~voxHiBoxString + "dB");
		~voxEQ.set(\hidB, ~voxHidB);
	};

	~voxHiBoxValue = ~voxHidB.round(0.1);
	if(~voxHiBoxValue >= 0, {
		~voxHiBoxString = "+" ++ ~voxHiBoxValue.asString;
	}, {
		~voxHiBoxString = ~voxHiBoxValue.asString;
	});
	~voxHiKnob = Knob.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.value_(~voxHidB.linlin(-6, 6, 0, 1))
	.centered_(true)
	.action_({
		~voxHidB = ~voxHiKnob.value.linlin(0, 1, -6, 6);
		~voxHiBoxValue = ~voxHidB.round(0.1);
		if(~voxHiBoxValue >= 0, {
			~voxHiBoxString = "+" ++ ~voxHiBoxValue.asString;
		}, {
			~voxHiBoxString = ~voxHiBoxValue.asString;
		});
		~voxHiBox.value_(~voxHiBoxString + "dB");
		~voxEQ.set(\hidB, ~voxHidB);
	});
	~voxHiBox = TextField.new(w)
	.fixedWidth_(70)
	.value_(~voxHiBoxString + "dB")
	.mouseDownAction_({
		~voxHiBox.value_("");
	})
	.action_({
		var input, outString;
		if(~voxHiBox.value == "", {
			~voxHiBox.value_(~voxHidB);
		});
		if(~cleanBoxInput.(~voxHiBox.value) == false, {
			~voxHiBox.value_(~voxHidB);
		});
		input = ~voxHiBox.value.asFloat;
		input = input.clip(-6, 6);
		~voxHiKnob.value_(input.linlin(-6, 6, 0, 1));
		~voxHidB = input;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		});
		~voxHiBox.value_(outString);
		~voxEQ.set(\hidB, ~voxHidB);
		w.focus;
	});

	~setVoxMidEQ = {
		arg db;
		~voxMiddB = db;
		~voxMidKnob.value_(db.linlin(-6, 6, 0, 1));
		~voxMidBoxValue = ~voxMiddB.round(0.1);
		if(~voxMidBoxValue >= 0, {
			~voxMidBoxString = "+" ++ ~voxMidBoxValue.asString;
		}, {
			~voxMidBoxString = ~voxMidBoxValue.asString;
		});
		~voxMidBox.value_(~voxMidBoxString + "dB");
		~voxEQ.set(\middB, ~voxMiddB);
	};

	~voxMidBoxValue = ~voxMiddB.round(0.1);
	if(~voxMidBoxValue >= 0, {
		~voxMidBoxString = "+" ++ ~voxMidBoxValue.asString;
	}, {
		~voxMidBoxString = ~voxMidBoxValue.asString;
	});
	~voxMidKnob = Knob.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.value_(~voxMiddB.linlin(-6, 6, 0, 1))
	.centered_(true)
	.action_({
		~voxMiddB = ~voxMidKnob.value.linlin(0, 1, -6, 6);
		~voxMidBoxValue = ~voxMiddB.round(0.1);
		if(~voxMidBoxValue >= 0, {
			~voxMidBoxString = "+" ++ ~voxMidBoxValue.asString;
		}, {
			~voxMidBoxString = ~voxMidBoxValue.asString;
		});
		~voxMidBox.value_(~voxMidBoxString + "dB");
		~voxEQ.set(\middB, ~voxMiddB);
	});
	~voxMidBox = TextField.new(w)
	.fixedWidth_(70)
	.value_(~voxMidBoxString + "dB")
	.mouseDownAction_({
		~voxMidBox.value_("");
	})
	.action_({
		var input, outString;
		if(~voxMidBox.value == "", {
			~voxMidBox.value_(~voxMiddB);
		});
		if(~cleanBoxInput.(~voxMidBox.value) == false, {
			~voxMidBox.value_(~voxMiddB);
		});
		input = ~voxMidBox.value.asFloat;
		input = input.clip(-6, 6);
		~voxMidKnob.value_(input.linlin(-6, 6, 0, 1));
		~voxMiddB = input;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		});
		~voxMidBox.value_(outString);
		~voxEQ.set(\middB, ~voxMiddB);
		w.focus;
	});


	~setVoxLoEQ = {
		arg db;
		~voxLodB = db;
		~voxLoKnob.value_(db.linlin(-6, 6, 0, 1));
		~voxLoBoxValue = ~voxLodB.round(0.1);
		if(~voxLoBoxValue >= 0, {
			~voxLoBoxString = "+" ++ ~voxLoBoxValue.asString;
		}, {
			~voxLoBoxString = ~voxLoBoxValue.asString;
		});
		~voxLoBox.value_(~voxLoBoxString + "dB");
		~voxEQ.set(\lodB, ~voxLodB);
	};

	~voxLoBoxValue = ~voxLodB.round(0.1);
	if(~voxLoBoxValue >= 0, {
		~voxLoBoxString = "+" ++ ~voxMidBoxValue.asString;
	}, {
		~voxMidBoxString = ~voxMidBoxValue.asString;
	});

	~voxLoKnob = Knob.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.value_(~voxLodB.linlin(-6, 6, 0, 1))
	.centered_(true)
	.action_({
		~voxLodB = ~voxLoKnob.value.linlin(0, 1, -6, 6);
		~voxLoBoxValue = ~voxLodB.round(0.1);
		if(~voxLoBoxValue >= 0, {
			~voxLoBoxString = "+" ++ ~voxLoBoxValue.asString;
		}, {
			~voxLoBoxString = ~voxLoBoxValue.asString;
		});
		~voxLoBox.value_(~voxLoBoxString + "dB");
		~voxEQ.set(\lodB, ~voxLodB);
	});
	~voxLoBox = TextField.new(w)
	.fixedWidth_(70)
	.value_(~voxLoBoxString + "dB")
	.mouseDownAction_({
		~voxLoBox.value_("");
	})
	.action_({
		var input, outString;
		if(~voxLoBox.value == "", {
			~voxLoBox.value_(~voxLodB);
		});
		if(~cleanBoxInput.(~voxLoBox.value) == false, {
			~voxLoBox.value_(~voxLodB);
		});
		input = ~voxLoBox.value.asFloat;
		input = input.clip(-6, 6);
		~voxLoKnob.value_(input.linlin(-6, 6, 0, 1));
		~voxLodB = input;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
			}, {
				outString = input.round(0.1).asString + "db";
		});
		~voxLoBox.value_(outString);
		~voxEQ.set(\middB, ~voxLodB);
		w.focus;
	});

	~setHiEQ = {
		arg db;
		~hidB = db;
		~hiKnob.value_(db.linlin(-6, 6, 0, 1));
		~hiBoxValue = ~hidB.round(0.1);
		if(~hiBoxValue >= 0, {
			~hiBoxString = "+" ++ ~hiBoxValue.asString;
		}, {
			~hiBoxString = ~hiBoxValue.asString;
		});
		~hiBox.value_(~hiBoxString + "dB");
		~eq.set(\hidB, ~hidB);
	};

	~hiBoxValue = ~hidB.round(0.1);
	if(~hiBoxValue >= 0, {
		~hiBoxString = "+" ++ ~hiBoxValue.asString;
	}, {
		~hiBoxString = ~hiBoxValue.asString;
	});
	~hiKnob = Knob.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.value_(~hidB.linlin(-6, 6, 0, 1))
	.centered_(true)
	.action_({
		~hidB = ~hiKnob.value.linlin(0, 1, -6, 6);
		~hiBoxValue = ~hidB.round(0.1);
		if(~hiBoxValue >= 0, {
			~hiBoxString = "+" ++ ~hiBoxValue.asString;
		}, {
			~hiBoxString = ~hiBoxValue.asString;
		}
		);
		~hiBox.value_(~hiBoxString + "dB");
		~eq.set(\hidB, ~hidB);
	});
	~hiBox = TextField.new(w)
	.fixedWidth_(70)
	.value_(~hiBoxString + "dB")
	.mouseDownAction_({
		~hiBox.value_("");
	})
	.action_({
		var input, outString;
		if(~hiBox.value == "", {
			~hiBox.value_(~hidB);
		});
		if(~cleanBoxInput.(~hiBox.value) == false, {
			~hiBox.value_(~hidB);
		});
		input = ~hiBox.value.asFloat;
		input = input.clip(-6, 6);
		~hiKnob.value_(input.linlin(-6, 6, 0, 1));
		~hidB = input;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		});
		~hiBox.value_(outString);
		~eq.set(\hidB, ~hidB);
		w.focus;
	});

	~setMidEQ = {
		arg db;
		~middB = db;
		~midKnob.value_(db.linlin(-6, 6, 0, 1));
		~midBoxValue = ~middB.round(0.1);
		if(~midBoxValue >= 0, {
			~midBoxString = "+" ++ ~midBoxValue.asString;
		}, {
			~midBoxString = ~midBoxValue.asString;
		});
		~midBox.value_(~midBoxString + "dB");
		~eq.set(\middB, ~middB);
	};

	~midBoxValue = ~middB.round(0.1);
	if(~midBoxValue >= 0, {
		~midBoxString = "+" ++ ~midBoxValue.asString;
	}, {
		~midBoxString = ~midBoxValue.asString;
	});
	~midKnob = Knob.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.value_(~middB.linlin(-6, 6, 0, 1))
	.centered_(true)
	.action_({
		~middB = ~midKnob.value.linlin(0, 1, -6, 6);
		~midBoxValue = ~middB.round(0.1);
		if(~midBoxValue >= 0, {
			~midBoxString = "+" ++ ~midBoxValue.asString;
		}, {
			~midBoxString = ~midBoxValue.asString;
		}
		);
		~midBox.value_(~midBoxString + "dB");
		~eq.set(\middB, ~middB);
	});
	~midBox = TextField.new(w)
	.fixedWidth_(70)
	.value_(~midBoxString + "dB")
	.mouseDownAction_({
		~midBox.value_("");
	})
	.action_({
		var input, outString;
		if(~midBox.value == "", {
			~midBox.value_(~middB);
		});
		if(~cleanBoxInput.(~middB.value) == false, {
			~midBox.value_(~middB);
		});
		input = ~midBox.value.asFloat;
		input = input.clip(-6, 6);
		~midKnob.value_(input.linlin(-6, 6, 0, 1));
		~middB = input;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		});
		~midBox.value_(outString);
		~eq.set(\middB, ~middB);
		w.focus;
	});

	~setLoEQ = {
		arg db;
		~lodB = db;
		~loKnob.value_(db.linlin(-6, 6, 0, 1));
		~loBoxValue = ~lodB.round(0.1);
		if(~loBoxValue >= 0, {
			~loBoxString = "+" ++ ~loBoxValue.asString;
		}, {
			~loBoxString = ~loBoxValue.asString;
		});
		~loBox.value_(~loBoxString + "dB");
		~eq.set(\lodB, ~lodB);
	};

	~loBoxValue = ~lodB.round(0.1);
	if(~loBoxValue >= 0, {
		~loBoxString = "+" ++ ~loBoxValue.asString;
	}, {
		~loBoxString = ~loBoxValue.asString;
	});
	~loKnob = Knob.new(w)
	.canFocus_(false)
	.fixedWidth_(40)
	.value_(~lodB.linlin(-6, 6, 0, 1))
	.centered_(true)
	.action_({
		~lodB = ~loKnob.value.linlin(0, 1, -6, 6);
		~loBoxValue = ~lodB.round(0.1);
		if(~loBoxValue >= 0, {
			~loBoxString = "+" ++ ~loBoxValue.asString;
		}, {
			~loBoxString = ~loBoxValue.asString;
		}
		);
		~loBox.value_(~loBoxString + "dB");
		~eq.set(\lodB, ~lodB);
	});
	~loBox = TextField.new(w)
	.fixedWidth_(70)
	.value_(~loBoxString + "dB")
	.mouseDownAction_({
		~loBox.value_("");
	})
	.action_({
		var input, outString;
		if(~loBox.value == "", {
			~loBox.value_(~lodB);
		});
		if(~cleanBoxInput.(~lodB.value) == false, {
			~loBox.value_(~lodB);
		});
		input = ~loBox.value.asFloat;
		input = input.clip(-6, 6);
		~loKnob.value_(input.linlin(-6, 6, 0, 1));
		~lodB = input;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		});
		~loBox.value_(outString);
		~eq.set(\lodB, ~lodB);
		w.focus;
	});


	// ~updateVals = {
	// 	~decayVal = StaticText().string_(~decayBus.getSynchronous.asString);
	// 	~timeVal = StaticText().string_(~timeBus.getSynchronous.asString);
	// 	~mixVal = StaticText().string_(~mixBus.getSynchronous.asString);
	// };
	//
	// ~updateVals.();
	(
		OSCdef.new(\phone, {
			arg input;
			// var fire;
			// input.postln;
			if(input[1] == 1.0, {
				AppClock.play({
					~advanceCue.();
				});
				// ~nextBtn.valueAction();
			});
			// fire = input[1];
			// ~laser.set(\amp, fire*0.3);
		// }, "/1/push1")
		},"/button1")
	);


	w = Window("L'amour pur", Rect(200, 200, 500, 150))
	.alwaysOnTop_(true)
	.onClose_({
		~inputGroup.free;
		~bufGroup.free;
		~effectGroup.free;
		~outputGroup.free;
		~change.stop;
		~panning.stop;
		~setMicPanSlider.stop;
		~setAmpSlider.stop;
		~nPlay.stop;
		~slowPan.stop;
	})
	.background_(Color.fromHexString("#84acbd"))
	.asView.keyDownAction_({
		arg i, char;
		// i.postln;
		// char.postln;
		if (char == $ , {
			~advanceCue.();
		});
		if (char == $d, {
			// ~echoMul = 0.4;
			// ~randHi = 1;
			// ~randLow = 1;
			if(~delayStatus == 0, {
				~delayOn.();
			}, {
				if(~delayStatus == 1, {
					~delayOff.();
				});
			}
			);
		});
		if (char == $g, {
			if (~grainStatus == 0, {
				~grainOn.();
			}, {
				if (~grainStatus == 1, {
					~grainOff.();
				});
			}
			);
		});
		// if(char == $r, {
		// 	~temp = Synth(\recordBuf, [\in0, 0, \in1, 1, \buf, ~recBuf]);
		// });
		// if(char == $t, {
		// 	~temp.free;
		// });
		// if (char == $w, {
		// 	~play = Synth(\playBuf, [\buf, ~recBuf, \out, ~reverbBus]);
		// });
	})
	.layout_(
		HLayout(
			VLayout(
				HLayout(
					VLayout(
						// StaticText().string_(""),
						HLayout(
							StaticText().string_("current file: ")
							.maxWidth_(100).maxHeight_(40).minWidth_(100)
							.font_(Font(size: 18)),

							~curtext = StaticText()
							.string_("nil")
							.font_(Font(size: 18))
							.background_(Color.gray(0.8, 0.5))
							.minWidth_(300).maxHeight_(40)
						),

						HLayout(
							StaticText().string_("next file: ")
							.font_(Font(size: 18))
							.maxWidth_(100).maxHeight_(40).minWidth_(100),

							~nexttext = StaticText()
							.string_(e[0].file)
							.font_(Font(size: 18))
							.background_(Color.gray(0.8, 0.5))
							.minWidth_(300).maxHeight_(40)
						),
					),
					VLayout(
						~delayButton = Button().states_([
							["DELAY",Color.gray(0.6), ~buttonColor], ["DELAY",Color.green, ~buttonColor]
						])
						.canFocus_(false)
						.action_({
							// ~delayButton.value.postln;
							if (~delayButton.value == 1, {
								~delayOn.();
							});
							if (~delayButton.value == 0, {
								~delayOff.();
							});
						}),

						~grainButton = Button().states_([
							["GRAINS",Color.gray(0.6), ~buttonColor], ["GRAINS", Color.green, ~buttonColor]
						])
						.canFocus_(false)
						.action_({
							if(~grainButton.value == 1, {
								~grainOn.();
							});
							if(~grainButton.value == 0, {
								~grainOff.();
							});
						})
					),

				),
				// ~delayOn.();
				~nextbtn = Button().states_([
					// ["PLAY NEXT (spacebar or MIDI pedal)", Color.gray(0.3), Color(0.7, 0.9, 1)]
					["PLAY NEXT (spacebar or MIDI pedal)", Color.gray(0.9), ~buttonColor]
				])
				.minHeight_(50)
				.font_(Font(size: 18))
				.action_({
					~advanceCue.();
				}),
				~playSlider = Slider.new(w)
				.orientation_(\horizontal)
				.background_(Color.gray(0.8, 0.1))
				.value_(~nPosValue)
				.action_({
					~nPosValue = ~playSlider.value;
					~buf.free;
					~buf = Synth(\playBuf, [\buf, b[~bufIndex].bufnum, \amp, ~bufAmp, \startPos, ~nPosValue, \numFrames, b[~bufIndex].numFrames, \out, ~eqBus, \ctrlOut, ~nPlayBus], target:~bufGroup);
					// ~nPlay.reset;
					// AppClock.play(~nPlay);
				}),

				HLayout(
					StaticText().string_("PART: ")
					.align_(\right).font_(Font(size: 18)),
					~mvtSelect,
					StaticText().string_("CUE: ")
					.align_(\right).font_(Font(size: 18)),
					~cueSelect,
					~playStop = Button().states_([['GO', Color.green, ~buttonColor], ['GO', Color.gray, ~buttonColor]]).canFocus_(false)
					.font_(Font(size: 18))
					.action_({
						arg button;
						var value = button.value;
						if (value == 1, {
							// s.freeAll;
							~bufGroup.freeAll;
							~effectGroup.set(\amp, 0);
							defer{ ~curtext.string_("nil");};
						});
						if (value == 0, {
							~effectGroup.set(\amp, 1);
						})
					}),
					~reset = Button().states_([['RESET', Color.gray(0.9), ~buttonColor]]).canFocus_(false)
					.font_(Font(size: 18))
					.action_({
						~bufGroup.freeAll;
						~seq.reset;
						~curtext.string_("nil");
						if(~mvt == 0, {
							~nexttext.string_(e[0].file);
						});
						if(~mvt == 1, {
							~nexttext.string_(f[0].file);
						});
						~cueSelect.value_(0);

					}),
					~record = Button().states_([['RECORD', Color.red, ~buttonColor], ['RECORD', Color.gray, ~buttonColor]]).canFocus_(false)
					.font_(Font(size: 18))
					.value_(1)
					.action_({
						arg button;
						var value = button.value;
						if(value == 1, {
							s.stopRecording;
						});
						if(value == 0, {
							s.record;
						});
					})
				),
				HLayout(
					VLayout(
						StaticText().string_("In Device: ").font_(Font(size: 18)),
						StaticText().string_("Out Device: ").font_(Font(size: 18)),
					),
					VLayout(
						~inSelect,
						~outSelect,
					),
					~deviceChange = Button().states_([["Confirm", Color.gray(0.9), ~buttonColor]]).canFocus_(false)
					.font_(Font(size: 18))
					.fixedHeight_(50)
					.action_({
						s.quit;
						Server.default.options.inDevice_(~inChoice);
						Server.default.options.outDevice_(~outChoice);
						s.waitForBoot({
							~loadSynths.();
							~init.();
							~loadBufs.();
						});
					})

				),
			),
			VLayout(
				StaticText().string_("Mic")
				.font_(Font(size:18))
				.align_(\center),
				~micPanSlider,
				~micSlider,
				~micBox,
			),
			VLayout(
				StaticText().string_("Buffers")
				.font_(Font(size:18))
				.align_(\center),
				~ampSlider,
				~ampBox
			),
			VLayout(
				StaticText().string_("Reverb")
				.font_(Font(size:18))
				.align_(\center),
				HLayout(
					VLayout(
						StaticText().string_("Decay")
						.font_(Font(size:8))
						.align_(\center),
						~revTimeSlider,
						~revTimeBox,
					),
					VLayout(
						StaticText().string_("Damping")
						.font_(Font(size:8))
						.align_(\center),
						~dampSlider,
						~dampBox
					)
				)
			),
			VLayout(
				StaticText().string_("Grains")
				.font_(Font(size:18))
				.align_(\center),
				HLayout(
					VLayout(
						StaticText().string_("Density")
						.font_(Font(size:8))
						.align_(\center),
						~dordSlider,
						~dordBox,
					),
					VLayout(
						StaticText().string_("Duration")
						.font_(Font(size:8))
						.align_(\center),
						~durSlider,
						~durBox
					)
				)

			),
			VLayout(
				StaticText().string_("EQ (mic)")
				.font_(Font(size:18))
				.align_(\center),
				[~voxHiKnob, align:\center],
				~voxHiBox,
				[~voxMidKnob, align:\center],
				~voxMidBox,
				[~voxLoKnob, align:\center],
				~voxLoBox

			),
			VLayout(
				StaticText().string_("EQ (buf)")
				.font_(Font(size:18))
				.align_(\center),
				[~hiKnob, align:\center],
				~hiBox,
				[~midKnob, align:\center],
				~midBox,
				[~loKnob, align:\center],
				~loBox
			),
			VLayout(
				StaticText().string_("Main")
				.font_(Font(size:18))
				.align_(\center),
				~mainAmpSlider,
				~mainAmpBox
			),


		)
	)
	.front;
	w.focus;
	~mvt1.();
	AppClock.play(~nPlay);
	AppClock.play(~setAmpSlider);
	AppClock.play(~setMicPanSlider);


	// s.record;
	s.sync;

});
)
NetAddr.langPort;

OSCFunc.trace(true);
OSCFunc.trace(false);

(
{
	s.record;
	s.sync;
}.fork;
)