/*
This file used to live in src.com.reintroducing.sound, but I moved it into our tree 2012/10/01
*/

package com.tinyspeck.engine.sound
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * The SoundManager is a singleton that allows you to have various ways to control sounds in your project.
	 * <p />
	 * The SoundManager can load external or library sounds, pause/mute/stop/control volume for one or more sounds at a time, 
	 * fade sounds up or down, and allows additional control to sounds not readily available through the default classes.
	 * <p />
	 * This class is dependent on TweenLite (http://www.tweenlite.com) to aid in easily fading the volume of the sound.
	 * 
	 * @author Matt Przybylski [http://www.reintroducing.com]
	 * @version 1.0
	 */
	public class SoundManager extends EventDispatcher
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------
		//defaults
		public static const DEFAULT_SFX_VOLUME:Number = .6;
		public static const DEFAULT_MUSIC_VOLUME:Number = .6;
		public static const INSTANCE_LOOP_COUNT:uint = 999; //this is how many times instance audio loops
		
		// singleton instance
		public static const instance:SoundManager = new SoundManager();
		
		//which sounds are allowed to play more than one at a time
		private static const MULTIPLE_INSTANCES:Array = ['QUOIN_GOT', 'CLICK_SUCCESS', 'CLICK_FAILURE', 'TOGGLE_VIEWPORT_SCALE_ONE_CLICK', 
														 'OPEN_HUB_MAP', 'CLOSE_HUB_MAP', 'FLIP_BACK', 'FLIP_OVER', 'IMAGINATION_OPEN', 'IMAGINATION_CLOSE',
														 'YOU_WIN', 'INCOMING_CHAT', 'INCOMING_CHAT_NEW', 'DOOR_OPEN', 'DOOR_CLOSE',
														 'COMPLETE_QUEST_REQUIREMENT'];
		
		//which sounds are allowed to play through a stop_all_sound_effects message
		private static const DOES_NOT_STOP:Array = ['TELEPORT_AWAY', 'TELEPORT_AWAY_HUB', 'LEVEL_UP', 
													'ACHIEVEMENT_UNLOCKED', 'TROPHY_RECEIVED', 'SKILL_ACHIEVED', 'NEW_DAY',
													'QUEST_COMPLETE', 'FIRST_STREET_LOADING', 'CLIENT_LOADED', 'HEARTBEAT'];
		
		//hold on to a list of music IDs that we are testing
		public var music_sound_id:Array = new Array();
		
		private var _soundsDict:Dictionary;
		private var _sounds:Array;
		private var muted:Boolean = false;
		
//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------
		
		
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
	
		public function SoundManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_soundsDict = new Dictionary(true);
			_sounds = new Array();
		}
		
//- PRIVATE & PROTECTED METHODS ---------------------------------------------------------------------------
		
		
		
//- PUBLIC & INTERNAL METHODS -----------------------------------------------------------------------------
	
		/**
		 * Adds a sound from the library to the sounds dictionary for playing in the future.
		 * 
		 * @param $linkageID The class name of the library symbol that was exported for AS
		 * @param $name The string identifier of the sound to be used when calling other methods on the sound
		 * 
		 * @return Boolean A boolean value representing if the sound was added successfully
		 */
		public function addLibrarySound($linkageID:*, $name:String, $isMusic:Boolean):Boolean
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				if (this._sounds[i].name == $name) return false;
			}
			
			var snd:Sound = new $linkageID;
			
			return addSound(snd, $name, $isMusic);
		}

		public function addSound(snd:*, $name:String, $isMusic:Boolean, $isExclusive:Boolean = false):Boolean
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				if (this._sounds[i].name == $name) return false;
			}
			
			//if we are using m4a we need to add a couple of things
			if(snd is NetStream){
				NetStream(snd).addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError, false, 0, true);
				NetStream(snd).client = this;
			}
			
			var sndObj:Object = new Object();
			
			sndObj.name = $name;
			sndObj.sound = snd;
			sndObj.channel = new SoundChannel();
			sndObj.position = 0;
			sndObj.paused = true;
			sndObj.volume = 1;
			sndObj.startTime = 0;
			sndObj.loops = 0;
			sndObj.pausedByAll = false;
			sndObj.isMusic = $isMusic;
			sndObj.isExclusive = $isExclusive;
			
			this._soundsDict[$name] = sndObj;
			this._sounds.push(sndObj);
			
			return true;
		}
		
		/**
		 * Adds an external sound to the sounds dictionary for playing in the future.
		 * 
		 * @param $path A string representing the path where the sound is on the server
		 * @param $name The string identifier of the sound to be used when calling other methods on the sound
		 * @param $buffer The number, in milliseconds, to buffer the sound before you can play it (default: 1000)
		 * @param $checkPolicyFile A boolean that determines whether Flash Player should try to download a cross-domain policy file from the loaded sound's server before beginning to load the sound (default: false) 
		 * 
		 * @return Boolean A boolean value representing if the sound was added successfully
		 */
		public function addExternalSound($path:String, $name:String, $isMusic:Boolean, $buffer:Number = 1000, $checkPolicyFile:Boolean = false):Boolean
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				if (this._sounds[i].name == $name) return false;
			}
			
			var sndObj:Object = new Object();
			var snd:Sound = new Sound(new URLRequest($path), new SoundLoaderContext($buffer, $checkPolicyFile));
			
			sndObj.name = $name;
			sndObj.sound = snd;
			sndObj.channel = new SoundChannel();
			sndObj.position = 0;
			sndObj.paused = true;
			sndObj.volume = 1;
			sndObj.startTime = 0;
			sndObj.loops = 0;
			sndObj.pausedByAll = false;
			sndObj.isMusic = $isMusic;
			sndObj.isExclusive = false;
			
			this._soundsDict[$name] = sndObj;
			this._sounds.push(sndObj);
			
			return true;
		}
		
		/**
		 * Removes a sound from the sound dictionary.  After calling this, the sound will not be available until it is re-added.
		 * 
		 * @param $name The string identifier of the sound to remove
		 * 
		 * @return void
		 */
		public function removeSound($name:String):void
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				if (this._sounds[i].name == $name)
				{
					this._sounds[i] = null;
					this._sounds.splice(i, 1);
				}
			}
			
			delete this._soundsDict[$name];
		}
		
		/**
		 * Removes all sounds from the sound dictionary.
		 * 
		 * @return void
		 */
		public function removeAllSounds():void
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				this._sounds[i] = null;
			}
			
			this._sounds = new Array();
			this._soundsDict = new Dictionary(true);
		}

		/**
		 * Plays or resumes a sound from the sound dictionary with the specified name.
		 * 
		 * @param $name The string identifier of the sound to play
		 * @param $volume A number from 0 to 1 representing the volume at which to play the sound (default: 1)
		 * @param $startTime A number (in milliseconds) representing the time to start playing the sound at (default: 0)
		 * @param $loops An integer representing the number of times to loop the sound (default: 0)
		 * 
		 * @return void
		 */
		public function playSound($name:String, $volume:Number = 1, $startTime:Number = 0, $loops:int = 0, $fade:Number = 0, $forceFromStart:Boolean = false, $isExclusive:Boolean = false, $allowMultiple:Boolean = false):void
		{
			//Console.info($name+' vol:'+$volume+' fade:'+$fade);
			var snd:Object = this._soundsDict[$name];
			
			// we used to bail if there was no sound channel, but we don't have to. We just make sure
			// we have a channel below before we try to do something with it! EC
			//if (!snd || (snd && !snd.channel)) return;
			
			// so now we can just do this:
			if (!snd) return;
			
			//if this is an exclusive track, we need to reset it, and allow it to be played again
			if($isExclusive && snd.paused === false){
				stopSound($name);
			}
			
			//if this is fading, let's stop it so it can be played again
			if(snd.channel && TSTweener.isTweening(snd.channel)) {
				TSTweener.removeTweens(snd.channel);
				stopSound($name);
			}
						
			//don't play more than one version
			if(MULTIPLE_INSTANCES.indexOf($name) == -1 && snd.paused === false && !$allowMultiple){
				return;
			}
			
			snd.volume = $volume;
			snd.startTime = $startTime;
			snd.loops = $loops;
			snd.currentLoop = 0;
			snd.isExclusive = $isExclusive;
						
			if($fade > 0 || muted) snd.volume = 0;
			
			const sndTransform:SoundTransform = new SoundTransform(snd.volume);
			$startTime = snd.paused ? ($forceFromStart ? 0 : snd.position) : $startTime;
			
			if(snd.sound is Sound){
				try {
					// Sound.play returns:
					// SoundChannel — A SoundChannel object, which you use to control the sound.
					// This method returns null if you have no sound card or if you run out of
					// available sound channels. The maximum number of sound channels available
					// at once is 32. 
					snd.channel = Sound(snd.sound).play($startTime, snd.loops, sndTransform);
					
					//find out when it's done
					if(snd.channel && !SoundChannel(snd.channel).hasEventListener(Event.SOUND_COMPLETE)){
						SoundChannel(snd.channel).addEventListener(Event.SOUND_COMPLETE, onSoundComplete, false, 0, true);
					}
				} catch (e:Error) {
					BootError.handleError('Tried to play, but no dice: '+
						'\n  loaded-'+Sound(snd.sound).bytesLoaded+
						'\n  total-'+Sound(snd.sound).bytesTotal+
						'\n  buffering-'+Sound(snd.sound).isBuffering+
						'\n  length-'+Sound(snd.sound).length+
						'\n  channel-'+snd.channel+
						'\n  start time-'+$startTime+
						'\n  loops-'+snd.loops+
						'\n  transform-'+sndTransform+
						'\n  name-'+$name, e, ['sound'], true, false);
					return;
				}
			}
			else if(snd.sound is NetStream){
				NetStream(snd.sound).play($name);
				NetStream(snd.sound).soundTransform = sndTransform;
				
				//find out when it's done
				if(!NetStream(snd.sound).hasEventListener(NetStatusEvent.NET_STATUS)){
					NetStream(snd.sound).addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, 0, true);
				}
			}
			
			snd.paused = false;
			
			if($fade > 0 && !muted) fadeSound($name, $volume, $fade);
			
			//let the dict know what the volume SHOULD be after an un-mute
			snd.volume = $volume;
			
			// we missing our sound channel?
			// NO WORRIES! it just means all 32 sound channels were used up. sad, but not the end of the world.
			// maybe we should try agian in a little while though? especially if it is music!!
			// So, as of 10.24.2012 we no longer care about this. EC
			/*if(snd.sound is Sound && !snd.channel){
				BootError.handleError('Missing some sound stuff: ' +
					'\n  loaded-'+Sound(snd.sound).bytesLoaded+
					'\n  total-'+Sound(snd.sound).bytesTotal+
					'\n  buffering-'+Sound(snd.sound).isBuffering+
					'\n  length-'+Sound(snd.sound).length+
					'\n  music-'+snd.isMusic+
					'\n  exclusive-'+snd.isExclusive+
					'\n  channel-'+snd.channel+
					'\n  start time-'+$startTime+
					'\n  loops-'+snd.loops+
					'\n  transform-'+sndTransform+
					'\n  name-'+$name, new Error('playSound sucks'), ['sound'], true, false);
			}*/
		}
		
		/**
		 * Stops the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return void
		 */
		public function stopSound($name:String, $fade:Number = 0):void {
			const snd:Object = this._soundsDict[$name];
			
			if(snd != null){
				//Console.warn('Stopping Sound: '+$name);
				if(snd.channel && TSTweener.isTweening(snd.channel)) TSTweener.removeTweens(snd.channel);
				if($fade > 0){
					fadeSound($name, 0, $fade, onStopFadeComplete, [snd]);
				}
				else {
					onStopFadeComplete(snd);
				}
			}
			else{
				CONFIG::debugging {
					Console.warn('Calling stopSound on "'+$name+'" returned null');
				}
			}
		}
		
		private function onStopFadeComplete(snd:Object):void {
			if(!snd) return;
			
			snd.paused = true;
			snd.currentLoop = 0;
			
			if(snd.sound is Sound){
				if(snd.channel) {
					snd.channel.stop();
					if(SoundChannel(snd.channel).hasEventListener(Event.SOUND_COMPLETE)){
						//clean up the listener
						SoundChannel(snd.channel).removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					}
				}
				snd.position = 0;
			}
			else if(snd.sound is NetStream){
				NetStream(snd.sound).close();
				onNetStatus(new NetStatusEvent('phoney', false, false, {status:'whatever', code:'NetStream.Play.Stop'}));
			}
		}
		
		/**
		 * Pauses the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return void
		 */
		public function pauseSound($name:String):void
		{
			var snd:Object = this._soundsDict[$name];
			snd.paused = true;
			if(snd.sound is Sound){
				//in the event we may be fading, stop the fade
				if('channel' in snd && TSTweener.isTweening(snd.channel)) TSTweener.removeTweens(snd.channel);
				snd.position = snd.channel.position;
				snd.channel.stop();
			}
			else if(snd.sound is NetStream){
				NetStream(snd.sound).pause();
			}
		}
		
		public function resumeSound($name:String, $volume:Number, $fadeTime:Number = 1):void {
			var snd:Object = this._soundsDict[$name];
			if(!snd){
				CONFIG::debugging {
					Console.warn('Trying to resume a sound that is not there: '+$name);
				}
				return;
			}
			
			if(!isSoundPaused($name)){
				//it's not paused, so nothing really to resume now is there
				return;
			}
			
			//un-pause and go!
			snd.paused = false;
			snd.volume = $fadeTime > 0 ? 0 : $volume;
									
			//if we are just finishing the song, or close to it, fire the complete
			if(snd.sound is Sound){
				if(getSoundPosition($name) < getSoundDuration($name)){
					//Console.warn('RESUMING SOUND: '+$name+' from time: '+snd.position);
					
					//if we are already fading, stop fading! (and set the volume to where it's currently at)
					if('channel' in snd && TSTweener.isTweening(snd.channel)) {
						TSTweener.removeTweens(snd.channel);
						snd.volume = SoundChannel(snd.channel).soundTransform.volume;
						SoundChannel(snd.channel).stop();
					}
					
					snd.channel = Sound(snd.sound).play(snd.position, 0, new SoundTransform(snd.volume));
					
					if((snd.isMusic === true || snd.isExclusive === true) && !SoundChannel(snd.channel).hasEventListener(Event.SOUND_COMPLETE)){
						SoundChannel(snd.channel).addEventListener(Event.SOUND_COMPLETE, onSoundComplete, false, 0, true);
					}
					
					//reset the position
					snd.position = 0;
				}
				else {
					//reset the position
					snd.position = 0;
					
					onSoundComplete(new TSEvent(TSEvent.SOUND_COMPLETE, snd.channel));
				}
			}
			else if(snd.sound is NetStream){
				if(snd.isMusic){
					NetStream(snd.sound).addEventListener(NetStatusEvent.NET_STATUS, onNetStatus, false, 0, true);
				}
				NetStream(snd.sound).soundTransform = new SoundTransform(snd.volume);
				NetStream(snd.sound).resume();
			}
			
			//fade if we need to
			if($fadeTime > 0) fadeSound($name, $volume, $fadeTime);
		}
		
		/**
		 * Plays all the sounds that are in the sound dictionary.
		 * 
		 * @param $useCurrentlyPlayingOnly A boolean that only plays the sounds which were currently playing before a pauseAllSounds() or stopAllSounds() call (default: false)
		 * 
		 * @return void
		 */
		public function playAllSounds($useCurrentlyPlayingOnly:Boolean = false):void
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				var id:String = this._sounds[i].name;
				
				if ($useCurrentlyPlayingOnly)
				{
					if (this._soundsDict[id].pausedByAll)
					{
						this._soundsDict[id].pausedByAll = false;
						this.playSound(id);
					}
				}
				else
				{
					this.playSound(id);
				}
			}
		}
		
		/**
		 * Stops all the sounds that are in the sound dictionary.
		 * 
		 * @return void
		 */
		public function stopAllSounds(is_music:Boolean, fade_secs:Number = 0):void
		{
			var i:int;
			var total:int = this._sounds.length;
			var id:String;
			var snd:Object;
			
			for (i; i < total; i++){
				id = this._sounds[i].name;
				snd = this._soundsDict[id];
				
				//if we aren't supposed to stop this one, keep on going
				if(DOES_NOT_STOP.indexOf(snd.name) != -1 || MULTIPLE_INSTANCES.indexOf(snd.name) != -1) continue;
				
				if (!snd.paused) {
					if(snd.isMusic && is_music){
						snd.pausedByAll = true;
						if(fade_secs){
							fadeSound(id, 0, fade_secs, stopSound, [id]);
						}
						else {
							stopSound(id);
						}
					}
					else if(!snd.isMusic && !is_music){
						snd.pausedByAll = true;
						if(fade_secs){
							fadeSound(id, 0, fade_secs, stopSound, [id]);
						}
						else {
							stopSound(id);
						}
					}
				}
			}
		}
		
		/**
		 * Pauses all the sounds that are in the sound dictionary.
		 * 
		 * @param $useCurrentlyPlayingOnly A boolean that only pauses the sounds which are currently playing (default: true)
		 * 
		 * @return void
		 */
		public function pauseAllSounds($useCurrentlyPlayingOnly:Boolean = true):void
		{
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				var id:String = this._sounds[i].name;
				
				if ($useCurrentlyPlayingOnly)
				{
					if (!this._soundsDict[id].paused)
					{
						this._soundsDict[id].pausedByAll = true;
						this.pauseSound(id);
					}
				}
				else
				{
					this.pauseSound(id);
				}
			}
		}
		
		/**
		 * Fades the sound to the specified volume over the specified amount of time.
		 * 
		 * @param $name The string identifier of the sound
		 * @param $targVolume The target volume to fade to, between 0 and 1 (default: 0)
		 * @param $fadeLength The time to fade over, in seconds (default: 1)
		 * 
		 * @return void
		 */
		public function fadeSound($name:String, $targVolume:Number = 0, $fadeLength:Number = 1, $onComplete:Function = null, $onCompleteParams:Array = null):void
		{
			//Console.info('fade '+$name+' to '+$targVolume)
			var snd:Object = this._soundsDict[$name];
			if(!snd || (snd && !snd.channel)) {
				CONFIG::debugging {
					Console.warn('Sound without a channel: '+$name+' (snd: '+snd+')');
				}
				return;
			}
			
			//make sure the audio is at the right level before fading it
			if($targVolume == 0){
				snd.volume = snd.isMusic === true ? music_volume : sfx_volume;
			}
			else {
				//we are fading in, so make sure the audio is quiet
				snd.volume = 0;
			}
			
			var fadeChannel:SoundChannel = snd.channel;
			var fadeTransform:SoundTransform = new SoundTransform(snd.volume);
			fadeChannel.soundTransform = fadeTransform; 
			
			// Moving away from using Tweener specific 'special properties'.  No longer using _sound_volume, instead just update the transform  onUpdate
			var args:Object = {volume: $targVolume, time: $fadeLength, transition:"linear", onUpdate:onVolumeUpdated, onUpdateParams: [fadeChannel, fadeTransform]};
			
			//Console.warn('FADING SOUND',$name,'start_vol: '+snd.volume,'end_vol: '+$targVolume,'actual_vol: '+SoundChannel(snd.channel).soundTransform.volume,'time: '+$fadeLength);
						
			if($onComplete != null) args.onComplete = $onComplete;
			if($onCompleteParams != null) args.onCompleteParams = $onCompleteParams;
			
			//if this is an m4a we need to do some custom stuff
			if(snd.sound is NetStream){
				var net_transform:SoundTransform;
				args.onUpdate = function():void {
					net_transform = fadeChannel.soundTransform;
					NetStream(snd.sound).soundTransform = net_transform;
				}
			}
			
			//if we are still tweening the sound channel, kill that here
			if(TSTweener.isTweening(snd.channel)) TSTweener.removeTweens(snd.channel);
			TSTweener.addTween(fadeTransform, args);
		}
		
		/** Update the soundChannel's soundTransform. Replacement to using Tweener specific "special properties" */
		private function onVolumeUpdated(soundChannel:SoundChannel, soundTransform:SoundTransform):void {
			soundChannel.soundTransform = soundTransform;
		}
		
		/**
		 * Mutes the volume for all sounds in the sound dictionary.
		 * 
		 * @return void
		 */
		public function muteAllSounds():void
		{
			muted = true;
			
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				var id:String = this._sounds[i].name;
				this.setSoundVolume(id, 0);
			}
		}
		
		/**
		 * Resets the volume to their original setting for all sounds in the sound dictionary.
		 * 
		 * @return void
		 */
		public function unmuteAllSounds():void
		{
			muted = false;
			
			for (var i:int = 0; i < this._sounds.length; i++)
			{
				var id:String = this._sounds[i].name;
				var snd:Object = this._soundsDict[id];
				var curTransform:SoundTransform = snd.channel.soundTransform;
				curTransform.volume = snd.volume;
				snd.channel.soundTransform = curTransform;
			}
		}
		
		public function setVolume(volume:Number, isMusic:Boolean = false):void {
			var i:int;
			var id:String;
			var snd:Object;
			var curTransform:SoundTransform;
			
			for (i; i < this._sounds.length; i++)
			{
				id = this._sounds[i].name;
				snd = this._soundsDict[id];
				
				if(snd && snd.sound && snd.isMusic == isMusic){
					if(snd.sound is NetStream){
						curTransform = NetStream(snd.sound).soundTransform;
						curTransform.volume = volume;
						NetStream(snd.sound).soundTransform = curTransform;
					}
					else if(snd.channel) {
						//if we are fading, make sure to stop that
						if(TSTweener.isTweening(snd.channel)) TSTweener.removeTweens(snd.channel);
						curTransform = snd.channel.soundTransform;
						curTransform.volume = volume;
						snd.channel.soundTransform = curTransform;
					}
				}
			}
		}
		
		/**
		 * Sets the volume of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * @param $volume The volume, between 0 and 1, to set the sound to
		 * 
		 * @return void
		 */
		private function setSoundVolume($name:String, $volume:Number):void
		{
			var snd:Object = this._soundsDict[$name];
			var curTransform:SoundTransform = snd.channel.soundTransform;
			//if we are fading, cut it out!
			if('channel' in snd && TSTweener.isTweening(snd.channel)) TSTweener.removeTweens(snd.channel);
			curTransform.volume = $volume;
			snd.channel.soundTransform = curTransform;
		}
		
		/**
		 * Gets the volume of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The current volume of the sound
		 */
		public function getSoundVolume($name:String):Number
		{
			return this._soundsDict[$name].channel.soundTransform.volume;
		}
		
		/**
		 * Gets the position of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The current position of the sound, in milliseconds
		 */
		public function getSoundPosition($name:String):Number
		{
			return this._soundsDict[$name].channel.position.toFixed(3);
		}
		
		/**
		 * Gets the duration of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The length of the sound, in milliseconds
		 */
		public function getSoundDuration($name:String):Number
		{
			return this._soundsDict[$name].sound.length.toFixed(3);
		}
		
		/**
		 * Gets the sound object of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Sound The sound object
		 */
		public function getSoundObject($name:String):Sound
		{
			if (!this._soundsDict) return null; 
			if (!this._soundsDict[$name]) return null; 
			return this._soundsDict[$name].sound;
		}
		
		public function getSoundObjectFromSound($snd:Sound):Object
		{
			if(!$snd) return null;
			
			var i:int;
			var total:int = this._sounds.length;
			
			for (i; i < total; i++){
				if (_sounds[i].sound == $snd) {
					return _sounds[i];
				}
			}
			
			return null;
		}
		
		public function getSoundChannel($name:String):SoundChannel
		{
			return this._soundsDict[$name].channel;
		}
		
		/**
		 * Identifies if the sound is paused or not.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Boolean The boolean value of paused or not paused
		 */
		public function isSoundPaused($name:String):Boolean
		{
			var snd:Object = this._soundsDict[$name];
			if(!snd){
				//see if it's in the music IDs first
				return music_sound_id.indexOf($name) == -1;
			}
						
			return snd.paused === true;
		}
		
		/**
		 * Identifies if the sound was paused or stopped by calling the stopAllSounds() or pauseAllSounds() methods.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The boolean value of pausedByAll or not pausedByAll
		 */
		public function isSoundPausedByAll($name:String):Boolean
		{
			return this._soundsDict[$name].pausedByAll;
		}
		
		private function getSoundFromNetStream(net_stream:NetStream):Object {
			if(!net_stream) return null;
			
			var i:int;
			var total:int = this._sounds.length;
			
			for (i; i < total; i++){
				if (_sounds[i].sound == net_stream) {
					return _sounds[i];
				}
			}
			
			return null;
		}

