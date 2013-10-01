package com.tinyspeck.engine.data.location {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.SortTools;

	public class LocationConnection extends AbstractPositionableLocationEntity {
		public var mote_id:String;
		public var target_key:String;
		public var label:String;
		public var custom_label:String;
		public var hidden:Boolean;
		public var hub_id:String;
		public var street_tsid:String;
		public var swf_file:String;
		public var swf_file_versioned:String;
		public var img_file_versioned:String;
		public var player_tsid:String; //used for your custom signpost outside your house
		public var button_position:String;
		
		public function LocationConnection(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			if (mote_id) ob.mote_id = mote_id;
			if (target_key) ob.target_key = target_key;
			if (label) ob.label = label;
			if (custom_label) ob.custom_label = custom_label;
			if (hidden) ob.hidden = hidden;
			if (hub_id) ob.hub_id = hub_id;
			if (street_tsid) ob.street_tsid = street_tsid;
			if (swf_file) ob.swf_filed = swf_file;
			if (swf_file_versioned) ob.swf_file_versioned = swf_file_versioned;
			if (img_file_versioned) ob.img_file_versioned = img_file_versioned;
			if (player_tsid) ob.player_tsid = player_tsid;
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<LocationConnection> {
			var connects:Vector.<LocationConnection> = new Vector.<LocationConnection>();
			var id:String;
			for(var j:String in object){
				id = j;
				/*if (!isNaN(parseInt(id.substr(0,1)))) {
					id = 'fl_'+id;
					CONFIG::debugging {
						Console.info(j+'-->'+id);
					}
				}*/
				connects.push(fromAnonymous(object[j],id));
			}
			
			return connects;
		}
		
		public static function fromAnonymous(object:Object,hashName:String):LocationConnection {
			var lc:LocationConnection = new LocationConnection(hashName);
			
			// because firebug barfs on props starting with a number, we have started prefixing the
			// prop names with "fl_", but it needs to work both ways, with the "fl_" and without
			lc.button_position = (hashName.indexOf('fl_') == 0) ? hashName.replace('fl_', '') : hashName;
			/*CONFIG::debugging {
				if (button_position != hashName) {
					Console.warn(hashName+'-->'+button_position);
				}
			}
			*/
			
			for(var j:String in object){
				if(j in lc){
					lc[j] = object[j];
				}else{
					resolveError(lc,object,j);
				}
			}
			
			// create a stub location for the location this connection links to
			Location.fromAnonymousLocationStub(lc);
		
			return lc;
		}
	}
}