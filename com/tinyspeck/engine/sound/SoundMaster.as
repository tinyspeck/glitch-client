package com.tinyspeck.engine.sound
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartSoundLoader;
	import com.tinyspeck.engine.loader.SmartURLLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingPlayMusicVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SortTools;
	
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.utils.getTimer;

	public class SoundMaster {
		
		/* singleton boilerplate */
		public static const instance:SoundMaster = new SoundMaster();
		
		private static const AMBIENT_FADE_MS:int = 1000;
		
		public var map:Object = {};
		
		private var xmlLoader:SmartURLLoader;
		private var model:TSModelLocator;
		private var loaded:Object = {};
		private var net_connection:NetConnection = new NetConnection();
		
		private var sound_url_root:String = 'http://files.tinyspeck.com/public/sounds/';
		private var music_id:String;
		
		private var total_bytes_loaded:int;
		private var ambient_track_index:int;
		CONFIG::debugging private var ambient_wait_time:uint; //used to track setTimeout bug
		
		private var can_play_ambient:Boolean;
		
		private var _is_sound_muted:Boolean;
		private var _sfx_volume:Number;
		private var _music_volume:Number;
		private var _ambient_library:Object;
		private var _current_ambient_set:String;

		public function SoundMaster() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private var add_count:int;
		private function addSound(name:String, file:String, is_music:Boolean, and_play:Boolean = false, loops:int = 0, fade:Number = 0, vol:Number = 1, is_exclusive:Boolean = false, allow_multiple:Boolean = false):void {
			var snd:Sound;
			var net_stream:NetStream;
			var url:String;
			
			if(!name){
				CONFIG::debugging {
					Console.warn('TRYING TO ADD A SOUND WITHOUT A NAME!', 'name: '+name, 'file: '+file);
				}
				return;
			}
			
			if (loaded[file]) {
				if(loaded[file] is Sound){
					snd = loaded[file];
				}
				else if(loaded[file] is NetStream){
					net_stream = loaded[file];
				}
				
			} else if(name.indexOf('.m4a') != -1) {
				//handle the m4a into the sounds
				net_stream = new NetStream(net_connection);
				loaded[file] = net_stream;
			} else {
				
				snd = new Sound();
				loaded[file] = snd;
				
				var ssl:SmartSoundLoader = new SmartSoundLoader(name, snd);
				ssl.complete_sig.add(onSoundLoadComplete);
				
				if (file.indexOf('http://') == 0) {
					url = file;
				} else {
					url = sound_url_root+file;
				}

				CONFIG::debugging {
					Console.log(66, name+' '+url);
				}
				
				ssl.load(new URLRequest(url));
			}
			
			//add the sound
			map[name] = snd ? snd : net_stream;
			SoundManager.instance.addSound(map[name], name, is_music, is_exclusive);
			
			//play the sound
			if(and_play) {
				playSound(name, loops, fade, is_music, is_exclusive, allow_multiple);
			}
		}
		
		private function onSoundLoadComplete(ssl:SmartSoundLoader):void {
			var snd:Sound = ssl.content;
			total_bytes_loaded+= ssl.bytesTotal;
			CONFIG::debugging {
				Console.log(420, '#'+(add_count++)+' '+ssl.name+' '+ssl.start_url+' '+(ssl.bytesTotal/1024).toFixed(1)+'kb total_bytes_loaded:'+(total_bytes_loaded/1024).toFixed(1)+'kb');
			}
		}
		
		public function init():void {
			SoundManager.instance.addEventListener(TSEvent.SOUND_COMPLETE, onSoundComplete, false, 0, true);
			
			//init the m4a
			net_connection.connect(null);
			
			//init the audio processor
			//SoundProcessor.instance.init();
			
			//handle user sounds
			isSoundMuted = LocalStorage.instance.getUserData(LocalStorage.IS_SOUND_MUTED);
			_sfx_volume = LocalStorage.instance.getUserData(LocalStorage.SFX_VOLUME);
			_music_volume = LocalStorage.instance.getUserData(LocalStorage.MUSIC_VOLUME);
			
			if(LocalStorage.instance.getUserData(LocalStorage.SFX_VOLUME) == undefined){
				//new user
				saveAudioLevels(SoundManager.DEFAULT_SFX_VOLUME, SoundManager.DEFAULT_MUSIC_VOLUME);
				
				_sfx_volume = SoundManager.DEFAULT_SFX_VOLUME;
				_music_volume = SoundManager.DEFAULT_MUSIC_VOLUME;
			}
			
			model = TSModelLocator.instance;
			var A:Array = AssetManager.instance.assets.soundsA;
			for (var i:int=0;i<A.length;i++) {
				map[A[int(i)]] = new AssetManager.instance.assets[A[int(i)]]()
				SoundManager.instance.addSound(map[A[int(i)]] as Sound, A[int(i)], false);
			}
			/*
			<sounds>
				<category name="General">
					<sound name="CLICK_SUCCESS" desc="click failed" file="Button.mp3" />
					<sound name="CLICK_FAILURE" desc="click failed" file="Uh_Oh.mp3" />
				</category>
			*/
			var sounds_file:String = model.flashVarModel.sounds_file;
			//Console.error('sm sounds_file:'+sounds_file)
			
			if (sounds_file) {
				sound_url_root = sounds_file.substr(0, sounds_file.lastIndexOf('/')+1);
			}
			
			xmlLoader = new SmartURLLoader('SoundMaster');
			// these are automatically removed on complete or error:
			xmlLoader.complete_sig.add(onXMLComplete);
			xmlLoader.error_sig.add(onXMLError);
			
			var url:String = 'http://files.tinyspeck.com/public/sounds/';
			
			if (sounds_file) {
				if (sounds_file.indexOf('http://') == 0) {
					url = sounds_file;
				} else {
					url+= sounds_file;
				}
			} else {
				url+= 'sounds.xml';
			}
			
			CONFIG::debugging {
				Console.log(66, url);
			}
			xmlLoader.load(new URLRequest(url));		
		}
		
		private function onXMLComplete(loader:SmartURLLoader):void {
			XML.ignoreWhitespace = true;
			var xml:XML = new XML(loader.data);
			//Console.info(xml);
			//Console.info(xml..sound.length()+'!!');
			var sound:XML;
			var file:String;
			var name:String;
			if (xml..sound) {
				for (var i:int=0; i<xml..sound.length(); i++) {
					sound = xml..sound[int(i)];
					file = sound.attribute('file');
					name = sound.attribute('name');
					//Console.info(i+' '+file+' '+sound)
					if (!file) continue;
					
					if (model.flashVarModel.preload_sounds) {
						// this will go ahead and load it
						addSound(name, file, false);
					} else {
						// keep track of it.
						sound_id_to_url_map[name] = file;
					}
					
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('not sounds in xml '+xml..sound);
				}
			}
		}
		
		private function onXMLError(loader:SmartURLLoader):void {
			//TODO
			trace('!!!!!!!' + loader.eventLog);
		}
		
		public function playSoundAllowMultiples(sound_id:String):void {
			playSound(sound_id, 0, 0, false, false, true);
		}
		
		// if sound_id is a url and it is not in the map, it will be loaded and then played
		public function playSound(sound_id:String, a_loops:int = 0, a_fade:Number = 0, is_music:Boolean = false, is_exclusive:Boolean = false, allow_multiple:Boolean = false):void {
			//if (SoundManager.instance.isPlaying(sound_id)) return;
			var channel:SoundChannel;
			var volume:Number = sfx_volume;
			var can_play:Boolean;
			if(is_music) volume = music_volume;
			
			if (sound_id in map) {
				CONFIG::debugging {
					Console.log(83, 'calling SoundManager.instance.playSound with '+sound_id)
				}
				
				if (map[sound_id] is Sound){
					if(map[sound_id].length > 0 || Sound(map[sound_id]).isBuffering){
						can_play = true;
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('Sound "'+sound_id+'" has no length. Probably failed to load Sound(map[sound_id]).isBuffering:'+Sound(map[sound_id]).isBuffering)
						}
					}
				} else if (map[sound_id] is NetStream) {
					can_play = true;
				} else {
					;// satisfy compiler
					CONFIG::debugging {
						Console.error('Unknown sound type: '+sound_id);
					}
				}
				
				if(can_play) {
					if(is_exclusive || is_music){
						if(is_ambient_playing) ambientStop();
						
						//this guy gets to play over everything
						stopAllSoundEffects(.5);
						
						//pause the music if we have a music_id
						if(music_id && sound_id != music_id) pauseMusic(music_id);
						
						//if this is music coming in and it has the instance loop count, we want to be able to resume it if it gets cut
						if(is_music && a_loops == SoundManager.INSTANCE_LOOP_COUNT){
							//check to see if there was an id already set, and stop that music if so
							if(music_id && sound_id != music_id) stopSound(music_id, 1);
							music_id = sound_id;
						}
					}
					
					//play it
					SoundManager.instance.playSound(sound_id, volume, 0, a_loops, a_fade, false, is_exclusive, allow_multiple);
				}
			} else {
				if (sound_id.indexOf('http://') == 0) {
					addSound(sound_id, sound_id, is_music, true, a_loops, a_fade, volume, is_exclusive, allow_multiple);
				} else if (sound_id_to_url_map[sound_id] && sound_id_to_url_map[sound_id].indexOf('http://') == 0) {
					addSound(sound_id, sound_id_to_url_map[sound_id], is_music, true, a_loops, a_fade, volume, is_exclusive, allow_multiple);
				} else {
					CONFIG::debugging {
						Console.warn('unknown sound_id, and it was not in sound_id_to_url_map, and it was not a url:'+sound_id);
					}
				}
			}
		}
		
		// for mapping sound id to url from the sounds xml we load
		private var sound_id_to_url_map:Object = {};
		
		public function stopSound(sound_id:String, a_fade:Number = 0):void {
			//if this was the id that had many loops, make sure we kill that
			if(music_id == sound_id) music_id = null;
			SoundManager.instance.stopSound(sound_id, a_fade);
			
			//resume playing our audio if we have it
			if(music_id){
				SoundManager.instance.resumeSound(music_id, _music_volume, AMBIENT_FADE_MS/1000);
			}
			else {
				ambientPlay();
			}
		}
		
		//TODO: allow passing of sound effects or music
		public function muteAllSounds(isMuted:Boolean):void {
			var volume:Number = 0;
			if(!isMuted) volume = 1;
			
			_is_sound_muted = isMuted;
			
			SoundMixer.soundTransform = new SoundTransform(volume);
			
			LocalStorage.instance.setUserData(LocalStorage.IS_SOUND_MUTED, isMuted, true);
		}
		
		public function stopAllSoundEffects(fade_secs:Number = 0):void {
			SoundManager.instance.stopAllSounds(false, fade_secs);
		}
		
		public function stopAllMusic(fade_secs:Number = 0):void {
			SoundManager.instance.stopAllSounds(true, fade_secs);
			
			//nothing to resume back to after
			music_id = null;
		}
		
		public function testSound(sound_id:String, is_music:Boolean, loop_count:int = 0):void {
			//if the sound is currently playing, stop it
			if(!SoundManager.instance.isSoundPaused(sound_id)){
				if(is_music){
					stopAllMusic();
					var index:int = SoundManager.instance.music_sound_id.indexOf(sound_id);
					if(index >= 0) SoundManager.instance.music_sound_id.splice(index, 1);
				}
				else {
					stopSound(sound_id);
				}
			}
			else {
				if(!is_music){
					//play the sound from the loaded XML file
					playSound(sound_id, loop_count, 0, is_music);
				}
				else {
					//tell the server to play it
					if(SoundManager.instance.music_sound_id.indexOf(sound_id) == -1){
						SoundManager.instance.music_sound_id.push(sound_id);
					}
					TSFrontController.instance.genericSend(new NetOutgoingPlayMusicVO(sound_id, loop_count), onPlayMusic, onPlayMusic);
				}
			}
		}
		
		private function onPlayMusic(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('That music name sure was wrong!');
			}
		}
		
		public function get isSoundMuted():Boolean {
			return LocalStorage.instance.getUserData(LocalStorage.IS_SOUND_MUTED);
		}
		
		public function set isSoundMuted(value:Boolean):void {
			muteAllSounds(value);
		}
		
		public function get sfx_volume():Number {
			if(LocalStorage.instance.getUserData(LocalStorage.SFX_VOLUME) == undefined){
				//set the sfx to default
				sfx_volume = SoundManager.DEFAULT_SFX_VOLUME;
				return SoundManager.DEFAULT_SFX_VOLUME;
			}
			
			return SoundManager.instance.sfx_volume;
		}
		
		public function set sfx_volume(volume:Number):void {
			//Console.trackValue("SM SFX", volume);
			
			_sfx_volume = volume;
			
			if(volume > 0 && _is_sound_muted){ 
				isSoundMuted = false;
			}else if(volume == 0 && _music_volume == 0){
				//mute this bad boy
				isSoundMuted = true;
			}
			
			SoundManager.instance.setVolume(volume);
		}
		
		public function get music_volume():Number {
			if(LocalStorage.instance.getUserData(LocalStorage.MUSIC_VOLUME) == undefined){
				//set the music to default
				music_volume = SoundManager.DEFAULT_MUSIC_VOLUME;
				return SoundManager.DEFAULT_MUSIC_VOLUME;
			}
			
			return SoundManager.instance.music_volume;
		}
		
		public function set music_volume(volume:Number):void {
			//Console.trackValue("SM Music", volume);
			_music_volume = volume;
			
			if(volume > 0  && _is_sound_muted){ 
				isSoundMuted = false;
			}else if(volume == 0 && _sfx_volume == 0){
				//mute this bad boy
				isSoundMuted = true;
			}
			
			//if we haven't loaded up the ambiant music and they've turned it up, go ahead and start loading it
			if(volume > 0 && !is_ambient_playing && model && model.worldModel && model.worldModel.location && !model.worldModel.location.no_ambient_music){
				ambientPlay(false);
			}
			else if(volume == 0 && is_ambient_playing){
				ambientStop();
			}
			
			SoundManager.instance.setVolume(volume, true);
		}
		
		public function get is_ambient_playing():Boolean { 
			if(!ambient_tracks) return false;
			
			var i:int;
			var total:int = ambient_tracks.length;
			var is_playing:Boolean;
			
			for(i; i < total; i++){
				if(!SoundManager.instance.isSoundPaused(ambient_tracks[i])){
					is_playing = true;
				}
			}
			
			return is_playing;
		}
		
		/**
		 * Use this when knowing if the ambient music can kick back in again 
		 * @return 
		 */		
		public function get is_other_music_playing():Boolean { 			
			var i:int;
			var is_playing:Boolean;
			var sounds:Array = SoundManager.instance.sounds;
			var total:int = sounds.length;
			
			for(i; i < total; i++){
				if(sounds[int(i)].paused === false && (sounds[int(i)].isMusic === true || sounds[int(i)].isExclusive === true)){
					is_playing = true;
				}
			}
			
			return is_playing;
		}

		public function get current_ambient_set():String {
			return _current_ambient_set;
		}

		public function changeAmbientSet(value:String, wait_ms:int=1000):void {
			//Console.warn('AMBIENT changing set from:'+current_ambient_set+' to:'+value);
			
			if (value == current_ambient_set) {
				//we may have stopped the ambient (eg. instance) and coming back to the same area after needs to resume the music
				if(!is_ambient_playing) ambientPlay();
				return;
			}
			
			if (!ambient_library[value]) {
				CONFIG::debugging {
					Console.warn(value+' not in ambient_library');
				}
				return;
			}
			
			ambientStop();
			ambient_track_index = 0;
			_current_ambient_set = value;
			//Console.warn(_current_ambient_set);
			
			// we must wait at least as long as it takes to fade out the previous ambient tracks
			CONFIG::debugging {
				ambient_wait_time = getTimer();
			}
			StageBeacon.setTimeout(ambientPlay, Math.max(wait_ms, AMBIENT_FADE_MS+1));
		}
		
		public function get ambient_tracks():Array {
			if (!ambient_library) return null;
			if (!current_ambient_set) return null;
			return ambient_library[current_ambient_set];
		}

		public function get ambient_library():Object { return _ambient_library; }
		public function set ambient_library(value:Object):void {
			for (var k:String in value) {
				if (value[k] is Array) value[k] = SortTools.shuffleArray(value[k]);
			}
			
			_ambient_library = value;
		}
		
		public function saveAudioLevels(sfx_volume:Number, music_volume:Number):void {
			LocalStorage.instance.setUserData(LocalStorage.SFX_VOLUME, sfx_volume, true);
			LocalStorage.instance.setUserData(LocalStorage.MUSIC_VOLUME, music_volume, true);
		}
		
		public function ambientPlay(and_fade:Boolean = true):void {
			//this should be called when the client is allowed to go fetch the mp3s and play them
			
			CONFIG::debugging {
				if(ambient_wait_time){
					Console.warn('SET TIMEOUT TOOK ABOUT THIS LONG:', (getTimer() - ambient_wait_time) + 'ms');
					ambient_wait_time = 0;
				}
			}
			//Console.warn('AMBIENT PLAY CALLED');
			can_play_ambient = true;
			if(!ambient_tracks) {
				//Console.warn('AMBIENT ambient_tracks:'+Boolean(ambient_tracks));
				return;
			}
			if(is_ambient_playing) {
				//Console.warn('AMBIENT is_ambient_playing:'+is_ambient_playing);
				return;
			}
			if(is_other_music_playing) {
				//Console.warn('AMBIENT is_other_music_playing:'+is_other_music_playing);
				return;
			}
			if(music_id) {
				//Console.warn('AMBIENT music_id is set:'+music_id);
				return;
			}
			if(model.worldModel.location && model.worldModel.location.no_ambient_music){
				//Console.warn('AMBIENT No ambient music allowed!');
				return;
			}
						
			if(_music_volume > 0 && ambient_tracks){
				//go fetch and play if needed
				if(!loaded[ambient_tracks[ambient_track_index]]){
					//Console.warn('AMBIENT TRACK NOT LOADED', ambient_tracks[ambient_track_index]);
					addSound(ambient_tracks[ambient_track_index], ambient_tracks[ambient_track_index], true, true, 0, AMBIENT_FADE_MS/1000, _music_volume);
				}
				else if(!is_ambient_playing){
					//resume the track we just paused
					//Console.warn('resumeSound '+ambient_tracks[ambient_track_index], 'vol: '+_music_volume);
					SoundManager.instance.resumeSound(ambient_tracks[ambient_track_index], _music_volume, AMBIENT_FADE_MS/1000);
				}		
			}
		}
		
		public function ambientStop():void {
			//fade out the ambient music if any of them are playing
			if(!ambient_tracks) return;
			can_play_ambient = false;
						
			var i:int;
			var total:int = ambient_tracks.length;
			var sound_obj:Object;
						
			for(i; i < total; i++){
				if(!SoundManager.instance.isSoundPaused(ambient_tracks[int(i)])){
					pauseMusic(ambient_tracks[int(i)]);
					ambient_track_index = i;
				}
			}
		}
		
		public function loadMultiple(sounds_array:Array, and_play:Boolean, is_music:Boolean = true, and_fade:Boolean = true):void {
			if(!sounds_array){
				CONFIG::debugging {
					Console.warn('loadMultiple was passed no array, that\'s silly!');
				}
				return;
			}
			
			var i:int;
			var total:int = sounds_array.length;
						
			//add the sounds to the map, play the first one if we need to
			for(i; i < total; i++){
				addSound(sounds_array[i], sounds_array[i], is_music, (and_play && i == 0), 0, (and_play && i == 0 && and_fade ? AMBIENT_FADE_MS/1000 : 0), is_music ? _music_volume : _sfx_volume);
			}
		}
		
		private function pauseMusic(sound_id:String, fade_secs:Number = 1):void {
			if(_music_volume > 0 && fade_secs > 0){
				SoundManager.instance.fadeSound(sound_id, 0, fade_secs, SoundManager.instance.pauseSound, [sound_id]);
			}
			else {
				//if the audio is nothing, don't worry about fading it, just pause it
				SoundManager.instance.pauseSound(sound_id);
			}
		}
		
		private function onSoundComplete(event:TSEvent):void {			
			//if this was our music_id clear it out and let ambient take over
			if(event.data == music_id) music_id = null;
			
			//resume the music_id if there is one
			if(music_id) {
				SoundManager.instance.resumeSound(music_id, music_volume, 1.5);
				return;
			}
			
			//let's see if this was an ambient track, if so, go get the next one, if not, resume ambient music
			if(!ambient_tracks) return;
			
			var index:int = ambient_tracks.indexOf(event.data);
			
			if(index != -1 && (can_play_ambient || is_ambient_playing)){
				//get the next track
				ambient_track_index++;
				if(ambient_track_index >= ambient_tracks.length) ambient_track_index = 0;
				
				//play the next sound
				if(!loaded[ambient_tracks[ambient_track_index]]){
					addSound(ambient_tracks[ambient_track_index], ambient_tracks[ambient_track_index], true, true, 0, 0, _music_volume);
				}
				else {
					SoundManager.instance.playSound(ambient_tracks[ambient_track_index], _music_volume, 0, 0, 0, true);
				}
				
				can_play_ambient = true;
			}
			else if(index == -1) {
				//resume playing the music
				ambientPlay();
			}
		}
	}
}