//- EVENT HANDLERS ----------------------------------------------------------------------------------------

		private function onSoundComplete(event:Event):void {
			//just stop the sound
			var i:int;
			var total:int = this._sounds.length;
			var snd:Object;
						
			for (i; i < total; i++){
				snd = _sounds[i];
				if (snd.channel == event.currentTarget) {
					stopSound(snd.name);
					if(snd.isMusic === true || snd.isExclusive === true){
						//check to see if this needs to keep looping
						if(snd.loops > 0){
							playSound(snd.name, (snd.isMusic === true ? music_volume : sfx_volume), 0, snd.loops);
						}
						else {
							//nope it's done
							dispatchEvent(new TSEvent(TSEvent.SOUND_COMPLETE, snd.name));
						}
					}
					break;
				}
			}
		}
		
		private function onNetStatus(event:NetStatusEvent):void {
			//check the info
			if(event.info.code == 'NetStream.Play.Stop'){
				//figure out if this was music or not
				var snd:Object = getSoundFromNetStream(event.currentTarget as NetStream);
				if(snd){
					var cur_sound:Object = this._soundsDict[snd.name];
					if(cur_sound.currentLoop < cur_sound.loops){
						cur_sound.currentLoop++;
						NetStream(cur_sound.sound).play(cur_sound.name);
					}
					else {
						cur_sound.paused = true;
						cur_sound.currentLoop = 0;
						dispatchEvent(new TSEvent(TSEvent.SOUND_COMPLETE, snd.name));
					}
				}
			}
		}
		
		public function onMetaData(obj:Object):void {
			//needs to be here so it isn't a sucky baby
		}
		
		private function onAsyncError(event:AsyncErrorEvent):void {
			//needs to be here so it isn't a sucky baby
		}

