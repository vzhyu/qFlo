(
// ***Instructions***
// Put the cursor here, hold Command and press Enter!

Window.closeAll;
// Server.default.options.inDevice_("Microphone (Scarlett 2i2 USB)");
// Server.default.options.outDevice_("Speakers (Scarlett 2i2 USB)");


// ServerOptions.inDevices;
// ServerOptions.outDevices;

MIDIIn.connectAll;
Buffer.freeAll;
s.options.memSize = 2.pow(20);
o = Server.default.options;
o.numOutputBusChannels = 4;

// ~recordPath = thisProcess.nowExecutingPath.dirname ++ "/Recordings/";
~buttonColor = Color.fromHexString("#2185b0");
~mainColor = Color.fromHexString("#84acbd");
// ~blankBuf.play;
m = NetAddr("172.20.10.5", 8000);

s.waitForBoot({
	~synthDefIO = Dictionary();
	~synthDefArgs = Dictionary();
	~synthDefSetArgs = Dictionary();
	~synthDefGUIs = Dictionary();
	~synthSetArgs = Dictionary();
	~fluxDelayPairs = Dictionary();
	~synthList = Dictionary();
	~blankBuf = Buffer.alloc(s, 10, 2);
	// ~inChoice = "(default)";
	// ~outChoice = "(default)";



	// ~dummy = Bus.control(s, 1);

	~loadSynths = {
		(
			SynthDef.new(\micIn, {
				arg in = 0, out = 0, amp = 1, ampLag = 0, ampKBus, mix = 0.0;
				var sig;
				sig = SoundIn.ar(in);
				// sig1 = SoundIn.ar(in1);
				// rawSig = inSig*rawAmp;
				// filtSig = BLowShelf.ar(inSig, 700)*filtAmp;
				// sig = XFade2.ar(sig0, sig1, mix);
				// sig = rawSig + filtSig;
				// sig = Pan2.ar(sig, 0.0);
				sig = sig*amp;
				amp = amp.lag(ampLag);
				Out.kr(ampKBus, amp);
				Out.ar(out, sig);
				// Out.kr(ampOut, amp);
			}).add;
		);
		~synthDefIO[\micIn] = Dictionary.newFrom([\inChannels, 1, \outChannels, 1, \group,~inputGroup]);
		~synthDefArgs[\micIn] = Dictionary.newFrom([\in, 0, \out, 0, \amp, 1, \ampLag, 2]);
		~synthDefGUIs[\micIn] = {
			arg synth;
			var slider, box, boxValue, toggle, boxString, ampValue,
			sliderConvert, boxConvert,
			gui, setArgVals,
			out;
			ampValue = ~synthArgs[synth][\amp];
			boxString = ampValue.ampdb.asString;
			gui = VLayout(
				StaticText().string_("Mic")
				.font_(Font(size:18))
				.align_(\center),
				// toggle = Button.new(w)
				// .states_([["Mic"]])
				// .fixedWidth_(70)
				// .action_({
				// 	synth.set(\mix
				// 	}),
				slider = Slider(w)
				.fixedWidth_(70)
				.minHeight_(200)
				.background_(Color.gray(0.8, 0.1))
				.value_(ampValue.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
				.orientation_(\vertical)
				.action_({
					ampValue = slider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
					~synthArgs[synth][\amp] = ampValue;
					// ~synthArgs[synth][\amp].postln;
					boxConvert = {
						arg ampValue;
						var boxValue;
						boxValue = ampValue.ampdb.round(0.1);
						if (boxValue >= 0, {
							boxString = "+" ++ boxValue.asString;
						}, {
							boxString = boxValue.asString;
						});
						boxString = boxString + "dB";
					};

					~editCueSlider.(val: ampValue, slider:slider, convert:boxConvert);

					// if (~editWindow.isNil == false, {
					// 	if(~editWindow.isClosed == false, {
					// 		var row, boxIndex, rowIndex, box;
					// 		// rowIndex = (~cueSelect.value + 1);
					// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
					// 		if(~cueNumber == -1, {
					// 			rowIndex = 0;
					// 			}, {
					// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
					// 			}
					// 		);
					//
					// 		~setArgs.do({
					// 			arg set, i;
					// 			var candidate;
					// 			// i.postln;
					// 			if (i > 0, {
					// 				candidate = set[\slider];
					// 				// candidate.postln;
					// 				if (candidate == slider, {
					// 					boxIndex = set[\index];
					// 					box = ~cueBoxes[rowIndex][boxIndex];
					// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
					// 					box.value_(boxString + "dB");
					// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = ampValue;
					//
					// 				});
					// 			});
					// 		});
					// 	});
					// });
					synth.set(\amp, ampValue, \ampLag, 0);
					box.value_(boxString);
				}),
				box = TextField(w)
				.fixedWidth_(70)
				.value_(ampValue.ampdb.asString + "dB")
				.mouseDownAction_({
					~setGUIs.stop;
					~synthSetArgs[synth].stop;
					~synthSetArgs[synth].reset;
					// setArgVals.stop;

					// setArgVals.postln;
					// setArgVals.reset;
					box.value_("");
				})
				.action_({
					var input, outString, diff, lag;
					if(box.value == "", {
						box.value_(ampValue.ampdb.round(0.1)).asString + "dB";
					});
					if(~cleanBoxInput.(box.value) == false, {
						box.value_(ampValue.ampdb.round(0.1)).asString + "dB";
					});
					input = box.value.asFloat;
					input = input.clip(-40, 15);
					slider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
					ampValue = input.dbamp;
					~synthArgs[synth][\amp] = ampValue;
					if (input >= 0, {
						outString = "+" ++ input.round(0.1).asString + "dB";
					}, {
						outString = input.round(0.1).asString + "dB";
					});
					box.value_(outString);
					synth.set(\amp, ~synthArgs[synth][\amp], \ampLag, 0);
					~setGUIs.reset;
					AppClock.play(~setGUIs);
					AppClock.play(~synthSetArgs[synth]);
					w.focus;
				});
			);
			setArgVals = Routine.new({
				var amp;
				{
					amp = ~synthArgs[synth][\ampKBus].getSynchronous;
					~synthArgs[synth][\amp] = amp;
					// amp.postln;

					// synth.get(\amp, {
					// arg amp;
					// amp.postln;
					// slider.value_(amp.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp));
					// ~synthArgs[synth][\amp] = amp;
					// });
					// amp.postln;
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);
			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\slider, slider,
				\box, box,
				0, \amp,
				\numArgs, 1,
				// \setArgs, [\amp],
				\amp, (
					\slider: slider,
					\box: box,
					\sliderConvert: {
						arg val;
						val.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1)
					},
					\boxConvert: {
						arg val;
						var boxString, boxValue;
						boxString = "";
						boxValue = val.ampdb.round(0.1);
						if (boxValue >= 0, {
							boxString = "+" ++ boxValue.asString;
						}, {
							boxString = boxValue.asString;
						}
						);
						boxString = boxString + "dB";
						boxString;

					};
				),

			]);

			// "hi".postln;
			// view = View(w)
			// .layout_(
			// );
			// layout;
		};
		~synthDefSetArgs[\micIn] = [\amp];
		// ~synthList[\micIn] = "Single input via Microphone.";÷
		// ~synthDefGUIs[\reverb].();
		// (
		// 	SynthDef(\mic, {
		// 		arg in = 0, out = 0, outrev = 0, amp = 1, fxamp = 1, revamp = 1, recOut = 0;
		// 		var sig;
		// 		sig = SoundIn.ar(in) * amp ! 2;
		// 		Out.ar(out, sig * fxamp);
		// 		Out.ar(outrev, sig * revamp);
		// 		// Out.ar(ghostOut, sig);
		// 		Out.ar(recOut, sig);
		// 	}).add;
		//
		// );
		// (
		// 	SynthDef(\rec, {
		// 		arg in = 0, buf = 0, loop = 1, gate = 1, fade = 0.02;
		// 		var sig;
		// 		sig = In.ar(in, 1);
		// 		sig = sig * Line.kr(0, 1, fade);
		// 		sig = sig * EnvGen.kr(Env([1,1,0],[0,fade],[0,0], 1), gate, doneAction:2);
		// 		RecordBuf.ar(sig, buf, loop: loop, doneAction: 2);
		// 	}).add;
		// );
		// (
		// 	SynthDef(\recle, {
		// 		arg buf = 0, pan = 0.0, amp = 1, ampLag = 0, out = 0;
		// 		var sig;
		// 		amp = amp.lag(ampLag);
		// 		sig = PlayBuf.ar(1, buf, BufRateScale.ir(buf), doneAction: 2)*amp;
		// 		sig = Pan2.ar(sig, pan);
		// 		Out.ar(out, sig);
		// 	}).add;
		//
		// );

		(
			SynthDef.new(\reverb, {
				arg in,
				hiCut = 3310, rs = 0.5,
				mix = 0, room = 100, revTime = 3, damp = 0.5,
				mixLag = 3, roomLag = 2, dampLag = 2, revTimeLag = 2,
				dryAmp = 1, wetAmp = 1, amp = 1, ampLag = 2, dryLevel = 1,
				pan = 0, panLag = 2,
				dampKBus, revTimeKBus, mixKBus, panKBus,
				out = 0;
				var sig, dry, wet;
				amp = amp.lag(ampLag);
				mix = mix.lag(mixLag);
				// mix = VarLag.kr(mix, mixLag, 0);

				// room = room.lag(roomLag);
				room = VarLag.kr(room, roomLag, 0);

				// damp = damp.lag(dampLag);
				damp = VarLag.kr(damp, dampLag, 0);
				// revTime = revTime.lag(revTimeLag);
				revTime = VarLag.kr(revTime, revTimeLag, 0);

				dry = In.ar(in, 2);
				// wet = In.ar(in, 2);
				wet = BHiShelf.ar(dry, hiCut, rs);
				wet = GVerb.ar(wet, room, revTime, damp, drylevel:dryLevel);
				// wet = FreeVerb.ar(sig, room:1, damp:damp)
				wet = LPF.ar(wet, 1500);
				// dry = dry*dryAmp;
				// wet = wet*wetAmp;
				// dry = Balance2.ar(dry[0], dry[1], pan);
				// wet = Balance2.ar(wet[0], wet[1], pan);
				sig = XFade2.ar(dry, wet, mix);
				// sig = Balance2.ar(sig[0], sig[1], pan);
				sig = sig*amp;
				Out.kr(dampKBus, damp);
				Out.kr(revTimeKBus, revTime);
				Out.kr(mixKBus, mix);
				Out.ar(out, sig);
			}).add;
		);
		~synthDefIO[\reverb] = Dictionary.newFrom([\inChannels, 2, \outChannels, 2, \group, ~effectGroup]);
		~synthDefArgs[\reverb] = Dictionary.newFrom([\in, nil, \out, 0, \mix, 0, \mixLag, 3, \damp, 0.5, \dampLag, 2, \revTime, 3, \pan, 0]);
		~synthDefGUIs[\reverb] = {
			arg synth;
			var layout,
			toggle,
			revTimeTitle, revTimeSlider, revTimeBox, revTime,
			dampTitle, dampSlider, dampBox, damp,
			mixTitle, mixSlider, mixBox, mix,
			panSlider, panBox, pan,
			gui, setArgVals,
			out;
			pan = ~synthArgs[synth][\pan];
			revTime = ~synthArgs[synth][\revTime];
			damp = ~synthArgs[synth][\damp];
			mix = ~synthArgs[synth][\mix];

			panSlider = Slider(w)
			.canFocus_(false)
			.fixedHeight_(20)
			.background_(Color.gray(0.8, 0.1))
			.value_(pan.linlin(-1, 1, 0, 1))
			.orientation_(\horizontal)
			.action_({
				pan = panSlider.value.linlin(0, 1, -1, 1);
				synth.set(\pan, pan, \panLag, 0);
				~synthArgs[synth][\pan] = pan;
				~editCueSlider.(val:pan, slider:panSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				//
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == panSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(pan.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = pan;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});
			panBox = TextField.new(w);

			revTimeTitle = StaticText().string_("Decay")
			.font_(Font(size:8))
			.align_(\center);

			revTimeSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(revTime.linlin(0.2, 8, 0, 1))
			.action_({
				revTime = revTimeSlider.value.linlin(0, 1, 0.2, 8);
				revTimeBox.value_(revTime.round(0.1));
				synth.set(\revTime, revTime, \revTimeLag, 0);
				~synthArgs[synth][\revTime] = revTime;
				~editCueSlider.(val:revTime, slider: revTimeSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		// rowIndex = (~cueSelect.value + 1);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == revTimeSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(revTime.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = revTime;
				// 				});
				// 			});
				// 		});
				// 	});
				// });
			});

			revTimeBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(revTime.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				revTimeBox.value_("");
			})
			.action_({
				revTime = revTimeBox.value.asFloat;
				revTimeSlider.value_(revTime.linlin(0.2, 8, 0, 1));
				synth.set(\revTime, revTime, \revTimeLag, 0);
				~synthArgs[synth][\revTime] = revTime;
				~setGUIs.reset;
				~synthSetArgs[synth].reset;
				AppClock.play(~setGUIs);
				AppClock.play(~synthSetArgs[synth]);
				w.focus;
			});

			dampTitle = StaticText().string_("Damping")
			.font_(Font(size:8))
			.align_(\center);

			dampSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(damp)
			.action_({
				damp = dampSlider.value;
				dampBox.value_(damp.round(0.01));
				synth.set(\damp, damp, \dampLag, 0);
				~synthArgs[synth][\damp] = damp;
				~editCueSlider.(val: damp, slider:dampSlider);
				// if(~editWindow.isNil == false, {
				//
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueSelect.value + 1);
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				//
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == dampSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(damp.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = damp;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});

			dampBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(damp.round(0.01))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				dampBox.value_("");
			})
			.action_({
				damp = dampBox.value.asFloat;
				dampSlider.value_(damp);
				synth.set(\damp, damp, \dampLag, 0);
				~synthArgs[synth][\damp] = damp;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);

				w.focus;
			});

			mixTitle = StaticText().string_("Dry/Wet")
			.font_(Font(size:8))
			.align_(\center);

			mixSlider = Slider.new(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(mix.value.linlin(-1, 1, 0, 1))
			.action_({
				mix = mixSlider.value.linlin(0, 1, -1, 1);
				mixBox.value_(mix.round(0.01));
				synth.set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~editCueSlider.(val: mix, slider: mixSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueSelect.value + 1);
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				//
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == mixSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(mix.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = mix;
				// 				});
				// 			});
				// 		});
				// 	});
				// });


				w.focus;

			});
			mixBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(mix)
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				mixBox.value_("");
			})
			.action_({
				mix = mixBox.value.asFloat;
				mixSlider.value_(mix.linlin(-1, 1, 0, 1));
				synth.set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			// revTime.postln;
			gui = VLayout(
				// toggle = Button.new(w)
				// .states_([["Reverb"]]),

				StaticText().string_("Reverb")
				.font_(Font(size:18))
				.align_(\center),
				// panSlider,
				HLayout(
					VLayout(
						revTimeTitle,
						revTimeSlider,
						revTimeBox,
					),
					VLayout(
						dampTitle,
						dampSlider,
						dampBox
					),
					VLayout(
						mixTitle,
						mixSlider,
						mixBox
					),
				)
			);

			setArgVals = Routine.new({
				var revTime, damp, mix;
				{
					revTime = ~synthArgs[synth][\revTimeKBus].getSynchronous;
					// revTime.postln;
					damp = ~synthArgs[synth][\dampKBus].getSynchronous;
					mix = ~synthArgs[synth][\mixKBus].getSynchronous;
					// pan = ~synthArgs[synth][\panKBus].getSynchronous;

					~synthArgs[synth][\revTime] = revTime;
					~synthArgs[synth][\damp] = damp;
					~synthArgs[synth][\mix] = mix;
					// ~synthArgs[synth][\pan] = pan;
					// synth.get(\revTime, {
					// 	arg revTime;
					// 	~synthArgs[synth][\revTime] = revTime;
					// });
					// synth.get(\damp, {
					// 	arg damp;
					// 	~synthArgs[synth][\damp] = damp;
					// });
					// synth.get(\mix, {
					// 	arg mix;
					// 	~synthArgs[synth][\mix] = mix;
					// });
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);

			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\revTimeSlider, revTimeSlider,
				\revTimeBox, revTimeBox,
				\dampSlider, dampSlider,
				\dampBox, dampBox,
				\mixSlider, mixSlider,
				\mixBox, mixBox,
				0, \revTime,
				1, \damp,
				2, \mix,
				// 3, \pan,
				\numArgs, 3,
				// \setArgs, [\revTime, \damp, \mix],
				\revTime, (
					\slider: revTimeSlider,
					\box: revTimeBox,
					\sliderConvert: {
						arg val;
						val.linlin(0.2, 8, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\damp, (
					\slider: dampSlider,
					\box: dampBox,
					\sliderConvert: {
						arg val;
						val;
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\mix, (
					\slider: mixSlider,
					\box: mixBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\pan, (
					\slider: panSlider,
					\box: panBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				)
			]);
			// out;
			// view = View(w)
			// .layout_(
			// );
			// view;
		};
		~synthDefSetArgs[\reverb] = [\revTime, \damp, \mix];
		~synthList[\reverb] = "2-channel reverb.\nInputs: 2\nOutputs: 2";
		// (\addGroup:~group)
		// (
		// 	SynthDef(\reverb, {
		// 		arg in = 0, decay = 1, damp = 0.5, lpf = 1000, mix = 0.2, amp = 1, recOut, out = 0;
		// 		var sig, outSig, rev;
		// 		sig = In.ar(in, 2);
		// 		rev = LPF.ar(GVerb.ar(sig.sum, 300, decay, damp), lpf);
		// 		sig = XFade2.ar(sig, rev, mix*2-1);
		// 		outSig = sig * amp;
		// 		Out.ar(out, outSig);
		// 		Out.ar(recOut, sig);
		// 	}).add;
		// );

		(
			SynthDef.new(\delay, {
				arg in, out = 0, amp = 1, ampLag = 2, rate = 0.2, rateLag = 2, rateKBus, decay= 5, decayLag = 2, decayKBus, mix = 0, mixLag = 2, mixKBus, pan = 0, panLag = 2, panKBus;
				var inSig, dry, wet, sig;
				amp = amp.lag(ampLag);
				// rate = rate.lag(rateLag);
				rate = VarLag.kr(rate, rateLag, 0);

				// decay = decay.lag(decayLag);
				decay = VarLag.kr(decay, decayLag, 0);
				mix = mix.lag(mixLag);
				// mix = VarLag.kr(mix, mixLag, 0);
				// pan = pan.lag(panLag);
				pan = VarLag.kr(pan, panLag, 0);
				inSig = In.ar(in, 1);
				dry = inSig;
				wet = CombC.ar(inSig, 10, rate, decay);

				// sig = Pan2.ar(sig, pan);
				// dry = dry!2;
				// wet = Pan2.ar(wet, pan);
				// wet = Balance2.ar(wet[0], wet[1], pan);
				sig = XFade2.ar(dry, wet, mix);
				sig = sig * amp;

				Out.kr(panKBus, pan);
				Out.kr(rateKBus, rate);
				Out.kr(decayKBus, decay);
				Out.kr(mixKBus, mix);
				Out.ar(out, sig);
			}).add;
		);
		~synthDefIO[\delay] = (inChannels:1, \outChannels:1, \group:~effectGroup);
		~synthList[\delay] = "Simple delay line.\nInputs: 1\nOutputs: 1";
		~synthDefArgs[\delay] = Dictionary.newFrom([\in, 0, \out, 0, \amp, 1, \rate, 0.2, \rateLag, 2, \decay, 5, \decayLag, 2, \mix, 0, \mixLag, 2, \pan, 0]);



		~synthDefGUIs[\delay] = {
			arg synth;
			var rateTitle, rateSlider, rateBox, rate,
			decayTitle, decaySlider, decayBox, decay,
			mixTitle, mixSlider, mixBox, mix,
			panSlider, panBox, pan,
			gui, setArgVals,
			out;
			rate = ~synthArgs[synth][\rate];
			decay = ~synthArgs[synth][\decay];
			mix = ~synthArgs[synth][\mix];
			pan = ~synthArgs[synth][\pan];

			panSlider = Slider(w)
			.canFocus_(false)
			.fixedHeight_(20)
			.background_(Color.gray(0.8, 0.1))
			.value_(pan.linlin(-1, 1, 0, 1))
			.orientation_(\horizontal)
			.action_({
				pan = panSlider.value.linlin(0, 1, -1, 1);
				synth.set(\pan, pan, \panLag, 0);
				~synthArgs[synth][\pan] = pan;
				~editCueSlider.(val: pan, slider:panSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				//
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == panSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(pan.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = pan;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});
			panBox = TextField.new(w);

			// ~streamList[0][2].set(\pan, 1);
			rateTitle = StaticText().string_("Rate")
			.font_(Font(size:8))
			.align_(\center);
			rateSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(rate.linlin(0.5, 5, 0, 1))
			.action_({
				rate = rateSlider.value.linlin(0, 1, 0.5, 5);
				rateBox.value_(rate.round(0.1));
				synth.set(\rate, rate, \rateLag, 0);
				~synthArgs[synth][\rate] = rate;
				~editCueSlider.(val:rate, slider:rateSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == rateSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(rate.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = rate;
				// 				});
				// 			});
				// 		});
				// 	});
				// });
			});

			rateBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(rate.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				rateBox.value_("");
			})
			.action_({
				rate = rateBox.value.asFloat;
				rateSlider.value_(rate.linlin(0.5, 5, 0, 1));
				synth.set(\rate, rate, \rateLag, 0);
				~synthArgs[synth][\rate] = rate;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			decayTitle = StaticText().string_("Decay")
			.font_(Font(size:8))
			.align_(\center);

			decaySlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(decay.linlin(5, 20, 0, 1))
			.action_({
				decay = decaySlider.value.linlin(0, 1, 5, 20);
				decayBox.value_(decay.round(0.1));
				synth.set(\decay, decay, \decayLag, 0);
				~synthArgs[synth][\decay] = decay;
				~editCueSlider.(val:decay, slider:decaySlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == decaySlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(decay.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = decay;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});

			decayBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(decay.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				decayBox.value_("");
			})
			.action_({
				decay = decayBox.value.asFloat;
				decaySlider.value_(rate.linlin(5, 20, 0, 1));
				synth.set(\decay, decay, \decayLag, 0);
				~synthArgs[synth][\decay] = decay;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});


			mixTitle = StaticText().string_("Dry/Wet")
			.font_(Font(size:8))
			.align_(\center);

			mixSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(mix.linlin(-1, 1, 0, 1))
			.action_({
				mix = mixSlider.value.linlin(0, 1, -1, 1);
				mixBox.value_(mix.round(0.1));
				synth.set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~editCueSlider.(val:mix, slider:mixSlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == mixSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(mix.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = mix;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});




			mixBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(mix.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				mixBox.value_("");
			})
			.action_({
				mix = mixBox.value.asFloat;
				mixSlider.value_(rate.linlin(-1, 1, 0, 1));
				synth.set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});
			gui = VLayout(
				StaticText().string_("Delay")
				.font_(Font(size:18))
				.align_(\center),
				// panSlider,
				// toggle = Button(w)
				// .states_([["FluxDelay",Color.green, ~buttonColor],["FluxDelay",Color.gray, ~buttonColor]])
				// .canFocus_(false)
				// .action_({
				// 	arg button;
				// 	var value;
				// 	value = button.value;
				// 	if (value == 1, {
				// 		~fluxDelayPairs[synth][\synth].set(\mix, 1);
				// 		synth.set(\mix, 1);
				// 		~synthArgs[synth][\mix] = 1;
				// 	});
				// 	if (value == 0, {
				// 		~fluxDelayPairs[synth][\synth].set(\mix, -1);
				// 		synth.set(\mix, -1);
				// 		~synthArgs[synth][\mix] = -1;
				//
				// 	});
				// }),
				HLayout(
					VLayout(
						rateTitle,
						rateSlider,
						rateBox,
					),
					VLayout(
						decayTitle,
						decaySlider,
						decayBox
					),
					VLayout(
						mixTitle,
						mixSlider,
						mixBox
					)
				)
			);

			setArgVals = Routine.new({
				var rate, decay, mix;
				{
					rate = ~synthArgs[synth][\rateKBus].getSynchronous;
					decay = ~synthArgs[synth][\decayKBus].getSynchronous;
					mix = ~synthArgs[synth][\mixKBus].getSynchronous;
					// pan = ~synthArgs[synth][\panKBus].getSynchronous;
					// rate.postln;
					~synthArgs[synth][\rate] = rate;
					~synthArgs[synth][\decay] = decay;
					~synthArgs[synth][\mix] = mix;
					// rate.postln;
					// decay.postln;
					// mix.postln;
					// ~synthArgs[synth][\pan] = pan;
					// synth.get(\rate, {
					// 	arg mulAmp;
					// 	~synthArgs[synth][\rate] = rate;
					// });
					// synth.get(\decay, {
					// 	arg decay;
					// 	~synthArgs[synth][\decay] = decay;
					// });
					// synth.get(\mix, {
					// 	arg mix;
					// 	~synthArgs[synth][\mix] = mix;
					// });
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);
			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\rateSlider, rateSlider,
				\rateBox, rateBox,
				\decaySlider, decaySlider,
				\decayBox, decayBox,
				0, \rate,
				1, \decay,
				2, \mix,
				// 3, \pan,
				\numArgs, 3,
				// \setArgs, [\rate, \decay],
				\rate, (
					\slider: rateSlider,
					\box: rateBox,
					\sliderConvert: {
						arg val;
						val.linlin(0.5, 5, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.1);
					},
				),
				\decay, (
					\slider: decaySlider,
					\box: decayBox,
					\sliderConvert: {
						arg val;
						val.linlin(5, 20, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.1);
					}
				),
				\mix, (
					\slider: mixSlider,
					\box: mixBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\pan, (
					\slider: panSlider,
					\box: panBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				)

			]);
		};
		~synthDefSetArgs[\delay] = [
			\rate,
			\decay,
			\mix,
			// \pan

		];

		(
			SynthDef.new(\pan, {
				arg in, pan, out = 0, amp = 1, ampLag, panLag = 0.5, panKBus;
				var sig;
				amp = amp.lag(ampLag);
				// pan = pan.lag(panLag);
				pan = VarLag.kr(pan, panLag, 0);
				sig = In.ar(in, 1);
				sig = sig*amp;
				sig = Pan2.ar(sig, pan);
				Out.kr(panKBus, pan);
				Out.ar(out, sig);
			}).add;
		);
		~synthDefIO[\pan] = (\inChannels:1, \outChannels:2, \group:~effectGroup);
		~synthList[\pan] = "2-channel pan.\nInputs: 1\nOutputs: 2";
		~synthDefArgs[\pan] = Dictionary.newFrom([\pan:0, \amp:1, \panLag:0.5]);
		~synthDefGUIs[\pan] = {
			arg synth;
			var layout,
			panTitle, panSlider, panBox, panRightLabel, panLeftLabel,
			pan,
			gui, setArgVals,
			out;
			pan = ~synthArgs[synth][\pan];
			panTitle = StaticText().string_("Pan")
			.font_(Font(size:18))
			.align_(\center);

			panRightLabel = StaticText().string_("R")
			.font_(Font(size:8))
			.align_(\center);
			panLeftLabel = StaticText().string_("L")
			.font_(Font(size:8))
			.align_(\center);

			panSlider = Slider(w)
			.canFocus_(false)
			// .fixedHeight_(20)
			.background_(Color.gray(0.8, 0.1))
			.value_(pan.linlin(-1, 1, 0, 1))
			.orientation_(\vertical)
			.action_({
				pan = panSlider.value.linlin(0, 1, -1, 1);
				synth.set(\pan, pan, \panLag, 0);
				~synthArgs[synth][\pan] = pan;
				~editCueSlider.(val:pan, slider:panSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == panSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(pan.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = pan;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});
			panBox = TextField.new(w);

			gui = VLayout(
				panTitle,
				panRightLabel,
				panSlider,
				panLeftLabel,
			);

			// ~synthArgs[~streamList[0][2]][\panKBus];
			setArgVals = Routine.new({
				var pan;
				{
					pan = ~synthArgs[synth][\panKBus].getSynchronous;
					// pan.postln;
					// rate.postln;
					~synthArgs[synth][\pan] = pan;
					// synth.get(\rate, {
					// 	arg mulAmp;
					// 	~synthArgs[synth][\rate] = rate;
					// });
					// synth.get(\decay, {
					// 	arg decay;
					// 	~synthArgs[synth][\decay] = decay;
					// });
					// synth.get(\mix, {
					// 	arg mix;
					// 	~synthArgs[synth][\mix] = mix;
					// });
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);

			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\panSlider, panSlider,
				\panBox, panBox,
				0, \pan,
				\numArgs, 1,
				\pan, (
					\slider: panSlider,
					\box: panBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),

			]);

		};
		~synthDefSetArgs[\pan] = [\pan];

		(
			SynthDef.new(\fluxDelay, {
				arg in = 0, out = 0, bandwidth = 4,
				decay = 10, decayLag = 2,
				amp = 1, ampLag = 2, mul0 = 1, mul1 = 1, mul2= 1,
				rate = 1, rateLag = 2,
				mix = -1, mixLag = 2,
				pan = 0, panLag = 2,
				decayKBus, rateKBus, mixKBus, panKBus;
				var sig, inSig, sigL, sigR, sigLR, dry, wet;
				amp = amp.lag(ampLag);
				// rate = rate.lag(rateLag);
				rate = VarLag.kr(rate, rateLag, 0);
				// decay = decay.lag(decayLag);
				decay = VarLag.kr(decay, decayLag, 0);
				mix = mix.lag(mixLag);
				// mix = VarLag.kr(mix, mixLag, 0);
				// pan = pan.lag(panLag);
				pan = VarLag.kr(pan, panLag, 0);
				mul0 = mul0*rate;
				mul1 = mul1*rate;
				mul2 = mul2*rate;
				inSig = In.ar(in, 1);
				dry = inSig!2;
				// inSig = inSig!2;
				sigL = BPF.ar(inSig, 704, bandwidth);
				sigL = CombN.ar(sigL, 10, 0.165*mul0, decay*0.21)*1.26;
				sigR = BPF.ar(inSig, 918, bandwidth);
				sigR = CombN.ar(sigR, 10, 0.477*mul1, decay*0.46)*2;
				sigLR = BPF.ar(inSig, 449, bandwidth);
				sigLR = CombN.ar(sigLR, 10, 1*mul2, decay*0.24)/1.26;
				// sig = [sigL+sigLR, sigR+sigLR];
				// sig = sig+(inSig/1.52);
				sigL = sigL + sigLR;
				sigR = sigR + sigLR;
				// dry = Balance2.ar(inSig[0], inSig[1], pan);
				// dry = [sigL, sigR];
				wet = Balance2.ar(sigL, sigR, pan);

				sig = XFade2.ar(dry, wet, mix);
				sig = sig*amp;

				// sig = sig*0.2;
				Out.kr(panKBus, pan);
				Out.kr(decayKBus, decay);
				Out.kr(rateKBus, rate);
				Out.kr(mixKBus, mix);
				Out.ar(out, sig);
			}).add;
		);
		// ~streamList[0][3].set(\pan, -1);
		~synthDefIO[\fluxDelay] = Dictionary.newFrom([\inChannels, 1, \outChannels, 2, \kBuses, [\decayKBus, \rateKBus], \group, ~effectGroup]);
		~synthDefArgs[\fluxDelay] = Dictionary.newFrom([\in:0, \out:0, \rate, 1, \bandwidth:4, \decay:10, \amp:1, \mul0:1, \mul1:1, \mul2:1, \mix, -1, \pan, 0]);
		~synthDefGUIs[\fluxDelay] = {
			arg synth;
			var toggle,
			rateTitle, rateSlider, rateBox, rate,
			decayTitle, decaySlider, decayBox, decay,
			mixTitle, mixSlider, mixBox, mix,
			panSlider, panBox, pan,
			gui, setArgVals,
			out;

			rate = ~synthArgs[synth][\rate];
			decay = ~synthArgs[synth][\decay];
			mix = ~synthArgs[synth][\mix];
			pan = ~synthArgs[synth][\pan];

			panSlider = Slider(w)
			.canFocus_(false)
			.fixedHeight_(20)
			.background_(Color.gray(0.8, 0.1))
			.value_(pan.linlin(-1, 1, 0, 1))
			.orientation_(\horizontal)
			.action_({
				pan = panSlider.value.linlin(0, 1, -1, 1);
				synth.set(\pan, pan, \panLag, 0);
				~fluxDelayPairs[synth][\synth].set(\pan, pan, \panLag, 0);
				~synthArgs[synth][\pan] = pan;
				~editCueSlider.(val:pan, slider:panSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == panSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(pan.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = pan;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});
			panBox = TextField.new(w);

			rateTitle = StaticText().string_("Rate")
			.font_(Font(size:8))
			.align_(\center);

			rateSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(rate.linlin(0.5, 5, 0, 1))
			.action_({
				rate = rateSlider.value.linlin(0, 1, 0.5, 5);
				rateBox.value_(rate.round(0.1));
				synth.set(\rate, rate, \rateLag, 0);
				~fluxDelayPairs[synth][\synth].set(\rate, rate, \rateLag, 0);
				~synthArgs[synth][\rate] = rate;
				if(~editWindow.isNil == false, {
					if(~editWindow.isClosed == false, {
						var row, boxIndex, rowIndex, box;
						// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
						if(~cueNumber == -1, {
							rowIndex = 0;
						}, {
							rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
						}
						);
						~setArgs.do({
							arg set, i;
							var candidate;
							// i.postln;

							if (i > 0, {
								candidate = set[\slider];
								// candidate.postln;
								if (candidate == rateSlider, {
									boxIndex = set[\index];
									box = ~cueBoxes[rowIndex][boxIndex];
									~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
									box.value_(rate.round(0.01));
									~cueList[~mvtSelect.value][rowIndex][boxIndex] = rate;
								});
							});
						});
					});
				});

			});

			rateBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(rate.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				rateBox.value_("");
			})
			.action_({
				rate = rateBox.value.asFloat;
				rateSlider.value_(rate.linlin(0.5, 5, 0, 1));
				synth.set(\rate, rate, \rateLag, 0);
				~fluxDelayPairs[synth][\synth].set(\rate, rate, \rateLag, 0);
				~synthArgs[synth][\rate] = rate;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			decayTitle = StaticText().string_("Decay")
			.font_(Font(size:8))
			.align_(\center);

			decaySlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(decay.linlin(5, 20, 0, 1))
			.action_({
				decay = decaySlider.value.linlin(0, 1, 5, 20);
				decayBox.value_(decay.round(0.1));
				synth.set(\decay, decay, \decayLag, 0);
				~fluxDelayPairs[synth][\synth].set(\decay, decay, \decayLag, 0);
				~synthArgs[synth][\decay] = decay;
				~editCueSlider.(val:decay, slider:decaySlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == decaySlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(decay.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = decay;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});

			decayBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(decay.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				decayBox.value_("");
			})
			.action_({
				decay = decayBox.value.asFloat;
				decaySlider.value_(rate.linlin(5, 20, 0, 1));
				synth.set(\decay, decay, \decayLag, 0);
				~fluxDelayPairs[synth][\synth].set(\decay, decay, \decayLag, 0);
				~synthArgs[synth][\decay] = decay;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			mixTitle = StaticText().string_("Dry/Wet")
			.font_(Font(size:8))
			.align_(\center);

			mixSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(mix.linlin(-1, 1, 0, 1))
			.action_({
				mix = mixSlider.value.linlin(0, 1, -1, 1);
				mixBox.value_(mix.round(0.1));
				synth.set(\mix, mix, \mixLag, 0);
				~fluxDelayPairs[synth][\synth].set(\mix, mix);
				~synthArgs[synth][\mix] = mix;
				~editCueSlider.(val:mix, slider:mixSlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == mixSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(mix.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = mix;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});

			mixBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(mix.round(0.1))
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				mixBox.value_("");
			})
			.action_({
				mix = mixBox.value.asFloat;
				mixSlider.value_(rate.linlin(-1, 1, 0, 1));
				synth.set(\mix, mix, \mixLag, 0);
				~fluxDelayPairs[synth][\mix].set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});



			gui = VLayout(
				StaticText().string_("FluxDelay")
				.font_(Font(size:18))
				.align_(\center),
				panSlider,
				// toggle = Button(w)
				// .states_([["FluxDelay",Color.green, ~buttonColor],["FluxDelay",Color.gray, ~buttonColor]])
				// .canFocus_(false)
				// .action_({
				// 	arg button;
				// 	var value;
				// 	value = button.value;
				// 	if (value == 1, {
				// 		~fluxDelayPairs[synth][\synth].set(\mix, 1);
				// 		synth.set(\mix, 1);
				// 		~synthArgs[synth][\mix] = 1;
				// 	});
				// 	if (value == 0, {
				// 		~fluxDelayPairs[synth][\synth].set(\mix, -1);
				// 		synth.set(\mix, -1);
				// 		~synthArgs[synth][\mix] = -1;
				//
				// 	});
				// }),
				HLayout(
					VLayout(
						rateTitle,
						rateSlider,
						rateBox,
					),
					VLayout(
						decayTitle,
						decaySlider,
						decayBox
					),
					VLayout(
						mixTitle,
						mixSlider,
						mixBox
					)
				)
			);

			setArgVals = Routine.new({
				var rate, decay, mix, pan;
				{
					rate = ~synthArgs[synth][\rateKBus].getSynchronous;
					decay = ~synthArgs[synth][\decayKBus].getSynchronous;
					mix = ~synthArgs[synth][\mixKBus].getSynchronous;
					pan = ~synthArgs[synth][\panKBus].getSynchronous;

					// rate.postln;
					~synthArgs[synth][\pan] = pan;
					~synthArgs[synth][\rate] = rate;
					~synthArgs[synth][\decay] = decay;
					~synthArgs[synth][\mix] = mix;
					// synth.get(\rate, {
					// 	arg mulAmp;
					// 	~synthArgs[synth][\rate] = rate;
					// });
					// synth.get(\decay, {
					// 	arg decay;
					// 	~synthArgs[synth][\decay] = decay;
					// });
					// synth.get(\mix, {
					// 	arg mix;
					// 	~synthArgs[synth][\mix] = mix;
					// });
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);

			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\rateSlider, rateSlider,
				\rateBox, rateBox,
				\decaySlider, decaySlider,
				\decayBox, decayBox,
				0, \rate,
				1, \decay,
				2, \mix,
				3, \pan,
				\numArgs, 4,
				// \setArgs, [\rate, \decay],
				\rate, (
					\slider: rateSlider,
					\box: rateBox,
					\sliderConvert: {
						arg val;
						val.linlin(0.5, 5, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.1);
					},
				),
				\decay, (
					\slider: decaySlider,
					\box: decayBox,
					\sliderConvert: {
						arg val;
						val.linlin(5, 20, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.1);
					}
				),
				\mix, (
					\slider: mixSlider,
					\box: mixBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\pan, (
					\slider: panSlider,
					\box: panBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				)

			]);
		};
		~synthDefSetArgs[\fluxDelay] = [\rate, \decay, \mix, \pan];
		~synthList[\fluxDelay] = "2 channel delay, irregular delay rates.\nInputs: 2\nOutputs: 2";


		(
			SynthDef.new(\grain, {
				arg in, out = 0,
				density = 10, densityLag = 2,
				rand = 1,
				dur = 0.01, durLag = 2,
				mix = 1, mixLag = 2,
				pan = 0, panLag = 2,
				densityKBus, durKBus, mixKBus, panKBus;
				var sig, dry, wet, trigger, sigL, sigR;
				pan = VarLag.kr(pan, panLag, 0);
				// pan = pan.lag(panLag);
				// mix = VarLag.kr(mix, mixLag, 0);
				mix = mix.lag(mixLag);
				density = VarLag.kr(density, densityLag, 0);
				// density = density.lag(densityLag);
				// dord = density;
				// dur = dur.lag(durLag);
				dur = VarLag.kr(dur, durLag, 0);
				dry = In.ar(in, 1);
				// trigger = Impulse.kr(density);
				// wet = 2.collect({
				// 	arg i;
				// 	GrainIn.ar(1, trigger, dur, dry[i], (-1) + (i * 2));
				// });
				sigL = GrainIn.ar(1, Impulse.kr(density*LFNoise1.kr(rand).range(0.8, 1.2)), dur, dry, -1);
				// sigR = GrainIn.ar(1, Impulse.kr(density*LFNoise1.kr(rand).range(0.8, 1.2)), dur, dry[1], 1);
				// density.postln;
				wet = sigL;
				// wet = Balance2.ar(sigL, sigR, pan);
				sig = XFade2.ar(dry, wet, mix);
				Out.kr(panKBus, pan);
				Out.kr(densityKBus, density);
				Out.kr(durKBus, dur);
				Out.kr(mixKBus, mix);
				Out.ar(out, sig);
			}).add;
		);
		~synthDefIO[\grain] = Dictionary.newFrom([\inChannels, 1, \outChannels, 1, \group, ~effectGroup]);
		~synthDefArgs[\grain] = Dictionary.newFrom([\in, nil, \out, 0, \density, 10, \rand, 1, \dur, 0.01, \mix, 1, \pan, 0]);
		~synthDefGUIs[\grain] = {
			arg synth;
			var toggle,
			density, dur, mix,
			dordTitle, dordSlider, dordBox,
			durTitle, durSlider, durBox,
			mixTitle, mixSlider, mixBox,
			panSlider, panBox, pan,
			gui, setArgVals,
			out;
			density = ~synthArgs[synth][\density];
			dur = ~synthArgs[synth][\dur];
			mix = ~synthArgs[synth][\mix];
			pan = ~synthArgs[synth][\pan];

			panSlider = Slider(w)
			.canFocus_(false)
			.fixedHeight_(20)
			.background_(Color.gray(0.8, 0.1))
			.value_(pan.linlin(-1, 1, 0, 1))
			.orientation_(\horizontal)
			.action_({
				pan = panSlider.value.linlin(0, 1, -1, 1);
				synth.set(\pan, pan, \panLag, 0);
				~synthArgs[synth][\pan] = pan;
				~editCueSlider.(val:pan, slider:panSlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == panSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(pan.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = pan;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});
			panBox = TextField.new(w);


			dordSlider = Slider(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(density.linlin(4, 20, 0, 1))
			.action_({
				density = dordSlider.value.linlin(0, 1, 4, 20);
				dordBox.value_(density.round(0.1));
				// density.postln;
				synth.set(\density, density, \densityLag, 0);
				~synthArgs[synth][\density] = density;
				~editCueSlider.(val:density, slider:dordSlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == dordSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(density.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = density;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

			});

			// ~streamList[0][1].set(\density, 13);

			dordTitle = StaticText().string_("Density")
			.font_(Font(size:8))
			.align_(\center);

			dordBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(density)
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				dordBox.value_("");
			})
			.action_({
				density = dordBox.value.asFloat;
				dordSlider.value_(density.linlin(4, 20, 0, 1));
				synth.set(\density, density, \densityLag, 0);
				~synthArgs[synth][\density] = density;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			durTitle = StaticText().string_("Duration")
			.font_(Font(size:8))
			.align_(\center);

			durSlider = Slider.new(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(dur.linlin(0.01, 0.05, 0, 1))
			.action_({
				dur = durSlider.value.linlin(0, 1, 0.01, 0.05);
				durBox.value_(dur.round(0.001));
				synth.set(\dur, dur, \durLag, 0);
				~synthArgs[synth][\dur] = dur;
				~editCueSlider.(val:dur, slider:durSlider);

				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == durSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(dur.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = dur;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

				w.focus;
			});
			durBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(dur)
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				durBox.value_("");
			})
			.action_({
				dur = durBox.value.asFloat;
				durSlider.value_(dur.linlin(0.01, 0.05, 0, 1));
				synth.set(\dur, dur, \durLag, 0);
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			mixTitle = StaticText().string_("Dry/Wet")
			.font_(Font(size:8))
			.align_(\center);

			mixSlider = Slider.new(w)
			.canFocus_(false)
			.fixedWidth_(40)
			.background_(Color.gray(0.8, 0.1))
			.value_(mix.value.linlin(-1, 1, 0, 1))
			.action_({
				mix = mixSlider.value.linlin(0, 1, -1, 1);
				mixBox.value_(mix.round(0.01));
				synth.set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~editCueSlider.(val:mix, slider:mixSlider);
				// if(~editWindow.isNil == false, {
				// 	if(~editWindow.isClosed == false, {
				// 		var row, boxIndex, rowIndex, box;
				// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				// 		if(~cueNumber == -1, {
				// 			rowIndex = 0;
				// 			}, {
				// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				// 			}
				// 		);
				// 		~setArgs.do({
				// 			arg set, i;
				// 			var candidate;
				// 			// i.postln;
				//
				// 			if (i > 0, {
				// 				candidate = set[\slider];
				// 				// candidate.postln;
				// 				if (candidate == mixSlider, {
				// 					boxIndex = set[\index];
				// 					box = ~cueBoxes[rowIndex][boxIndex];
				// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
				// 					box.value_(mix.round(0.01));
				// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = mix;
				// 				});
				// 			});
				// 		});
				// 	});
				// });

				w.focus;

			});
			mixBox = TextField.new(w)
			.fixedWidth_(40)
			.value_(mix)
			.mouseDownAction_({
				~setGUIs.stop;
				~synthSetArgs[synth].stop;
				mixBox.value_("");
			})
			.action_({
				mix = mixBox.value.asFloat;
				mixSlider.value_(mix.linlin(-1, 1, 0, 1));
				synth.set(\mix, mix, \mixLag, 0);
				~synthArgs[synth][\mix] = mix;
				~synthSetArgs[synth].reset;
				~setGUIs.reset;
				AppClock.play(~synthSetArgs[synth]);
				AppClock.play(~setGUIs);
				w.focus;
			});

			// ~setGUIs.stop;

			gui = VLayout(
				// toggle = Button(w)
				// .states_([["Grains",Color.green, ~buttonColor],["FluxDelay",Color.gray, ~buttonColor]])
				// .canFocus_(false)
				// .action_({
				// 	arg button;
				// 	var value;
				// 	value = button.value;
				// 	if (value == 0, {
				// 		synth.set(\mix, 1);
				// 	});
				// 	if (value == 1, {
				// 		synth.set(\mix, -1);
				// 	});
				// }),

				StaticText().string_("Grains")
				.font_(Font(size:18))
				.align_(\center),
				// panSlider,
				HLayout(
					VLayout(
						dordTitle,
						dordSlider,
						dordBox,
					),
					VLayout(
						durTitle,
						durSlider,
						durBox
					),
					VLayout(
						mixTitle,
						mixSlider,
						mixBox
					),
				)
			);

			setArgVals = Routine.new({
				var density, dur, mix, pan;
				{
					/*I don't know why this needs me to go -14!*/
					density = ~synthArgs[synth][\densityKBus].getSynchronous;
					// density.postln;
					// ~synthArgs[synth][\density].postln;
					// density2.postln;
					dur = ~synthArgs[synth][\durKBus].getSynchronous;
					// dur.postln;
					mix = ~synthArgs[synth][\mixKBus].getSynchronous;
					// pan = ~synthArgs[synth][\panKBus].getSynchronous;
					~synthArgs[synth][\density] = density;
					~synthArgs[synth][\dur] = dur;
					~synthArgs[synth][\mix] = mix;
					// ~synthArgs[synth][\pan] = pan;

					// synth.get(\density, {
					// 	arg density;
					// 	~synthArgs[synth][\density] = density;
					// 	// density.postln;
					// });
					// synth.get(\dur, {
					// 	arg dur;
					// 	~synthArgs[synth][\dur] = dur;
					// });
					// synth.get(\mix, {
					// 	arg mix;
					// 	~synthArgs[synth][\mix] = mix;
					// });
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);

			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\dordSlider, dordSlider,
				\dordBox, dordBox,
				\durSlider, durSlider,
				\durBox, durBox,
				0, \density,
				1, \dur,
				2, \mix,
				// 3, \pan,
				\numArgs, 3,
				// \setArgs, [\density, \dur],
				\density, (
					\slider: dordSlider,
					\box: dordBox,
					\sliderConvert: {
						arg val;
						val.linlin(4, 20, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\dur, (
					\slider: durSlider,
					\box: durBox,
					\sliderConvert: {
						arg val;
						val.linlin(0.01, 0.05, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\mix, (
					\slider: mixSlider,
					\box: mixBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				),
				\pan, (
					\slider: panSlider,
					\box: panBox,
					\sliderConvert: {
						arg val;
						val.linlin(-1, 1, 0, 1);
					},
					\boxConvert: {
						arg val;
						val.round(0.01);
					}
				)

			]);

		};
		// ~streamList[0][1].get(\density, {
		// 	arg density;
		// 	density.postln;
		// });
		~synthDefSetArgs[\grain] = [\density, \dur, \mix];
		~synthList[\grain] = "Granulator. Subtly fluctuating grain rate.\nInputs: 1\nOutputs: 1";
		// ~synthDefGUIs[\grain].();

		// (
		// 	SynthDef(\memDelay, {
		// 		arg deltime = 0.1, decaytime = 4, trighz = 12, amp = 1, ampLag = 0, in = 0, out = 0,
		// 		graindurmin = 0.05, graindurmax = 0.1, pan = 1, mix = 0.25, sus = 5, dec = 5;
		// 		var sig, echo, rev, env;
		// 		amp = amp.lag(ampLag);
		// 		sig = In.ar(in, 1);
		//
		// 		env = EnvGen.kr(Env([0.7,1,0],[sus,dec],[0,-2]), doneAction: 2);
		//
		// 		echo = CombN.ar(
		// 			in: sig,
		// 			maxdelaytime: 1,
		// 			delaytime: deltime,
		// 			decaytime: decaytime,
		// 		);
		//
		// 		echo = GrainIn.ar(
		// 			numChannels: 2,
		// 			trigger: Dust.kr(trighz),
		// 			dur: LFNoise1.kr(100).range(graindurmin, graindurmax),
		// 			in: echo,
		// 			pan: LFNoise0.kr().bipolar(pan)
		// 		);
		//
		// 		sig = XFade2.ar(sig, echo, mix*2-1, amp) * env;
		// 		Out.ar(out, sig);
		// 	}).add;
		// );


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
		~synthDefIO[\eq] = Dictionary.newFrom([\inChannels, 2, \outChannels, 2, \group, ~effectGroup]);
		~synthDefArgs[\eq] = Dictionary.newFrom([\hiFreq, 1200, \midFreq, 600, \lowFreq, 300, \hidB, 0, \middB, 0, \lodB, 0, \in, nil, \out, 0]);

		(
			SynthDef.new(\playBuf, {
				arg buf, rate = 1, amp = 1,
				startPos = 0, endPos = 1, numFrames,
				loop = 0,
				ampLag,
				ampKBus,
				doneAction = 2,
				// ampKBus,
				// recOut,
				out = 0;
				var sig, pos;
				sig = PlayBuf.ar(2, buf, rate*BufRateScale.ir(buf), startPos:startPos.linlin(0, 1, 0, numFrames), loop:loop, doneAction:doneAction);
				// pos = Line.ar(startPos, endPos, (abs(numFrames/s.sampleRate*(endPos-startPos)/rate)), doneAction:2);
				amp = amp.lag(ampLag);
				sig = sig * amp;

				Out.kr(ampKBus, amp);
				// Out.kr(ctrlOut, pos);
				// Out.ar(recOut, sig);
				Out.ar(out, sig);
			}).add;
		);
		~synthDefArgs[\playBuf] = Dictionary.newFrom([\rate, 1, \amp, 1, \loop, 1, \doneAction, 2]);

		// (
		// 	SynthDef.new(\recordBuf, {
		// 		arg in0, in1, buf, amp = 1;
		// 		var sig;
		// 		amp = amp.lag(2);
		// 		sig = XFade2.ar(In.ar(in0, 1), In.ar(in1, 1), 0);
		// 		sig = sig*amp;
		// 		RecordBuf.ar(sig!2, buf);
		// 	}).add;
		// );

		(
			SynthDef.new(\mainAmp, {
				arg in, amp = 1, ampLag = 0, ampKBus;
				var sig, out = 0, ampOut;
				amp = amp.lag(ampLag);
				sig = In.ar(in, 2);
				// ampOut = XLine.kr();
				sig = sig * amp;
				sig = Limiter.ar(sig);
				Out.kr(ampKBus, amp);
				// Out.ar(recOut, sig);
				Out.ar(out, sig);
			}).add;
		);
		~synthDefIO[\mainAmp] = Dictionary.newFrom([\inChannels, 2, \outChannels, 2, \kBuses, [\ampKBus], \group, ~outputGroup]);
		~synthDefArgs[\mainAmp] = Dictionary.newFrom([\in, nil, \out, 0, \amp, 1, \ampLag, 0]);
		~synthDefGUIs[\mainAmp] = {
			arg synth;
			var slider, box, boxValue, boxString, ampValue,
			sliderConvert, boxConvert,
			gui, setArgVals,
			out;
			ampValue = ~synthArgs[synth][\amp];
			boxString = ampValue.ampdb.asString;
			gui = VLayout(
				StaticText().string_("Main")
				.font_(Font(size:18))
				.align_(\center),
				slider = Slider(w)
				.fixedWidth_(70)
				.minHeight_(200)
				.background_(Color.gray(0.8, 0.1))
				.value_(ampValue.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
				.orientation_(\vertical)
				.action_({
					ampValue = slider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
					~synthArgs[synth][\amp] = ampValue;
					// ~synthArgs[synth][\amp].postln;
					boxConvert = {
						arg ampValue;
						var boxValue;
						boxValue = ampValue.ampdb.round(0.1);
						if (boxValue >= 0, {
							boxString = "+" ++ boxValue.asString;
						}, {
							boxString = boxValue.asString;
						});
						boxString = boxString + "dB";
					};

					~editCueSlider.(val: ampValue, slider:slider, convert:boxConvert);
					// if (~editWindow.isNil == false, {
					// 	if(~editWindow.isClosed == false, {
					// 		var row, boxIndex, rowIndex, box;
					// 		// rowIndex = (~cueSelect.value + 1);
					// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
					// 		if(~cueNumber == -1, {
					// 			rowIndex = 0;
					// 			}, {
					// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
					// 			}
					// 		);
					// 		~setArgs.do({
					// 			arg set, i;
					// 			var candidate;
					// 			// i.postln;
					// 			if (i > 0, {
					// 				candidate = set[\slider];
					// 				// candidate.postln;
					// 				if (candidate == slider, {
					// 					boxIndex = set[\index];
					// 					box = ~cueBoxes[rowIndex][boxIndex];
					// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
					// 					box.value_(boxString + "dB");
					// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = ampValue;
					//
					// 				});
					// 			});
					// 		});
					// 	});
					// });

					synth.set(\amp, ampValue, \ampLag, 0);
					box.value_(boxString);
				}),
				box = TextField(w)
				.fixedWidth_(70)
				.value_(ampValue.ampdb.asString + "dB")
				.mouseDownAction_({
					~setGUIs.stop;
					~synthSetArgs[synth].stop;
					box.value_("");
				})
				.action_({
					var input, outString, diff, lag;
					if(box.value == "", {
						box.value_(ampValue.ampdb.round(0.1)).asString + "dB";
					});
					if(~cleanBoxInput.(box.value) == false, {
						box.value_(ampValue.ampdb.round(0.1)).asString + "dB";
					});
					input = box.value.asFloat;
					input = input.clip(-40, 15);
					slider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
					ampValue = input.dbamp;
					~synthArgs[synth][\amp] = ampValue;
					if (input >= 0, {
						outString = "+" ++ input.round(0.1).asString + "dB";
					}, {
						outString = input.round(0.1).asString + "dB";
					});
					box.value_(outString);
					synth.set(\amp, ~synthArgs[synth][\amp], \ampLag, 0);
					~synthSetArgs[synth].reset;
					~setGUIs.reset;
					AppClock.play(~synthSetArgs[synth]);
					AppClock.play(~setGUIs);
					w.focus;
				});
			);
			setArgVals = Routine.new({
				var amp;
				{
					amp = ~synthArgs[synth][\ampKBus].getSynchronous;
					~synthArgs[synth][\amp] = amp;
					// synth.get(\amp, {
					// arg amp;
					// amp.postln;
					// slider.value_(amp.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp));
					// ~synthArgs[synth][\amp] = amp;
					// });
					// amp.postln;
					0.01.wait;
				}.loop;
			});
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);
			out = Dictionary.newFrom([
				\synth, synth,
				\gui, gui,
				\slider, slider,
				\box, box,
				0, \amp,
				\numArgs, 1,
				// \setArgs, [\amp],
				\amp, (
					\slider: slider,
					\box: box,
					\sliderConvert: {
						arg val;
						val.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1)
					},
					\boxConvert: {
						arg val;
						var boxString, boxValue;
						boxString = "";
						boxValue = val.ampdb.round(0.1);
						if (boxValue >= 0, {
							boxString = "+" ++ boxValue.asString;
						}, {
							boxString = boxValue.asString;
						}
						);
						boxString = boxString + "dB";
						boxString;

					};
				),

			]);
		};
		~synthDefSetArgs[\mainAmp] = [\amp];

		~synthDefGUIs[\playBuf] = {
			arg synth;
			var slider, box, boxValue, boxString, ampValue,
			sliderConvert, boxConvert,
			gui, setArgVals,
			out;
			ampValue = ~bufAmp;
			boxString = ampValue.ampdb.asString;
			gui = VLayout(
				StaticText().string_("Buf")
				.font_(Font(size:18))
				.align_(\center),
				slider = Slider(w)
				.fixedWidth_(70)
				.minHeight_(200)
				.background_(Color.gray(0.8, 0.1))
				.value_(ampValue.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
				.orientation_(\vertical)
				.action_({
					ampValue = slider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
					~bufAmp = ampValue;
					~synthArgs[synth][\amp] = ampValue;
					boxConvert = {
						arg ampValue;
						var boxValue;
						boxValue = ampValue.ampdb.round(0.1);
						if (boxValue >= 0, {
							boxString = "+" ++ boxValue.asString;
						}, {
							boxString = boxValue.asString;
						});
						boxString = boxString + "dB";
					};
					~editCueSlider.(val: ampValue, slider:slider, convert:boxConvert);

					// if (~editWindow.isNil == false, {
					// 	if(~editWindow.isClosed == false, {
					// 		var row, boxIndex, rowIndex, box;
					// 		// rowIndex = (~cueSelect.value + 1);
					// 		// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
					// 		if(~cueNumber == -1, {
					// 			rowIndex = 0;
					// 			}, {
					// 				rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
					// 			}
					// 		);
					// 		~setArgs.do({
					// 			arg set, i;
					// 			var candidate;
					// 			// i.postln;
					// 			if (i > 0, {
					// 				candidate = set[\slider];
					// 				// candidate.postln;
					// 				if (candidate == slider, {
					// 					boxIndex = set[\index];
					// 					box = ~cueBoxes[rowIndex][boxIndex];
					// 					~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
					// 					box.value_(boxString + "dB");
					// 					~cueList[~mvtSelect.value][rowIndex][boxIndex] = ampValue;
					//
					// 				});
					// 			});
					// 		});
					// 	});
					// });

					synth.set(\amp, ampValue, \ampLag, 0);
					~bufGroup.set(\amp, ampValue, \ampLag, 0);
					box.value_(boxString);
				}),
				box = TextField(w)
				.fixedWidth_(70)
				.value_(ampValue.ampdb.asString + "dB")
				.mouseDownAction_({
					~setGUIs.stop;
					box.value_("");
				})
				.action_({
					var input, outString, diff, lag;
					if(box.value == "", {
						box.value_(ampValue.ampdb.round(0.1)).asString + "dB";
					});
					if(~cleanBoxInput.(box.value) == false, {
						box.value_(ampValue.ampdb.round(0.1)).asString + "dB";
					});
					input = box.value.asFloat;
					input = input.clip(-40, 15);
					slider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
					ampValue = input.dbamp;
					~synthArgs[synth][\amp] = ampValue;
					~bufAmp = ampValue;
					if (input >= 0, {
						outString = "+" ++ input.round(0.1).asString + "dB";
					}, {
						outString = input.round(0.1).asString + "dB";
					});
					box.value_(outString);
					synth.set(\amp, ~synthArgs[synth][\amp], \ampLag, 0);
					~bufGroup.set(\amp, ~bufAmp, \ampLag, 0);
					~synthSetArgs[synth].reset;
					~setGUIs.reset;
					AppClock.play(~synthSetArgs[synth]);
					AppClock.play(~setGUIs);
					w.focus;
				});
			);
			setArgVals = Routine.new({
				var amp;
				{
					amp = ~synthArgs[synth][\ampKBus].getSynchronous;
					// amp.postln;
					~synthArgs[synth][\amp] = amp;
					// synth.get(\amp, {
					// arg amp;
					// amp.postln;
					// slider.value_(amp.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp));
					// ~synthArgs[synth][\amp] = amp;
					// });
					// amp.postln;
					0.01.wait;
				}.loop;
			});ˇ
			~synthSetArgs[synth] = setArgVals;
			AppClock.play(setArgVals);
			out = Dictionary.newFrom([
				// \synth, synth,
				\gui, gui,
				\slider, slider,
				\box, box,
				0, \amp,
				\numArgs, 1,
				// \setArgs, [\amp],
				\amp, (
					\slider: slider,
					\box: box,
					\sliderConvert: {
						arg val;
						val.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1)
					},
					\boxConvert: {
						arg val;
						var boxString, boxValue;
						boxString = "";
						boxValue = val.ampdb.round(0.1);
						if (boxValue >= 0, {
							boxString = "+" ++ boxValue.asString;
						}, {
							boxString = boxValue.asString;
						}
						);
						boxString = boxString + "dB";
						boxString;

					};
				),

			]);

		};
		~synthDefSetArgs[\playBuf] = [\amp];
		~synthDefArgs[\playBuf] = [\amp, 1, \ampLag, 2];


	};
	// ~bufDict[0][-1].set(\amp, 0.2);
	~loadGroups = {
		~bufGroup = Group.new(addAction:'addToHead');
		~inputGroup = Group.new(addAction:'addToHead');
		~effectGroup = Group.new(addAction:'addToTail');
		~outputGroup = Group.new(addAction:'addToTail');
	};

	~loadGroups.();
	~loadSynths.();
	~filePath = "";
	// ~filePath = "/Users/vzhyu/Documents/qFlo/Base/project7.flo";
	~configFile = File.new(~filePath, "r");
	// ~configFile.isOpen.postln;
	// ~configFile = File.new("text.flo".resolveRelative, "r");
	// ~configFile.readAllString;
	1.wait;
	s.sync;
	~synthArgs = Dictionary();
	~synthGUIs = Dictionary();

	// ~streamList[0][1].set(\pan, 0.2);
	~init = {
		var configFile, configString, configList,
		seqString, seqList,
		initString, initList,
		cueString, cueList,
		lagString, lagList,
		streamList;

		// ~recbuf = 10.collect({Buffer.alloc(s, s.sampleRate * 10, 1) });
		// ~indBufGroup = Group.new(addAction:'addToHead');
		// ~tempGroup = Group.new(addAction:'addToTail');
		// ~dirMicBus = Bus.audio(s, 2);
		// ~bufBus = Bus.audio(s, 2);
		// ~reverbBus = Bus.audio(s, 2);
		// ~grainBus = Bus.audio(s, 2);
		// ~delayBus = Bus.audio(s, 1);
		// ~panBus = Bus.audio(s, 1);
		// ~voxEQBus = Bus.audio(s, 2);
		// ~eqBus = Bus.audio(s, 2);
		~outBus = Bus.audio(s, 2);
		~dummyKBus = Bus.control(s, 1);
		//
		// ~bufRecordBus = Bus.audio(s, 2);
		// ~micRecordBus = Bus.audio(s, 2);
		// ~leRecordBus = Bus.audio(s, 2);
		// ~mainRecordBus = Bus.audio(s, 2);
		//
		// ~micAmpBus = Bus.control(s, 1);
		// ~bufAmpBus = Bus.control(s, 1);
		// ~revTimeBus = Bus.control(s, 1);
		// ~revDampBus = Bus.control(s, 1);
		// ~revMixBus = Bus.control(s, 1);
		// ~grainDordBus = Bus.control(s, 1);
		// ~grainDurBus = Bus.control(s, 1);
		//
		// ~ampCtrlBus = Bus.control(s, 1);
		// ~nPlayBus = Bus.control(s, 1);
		// ~panCtrlBus = Bus.control(s, 1);

		~time = 0;
		~clockStarted = false;
		~clockRunning = false;

		~cueNumber = 0;

		// ~recBuf = Buffer.alloc(s, 5*s.sampleRate, 2);
		// ~decayBus0 = Bus.control(s, 1);
		// ~decayBus1 = Bus.control(s, 1);
		// ~decayBus;
		// ~timeBus = Bus.control(s, 1);
		// ~mixBus = Bus.control(s, 1);
		~delayStatus = 1;
		~grainStatus = 0;
		~delayAmp = 1;
		~micAmp = 0.dbamp;
		~dirMicAmp = 0.dbamp;
		// ~bufAmp = -12.dbamp;
		~bufAmp = 1;
		~mainAmp = 0.dbamp;
		~ampMin = -30;
		~ampMax = 12;

		~bufIndex = -1;

		// ~revTime = 2;
		~revTime = 3.5;
		// ~revTime = 1;
		// ~revDamp = 0.7;
		~revDamp = 0.5;
		// ~revDamp = 0;
		// ~roomSize = 100;
		//(Revert to old values for mvt. 1 if necessary, mix = 0.5)
		//reverb, 0.2 time, 0 damp
		~revMix = 0.25;
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

		~bufRecord = Recorder.new(s);
		~micRecord = Recorder.new(s);
		~leRecord = Recorder.new(s);
		~mainRecord = Recorder.new(s);

		~bufRecord.filePrefix = "BUF";
		~micRecord.filePrefix = "MIC";
		~leRecord.filePrefix = "LE";
		~mainRecord.filePrefix = "MAIN";

		~currentDrag = [];
		~destDrag = [];

		~streamList = [];
		~guiList = [];
		// ~bufDict = ();

		// ~cueSelect.value;
		~cueRows = [];
		~cueBoxes = ();
		~lagCueBoxes = ();

		~nowPlaying = Dictionary.new();
		// ~cueRows[2].background_(~buttonColor);

		// ~bufRecord.prepareForRecord(numChannels:2);
		// ~micRecord.prepareForRecord(numChannels:2);
		// ~leRecord.prepareForRecord(numChannels:2);
		// ~mainRecord.prepareForRecord(numChannels:2);

		// ~nPosValue = 0;
		~newFolderPath = "";
		~newStreamList = [];
		~newCues = [];
		~newLags = [];

		~curDirPathStr = "";
		~curStreamStr = "";
		~curCuesStr = "";
		~curLagsStr = "";
		~curFileStr = "";

		~newDirPathStr = "";
		~newStreamStr = "";
		~newCuesStr = "";
		~newLagsStr = "";
		~newFileStr = "";

		~configFile = File.new(~filePath, "r");

		configFile = ~configFile;
		if (~configFile.isOpen == false, {
			configString = "\n\n\n";
		}, {
			configString = configFile.readAllString;
		}
		);
		configList = configString.split($\n);
		seqString = configList[0];
		~curDirPathStr = seqString;
		seqList = seqString.split($|);
		// seqList.postln;
		~pathList = seqList;
		if (~pathList == [], {

		});
		~bufDict = ~pathList.collect({
			arg n, i;
			(
				name:n;
			);
		});

		initString = configList[1];
		// if (initString == "", {
		// 	initString = "reverb";
		// });
		if (initString == "", {
			initString = "pan;reverb";
		});
		~curStreamStr = initString;
		// configList.postln;
		// cueString.postln;
		// cueString = cueFile.readAllString;
		initList = initString.split($|);
		// initList.postln;
		streamList = initList.collect({
			arg streamString;
			var streamList;
			streamList = streamString.split($;);
			streamList = streamList.collect({
				arg synthDefString;
				var synthDef;
				synthDef = synthDefString.asSymbol;
			});

		});
		streamList.do({
			arg stream;
			var micIn, mainOut, playBufGUI, playBuf, playBufKBus;
			stream = stream.collect({
				arg synthName, i;
				var group, synth, gui, controls;
				// synth.postln;
				// ~synthDefIO[synth][\group].postln;
				group = ~synthDefIO[synthName][\group];
				if(synthName == \fluxDelay, {
					synth = Synth.new(synthName, target:group, addAction:\addToTail);
					~fluxDelayPairs[synth] = (\synth: Synth.new(synthName, [\amp, 0], target:group, addAction:\addToTail));
					~fluxDelayPairs[synth][\routine] = Routine.new({
						{
							var mul0, mul1, mul2, mul3, mul4, mul5;
							mul0 = rrand(0.3, 1.6);
							mul1 = rrand(0.3, 1.6);
							mul2 = rrand(0.3, 1.6);
							mul3 = rrand(0.3, 1.6);
							mul4 = rrand(0.3, 1.6);
							mul5 = rrand(0.3, 1.6);
							synth.set(\amp, 0);
							// synth.get(\amp, {arg amp; amp.postln});
							// "set1".postln;
							~fluxDelayPairs[synth][\synth].set(\amp, 1);
							// ~fluxDelayPairs[synth][\synth].get(\amp, {arg amp; amp.postln;});
							// ~fluxDelayPairs[synth][\synth].postln;
							1.wait;

							synth.set(\mul0, mul0, \mul1, mul1, \mul2, mul2);
							rrand(0.4, 2).wait;
							synth.set(\amp, 1);
							// synth.get(\amp, {arg amp; amp.postln});
							// "set0".postln;
							~fluxDelayPairs[synth][\synth].set(\amp, 0);
							// ~fluxDelayPairs[synth][\synth].get(\amp, {arg amp; amp.postln;});


							1.wait;
							~fluxDelayPairs[synth][\synth].set(\mul0, mul3, \mul1, mul4, \mul2, mul5);
							rrand(0.4, 2).wait;
						}.loop;

					}).play;

				}, {
					synth = Synth.new(synthName, target:group, addAction:\addToTail);
				});
				~synthArgs[synth] = Dictionary.new();
				// synth.defName.postln;
				~synthDefArgs[synth.defName].keysValuesDo({
					arg key, value;
					// [key, value].postln;
					if (~synthDefSetArgs[synth.defName].includes(key), {
						// key.postln;
						var kArg, kBus, pairBus;
						kArg = key.asString ++ "KBus";
						kArg = kArg.asSymbol;
						kBus = Bus.control(s, 1);
						// 4.do({
						// 	Bus.control(s, 1);
						// });
						synth.set(kArg, kBus);
						if(synth.defName == \fluxDelay, {
							pairBus = Bus.control(s, 1);
							~fluxDelayPairs[synth][\synth].set(kArg, pairBus);
						});
						// kArg.postln;
						~synthArgs[synth][kArg] = kBus;
						// ~synthArgs[synth].postln;
						// kBus.getSynchronous.postln;
					});
					if(key != \in, {
						if (key != \out, {
							~synthArgs[synth][key] = value;
						});
					});
				});
				gui = ~synthDefGUIs[synth.defName].(synth);
				// controls = gui[\numArgs].collect({
				// 	arg i;
				// 	var control;
				// 	// i.postln;
				// 	control = gui[gui[i]];
				// 	// i.postln;
				// 	// control.postln;
				// });
				// controls.postln;
				~guiList = ~guiList.add(gui[\gui]);
				~synthGUIs[synth] = gui;
				// AppClock.play({~synthDefGUIs[synth.defName].()});
				synth;

			});
			// stream.postln;
			micIn = Synth.new(\micIn, [\in, 0], target:~inputGroup, addAction:'addToHead');
			mainOut = Synth.new(\mainAmp, target:~outputGroup, addAction:'addToTail');
			[micIn, mainOut].do({
				arg synth, i;
				var gui, kBus;
				~synthArgs[synth] = Dictionary.new();
				// synth.defName.postln;
				kBus = Bus.control(s, 1);
				synth.set(\ampKBus, kBus);
				~synthArgs[synth][\ampKBus] = kBus;
				~synthDefArgs[synth.defName].keysValuesDo({
					arg key, value;
					// [key, value].postln;
					if(key != \in, {
						if (key != \out, {
							~synthArgs[synth][key] = value;
						});
					});
				});
				gui = ~synthDefGUIs[synth.defName].(synth);
				if(i == 0, {
					~guiList = ~guiList.insert(0, gui[\gui]);
				}, {
					~guiList = ~guiList.add(gui[\gui]);
				}
				);
				~synthGUIs[synth] = gui;

			});
			// "hi".postln;
			playBufKBus = Bus.control(s, 1);
			playBuf = Synth(\playBuf, [\buf, ~blankBuf, \loop, 1, \doneAction, 2, \ampKBus, playBufKBus], ~inputGroup);
			// playBuf.postln;
			playBufGUI = ~synthDefGUIs[\playBuf].(playBuf);
			~synthArgs[playBuf] = Dictionary.new();
			~synthArgs[playBuf][\amp] = ~bufAmp;
			~synthArgs[playBuf][\ampKBus] = playBufKBus;
			~synthGUIs[playBuf] = playBufGUI;
			~guiList = ~guiList.insert(0, playBufGUI[\gui]);
			~bufDict[~mvt][-1] = playBuf;

			// ~synthArgs[micIn] = Dictionary.new();
			stream = stream.insert(0, micIn);
			stream = stream.add(mainOut);


			~streamList = ~streamList.add(stream);
		});
		~streamList.do({
			arg stream;
			// stream.size.postln;

			stream.do({
				arg synth, i;
				var synthName, inChannels, outChannels, prevSynth;
				// i.postln;
				if(i>0, {
					prevSynth = stream[i-1];
				});
				// prevSynth.postln;
				// synth.postln;
				synthName = synth.defName;
				inChannels = ~synthDefIO[synthName][\inChannels];
				outChannels = ~synthDefIO[synthName][\outChannels];
				// synthName.postln;
				// inChannels.postln;
				// outChannels.postln;
				if(synth.group == ~inputGroup, {
					// synth.postln;
					var out;
					// i.postln;
					out = Bus.audio(s, outChannels);
					// out.postln;
					synth.set(\in, 0);
					synth.set(\out, out);
					~synthArgs[synth][\in] = 0;
					~synthArgs[synth][\out] = out;
				});
				if(synth.group == ~effectGroup, {
					var in, out;
					// in = Bus.audio(s, inChannels);
					if(i < (stream.size - 1), {
						in = ~synthArgs[prevSynth][\out];
						out = Bus.audio(s, outChannels);
						// i.postln;
						// in.postln;
						// out.postln;
						synth.set(\in, in, \out, out);
						~synthArgs[synth][\in] = in;
						~synthArgs[synth][\out] = out;
						if(synth.defName == \fluxDelay, {
							~fluxDelayPairs[synth][\synth].set(\in, in, \out, out);
						});
					});

				});
				if(synth.group == ~outputGroup, {
					var in;
					// i.postln;
					// "haisdhaks".postln;
					in = ~synthArgs[prevSynth][\out];
					~bufOut = in;
					synth.set(\in, in, \out, 0);
					~synthArgs[synth][\in] = in;
					~synthArgs[synth][\out] = 0;
					// ~mainOut = Synth(\mainAmp, [\in, ~outBus], ~outputGroup, \addToTail);
				});
				// ~synthArgs[synth].postln;
			});
		});
		// ~cueList[0].size;
		cueString = configList[2];
		if (cueString == "", {
			// "hi".postln;
			cueString = "0,1,1,0,1,1,1,1";
		});
		~curCueStr = cueString;
		cueList = cueString.split($|);
		// cueList.postln;
		cueList = cueList.collect({
			arg list;
			// var cue;
			list = list.split($;);
			list = list.collect({
				arg cue;
				cue = cue.split($,);
			});
		});
		// cueList.postln;

		~cueList = cueList;

		lagString = configList[3];
		if(lagString == "", {
			lagString = "0,0,0,0,0,0,0,0"
		});
		~curLagStr = lagString;
		lagList = lagString.split($|);
		lagList = lagList.collect({
			arg list;
			// var cue;
			list = list.split($;);
			list = list.collect({
				arg cue;
				cue = cue.split($,);
			});
		});

		// lagList.insert(0, \);
		~lagList = lagList;
		// ~cues = cueList.collect({
		// 	arg subList;
		// 	subList = subList.collect({
		// 		arg cue;
		// 	});
		// });

		// ~streamList[0].do({
		// 	arg synth;
		// 	synth.postln;
		// 	~synthArgs[synth][\in].postln;
		// 	~synthArgs[synth][\out].postln;
		// 	// synth.get(\in, {arg val; val.postln;});
		// 	// synth.get(\out, {arg val; val.postln;});
		// });
		// ~synthArgs[~streamList[0][0]];
		// ~streamList.do({
		// 	arg i;
		// 	i.postln;
		// 	i.do({
		// 		arg j;
		// 		j.get(\in, {arg out; out.postln});
		//
		// 		j.get(\out, {arg out; out.postln});
		// 		~synthArgs[j][\in].postln;
		// 		~synthArgs[j][\out].postln;
		// 	})
		// });
		// ~streamList.postln;
		// ~in = Synth(\micIn, [\amp, ~micAmp, \out, ~voxEQBus], target:~inputGroup);
		// ~in = Synth(\mic, [
		// 	\in, 0,
		// 	\out, ~dirMicBus,
		// 	\outrev, ~reverbBus,
		// 	\amp, 1,
		// 	\fxamp, 1,
		// 	\revamp, ~dirMicAmp,
		// 	\recOut, ~micRecordBus,
		// ], target:~inputGroup);

		// ~delay0 = Synth(\delay, [
		// 	\in, ~delayBus,
		// 	\out, ~grainBus,
		// 	\decay, 3,
		// 	\bandwidth, 4,
		// 	\amp, 1,
		// ], target:~effectGroup, addAction:'addToTail');
		// ~delay1 = Synth(\delay, [
		// 	\in, ~delayBus,
		// 	\out, ~grainBus,
		// 	\decay, 3,
		// 	\bandwidth, 4,
		// 	\amp, 0,
		// ], target:~effectGroup, addAction:'addToTail');
		//
		// ~pan = Synth(\pan, [
		// 	\in, ~panBus,
		// 	\out, ~grainBus,
		// 	\panKBus, ~panCtrlBus
		// ], target:~effectGroup, addAction:'addToTail');

		// ~grain = Synth(\grain, [
		// 	\in, ~grainBus,
		// 	\out, ~reverbBus,
		// 	\mix, -1,
		// 	\density, ~grainDord,
		// 	\dur, ~grainDur,
		// 	\rand, ~grainRand,
		// ], target:~effectGroup, addAction:'addToTail');

		// ~reverb = Synth(\reverb, [
		// 	\in, ~reverbBus,
		// 	\out, ~outBus,
		// 	// \revTime, 4.34,
		// 	\mix, ~revMix,
		// 	\decay, ~revTime,
		// 	\damp, ~revDamp,
		// 	// \lpf, ~revDamp,
		// 	// \room, ~roomSize,
		// 	// \timeOut, ~timeBus,
		// 	// \mixOut, ~mixBus,
		// 	\recOut, ~leRecordBus,
		// ], target:~effectGroup, addAction:'addToTail');

		// ~voxEQ = Synth(\eq, [
		// 	\in, ~voxEQBus,
		// 	\out, ~outBus,
		// ], target:~effectGroup, addAction:'addToTail');
		//
		// ~eq = Synth(\eq, [
		// 	\in, ~eqBus,
		// 	\out, ~outBus,
		// ], target:~effectGroup, addAction:'addToTail');

		// ~mainOut = Synth(\mainAmp, [
		// 	\in, ~outBus,
		// 	\ctrlOut, ~ampCtrlBus,
		// 	\recOut, ~mainRecordBus,
		// 	\out, 0,
		// ], target:~outputGroup, addAction:'addToTail');
		// ~resetAction.();
		s.sync;
	};


	~init.();
	s.sync;
	// ~pathList = ["cueFiles"];
	~extensionList = ["wav", "aif", "aiff"];
	~loadPaths = {
		~paths = ~pathList.collect({
			arg i;
			PathName(i).entries.collect({
				arg j;
				// j.extension.postln;
				// ~extensionList.includesEqual(j.extension).postln;
				if (~extensionList.includesEqual(j.extension), {
					// j.postln;
					if (j.fileName[0] != "*", {
						j.fullPath;
					})
				});

			});
		});
	};





	// ~paths1 = PathName("6 - Toccata".resolveRelative).entries.collect({ |n|
	// 	// n.fullPath;
	// 	// n.extension.postln;
	// });

	// ~paths2 = PathName("Emile_Mov#2_Cues".resolveRelative).entries.collect({ |n|
	// 	n.fullPath;
	// })


	~loadBufs2 = {
		// var bufRead;
		~bufRead = ~paths.collect({
			arg path, i;
			var bufCollect, funcCollect;
			bufCollect = path.collect({
				arg path;
				Buffer.read(s, path);
			});

			funcCollect = bufCollect.collect({
				arg buf, j;
				(
					playfn: {
						// ~buf = { PlayBuf.ar(2, b[i].bufnum, BufRateScale.ir(b[i].bufnum), doneAction: 2)*(~bufAmp) };
						// ~bufAmp.postln;
						~bufDict[i][j+1] = Synth(\playBuf, [\buf, bufCollect[j].bufnum, \amp, ~bufAmp, \numFrames, bufCollect[j].numFrames, \out, ~bufOut, \ampKBus, ~dummyKBus], target:~bufGroup);
						// ~bufDict[i][j+1].set(\amp, ~bufAmp, \ampLag, 0);
						// ~buf.play(target:~bufGroup, fadeTime:0);
					},
					buf: buf,
					file: PathName(bufCollect[j].path).fileNameWithoutExtension,
					prevfile: if(
						bufCollect[j-1].notNil,
						{ PathName(bufCollect[j-1].path).fileNameWithoutExtension },
						{ "nil" }
					),
					nextfile: if(
						bufCollect[j+1].notNil,
						{ PathName(bufCollect[j+1].path).fileNameWithoutExtension },
						{ "nil" }
					),
					number: j+1,
					ctrlfn: {
						~cues[i][j+1].();
					},
					nextfn: {
						~cues[i][j+2].();
					}


				)
			});
		});
		// bufRead.postln;

		~files = ~bufRead[0];
		if(~files == [], {
			~files = ~files.add(
				(
					playfn:{},
					buf:nil,
					file:nil,
					prevfile:nil,
					nextfile:nil,
					number:0,
					ctrlfn:nil
				)
			)
		});

		~seq = Pseq(~files).asStream;

	};


	// ~loadBufs2.();

	// ~cues = ~bufRead.collect({
	// 	arg funcList;
	// 	funcList.collect({
	// 		arg func;
	// 		var fileNo, args;
	// 		fileNo = func[\number];
	// 		// fileNo.postln;
	// 		// ~streamList.do({
	// 		// 	arg stream;
	// 		// 	stream.do({
	// 		// 		arg synth;
	// 		//
	// 		// 	});
	// 		// });
	// 		args = ~streamList[0].collect({
	// 			arg synth, i;
	// 			var fullArgs, setArgs, out;
	// 			// synth.postln;
	// 			fullArgs = ~synthArgs[synth];
	// 			setArgs = ~synthDefSetArgs[synth.defName];
	// 			// setArgs.postln;
	// 			out = Dictionary.newFrom([synth, setArgs.collect({
	// 				arg argument, val;
	// 				((argument): fullArgs[argument]);
	// 			})]);
	// 			// setArgs = ~synthDefGUIs[synth.defName];
	//
	// 			// setArgs.().postln;
	// 			// fullArgs.postln;
	// 			// setArgs.collect({
	// 			// 	arg val;
	// 			// 	val.postln;
	// 			// 	// (val: fullArgs[setArgs])
	// 			// });
	// 		});
	// 		// ((fileNo): args);
	// 	});
	// 	//
	// });
	//
	// ~cues.do({
	// 	arg line;
	// 	line.do({
	// 		arg i;
	// 		i.do({
	// 			arg key;
	// 			key.postln;
	// 		});
	// 	});
	// });


	// ~cues.postln;
	s.sync;

	~randLo = 0.3;
	~randHi = 1.6;

	// "jkjkdsa44F4".asFloat;

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
	// ~change = Routine.new({
	// 	{
	// 		var mul0, mul1, mul2, mul3, mul4, mul5, mulAmp;
	// 		mulAmp = ~echoMul;
	// 		mul0 = rrand(~randLo, ~randHi)*mulAmp;
	// 		mul1 = rrand(~randLo, ~randHi)*mulAmp;
	// 		mul2 = rrand(~randLo, ~randHi)*mulAmp;
	// 		mul3 = rrand(~randLo, ~randHi)*mulAmp;
	// 		mul4 = rrand(~randLo, ~randHi)*mulAmp;
	// 		mul5 = rrand(~randLo, ~randHi)*mulAmp;
	// 		~delay0.set(\amp, 0);
	// 		~delay1.set(\amp, 1*~delayAmp);
	// 		// ~decayBus = ~decayBus1;
	// 		// "switch1".postln;
	// 		1.wait;
	// 		// ~delay0.set(\mul0, rrand(0.3, 1.6), \mul1, rrand(0.3, 1.6), \mul2, rrand(0.3, 1.6));
	// 		~delay0.set(\mul0, mul0, \mul1, mul1, \mul2, mul2);
	// 		// "change1".postln;
	//
	// 		rrand(0.4,2).wait;
	// 		~delay0.set(\amp, 1*~delayAmp);
	// 		~delay1.set(\amp, 0);
	// 		// ~decayBus = ~decayBus0;
	// 		// "switch0".postln;
	// 		1.wait;
	// 		// ~delay1.set(\mul0, rrand(0.3, 1.6), \mul1, rrand(0.3, 1.6), \mul2, rrand(0.3, 1.6));
	//
	// 		~delay1.set(\mul0, mul3, \mul1, mul4, \mul2, mul5);
	// 		// "change0".postln;
	// 		rrand(0.4, 2).wait;
	//
	//
	// 	}.loop;
	// }).play;

	// ~streamList[0][1].set(\dur, 0.02);

	// ~cues[0][2].();
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
	// ~dummyKBus.getSynchronous;
	~setGUIs = Routine.new({
		var playBuf, playBufArgs, playBufGUI, playBufSlider, playBufBox, playBufSliderInput, playBufBoxInput, playBufAmpVal;
		{

			playBuf = ~bufDict[~mvt][-1];

			playBufArgs = ~synthArgs[playBuf];
			playBufAmpVal = playBufArgs[\amp];
			playBufGUI = ~synthGUIs[playBuf];
			playBufSlider = playBufGUI[\amp][\slider];
			playBufBox = playBufGUI[\amp][\box];
			playBufSliderInput = playBufGUI[\amp][\sliderConvert].(val: playBufAmpVal);
			playBufBoxInput = playBufGUI[\amp][\boxConvert].(val:playBufAmpVal);
			playBufSlider.value_(playBufSliderInput);
			playBufBox.value_(playBufBoxInput);
			// ~bufAmp = playBufAmpVal;
			// ~streamList[0][1].set(\pan, -1);
			// ~synthArgs[~streamList[0][1]][\pan]
			// ~synthGUIs[~streamList[0][1]]
			~streamList.do({
				arg stream;
				stream.do({
					arg synth;
					var argDict, guiDict, numArgs, args;
					argDict = ~synthArgs[synth];
					guiDict = ~synthGUIs[synth];
					numArgs = guiDict[\numArgs];
					// synth.defName.postln;
					numArgs.do({
						arg i;
						var val, key, slider, box, sliderInput, boxInput;
						key = guiDict[i];
						val = argDict[key];
						// synth.postln;
						// key.postln;
						// val.postln;
						slider = guiDict[key][\slider];
						box = guiDict[key][\box];
						sliderInput = guiDict[key][\sliderConvert].(val: val);
						boxInput = guiDict[key][\boxConvert].(val: val);
						slider.value_(sliderInput);
						box.value_(boxInput);
					});
					// args.postln;

				});
			});
			0.01.wait;
		}.loop;
	});
	// ~streamList[0][2].set(\mix, 1);

	// ~streamList[0][1].set(\decay, inf);
	// ~nPlay = Routine.new({
	// 	{
	// 		var pos;
	// 		pos = ~nPlayBus.getSynchronous;
	// 		~nPosValue = pos;
	//
	// 		// pos.postln;
	// 		if(~nPosValue.round(0.001) == 1, {
	// 			// "reset".postln;
	// 			// ~controlSet.(~nPosControl, 0, \slider);
	// 			~playSlider.value_(0);
	// 			~nPosValue = 0;
	// 			~nPlayBus.setSynchronous(0);
	// 			// ~nPlayBus.getSynchronous.postln;
	// 			~setButtonState.(~nPlayButtonControls, 1);
	//
	// 			}, {
	// 				// pos.postln;
	// 				~playSlider.value_(pos);
	// 				// ~controlSet.(~nPosControl, pos.round(0.001), \box);
	// 			}
	// 		);
	// 		0.01.wait;
	// 	}.loop;
	// });
	//
	// ~setMicSlider = Routine.new({
	// 	var amp;
	// });

	// ~setAmpSlider = Routine.new({
	// 	{
	// 		var amp;
	// 		amp = ~ampCtrlBus.getSynchronous;
	// 		~mainAmpValue = amp;
	// 		~mainAmpBoxValue = ~mainAmpValue.ampdb.round(0.1);
	// 		// ~setMainAmp.(amp);
	// 		~mainAmpSlider.value_(amp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
	// 		if(~mainAmpBoxValue >= 0, {
	// 			~mainAmpBoxString = "+" ++ ~mainAmpBoxValue.asString;
	// 			}, {
	// 				~mainAmpBoxString = ~mainAmpBoxValue.asString;
	// 			}
	// 		);
	// 		~mainAmpBox.value_(~mainAmpBoxString + "dB");
	//
	// 		0.01.wait;
	// 	}.loop;
	// });
	//
	// ~setMicPanSlider = Routine.new({
	// 	{
	// 		var pan;
	// 		pan = ~panCtrlBus.getSynchronous;
	// 		~panVal = pan;
	// 		~micPanSlider.value_(pan.linlin(-1, 1, 0, 1));
	// 		0.01.wait;
	// 	}.loop;
	// });

	~prepMvt = {
		~files = ~bufRead[~mvt];
		~seq = Pseq(~files).asStream;
		~bufGroup.freeAll;
		~seq.reset;
		~mvtSelect.value_(~mvt);
		~cueSelect.items_((1..~files.size).collect(_.asSymbol));
		~cueSelect.value_(0);
		~curtext.string_("");
		~nexttext.string_(~files[0].file);
		~cues[~mvt][0].();
		~resetAction.();
	};


	// ~timeAndMoney = {
	// 	~mvt = 0;
	// };
	// ~glacier = {
	// 	~files = ~bufRead[0];
	// 	~seq = Pseq(~files).asStream;
	// 	~bufGroup.freeAll;
	// 	~seq.reset;
	// 	// ~files = e;
	// 	~cueSelect.items_((1..~files.size).collect(_.asSymbol));
	// 	~curtext.string_("");
	// 	~nexttext.string_(~files[0].file);
	// 	// ~mvtSelect.value_(0);
	// 	~cueSelect.value_(0);
	// 	// ~delayOff.(false);
	// 	// ~grainOff.(false);
	// 	~bufAmp = 0.dbamp;
	// 	~micAmp = -6.dbamp;
	// 	~mainAmp = 0.dbamp;
	// 	~setBufAmp.(~bufAmp);
	// 	~setMainAmp.(~mainAmp);
	// 	// ~reverb.set(\revTime, ~revTime, \damp, ~damp);
	// 	// ~delay0.set(\decay, 3);
	// 	// ~delay1.set(\decay, 3);
	// 	// ~reverb.set(\revTime, 1, \mix, -1, \damp, 0.7);
	// 	// ~setReverbParams.(time:1, damp:0.7);
	// 	// ~effectGroup.set(\amp, 1);
	// 	~mvt = 0;
	// 	~mvtSelect.value_(~mvt);
	//
	// 	// "Preset: Movt. 1".postln;
	// };
	//
	// ~silentium = {
	// 	~mvt = 1;
	// 	~setMainAmp.(~mainAmp);
	//
	// 	~prepMvt.();
	// };
	//
	// ~prelude = {
	// 	~mvt = 2;
	// 	~prepMvt.();
	//
	// };
	//
	// ~memory = {
	// 	~mvt = 3;
	// 	~prepMvt.();
	//
	// };
	//
	// ~postlude = {
	// 	~mvt = 4;
	// 	~prepMvt.();
	//
	// };
	//
	// ~toccata = {
	// 	~mvt = 5;
	// 	~prepMvt.();
	//
	// };

	// ~playSeq = [~glacier, ~silentium, ~prelude, ~memory, ~postlude, ~toccata];
	// ~playSeq = [~timeAndMoney];
	~playSeq = ~pathList.collect({
		arg title, i;
		{
			~mvt = i;
			~prepMvt.();
			// ~files = ~bufRead[i];
			// ~seq = Pseq(~files).asStream;

		}
	});
	// ~delay.set(\amp, 1);

	s.sync;
	MIDIdef.cc(\pedal, { |val|
		if(val == 127) { defer{ ~nextbtn.valueAction_(0) } };

	}).permanent_(true);



	~advanceCue = {
		var ev;
		ev = ~seq.next;
		// ~updateVals.();
		if (ev == nil) {
			if(~mvt == (~playSeq.size - 1), {
				~bufGroup.freeAll;
				~effectGroup.set(\amp, 0, \ampLag, 5);
				// ~change.stop;
				// ~panning.stop;
				defer({~curtext.string_("")});
				defer({~nexttext.string_("End of Performance")});
				~stopClock.();
			});
			if(~mvt < (~playSeq.size - 1), {
				~playSeq[(~mvt+1)].();
				~stopClock.();
			});
		};
		if(ev.notNil) {
			// ev.postln;

			// ~clockRunning = true;
			~startClock.();
			// "next".postln;
			~playStop.value_(0);
			if(~cueNumber == -1, {
				~cueNumber = 0;
			});
			~cueNumber = ~cueNumber + 1;
			// ~effectGroup.set(\amp, 1);
			defer({~curtext.string_(ev[\file])});
			defer({~nexttext.string_(ev[\nextfile])});
			m.sendMsg("curCue", ev[\number]);
			m.sendMsg("nxtCue", ev[\number]+1);
			if(~nexttext.string == "nil", {
				// ~nexttext.string_("End of Piece");
				if (~mvt < (~playSeq.size - 1), {
					defer({~nexttext.string_("Press NEXT to load next piece")});
				});
				if (~mvt == (~playSeq.size - 1), {
					defer({~nexttext.string_("Press NEXT to end")});
				});
			});
			defer({~cueSelect.value_(ev[\number])});
			// if(~mvtSelect.value == 0) {
			// };
			// if(~mvtSelect.value == 1) {
			// };
			// ~cues[~mvtSelect.value][ev.number].();
			ev[\ctrlfn].();
			// ~bufAmp.postln;
			ev[\playfn].();
			// ~bufAmp.postln;
			if (~editWindow.isNil == false, {
				if (~editWindow.isClosed == false, {
					~cueRows.do({
						arg row, i;
						var selectIndex, highlight;
						selectIndex = i;
						~nowPlaying[~cueNumber] = ev[\file];
						// ~nowPlaying.postln;
						// ev[\buf].sampleRate.postln;
						// s.sampleRate;
						// 1.1/0.9;
						// ev[\buf]

						if ((i) == ~cueNumber, {
							highlight = Routine.new({
								var playIndex, curBuf, playTime, sampleRateScale;
								playIndex = ~cueNumber;
								curBuf = ev[\buf];
								sampleRateScale = s.sampleRate/curBuf.sampleRate;
								playTime = curBuf.numFrames*sampleRateScale/s.sampleRate;
								row.background_(Color.green(0.8, 0.5));
								playTime.wait;
								if (playIndex == ~cueNumber, {
									// "blue".postln;
									row.background_(~buttonColor);
								}, {
									// "gray1".postln;
									row.background_(Color.gray(0.8, 0.5));
								}
								);
								~nowPlaying[playIndex] = nil;
								// ~nowPlaying.postln;

							});
							AppClock.play(highlight);
						}, {
							if(~nowPlaying.keys.includes(selectIndex) == false, {
								row.background_(Color.gray(0.8, 0.5));
							});
							// "gray".postln;
						}
						);
					});
				});
			});
		};
		~lastAction = \advanceCue;

	};

	~resetAction = {
		~bufGroup.freeAll;
		// ~tempGroup.freeAll;
		~seq.reset;
		~curtext.string_("");
		~resetClock.();
		if(~mvt == 0, {
			~nexttext.string_(~files[0].file);
			m.sendMsg("nxtCue", ~files[0].number);
			m.sendMsg("curCue", "--");
		});
		// if(~mvt == 1, {
		// 	~nexttext.string_(f[0].file);
		// });
		~cueNumber = 0;
		~cueSelect.value_(~cueNumber);
		~cueRows.do({
			arg row, i;
			if (i == 0, {
				row.background_(~buttonColor);
			}, {
				row.background_(Color.gray(0.8, 0.5));
			}
			);
		});
		~effectGroup.set(\amp, 1, \ampLag, 2);
		// ~prepMvt.();
		m.sendMsg("stop", 1);
		m.sendMsg("stop", 0);
		~lastAction = \reset;

	};

	~goAction = {
		arg button;
		var value = button.value;
		if (value == 1, {
			// s.freeAll;
			~bufGroup.freeAll;
			~effectGroup.set(\amp, 0);
			defer{ ~curtext.string_("");};
			~stopClock.();
		});
		if (value == 0, {
			~effectGroup.set(\amp, 1);
		})
	};

	~advanceClock = Routine.new({
		// "tock".postln;
		// "tocktock".postln;
		{
			0.01.wait;
			// "ticktick".postln;
			if (~clockRunning == true, {
				var seconds, clockString;
				~time = ~time + 1;
				if (~time%100 == 0, {
					// "tick".postln;
				});
				seconds = ~time/100;
				clockString = seconds.asTimeString.drop(-4).drop(3);
				defer({~clock.string_(clockString)});
				m.sendMsg("timer", clockString);

			});


		}.loop;
	});
	// ~tempGroup.queryTree
	~startClock = {
		if (~clockRunning == false, {
			// ~advanceClock.reset;
			if (~advanceClock.isPlaying == false, {
				// AppClock.play(~advanceClock);
				~advanceClock.play;
				~clockStarted = true;
				// "hfdsafds".postln;
				// "tocktock".postln;
			}, {
				if (~advanceClock.isPlaying == true, {
					~advanceClock.next;
					// "ticktock".postln;
				});

			}
			);
			~clockRunning = true;
		});
	};

	~stopClock = {
		if (~clockRunning == true, {
			~clockRunning = false;
			// "click".postln;
		});
	};

	~resetClock = {
		var clockString;
		~stopClock.();
		~advanceClock.stop;
		~advanceClock.reset;
		// ~clockStarted = false;

		~time = 0;
		// "ding".postln;
		clockString = ~time.asTimeString.drop(-4).drop(3);
		m.sendMsg("timer", clockString);
		defer({~clock.string_(clockString)});
	};

	// ~tempGroup.reference

	~memDelUpdate = Routine.new({
		var delayText, tree;
		{
			var delayText = ~tempGroup.dumpTree.asString;

			// tree = ~tempGroup.dumpTree({
			// 	arg i;
			// 	// i.postln;
			~memDelDisplay.string_(delayText);
			//
			// });

			0.1.wait;
		}.loop;
	});

	~editCueSlider = {
		arg val, slider, convert = {val.round(0.01)};
		var boxString;
		boxString = convert.(val);
		if(~editWindow.isNil == false, {
			if(~editWindow.isClosed == false, {
				var row, boxIndex, rowIndex, box;
				// rowIndex = (~cueNumber + 1).clip(0, ~cueSelect.items.size);
				if(~cueNumber == -1, {
					rowIndex = 0;
				}, {
					rowIndex = ~cueNumber + (~lastAction == \editSelect).asInteger;
				}
				);

				~setArgs.do({
					arg set, i;
					var candidate;
					// i.postln;

					if (i > 0, {
						candidate = set[\slider];
						// candidate.postln;
						if (candidate == slider, {
							boxIndex = set[\index];
							box = ~cueBoxes[rowIndex][boxIndex];
							~cueRows[rowIndex].background_(Color.red(0.7, 0.3));
							box.value_(boxString);
							~cueList[~mvtSelect.value][rowIndex][boxIndex] = val;
						});
					});
				});
			});
		});

	};


	// ~cues = [
	// 	(
	//
	// 	),
	// 	(
	// 	)
	// ];




	// ~cueFile = FileReader.new("text.flo".resolveRelative, delimiter:\n);
	// ~cues = ~cueFile.read.collect({
	// 	arg line;
	// 	var index, name;
	// 	index = line[0];
	// 	name = line[1];
	// 	(index, name);
	// });
	// ~cueFile.readAllString;

	s.sync;





	// ~cueDisplay.asView.resizeTo(0, 0);



	~initGUI = {
		~streamDisplayView = View(w)
		.fixedWidth_(100)
		.layout_(
			VLayout(
				~fileDisplay = StaticText.new(w)
				.string_(PathName(~filePath).fileName)
				.background_(Color.gray(0.8, 0.5))
				// .fixedWidth_(90)
				.fixedHeight_(40)
				.minWidth_(90)
				.maxWidth_(200)
				.align_(\center),
				~newButton = Button.new(w)
				.states_([["NEW", Color.gray(0.9), ~buttonColor]])
				.canFocus_(false)
				.minWidth_(90)
				.maxWidth_(200)
				.font_(Font(size: 18))
				.action_({
					~openNewWindow.();
				}),
				~openButton = Button.new(w)
				.states_([["OPEN", Color.gray(0.9), ~buttonColor]])
				.canFocus_(false)
				.minWidth_(90)
				.maxWidth_(200)
				.font_(Font(size: 18))
				.action_({
					var searchPath;
					if (~filePath == "", {
						searchPath = thisProcess.nowExecutingPath;
						// searchPath.postln;
					}, {
						searchPath = PathName(~filePath).parentPath;
					});
					FileDialog(
						{
							arg path;
							~filePath = path[0];
							// path[0].postln;
							~configFile = File.new(~filePath, "r");
							// ~fileDisplay
							~resetGUI.();
						},
						path:searchPath;
					);
				}),
				~editButton = Button.new(w)
				.states_([["EDIT", Color.gray(0.9), ~buttonColor]])
				.canFocus_(false)
				.minWidth_(90)
				.maxWidth_(200)
				.font_(Font(size: 18))
				.action_({
					// ~editWindow.close;
					~openEditWindow.();
					// ~cueEditMode = true;
				}),


				// ~streamDisplay = HLayout();
			);
		);
		~streamDisplayContent = ();

		~mixerView = View(w)
		// .fixedWidth_(100)
		.layout_(
			~mixer = HLayout();
		);

		// ~mixerView.isClosed

		// ~streamDisplayView.visible_(false);
		// ~testView.visible_(true);

		// ~streamDisplay[1];
		// ~streamDisplay.subtract(10);

		// ~streamList.do({
		// 	arg stream;
		// 	var displayList;
		// 	displayList = VLayout();
		// 	stream.do({
		// 		arg synth;
		// 		var synthName;
		// 		synthName = synth.defName;
		// 		// synthName.postln;
		// 		displayList.add(DragBoth(w)
		// 			.object_(synthName)
		// 			.minWidth_(90)
		// 			.maxWidth_(130)
		// 			.beginDragAction_(
		// 				{
		// 					arg obj;
		// 					~currentDrag = obj;
		// 					// ~currentDrag.object.postln;
		// 					"begin drag".postln;
		// 				}
		// 			)
		// 			.receiveDragHandler_(
		// 				{
		// 					arg obj;
		// 					var current, dest;
		// 					~destDrag = obj;
		// 					dest = ~destDrag;
		// 					current = ~currentDrag.object;
		// 					// subj = ~currentDrag;
		// 					// ~currentDrag = ~currentDrag.add(obj);
		// 					// ~destDrag = [obj, ~currentDrag[0]];
		// 					// ~destDrag[0].object = ~currentDrag[0].object;
		// 					// ~currentDrag[1].object = ~destDrag[1].object;
		// 					// ~destDrag = ~destDrag.add(obj);
		// 					// ~destDrag.object.postln;
		// 					// ~currentDrag.postln;
		// 					~currentDrag.object = dest.object;
		//
		// 					~destDrag.object = current;
		// 					// ~destDrag.object.postln;
		// 					// ~destDrag.object.postln;
		// 					"release drag".postln;
		// 					// ~destDrag.object = View.currentDrag.object;
		// 					// ~currentDrag.object = obj
		// 				}
		// 			)
		// 		);
		// 	});
		// 	// ~streamDisplay.add(displayList);
		// });
		// ~mixer.add(~synthDefGUIs[\playBuf].()[\gui]);
		~guiList.do({
			arg gui;
			~mixer.add(gui);
		});
		// ~mixer.add(
		// 	~mainAmpControls = VLayout(
		// 		StaticText().string_("Main")
		// 		.font_(Font(size:18))
		// 		.align_(\center),
		// 		~mainAmpSlider,
		// 		~mainAmpBox
		// 	);
		//
		// )
	};


	~openEditWindow = {
		// var window;
		var matrix, titleBarView, saveButton, saveAsButton, cueSelection, copy;
		cueSelection = [];
		saveButton = Button.new(~editWindow)
		.states_([["SAVE", Color.gray(0.9), ~buttonColor]])
		.canFocus_(false)
		.minWidth_(90)
		.maxWidth_(200)
		.font_(Font(size: 18))
		.action_({
			~overWriteFile.();
		});

		saveAsButton = Button.new(~editWindow)
		.states_([["SAVE AS", Color.gray(0.9), ~buttonColor]])
		.canFocus_(false)
		.minWidth_(90)
		.maxWidth_(200)
		.font_(Font(size: 18))
		.action_({
			FileDialog(
				{
					arg pathList;
					pathList.postln;
					~saveAsFile.(pathList[0]);
				},
				acceptMode:1,
				path:PathName(~filePath).parentPath;

			);
		});



		~cueRows = [];
		matrix = VLayout(
		);
		if (~editWindow != nil, {
			if (~editWindow.isClosed == false, {
				~editWindow.close;
			});
		});

		~cueList.do({
			arg subList, i;
			var titleBar, synthRow, argRow, currentSynthName, row, rowView, subRowView, lagSubList, lagRow, lagRowView;
			// matrix.add(StaticText.new(~editWindow).string_(i.asString));
			lagSubList = ~lagList[i];
			// lagSubList.postln;
			currentSynthName = "";
			titleBar = VLayout(
			);
			synthRow = HLayout();
			argRow = HLayout();
			~setArgs.do({
				arg pair, j;
				var synthName, argName;
				if (j == 0, {
					synthRow.add(
						StaticText.new(~editWindow)
						.string_("")
						.font_(Font.new(size:12))
						.fixedWidth_(30)
						.fixedHeight_(15)
					);
					argRow.add(
						StaticText.new(~editWindow)
						.string_("#")
						.align_(\center)
						.font_(Font.new(size:12))
						.fixedWidth_(30)
						.fixedHeight_(15)

					)
				});
				if (j > 0, {
					// synthName = pair[0];
					argName = pair[\arg];
					if (pair[\synth].defName == currentSynthName, {
						synthName = "";
					}, {
						synthName = pair[\synth].defName;
						currentSynthName = synthName;
					}
					);
					synthRow.add(
						StaticText.new(~editWindow)
						.string_(synthName)
						.align_(\center)
						.font_(Font.new(size:12))
						.fixedWidth_(70)
						.fixedHeight_(15)
					);
					argRow.add(
						StaticText.new(~editWindow)
						.string_(argName)
						.align_(\center)
						.font_(Font.new(size:12))
						.fixedWidth_(70)
						.fixedHeight_(15)
					);
					// synthName.postln;

				});
			});
			titleBar.add(synthRow);
			titleBar.add(argRow);
			titleBarView = View.new(~editWindow)
			.layout_(
				titleBar,
			);
			// matrix.add(titleBarView);
			// matrix.postln;
			subList.do({
				arg cue, j;
				var rowList, lagCue, lagRowList;
				lagCue = lagSubList[j];
				// lagCue.postln;
				// cue.postln;
				rowView = View.new()
				.background_(Color.gray(0.8, 0.5))
				.mouseDownAction_({
					arg view, x, y, modifiers, buttonNumber, clickCount;
					if (modifiers == 131072, {
						var start, end, loopStart, loopEnd;
						// "SHIFT".postln;

						if(cueSelection.size == 0, {
							cueSelection = cueSelection.add(j);
						});
						start = cueSelection[0];
						end = j;
						start.postln;
						if (end >= start, {
							loopStart = start;
							loopEnd = end + 1;
						}, {
							loopStart = end;
							loopEnd = start;
						});
						(loopEnd - loopStart).do({
							arg i;
							if (cueSelection.includes(loopStart + i) == false, {
								cueSelection = cueSelection.add(loopStart + i);
							});
						});

						// j.postln;
					}, {
						if (modifiers == 262144, {
							// "CTRL".postln;
							if (cueSelection.includes(j) == false, {
								cueSelection = cueSelection.add(j);
								cueSelection = cueSelection.sort;
							});
						}, {
							cueSelection = [j];
						});


					});

					// modifiers.postln;
					// cueSelection.postln;
					~cueRows.do({
						arg row, k;
						// j.postln;
						if (cueSelection.includes(k), {
							// j.postln;
							// k.postln;
							if(cueSelection.size == 1, {
								if (k == 0, {
									// ~cueSelect.valueAction_(0);
									~reset.action.();
									~cueNumber = -1;
								}, {
									// j.class.postln;

									~cueSelect.valueAction_(j);
									~seq.reset;
									(j-1).do({
										arg n;
										var next;
										// n.postln;
										next = ~seq.next;
										// next.postln;
									});
									~cueNumber = ~cueNumber-1;
									~nexttext.string_(~files[j-1].file);
									~cueSelect.value_(j-1);
									// 1.class;
									// j.postln;

								}
								);

							});
							row.background_(~buttonColor);

						}, {
							row.background_(Color.gray(0.8, 0.5));
						}
						);
					});
					~lastAction = \editSelect;

				});

				lagRowView = View.new();
				subRowView = View.new();
				// .background_(~buttonColor);
				row = HLayout();
				rowList = [];
				cue.do({
					arg val, k;
					var ampBox, oldVal, boxVal, box, entry, synthName, argName, boxTitle, lagVal, lagEntry;
					// argName.postln;
					// k.postln;
					// ~lagList[i][j][k].postln;
					if (k == 0, {
						box = StaticText.new(~editWindow)
						.string_(val.asString)
						.fixedWidth_(30)
						.font_(Font.new("Courier New", 24));
					}, {
						if([1, 2, cue.size-1].includes(k), {
							var amp, db;
							ampBox = true;
							// k.postln;
							amp = val.asFloat;
							db = amp.ampdb.round(0.1);
							if (db >= 0, {
								boxVal = "+" ++ db.asString + "dB";
							}, {
								boxVal = db.asString + "dB";
							});
						}, {
							ampBox = false;
							boxVal = val;
						}
						);

						synthName = ~setArgs[k][\synth].defName;
						argName = ~setArgs[k][\arg].asString;
						// argName.postln;
						// k.postln;
						boxTitle = synthName + \n + argName;
						// boxTitle.postln;
						box = VLayout(
							// StaticText.new(~editWindow)
							// .string_(argName),
							entry = TextField.new(~editWindow)
							.value_(boxVal)
							.fixedWidth_(70)
							.mouseDownAction_({
								entry.value_("");
								// j.postln;
							})
							.action_({
								var input, outString;
								input = entry.value;
								if(input == "", {
									// oldVal.postln;
									if (ampBox == true, {
										oldVal = ~cueList[i][j][k].asFloat;
										oldVal = oldVal.ampdb.round(0.1);
										// oldVal.postln;
										if (oldVal >= 0, {
											outString = "+" ++ oldVal.round(0.1).asString + "dB";
										}, {
											outString = oldVal.round(0.1).asString + "dB";
										});
									}, {
										oldVal = ~cueList[i][j][k].asFloat;
										outString = oldVal.asString;
									});
									// input = oldVal;
									entry.value_(outString);
								}, {
									if(~cleanBoxInput.(input) == false, {
										// "hi".postln;
										if (ampBox == true, {
											oldVal = ~cueList[i][j][k].asFloat;
											oldVal = oldVal.ampdb.round(0.1);
											// oldVal.postln;
											if (oldVal >= 0, {
												outString = "+" ++ oldVal.round(0.1).asString + "dB";
											}, {
												outString = oldVal.round(0.1).asString + "dB";
											});
										}, {
											oldVal = ~cueList[i][j][k].asFloat;
											outString = oldVal.asString;
										});
										entry.value_(outString);

									}, {
										if(ampBox == true, {
											// "amp".postln;
											var inputVal, amp;
											inputVal = input.asFloat;
											amp = inputVal.dbamp;
											~cueList[i][j][k] = amp;
											if (inputVal >= 0, {
												outString = "+" ++ inputVal.round(0.1).asString + "dB";
											}, {
												outString = inputVal.round(0.1).asString + "dB";
											});
										}, {
											outString = input;
											~cueList[i][j][k] = input;
										}
										);
										entry.value_(outString);
									});

								});
								~loadCues.();
								~editWindow.asView.focus;
								~cueList.postln;
							}),

							// lagEntry = TextField.new(~editWindow)
							// .value_(val)
							// .fixedWidth_(70)
							// .mouseDownAction_({
							// 	lagEntry.value_("");
							// 	// j.postln;
							// })
							// .action_({
							// 	var input;
							// 	input = entry.value;
							// 	~cueList[i][j][k] = input;
							// 	~loadCues.();
							// 	~editWindow.asView.focus;
							// }),
						)
					}
					);
					subRowView.layout_(row);
					rowList = rowList.add(entry);
					row.add(box);

				});
				if (j > 0, {
					lagRow = HLayout();
					lagRowList = [];
					lagCue.do({
						arg val, k;
						var box, entry;
						// val.postln;
						if (k == 0, {
							box = StaticText.new(~editWindow)
							.string_(" ")
							.fixedWidth_(30)
							.font_(Font.new("Courier New", 24));
						}, {
							box = VLayout(
								entry = TextField.new(~editWindow)
								.value_(val)
								.fixedWidth_(70)
								.mouseDownAction_({
									entry.value_("");
									// j.postln;
								})
								.action_({
									var input;
									input = entry.value;
									~lagList[i][j][k] = input;
									~loadCues.();
									~editWindow.asView.focus;
								}),
							);

						}
						);
						lagRowList = lagRowList.add(entry);

						lagRowView.layout_(lagRow);
						lagRow.add(box);

					});

				});
				// lagRowList = [];


				~cueBoxes[j] = rowList;
				~lagCueBoxes[j] = lagRowList;
				rowView.layout_(
					VLayout(
						lagRowView,
						subRowView,
					)
				);
				matrix.add(rowView);
				~cueRows = ~cueRows.add(rowView);

			});
		});

		// ~cueRows[1].visible_(true);
		~streamList.do({
			arg stream;
			stream.do({
				arg synth;
				// synth.postln;
			});
		});
		~editWindow = Window.new("Edit Cues", Rect(300, 800, ((~lagList[0][0].size)-1)*90, (((~lagList[0].size)-1)*100).clip(500, 1000)))
		.background_(~mainColor)
		.alwaysOnTop_(true)
		.asView.keyDownAction_({
			arg i, char, modifiers, unicode, keycode, key;
			// modifiers.postln;

			if( modifiers == 1048576, {
				if (key == 67, {
					// "COPY".postln;
					copy = cueSelection.collect({
						arg i;
						[~cueList[~mvt][i], ~lagList[~mvt][i]];
					});
					copy.postln;
				});
				if (key == 86, {
					var pasteStart, pasteTargets, repeats, copyRange;
					pasteStart = cueSelection[0].asInteger;
					// pasteStart.postln;
					copyRange = copy[(copy.size-1)][0][0].asInteger-copy[0][0][0].asInteger + 1;
					// copyRange.postln;
					if(copy.size == 1, {
						if(cueSelection.size > 1, {
							repeats = cueSelection.size.div(copyRange);
							if (repeats == 0, {
								repeats = 1;
							});
						}, {
							repeats = 1;
						}
						);
					}, {
						repeats = 1;
					}
					);
					repeats = cueSelection.size.div(copyRange);
					if (repeats == 0, {
						repeats = 1;
					});

					// repeats.postln;
					repeats.do({
						arg i;
						var repeatIndex;
						repeatIndex = pasteStart + (copyRange * i);
						// targetIndex.postln;
						copy.do({
							arg pair, i;

							var cue, lagCue, targetIndex, newCue, newLagCue, diff;
							cue = pair[0];
							lagCue = pair[1];
							// cueSelection[i].postln;
							// cue.postln;
							if (i == 0, {
								diff = 0;
							}, {
								diff = cue[0].asInteger - copy[i-1][0][0].asInteger;
							}
							);
							// diff.postln;
							newCue = cue.collect({
								arg val, i;
								if (i == 0, {
									val = repeatIndex + diff;
									val.asString;
								}, {
									val;
								});
							});
							newLagCue = lagCue.collect({
								arg val, i;
								if (i == 0, {
									val = repeatIndex + diff;
									val.asString;
								}, {
									val;
								});
							});
							// newCue[0] = newCue[0].asInteger + pasteStart;
							// newCue.postln;
							targetIndex = newCue[0].asInteger;
							// targetIndex = pasteStart + (copy[i][0] - pasteStart);
							// targetIndex = cue[0].asInteger + pasteStart - 1;
							// targetIndex.postln;
							if(targetIndex < ~cueList[~mvt].size, {
								newCue.do({
									arg val, i;
									var boxVal, lagBoxVal;
									// lagBoxVal = newLagCue[i];
									if (i > 0, {
										lagBoxVal = newLagCue[i];
										if([1, 2, cue.size-1].includes(i), {
											var amp, db;
											// ampBox = true;
											// k.postln;
											amp = val.asFloat;
											db = amp.ampdb.round(0.1);
											if (db >= 0, {
												boxVal = "+" ++ db.asString + "dB";
											}, {
												boxVal = db.asString + "dB";
											});
										}, {
											// ampBox = false;
											boxVal = val;
										}
										);
										~cueBoxes[targetIndex][i].value_(boxVal);
										~cueList[~mvt][targetIndex] = newCue;

										if (targetIndex != 0, {
											~lagCueBoxes[targetIndex][i].value_(lagBoxVal);
											~lagList[~mvt][targetIndex] = newLagCue;

										});
									});
								});
							});
						});
						~loadCues.();
					});
					// pasteTargets = copy.collect({
					// 	arg cue;
					//
					// 	// pasteStart +
					// });
				});
				// key./postln;
			});



			// if (char == $c, {
			// 	char.postln;
			// 	if (modifiers == 1048576, {
			// 		"COPY".postln;
			// 	});
			// 	// cueSelection.postln;
			// });
			if (char == $ , {
				~advanceCue.();
			});
		})
		.mouseDownAction_(
			~cueSelection = [];
		)
		// .onClose_({
		// 	// "hi".postln;
		// 	// ~cueEditMode = false;
		// })
		.layout_(
			VLayout(
				StaticText.new(~editWindow)
				.string_("Edit Cues")
				.font_(Font.new(size:14)),
				View(~editWindow)
				.layout_(
					VLayout(
						titleBarView,
					)
				),
				ScrollView.new(~editWindow, Rect(0, 0, 4000, 4000))
				.hasBorder_(false)
				// .maxHeight_(4000)
				// .innerBounds_(Rect(0, 0, 4000, 4000))
				// .scroll
				.canvas_(
					View.new(~editWindow)
					.background_(~mainColor)
					.layout_(
						matrix
					)
				),
				HLayout(
					saveAsButton,
					saveButton
				)


			)
		).front;
		// ~cueEditMode.postln;
		// ~cueEditMode = true;
		// ~cueRows[1].background_(~buttonColor);
		w.asView.focus;
		// ~cueEditMode.postln;

	};
	// .visible_(true);

	~openNewWindow = {
		var folderSelect, folderInfo, synthMenu, synthFlow, synthInfo, cancelButton, confirmButton, ready;
		if(~newWindow != nil, {
			if(~newWindow.isClosed == false, {
				~newWindow.close;
			});
		});
		ready = false;
		folderSelect = Button.new(~newWindow)
		.states_([["SELECT FOLDER", Color.gray(0.9), ~buttonColor]])
		.canFocus_(false)
		.minWidth_(90)
		.maxWidth_(200)
		.font_(Font(size: 18))
		.action_({
			var searchPath;
			if (~filePath == "", {
				searchPath = thisProcess.nowExecutingPath;
				// searchPath.postln;
			}, {
				searchPath = PathName(~filePath).parentPath;
			});
			FileDialog(
				{
					arg dirPath;
					// ~filePath = path[0];
					// path[0].postln;
					// ~configFile = File.new(~filePath, "r");
					// ~fileDisplay

					// ~resetGUI.();
					// path.postln;
					~newPathList = dirPath;
					~newPathList.do({
						arg path, i;
						~newDirPathStr = ~newDirPathStr ++ path;
						if (i < (~newPathList.size - 1), {
							~newDirPathStr = ~newDirPathStr ++ ";";
						});
					});
					// ~newDirPathStr.postln;
					folderInfo.string_(~newDirPathStr);
					ready = true;
					confirmButton.states_([["CREATE", Color.gray(0.9), ~buttonColor]]);
				},
				fileMode:2,
				path:searchPath;
			);
		});

		folderInfo = StaticText.new(~newWindow)
		.minWidth_(200)
		.maxWidth_(500)
		.background_(Color.gray(0.8, 0.5))
		.string_("");

		synthMenu = ListView.new(~newWindow)
		.minHeight_(100)
		.maxWidth_(300)
		.items_(~synthList.keys.asArray)
		.mouseDownAction_({
			arg self, x, y, modifiers, buttonNumber, clickCount;
			var val, add;
			val = self.value;
			if(clickCount == 2, {
				add = self.items[val];
				// add.postln;
				~newStreamList = ~newStreamList.add(self.items[val]);
				synthFlow.items_(~newStreamList);
			});
			// x.postln;
			// y.postln;
			// modifiers.postln;
			// buttonNumber.postln;
			// clickCount.postln;

		})
		.action_({
			// "hi".postln;
			arg self;
			synthInfo.string_(~synthList[self.items[self.value]]);
		});

		synthInfo = StaticText.new(~newWindow)
		.minWidth_(200)
		.maxWidth_(500)
		.minHeight_(100)
		.maxHeight_(2000)
		.background_(Color.gray(0.8, 0.5))
		.string_("");

		synthFlow = ListView.new(~newWindow)
		.items_(~newStreamList)
		.minHeight_(100)
		.maxWidth_(300)
		.mouseDownAction_({
			arg self, x, y, modifiers, buttonNumber, clickCount;
			var val, remove;
			val = self.value;
			if(clickCount == 2, {
				// remove = self.items[val];
				// add.postln;
				~newStreamList.removeAt(val);
				self.items_(~newStreamList);
			});
			// x.postln;
			// y.postln;
			// modifiers.postln;
			// buttonNumber.postln;
			// clickCount.postln;

		})
		.action_({
			arg self;
			synthInfo.string_(~synthList[self.items[self.value]]);
		});

		cancelButton = Button.new(~newWindow)
		.states_([["CANCEL", Color.gray(0.9), ~buttonColor]])
		.canFocus_(false)
		.minWidth_(90)
		.maxWidth_(200)
		.font_(Font(size: 18))
		.action_({
			~newWindow.close;
		});

		confirmButton = Button.new(~newWindow)
		.states_([["CREATE", Color.gray(0.9), Color.gray(0.4, 0.5)]])
		.canFocus_(false)
		.minWidth_(90)
		.maxWidth_(200)
		.font_(Font(size: 18))
		.action_({
			var newStreamStr, newCuesStr, newLagsStr;
			if (ready == false, {
				var error;
				// "error".postln;
				error = Window.new("Error", Rect(650, 550, 200, 100))
				.alwaysOnTop_(true)
				.background_(~mainColor)
				.layout_(
					VLayout(
						StaticText.new()
						.align_(\center)
						.string_("Please select a folder."),
						HLayout(
							Button.new()
							.fixedWidth_(50)
							.states_([["OK", Color.gray(0.9), ~buttonColor]])
							.action_({
								error.close;
							});
						)
					)
				);
				error.front;
			}, {
				var searchPath;
				if (~filePath == "", {
					searchPath = thisProcess.nowExecutingPath;
					// searchPath.postln;
				}, {
					searchPath = PathName(~filePath).parentPath;
				});

				newStreamStr = "";
				newCuesStr = "";
				// ~newStreamList.postln;
				newCuesStr = "0,1,1,";
				newLagsStr = "0,2,2,";
				~newStreamList.do({
					arg synth, i, setArgs;
					newStreamStr = newStreamStr ++ synth;
					if(i < (~newStreamList.size - 1), {
						newStreamStr = newStreamStr ++ ";"
					});
					setArgs = ~synthDefSetArgs[synth.asSymbol];
					// setArgs.postln;
					setArgs.do({
						arg argument, i;
						var val;
						val = ~synthDefArgs[synth][argument];
						newCuesStr = newCuesStr ++ val.asString ++ ",";
						newLagsStr = newLagsStr ++ "2,";
					});
					// newCueStr = ~synthDefSetArgs
				});
				newCuesStr = newCuesStr ++ "1";
				newLagsStr = newLagsStr ++ "2";
				// newCuesStr.postln;
				// newLagsStr.postln;
				~newDirPathStr;
				~newStreamStr = newStreamStr;
				~newCuesStr = newCuesStr;
				~newLagsStr = newLagsStr;
				~newFileStr = ~newDirPathStr ++ "\n" ++ ~newStreamStr ++ "\n" ++ ~newCuesStr ++ "\n" ++ ~newLagsStr;
				~newFileStr.postln;
				FileDialog.new({
					arg name;
					var file;
					name.postln;
					~filePath = name[0];
					~filePath = ~filePath ++ ".flo";
					file = File.open(~filePath, "w");
					file.write(~newFileStr);
					file.close;

					~configFile = File.new(~filePath, "r");
					~resetGUI.();
				},
				fileMode: 0,
				acceptMode: 1,
				path:searchPath);

			}
			);
			// ~newStreamStr.postln;
		});



		~newWindow = Window.new("Create New Project", Rect(500, 500, 500, 400))
		.background_(~mainColor)
		.alwaysOnTop_(true)
		.layout_(
			VLayout(
				// StaticText.new()
				// .font_(Font.new(size:16))
				// .string_("New Project"),
				StaticText.new()
				.string_("Select the folder containing your audio cues.\n"),
				HLayout(
					folderSelect,
					folderInfo
				),
				StaticText.new()
				.string_("\nFrom the menu on the left, select the synths to incorporate into your signal flow on the right. The signal flow will be constructed in order from top to bottom. Double click to add/remove.\n"),
				HLayout(
					synthMenu,
					synthInfo,
					synthFlow,
				),
				StaticText.new()
				.font_(Font.new(size:8))
				.string_("\n"),
				HLayout(
					cancelButton,
					confirmButton
				)
			),
		).front;

	};

	// ~openNewWindow.();
	// AppClock.play(~editWindow.());
	// ~editWindow.();
	// ~openEditWindow.();

	// ~setArgs.size;
	~generateSetArgs = {
		var playBufControls, playBufSetArgs, playBufSynth;
		~setArgs = [\];
		playBufSynth = ~bufDict[~mvt][-1];
		playBufControls = ~synthGUIs[playBufSynth];
		playBufSetArgs = ~synthDefSetArgs[\playBuf];
		// playBufSynth =
		playBufSetArgs.do({
			arg argument;
			var slider, box;
			slider = playBufControls[argument][\slider];
			box = playBufControls[argument][\box];
			~setArgs = ~setArgs.add((\synth: playBufSynth, \arg: argument, \slider: slider, \box: box));
		});
		~streamList[0].do({
			arg synth, i;
			var setArgs, synthControls;
			// synth.postln;
			synthControls = ~synthGUIs[synth];
			setArgs = ~synthDefSetArgs[synth.defName];
			setArgs.do({
				arg argument;
				var slider, box;
				slider = synthControls[argument][\slider];
				box = synthControls[argument][\box];
				~setArgs = ~setArgs.add((\synth: synth, \arg: argument, \slider:slider, \box:box));
			});


			// Dictionary.newFrom([synth,  ~synthDefSetArgs[synth.defName]]);
		});
		~setArgs.do({
			arg set, j;

			if (j > 0, {
				set[\index] = j;
			});
			// set.postln;
		});

	};
	~generateSetArgs.();

	// ~setArgs.postln;
	// ~setArgs.do({
	// 	arg i;
	// 	i.postln;
	// })
	//
	// ~cues.postln;

	~loadCues = {
		~cues = [];
		~cueList.do({
			arg subList, i;
			var subDict, lagSubList;
			// i.postln;
			subDict = ();
			// subList.size.postln;
			// ~paths[0];
			// ~paths[i].size.postln;
			// subList.postln;
			if (subList.size < (~paths[i].size + 1), {
				var diff;
				diff = (~paths[i].size + 1) - subList.size;
				// diff.postln;
				// "warning".postln;
				diff.do({
					arg i;
					var newCue;
					newCue = subList[subList.size - 1].collect({
						arg param, j;
						if (j == 0, {
							param = param.asInteger + 1;
						});
						param.asString;
					});
					// newCue[0] = subList.size + i;
					subList = subList.add(newCue);
				});
				~cueList[i] = subList;
			});

			lagSubList = ~lagList[i];
			// lagSubList.postln;
			if (lagSubList.size < (~paths[i].size + 1), {
				var diff;
				diff = (~paths[i].size + 1) - lagSubList.size;
				// diff.postln;
				// "warning".postln;
				diff.do({
					arg i;
					var newLagCue;
					newLagCue = lagSubList[lagSubList.size - 1].collect({
						arg param, j;
						if (j == 0, {
							param = param.asInteger + 1;
						});
						param.asString;
					});
					// newCue[0] = subList.size + i;
					lagSubList = lagSubList.add(newLagCue);
				});
				~lagList[i] = lagSubList;
			});
			// lagSubList.postln;

			// subList.postln;
			subList.do({
				arg cue, j;
				var cueNo, argList, cueLag, lagCue, func;
				if(cue.size < ~setArgs.size, {
					var diff;
					diff = ~setArgs.size - cue.size;
					diff.do({
						cue = cue.add(1);
					});
					// cue.postln;
					// "hi".postln;
				});


				cueNo = cue[0].asInteger;
				// j.postln;
				lagCue = ~lagList[i][j];
				if(lagCue.size < ~setArgs.size, {
					var diff;
					diff = ~setArgs.size - lagCue.size;
					diff.do({
						lagCue = lagCue.add(0);
					});
					// lagCue.postln;
					// "hi".postln;

				});
				// lagSubList.postln;

				// ~lagList[i][j].postln;
				// cueLag = ~lagList[i];
				// cue.postln;
				// lagSubList.postln;
				func = {
					~setArgs.do({
						arg pair, k;
						var synth, argument, lagArg, lagVal;
						// i.postln;
						// j.postln;
						// k.postln;
						// ~lagList[0][1][4].postln;
						if (k > 0, {
							// k.postln;
							synth = pair[\synth];
							argument = pair[\arg];
							if (k == 1, {
								~bufAmp = cue[k].asFloat;
							});

							// synth.postln;

							// lagSubList.postln;
							// lagVal.postln;
							lagVal = lagCue[k].asFloat;
							// lagVal.postln;
							lagArg = argument.asString ++ "Lag";
							lagArg = lagArg.asSymbol;
							// cue[k].postln;
							// lagSubList[k].postln;
							// synth.postln;
							// j.postln;

							// ~lagList[i][j].postln;
							// lagVal.postln;
							// synth.postln;
							// argument.postln;
							// cue[i].postln;
							synth.set(argument, cue[k].asFloat, lagArg, lagVal);
						});
					});
				};
				subDict[cueNo] = func;
				// func.();
			});
			~cues = ~cues.add(subDict);
		});

	};

	// ~loadLags = {
	// 	~lags = [];
	// 	~lagList.do({
	// 		arg subList, i;
	// 		var subDict;
	// 		subDict = ();
	// 		// subList.size.postln;
	// 		// ~paths[0];
	// 		// ~paths[i].size.postln;
	// 		// subList.postln;
	// 		if (subList.size < (~paths[i].size), {
	// 			var diff;
	// 			diff = (~paths[i].size) - subList.size;
	// 			// diff.postln;
	// 			// "warning".postln;
	// 			diff.do({
	// 				arg i;
	// 				var newCue;
	// 				newCue = subList[subList.size - 1].collect({
	// 					arg param, j;
	// 					if (j == 0, {
	// 						param = param.asInteger + 1;
	// 					});
	// 					param.asString;
	// 				});
	// 				// newCue[0] = subList.size + i;
	// 				subList = subList.add(newCue);
	// 			});
	// 			~lagList[i] = subList;
	// 		});
	// 		subList.do({
	// 			arg cue;
	// 			var cueNo, argList, func;
	// 			cueNo = cue[0].asInteger;
	// 			func = {
	// 				~setArgs.do({
	// 					arg pair, i;
	// 					var synth, argument;
	// 					if (i > 0, {
	// 						synth = pair[\synth];
	// 						argument = pair[\arg];
	// 						// synth.postln;
	// 						// argument.postln;
	// 						// cue[i].postln;
	// 						synth.set(argument, cue[i].asFloat);
	// 					});
	// 				});
	// 			};
	// 			subDict[cueNo] = func;
	// 			// func.();
	// 		});
	// 		~cues = ~cues.add(subDict);
	//
	// 	});
	// };


	~resetGUI = {
		var mvt;
		mvt = ~mvt;
		// ~resetClock.();
		// ~setAmpSlider.stop;
		~configFile.close;
		~synthSetArgs.do({
			arg set;
			// set.postln;
			set.stop;
			// ~synthSetArgs[synth].postln;
		});
		~synthSetArgs.do({
			arg i;
			i.stop;
		});
		// ~setGUIs.stop;
		// ~setGUIs.reset;
		s.quit;
		// w.close;
		Window.closeAll;
		Server.default.options.inDevice_(~inChoice);
		Server.default.options.outDevice_(~outChoice);
		s.waitForBoot({
			~loadGroups.();
			~loadSynths.();
			~init.();
			s.sync;
			~resetClock.();
			~clockStarted = true;
			~loadPaths.();
			~loadBufs2.();
			~generateSetArgs.();

			~loadCues.();

			~initGUI.();
			~playSeq[mvt].();
			~openWindow.();
			// ~openEditWindow.();
			// ~editWindow.close;
			// AppClock.play(~setGUIs);

			s.sync;
		});
	};
	~cueList;
	// ~cues[].postln;
	// ~controls.visible_(true);

	// ~mixer = HLayout(
	// );



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
		},"/button1");

		OSCdef.new(\countDownNext, {
			arg input;
			if (input[1] == 1.0, {
				AppClock.play({
					~advanceCue.();
				});
			});
		}, "/start");
		OSCdef.new(\countDownReset, {
			arg input;
			if (input[1] == 1.0, {
				AppClock.play({
					~resetAction.();
				});
			});

		}, "/reset");

		OSCdef.new(\countDownStop, {
			arg input;
			if (input[1] == 1.0, {
				AppClock.play({
					~bufGroup.freeAll;
					~effectGroup.set(\amp, 0);
					m.sendMsg(\curCue, "--");
					defer{ ~curtext.string_("");};

					~playStop.value_(1);
				});
			});
		}, "/stop");
	);

	~openWindow = {
		// ~streamDisplayView = View(w)
		// .fixedWidth_(100)
		// .layout_(
		// 	~streamDisplay = HLayout();
		// );
		// ~streamDisplayContent = ();
		//
		// ~mixerView = View(w)
		// // .fixedWidth_(100)
		// .layout_(
		// 	~mixer = HLayout();
		// );

		~currentCue = HLayout(
			StaticText().string_("Current File: ")
			.maxWidth_(100).maxHeight_(40).minWidth_(100)
			.font_(Font(size: 18)),

			~curtext = StaticText()
			.string_("")
			.font_(Font(size: 18))
			.background_(Color.gray(0.8, 0.5))
			.minWidth_(200).maxWidth_(400).maxHeight_(40)
		);

		~nextCue = HLayout(
			StaticText().string_("Next File: ")
			.font_(Font(size: 18))
			.maxWidth_(100).maxHeight_(40).minWidth_(100),

			~nexttext = StaticText()
			.string_(~files[0].file)
			.font_(Font(size: 18))
			.background_(Color.gray(0.8, 0.5))
			.minWidth_(200).maxWidth_(400).maxHeight_(40)
		);
		~clock = StaticText().string_(~time.asTimeString.drop(-4).drop(3))
		.font_(Font("Courier New", size:24))
		.background_(Color.gray(0.8, 0.5))
		.align_(\center)
		.minHeight_(80).maxWidth_(100).minWidth_(50);
		// ~cueSelect.items;
		// 0.asSymbol;
		~cueSelect = PopUpMenu().items_((1..~files.size).collect(_.asSymbol)).canFocus_(false)
		.minWidth_(50).maxWidth_(300)
		.allowsReselection_(true)
		.background_(Color.fromHexString("#a3bdc6"))
		.mouseDownAction_({
			~bufGroup.freeAll;
			defer{ ~curtext.string_(""); }; })
		.font_(Font(size: 18))
		.action_({
			arg n, editMode;
			var value, next;
			value = n.value;
			if (value == nil, {
				value = ~files.size-1;
			});
			// n = n.value.clip(-1, (~files.size - 1))
			~seq.reset;
			(n.value).do({
				// var next;
				next = ~seq.next;
				// next.postln;
				next[\ctrlfn].();
				// ~tempGroup.freeAll;

			});
			if (editMode == true, {
				next[\nextfn].();
			});

			// n.value.postln;
			// n.class.postln;
			~nexttext.string_(~files[value].file);
			~cueSelect.value_(value);
			~cueNumber = ~cueSelect.value;
			~cueRows.do({
				arg row, i;
				if ((i - 1) == n.value, {
					row.background_(~buttonColor);
				}, {
					row.background_(Color.gray(0.8, 0.5));
				}
				);
			});
			m.sendMsg("/nxtCue", ~cueSelect.value + 1);

		});

		~mvtSelect = PopUpMenu().items_(~pathList).canFocus_(false)
		.minWidth_(150).maxWidth_(300)
		.allowsReselection_(true)
		.background_(Color.fromHexString("#a3bdc6"))
		.mouseDownAction_({
			// ~bufGroup.freeAll;
			defer{ ~curtext.string_(""); }; })
		.font_(Font(size: 18))
		.action_({ |n|
			// n.value.postln;
			~playSeq[n.value].();
			// if(n.value == 0) {
			// 	~playSeq[n].();
			// };
			// if(n.value == 1) {
			// 	~mvt2.();
			// };
			~seq.reset;
		});

		~inList = ServerOptions.inDevices.insert(0, ~inChoice);
		~inSelect = PopUpMenu().items_(~inList).canFocus_(false)
		.minWidth_(200).maxWidth_(300)
		.allowsReselection_(true)
		.background_(Color.fromHexString("#a3bdc6"))
		.font_(Font(size: 18))
		.action_({ |n|
			~inChoice = ~inList[n.value];
			Server.default.options.inDevice_(~inChoice);
			// ~inChoice.postln;
			// n[n.value].postln;
			// s.quit;
			// s.waitForBoot({~init.()});
		});
		~outList = ServerOptions.outDevices.insert(0, ~outChoice);
		~outSelect = PopUpMenu().items_(~outList).canFocus_(false)
		.minWidth_(200).maxWidth_(300)
		.allowsReselection_(true)
		.background_(Color.fromHexString("#a3bdc6"))
		.font_(Font(size: 18))
		.action_({ |n|
			~outChoice = ~outList[n.value];
			Server.default.options.outDevice_(~outChoice);
			// ~outChoice.postln;
			// s.quit;
			// s.waitForBoot({~init.()});
		});


		// ~newWindow.bounds;
		// w.bounds;

		// w.close;


		w = Window("qFlo", Rect(100, 300, 500, 150))
		.alwaysOnTop_(true)
		.onClose_({
			~synthSetArgs.do({
				arg routine;
				routine.stop;
			});
			// ~synthSetArgs = Dictionary.new();
			~fluxDelayPairs.do({
				arg pair;
				pair[\routine].stop;
			});
			~setGUIs.stop;
			~setGUIs.reset;
			~inputGroup.free;
			~bufGroup.free;
			~effectGroup.free;
			~outputGroup.free;
			~tempGroup.free;
			// ~change.stop;
			// ~panning.stop;
			// ~setMicPanSlider.stop;
			// ~setAmpSlider.stop;
			// ~nPlay.stop;
			// ~slowPan.stop;
			~advanceClock.stop;
			s.newBusAllocators;
		})
		.background_(~mainColor)
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
			~main = HLayout(
				~initControl = VLayout(
					~cueFlow = HLayout(
						~cueDisplay = VLayout(
							// StaticText().string_(""),
							~currentCue,
							~nextCue,
						),
						~clock,
						// VLayout(
						// 	~delayButton = Button().states_([
						// 		["DELAY",Color.gray(0.6), ~buttonColor], ["DELAY",Color.green, ~buttonColor]
						// 	])
						// 	.canFocus_(false)
						// 	.action_({
						// 		// ~delayButton.value.postln;
						// 		if (~delayButton.value == 1, {
						// 			~delayOn.();
						// 		});
						// 		if (~delayButton.value == 0, {
						// 			~delayOff.();
						// 		});
						// 	}),
						//
						// 	~grainButton = Button().states_([
						// 		["GRAINS",Color.gray(0.6), ~buttonColor], ["GRAINS", Color.green, ~buttonColor]
						// 	])
						// 	.canFocus_(false)
						// 	.action_({
						// 		if(~grainButton.value == 1, {
						// 			~grainOn.();
						// 		});
						// 		if(~grainButton.value == 0, {
						// 			~grainOff.();
						// 		});
						// 	})
						// ),

					),
					// ~delayOn.();
					HLayout(
						~nextbtn = Button().states_([
							// ["PLAY NEXT (spacebar or MIDI pedal)", Color.gray(0.3), Color(0.7, 0.9, 1)]
							["NEXT", Color.gray(0.9), ~buttonColor]
						])
						.canFocus_(false)
						.minHeight_(50)
						.minWidth_(400)
						.maxWidth_(600)
						.font_(Font(size: 18))
						.action_({
							~advanceCue.();
						}),
					),
					// ~playSlider = Slider.new(w)
					// .orientation_(\horizontal)
					// .background_(Color.gray(0.8, 0.1))
					// .value_(~nPosValue)
					// .action_({
					// 	~nPosValue = ~playSlider.value;
					// 	~buf.free;
					// 	~buf = Synth(\playBuf, [\buf, b[~bufIndex].bufnum, \amp, ~bufAmp, \startPos, ~nPosValue, \numFrames, b[~bufIndex].numFrames, \out, ~eqBus, \ctrlOut, ~nPlayBus], target:~bufGroup);
					// 	// ~nPlay.reset;
					// 	// AppClock.play(~nPlay);
					// }),

					HLayout(
						StaticText().string_("PART: ")
						.minWidth_(50).maxWidth_(150)
						.align_(\right).font_(Font(size: 18)),
						~mvtSelect,
						StaticText().string_("CUE: ")
						.minWidth_(50).maxWidth_(150)
						.align_(\right).font_(Font(size: 18)),
						~cueSelect,
						~playStop = Button().states_([['GO', Color.green, ~buttonColor], ['GO', Color.gray, ~buttonColor]]).canFocus_(false)
						.font_(Font(size: 18))
						.action_({
							arg button;
							~goAction.(button: button);
						}),
						~reset = Button().states_([['RESET', Color.gray(0.9), ~buttonColor]]).canFocus_(false)
						.font_(Font(size: 18))
						.action_({
							~prepMvt.(~mvt);
							~resetAction.();



						}),
						~record = Button().states_([['RECORD', Color.red, ~buttonColor], ['RECORD', Color.gray, ~buttonColor]]).canFocus_(false)
						.font_(Font(size: 18))
						.value_(1)
						.action_({
							arg button;
							var value = button.value;
							if(value == 1, {
								// s.stopRecording;
								~bufRecord.stopRecording;
								~micRecord.stopRecording;
								~leRecord.stopRecording;
								~mainRecord.stopRecording;

							});
							if(value == 0, {
								~bufRecord.record(bus:~bufRecordBus);
								~micRecord.record(bus:~micRecordBus);
								~leRecord.record(bus:~leRecordBus);
								~mainRecord.record(bus:~mainRecordBus);
								// s.record;
							});
						})
					),
					~deviceSelector = HLayout(
						VLayout(
							StaticText().string_("In Device: ")
							.fixedWidth_(100)
							.font_(Font(size: 18)),
							StaticText().string_("Out Device: ")
							.fixedWidth_(100)
							.font_(Font(size: 18)),
						),
						VLayout(
							~inSelect,
							~outSelect,
						),
						~deviceChange = Button().states_([["SWITCH", Color.gray(0.9), ~buttonColor]]).canFocus_(false)
						.font_(Font(size: 18))
						.fixedHeight_(50)
						.maxWidth_(100)
						.action_({
							~resetGUI.();
						})

					),
				),
				~streamDisplayView,
				~mixerView,

				// ~controls,
				// VLayout(
				// 	StaticText().string_("EQ (buf)")
				// 	.font_(Font(size:18))
				// 	.align_(\center),
				// 	[~hiKnob, align:\center],
				// 	~hiBox,
				// 	[~midKnob, align:\center],
				// 	~midBox,
				// 	[~loKnob, align:\center],
				// 	~loBox
				// ),




			)
		).front;
		// ~editWindow = Window.new("");
	};
	// ~streamList[0][1].set(\density, 4);

	~generateFileString = {
		var outString;
		outString = "";
		// ~pathList.postln;
		~pathList.do({
			arg folder, i;
			outString = outString ++ folder;
			if (i < ((~pathList.size) - 1), {
				outString = outString ++ "|";
			});
		});
		outString = outString ++ "\n";
		// outString.postln;
		// ~streamList.postln;
		~streamList.do({
			arg stream, i;
			stream.do({
				arg synth, j;
				if (j > 0, {
					if (j < (stream.size - 1), {
						outString = outString ++ synth.defName;
						if (j < ((stream.size) - 2), {
							outString = outString ++ ";";
						});

					});
				});
			});
			if (i < ((~streamList.size) - 1), {
				outString = outString ++ "|";
			});

		});

		outString = outString ++ "\n";
		// outString.postln;

		// ~cueList.postln;
		~cueList.do({
			arg list, i;
			list.do({
				arg cue, j;
				cue.do({
					arg param, k;
					outString = outString ++ param.asString;
					if (k < ((cue.size) - 1), {
						outString = outString ++ ",";
					})
				});
				if (j < (list.size - 1), {
					outString = outString ++ ";";
				});
			});
			if (i < (~cueList.size - 1), {
				outString = outString ++ "|";
			});
		});
		outString = outString ++ "\n";
		~lagList.do({
			arg list, i;
			list.do({
				arg cue, j;
				cue.do({
					arg param, k;
					outString = outString ++ param.asString;
					if (k < ((cue.size) - 1), {
						outString = outString ++ ",";
					})
				});
				if (j < (list.size - 1), {
					outString = outString ++ ";";
				});
			});
			if (i < (~cueList.size - 1), {
				outString = outString ++ "|";
			});
		});
		outString;
	};

	~overWriteFile = {
		// ~configFile.close;
		~configFile = File.open(~filePath, "w");
		~configFile.write(~generateFileString.());
		~configFile.close;

	};

	~saveAsFile = {
		arg path;
		var newFile;
		newFile = File.open(path, "w");
		newFile.write(~generateFileString.());
		newFile.close;
	};

	// ~overWriteFile.();

	// ~generateFileString.().postln;

	~generateSetArgs.();
	~loadPaths.();
	~loadBufs2.();
	~loadCues.();

	// ~cues[0].size;
	// ~files[1].size;
	// ~pathList.do({
	// 	arg path, i;
	// 	if (~cueList[i].size < ~files
	// 	});
	// ~files.size;
	// ~cueList.size;
	// ~openEditWindow.();
	~openWindow.();
	~initGUI.();
	w.focus;
	~playSeq[0].();
	AppClock.play(~setGUIs);
	// ~setGUIs.stop;
	// AppClock.play(~nPlay);
	// AppClock.play(~setAmpSlider);
	// AppClock.play(~memDelUpdate);
	// AppClock.play(~advanceClock);
	// AppClock.play(~setMicPanSlider);


	// s.record;
	s.sync;

});
)
NetAddr.langPort;

OSCFunc.trace(true);
OSCFunc.trace(false);


~synthArgs.keysValuesDo({
	arg key, value;
	key.postln;
	value.postln;
	// [key, value].postln;
});

(
{
	s.record;
	s.sync;
}.fork;
)