package com.tinyspeck.core.memory
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.view.IFocusableComponent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;

	CONFIG::god { import flash.utils.getQualifiedClassName; }
	CONFIG::god { import com.tinyspeck.engine.util.StringUtil; }
	
	public class DisposableSprite extends Sprite implements IDisposable {
		CONFIG::god private static var instance_totals:Object = {};
		
		private var _dirty:Boolean;
		private var _disposed:Boolean;
		
		private const listeners:Vector.<EventListenerVO> = new Vector.<EventListenerVO>();
		
		// TSFC will set this in the client, so the class knows the method to call back to when disposed.
		// It is done this way to avoid dependancies in this class on TSFrontController, so that, for instance,
		// Button can be used in other apps without loading the whole fucking client. Later note: HAHAHAHAHA
		public static var onDispose:Function = null;

		CONFIG::god public static function memReport():String {
			var class_name:String;
			var all_total:int;
			var all_current:int;
			var A:Array = [];
			for (class_name in instance_totals) {
				A.push({num:instance_totals[class_name].instances.length, name:class_name});
				all_current+= instance_totals[class_name].instances.length;
				all_total+= instance_totals[class_name].total;
			}
			
			var str:String = '\nDisposableSprite memReport\n+--------------------------------------------------\n';
			//str+= 'total: '+all_current+'\n';
			A.sortOn(['name', 'num'], [Array.CASEINSENSITIVE, Array.NUMERIC])
			for (var i:int=0;i<A.length;i++) {
				str+= StringUtil.padString(A[i].num, 6)+' '+StringUtil.padString('('+instance_totals[A[i].name].total+')', 8, true)+' '+A[i].name+'\n';
			}
			str+='---------------------------------------------\n';
			
			str+= StringUtil.padString(all_current.toString(), 6)+' '+StringUtil.padString('('+all_total+')', 8, true)
			
			return str;
		}
		
		public function DisposableSprite()
		{
			CONFIG::god {
				var class_name:String = getQualifiedClassName(this);
				if (!instance_totals[class_name]) {
					instance_totals[class_name] = {
						instances: [],
						total: 0
					}
				}
				instance_totals[class_name].instances.push(this);
				instance_totals[class_name].total++;
			}
		}
		
		override public function set x(value:Number):void
		{
			if (x != value) _dirty = true;
			super.x = value;
		}
		
		override public function set y(value:Number):void
		{
			if (y != value) _dirty = true;
			super.y = value;
		}
		
		private function removeAllChildren():void
		{
			var doc:DisplayObjectContainer;
			var child:DisplayObject;
			while(numChildren){
				child = removeChildAt(0);
				// not sure why, but sometimes they can be null and this
				// loop won't terminate; safe than sorry:
				if (!child) break;
				// we've seen problems in the past where recursively destroying
				// a movieclip is hella busted
				if(!(child is Loader) && !(child is MovieClip)) {
					doc = (child as DisplayObjectContainer);
					if (doc) recurseChildrenRemove(doc);
				}
			}
		}
		
		private function recurseChildrenRemove(doc:DisplayObjectContainer):void
		{
			if (doc is IDisposable){
				(doc as IDisposable).dispose();
			// we've seen problems in the past where recursively destroying
			// a movieclip is hella busted
			} else if(!(doc is Loader) && !(doc is MovieClip)) {
				var c:DisplayObject;
				var cdoc:DisplayObjectContainer;
				while(doc.numChildren){
					c = doc.removeChildAt(0);
					// not sure why, but sometimes they can be null and this
					// loop won't terminate; safe than sorry:
					if (!c) break;
					cdoc = (c as DisplayObjectContainer);
					if(cdoc) recurseChildrenRemove(cdoc);
				}
			}
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false) : void
		{
			var elvo:EventListenerVO = EnginePools.EventListenerVOPool.borrowObject();
			elvo.type = type
			elvo.listener = listener;
			elvo.useCapture = useCapture;
			listeners[listeners.length] = elvo;
			super.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false) : void
		{
			//Find the event listeners in the listeners list.
			var elvo:EventListenerVO;
			if(listeners){
				var l:int = listeners.length;
				for(var i:int = 0; l<i; i++){
					elvo = listeners[int(i)];
					if(elvo.type == type && elvo.listener == listener && elvo.useCapture == useCapture){
						EnginePools.EventListenerVOPool.returnObject(elvo);
						listeners.splice(i,1);
						--l;
						--i;
					}
				}
			}
			super.removeEventListener(type, listener, useCapture);
		}
		
		public function removeAllEventListeners():void
		{
			var elvo:EventListenerVO;
			if(listeners){
				var l:int = listeners.length;
				for(var i:int = 0; i<l; i++){
					elvo = listeners[int(i)];
					if (elvo.type == null) {
						;
						// we should report an error here, I think!
						CONFIG::debugging {
							Console.error('WTF no elvo.type?');
						}
					} else {
						super.removeEventListener(elvo.type, elvo.listener, elvo.useCapture);
					}
					EnginePools.EventListenerVOPool.returnObject(elvo);
				}
				listeners.length = 0;
			}
		}
		
		public function dispose():void
		{
			if (this is IFocusableComponent) IFocusableComponent(this).removeSelfAsFocusableComponent();
			if (DisposableSprite.onDispose != null) DisposableSprite.onDispose(this);
			removeAllEventListeners();
			removeAllChildren();
			_disposed = true;
			CONFIG::god {
				var class_name:String = getQualifiedClassName(this);
				var i:int = instance_totals[class_name].instances.indexOf(this);
				if (i>-1) instance_totals[class_name].instances.splice(i, 1);
	
			}
		}

		public function get dirty():Boolean { return _dirty; }
		public function set dirty(value:Boolean):void { _dirty = value; }

		public function get disposed():Boolean { return _disposed; }
		public function set disposed(value:Boolean):void { _disposed = value; }
	}
}