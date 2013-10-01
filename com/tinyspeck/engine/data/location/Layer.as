package com.tinyspeck.engine.data.location
{
	import com.tinyspeck.engine.filters.ColorMatrix;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SortTools;
	
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;

	public class Layer extends AbstractLocationEntity
	{
		public var z:int;
		public var h:int;
		public var w:int;
		public var is_hidden:Boolean;
		public var filtersNEW:Object;
		
		public var decos:Vector.<Deco> = new Vector.<Deco>();
		
		// yeah, this is not entirely the place to store filters,
		// but it makes the most sense atm; we'll consider them 'data'
		private var _filtersA:Array
		private var _filtersDirty:Boolean = true;
		
		public function Layer(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var i:int;
			var ob:Object = super.AMF();
			
			ob.z = z;
			ob.h = h;
			ob.w = w;
			// only create filtersNEW if we have non-defaults
			if (blur || brightness || contrast || saturation || tintAmount /* || tintColor */) {
				ob.filtersNEW = filtersNEW;
			}
			
			ob.name = name;
			if (is_hidden) ob.is_hidden = is_hidden;
			
			ob.decos = {};
			for (i=decos.length-1; i>-1; i--) {
				ob.decos[decos[int(i)].hashName] = decos[int(i)].AMF();
			}
			
			return ob;
		}
		
		public function getDecoByTsid(tsid:String):Deco {
			var deco:Deco;
			for (var i:int=0;i<decos.length;i++) {
				deco = decos[int(i)];
				if (tsid == deco.tsid) return deco;
			}
			return null;
		}
		
		public function getDecoByName(name:String):Deco {
			var deco:Deco;
			for (var i:int=0;i<decos.length;i++) {
				deco = decos[int(i)];
				if (name == deco.name) return deco;
			}
			return null;
		}
		
		public static function parseMultiple(object:Object):Vector.<Layer> {
			var layers:Vector.<Layer> = new Vector.<Layer>();
			var layer:Layer;
			for(var j:String in object){
				if(j != "middleground"){
					if (TSModelLocator.instance.flashVarModel.only_mg) continue;
					layer = fromAnonymous(object[j],j);
				}else{
					layer = MiddleGroundLayer.fromAnonymous(object[j],j);
				}
				layers.push(layer);
			}
			layers.sort(SortTools.layerZSort);
			return layers;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Layer {
			if (object.filters) delete object.filters;
			var layer:Layer = new Layer(hashName);
			for(var j:String in object){
				if(j in layer){
					if(j == "decos"){
						layer.decos = Deco.parseMultiple(object[j]);
					}else{
						layer[j] = object[j];
					}
				}else if (j == 'filters') {
					// ignore, legacy
				}else{
					resolveError(layer,object,j);
				}
			}
			layer.decos.sort(SortTools.decoZSort);
			return layer;
		}
		
		public function get filtersA():Array {
			if (_filtersDirty) {
				_filtersDirty = false;
				
				_filtersA = null;
				
				if (brightness || contrast || saturation || tintAmount /* || tintColor */) {
					_filtersA = [ColorMatrix.getFilter(brightness, contrast, saturation, tintColor, tintAmount)];
				}
				
				if (blur) {
					if (_filtersA) {
						_filtersA.push(new BlurFilter(blur, blur, flash.filters.BitmapFilterQuality.LOW));
					} else {
						_filtersA = [new BlurFilter(blur, blur, flash.filters.BitmapFilterQuality.LOW)];
					}
				}
			}
			
			return _filtersA;
		}
		
		public function get blur():int {
			return (filtersNEW && filtersNEW.blur && filtersNEW.blur.value)
				? filtersNEW.blur.value : 0;
		}
		
		public function set blur(b:int):void {
			if (!filtersNEW) filtersNEW = {};
			filtersNEW.blur = {value: b};
			_filtersDirty = true;
		}
		
		public function get brightness():int {
			return (filtersNEW && filtersNEW.brightness && filtersNEW.brightness.value)
				? filtersNEW.brightness.value : 0;
		}
		
		public function set brightness(b:int):void {
			if (!filtersNEW) filtersNEW = {};
			filtersNEW.brightness = {value: b};
			_filtersDirty = true;
		}
		
		public function get contrast():int {
			return (filtersNEW && filtersNEW.contrast && filtersNEW.contrast.value)
				? filtersNEW.contrast.value : 0;
		}
		
		public function set contrast(b:int):void {
			if (!filtersNEW) filtersNEW = {};
			filtersNEW.contrast = {value: b};
			_filtersDirty = true;
		}
		
		public function get saturation():int {
			return (filtersNEW && filtersNEW.saturation && filtersNEW.saturation.value)
				? filtersNEW.saturation.value : 0;
		}
		
		public function set saturation(b:int):void {
			if (!filtersNEW) filtersNEW = {};
			filtersNEW.saturation = {value: b};
			_filtersDirty = true;
		}
		
		public function get tintColor():int {
			return (filtersNEW && filtersNEW.tintColor && filtersNEW.tintColor.value)
				? filtersNEW.tintColor.value : 0;
		}
		
		public function set tintColor(b:int):void {
			if (!filtersNEW) filtersNEW = {};
			filtersNEW.tintColor = {value: b};
			_filtersDirty = true;
		}
		
		public function get tintAmount():int {
			return (filtersNEW && filtersNEW.tintAmount && filtersNEW.tintAmount.value)
				? filtersNEW.tintAmount.value : 0;
		}
		
		public function set tintAmount(b:int):void {
			if (!filtersNEW) filtersNEW = {};
			filtersNEW.tintAmount = {value: b};
			_filtersDirty = true;
		}
		
		CONFIG::god public function setSize(w:int, h:int):void {
			this.w = w;
			this.h = h;
		}
	}
}
