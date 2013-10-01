package com.tinyspeck.engine.data {
	
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.vo.TSVO;
	
	public class AbstractTSDataEntity extends TSVO implements IDisposable {
		public var hashName:String;
		client var unexpected:Object = {};
		
		public function AbstractTSDataEntity(hashName:String) {
			this.hashName = hashName;
		}
		
		public static function resolveError(typedObject:AbstractTSDataEntity, anonymousObject:Object, valueName:String, no_warning:Boolean = false):void {
			use namespace client;
			
			if (valueName.indexOf('__') == 0) return;
			
			CONFIG::debugging {
				if (!no_warning) {
					if (valueName in anonymousObject) {
						Console.warn('Class:"'+typedObject+'" can\'t resolve property:"'+valueName+'" w/ value:"'+anonymousObject[valueName]+'"');
					} else {
						Console.warn('Class:"'+typedObject+'" can\'t resolve property:"'+valueName+'"');
					}
				}
			}
			
			
			if (valueName in anonymousObject) {
				typedObject.unexpected[valueName] = anonymousObject[valueName];
			} else {
				; // wtf
				CONFIG::debugging {
					Console.warn('valueName:"'+valueName+'" not in anonymousObject:"'+anonymousObject+'"');
				}
			}
			
		}
		
		public function AMF():Object {
			use namespace client;
			
			const ob:Object = {};
			
			for (var k:String in unexpected) {
				ob[k] = unexpected[k];
			}
			
			return ob;
		}
		
		public function dispose():void {
			
		}
	}
}