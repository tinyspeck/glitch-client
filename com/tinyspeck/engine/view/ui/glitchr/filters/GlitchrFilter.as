package com.tinyspeck.engine.view.ui.glitchr.filters {
	
	
	public class GlitchrFilter {
		
		private var _tsid:String;
		private var _name:String;
		protected const _overlays:Vector.<FilterOverlay> = new Vector.<FilterOverlay>();
		
		protected var _components:Array;
		protected var _defaultAlpha:Number = 1;
		
		public function GlitchrFilter(tsid:String, name:String = null, components:Array = null) {
			_tsid = tsid;
			_name = name;
			_components = components ? components : [];
			
			init();
		}
		
		protected function init():void {
		}

		public function get components():Array {
			return _components;
		}

		public function get name():String {
			return _name;
		}
		
		public function set name(value:String):void {
			_name = value;
		}		

		public function get overlays():Vector.<FilterOverlay> {
			return _overlays;
		}

		public function get tsid():String {
			return _tsid;
		}
		
		public function get defaultAlpha():Number {
			return _defaultAlpha;
		}
	}
}