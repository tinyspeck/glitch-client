/**
* This class lets you play animated GIF files in AS3
* @author Thibault Imbert (bytearray.org)
* @version 0.6
*/

package org.bytearray.gif.player
{	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.errors.ScriptTimeoutError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import org.bytearray.gif.decoder.GIFDecoder;
	import org.bytearray.gif.errors.FileTypeError;
	import org.bytearray.gif.events.FileTypeEvent;
	import org.bytearray.gif.events.FrameEvent;
	import org.bytearray.gif.events.GIFPlayerEvent;
	import org.bytearray.gif.events.TimeoutEvent;
	import org.bytearray.gif.frames.GIFFrame;
	
	public class GIFPlayer extends Bitmap
	{
		private var urlLoader:URLLoader;
		private var aFrames:Array;
		private var myTimer:Timer;
		private var iInc:int;
		private var iIndex:int;
		private var auto:Boolean;
		private var arrayLng:uint;
        private var source:String;
        private var _loopCount:int;
        private static var byteStreamCache:Object = {};
		
		public function GIFPlayer ( pAutoPlay:Boolean = true )
		{
			auto = pAutoPlay;
			iIndex = iInc = 0;
			
			myTimer = new Timer ( 0, 0 );
			aFrames = new Array();
			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			urlLoader.addEventListener ( Event.COMPLETE, onComplete );
			urlLoader.addEventListener ( IOErrorEvent.IO_ERROR, onIOError );
			
			myTimer.addEventListener ( TimerEvent.TIMER, update );
		}
		
		private function onIOError ( pEvt:IOErrorEvent ):void
		{
			dispatchEvent ( pEvt );	
		}
		
		private function onComplete ( pEvt:Event ):void 
		{
            byteStreamCache[this.source] = ByteArray(pEvt.target.data);
			readStream ( pEvt.target.data );	
		}
		
		private function readStream ( pBytes:ByteArray ):void
		{
			var gifStream:ByteArray = pBytes;

			aFrames = new Array;
			iInc = 0;

            var gifDecoder:GIFDecoder = new GIFDecoder();
			try 
			{
				gifDecoder.read ( gifStream );
				
				var lng:int = gifDecoder.getFrameCount();
				
				for ( var i:int = 0; i< lng; i++ ) 
					aFrames[int(i)] = gifDecoder.getFrame(i);
				
				arrayLng = aFrames.length;
				
				auto ? play() : gotoAndStop (1);
                _loopCount = gifDecoder.getLoopCount();	

				dispatchEvent ( new GIFPlayerEvent ( GIFPlayerEvent.COMPLETE , aFrames[0].bitmapData.rect ) );

			} catch ( e:ScriptTimeoutError )
			{	
				dispatchEvent ( new TimeoutEvent ( TimeoutEvent.TIME_OUT ) );
				
			} catch ( e:FileTypeError )
			{	
				dispatchEvent ( new FileTypeEvent ( FileTypeEvent.INVALID ) );
				
			} catch ( e:Error )
			{
				throw new Error ("An unknown error occured, make sure the GIF file contains at least one frame\nNumber of frames : " + aFrames.length);	
			}

		}
		
		private function update ( pEvt:TimerEvent ) :void
		{
            var frame:GIFFrame = aFrames[ int(iIndex = iInc++ % arrayLng) ];
			var delay:int = frame.delay;
			
			pEvt.target.delay = ( delay > 0 ) ? delay : 100;

			switch ( frame.dispose ) 
			{		
				case 1:
					if ( !iIndex ) {
						bitmapData = aFrames[ 0 ].bitmapData.clone();
                    }
					bitmapData.draw ( aFrames[ iIndex ].bitmapData );
					break;
				case 2:
					bitmapData = aFrames[ iIndex ].bitmapData;
					break;
                default:
                    bitmapData = aFrames[ iIndex ].bitmapData;
                    break;
			}
			
			dispatchEvent ( new FrameEvent ( FrameEvent.FRAME_RENDERED, aFrames[ iIndex ] ) );
		}
		
		private function concat ( pIndex:int ):int
		{	
			bitmapData.lock();
			for (var i:int = 0; i< pIndex; i++ ) 
				bitmapData.draw ( aFrames[ i ].bitmapData );
			bitmapData.unlock();
			
			return i;
		}
		
		/**
		 * Load any GIF file
		 *
		 * @return void
		*/
		public function load ( pRequest:URLRequest ):void
		{
            this.source = pRequest.url;
			stop();
            if (byteStreamCache[this.source]) {
                var b:ByteArray = new ByteArray();
                ByteArray(byteStreamCache[this.source]).position = 0;
                b.writeBytes(byteStreamCache[this.source]);
                b.position = 0;
                loadBytes(b);
                return;
            }
			urlLoader.load ( pRequest );	
		}
		
		/**
		 * Load any valid GIF ByteArray
		 *
		 * @return void
		*/
		public function loadBytes ( pBytes:ByteArray ):void 
		{
			readStream ( pBytes );	
		}
		
		/**
		 * Start playing
		 *
		 * @return void
		*/
		public function play ():void
		{	
			if ( aFrames.length > 0 ) 
			{	
				if ( !myTimer.running ) 
					myTimer.start();
				
			} else throw new Error ("Nothing to play");
		}
		
		/**
		 * Stop playing
		 *
		 * @return void
		*/
		public function stop ():void
		{
			if ( myTimer.running ) 
				myTimer.stop();	
		}
		
		/**
		 * Returns current frame being played
		 *
		 * @return frame number
		*/
		public function get currentFrame ():int
		{
			return iIndex+1;	
		}
		
		/**
		 * Returns GIF's total frames
		 *
		 * @return number of frames
		*/
		public function get totalFrames ():int
		{	
			return aFrames.length;	
		}
				
		/**
		 * Returns how many times the GIF file is played
		 * A loop value of 0 means repeat indefinitiely.
		 *
		 * @return loop value
		*/
		public function get loopCount ():int
		{
			return _loopCount;
		}
		
		/**
		 * Returns is the autoPlay value
		 *
		 * @return autoPlay value
		*/
		public function get autoPlay ():Boolean
		{
			return auto;	
		}
		
		/**
		 * Returns an array of GIFFrame objects
		 *
		 * @return aFrames
		*/
		public function get frames ():Array
		{
			return aFrames;	
		}
		
		/**
		 * Moves the playhead to the specified frame and stops playing
		 *
		 * @return void
		*/
		public function gotoAndStop (pFrame:int):void
		{
			if ( pFrame >= 1 && pFrame <= aFrames.length ) 	
			{
				if ( pFrame == currentFrame ) return;
				iIndex = iInc = int(int(pFrame)-1);
				
				switch ( aFrames[ pFrame ].dispose ) 
				{
					case 1:
						bitmapData = aFrames[ 0 ].bitmapData.clone();
						bitmapData.draw ( aFrames[ concat ( iInc ) ].bitmapData );
						break
					case 2:
						bitmapData = aFrames[ iInc ].bitmapData;
						break;
				}
				
				if ( myTimer.running ) 
					myTimer.stop();
				
			} else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );
		}
		
		/**
		 * Starts playing the GIF at the frame specified as parameter
		 *
		 * @return void
		*/
		public function gotoAndPlay (pFrame:int):void
		{	
			if ( pFrame >= 1 && pFrame <= aFrames.length ) 
			{	
				if ( pFrame == currentFrame ) return;
				iIndex = iInc = int(int(pFrame)-1);
				
				switch ( aFrames[ pFrame ].dispose ) 
				{	
					case 1:
						bitmapData = aFrames[ 0 ].bitmapData.clone();
						bitmapData.draw ( aFrames[ concat ( iInc ) ].bitmapData );
						break
					case 2:
						bitmapData = aFrames[ iInc ].bitmapData;
						break;		
				}
				if ( !myTimer.running ) myTimer.start();
				
			} else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );
		}
		
		/**
		 * Retrieves a frame from the GIF file as a BitmapData
		 *
		 * @return BitmapData object
		*/
		public function getFrame ( pFrame:int ):GIFFrame
		{
			var frame:GIFFrame;
			
			if ( pFrame >= 1 && pFrame <= aFrames.length ) 
				frame = aFrames[ pFrame-1 ];
			
			else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );
			
			return frame;	
		}
		
		/**
		 * Retrieves the delay for a specific frame
		 *
		 * @return int
		*/
		public function getDelay ( pFrame:int ):int
		{
			var delay:int;
			
			if ( pFrame >= 1 && pFrame <= aFrames.length )
				delay = aFrames[ pFrame-1 ].delay;
			
			else throw new RangeError ("Frame out of range, please specify a frame between 1 and " + aFrames.length );
			
			return delay;	
		}
		
		/**
		 * Dispose a GIFPlayer instance
		 *
		 * @return int
		*/
		public function dispose():void
		{
			stop();
			var lng:int = aFrames.length;
				
			for ( var i:int = 0; i< lng; i++ ) 
				aFrames[int(i)].bitmapData.dispose();
		}
	}
}