//- GETTERS & SETTERS -------------------------------------------------------------------------------------
	
		public function get sounds():Array
		{
		    return this._sounds;
		}
		
		public function get sfx_volume():Number {
			if(LocalStorage.instance.getUserData(LocalStorage.IS_SOUND_MUTED)){
				return 0;
			}
			
			if(LocalStorage.instance.getUserData(LocalStorage.SFX_VOLUME) == undefined){
				//set the sfx to default
				return DEFAULT_SFX_VOLUME;
			}
			
			return LocalStorage.instance.getUserData(LocalStorage.SFX_VOLUME);
		}
		
		public function get music_volume():Number {
			if(LocalStorage.instance.getUserData(LocalStorage.IS_SOUND_MUTED)){
				return 0;
			}
			
			if(LocalStorage.instance.getUserData(LocalStorage.MUSIC_VOLUME) == undefined){
				//set the music to default
				return DEFAULT_MUSIC_VOLUME;
			}
			
			return LocalStorage.instance.getUserData(LocalStorage.MUSIC_VOLUME);
		}
	
//- HELPERS -----------------------------------------------------------------------------------------------
	
		override public function toString():String
		{
			return getQualifiedClassName(this);
		}
	
//- END CLASS ---------------------------------------------------------------------------------------------
	}
}