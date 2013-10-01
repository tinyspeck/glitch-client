package com.tinyspeck.engine.data.craftybot
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class CraftyComponent extends AbstractTSDataEntity
	{
		public static const TYPE_FETCH:String = 'fetch';
		public static const TYPE_CRAFT:String = 'craft';
		public static const STATUS_COMPLETE:String = 'complete';
		public static const STATUS_ACTIVE:String = 'active';
		public static const STATUS_MISSING:String = 'missing';
		public static const STATUS_PENDING:String = 'pending';
		public static const STATUS_HALTED:String = 'halted';
		
		public var item_classes:Array;
		public var counts:Array;
		public var counts_missing:Array;
		public var type:String;
		public var status:String;
		public var status_txt:String;
		public var can_start:Boolean;
		public var tool_class:String; //the tool needed to make the item_classes
		
		public function CraftyComponent(){
			super('crafty_component');
		}
		
		public static function fromAnonymous(object:Object):CraftyComponent {
			const component:CraftyComponent = new CraftyComponent();
			var k:String;
			
			for(k in object){
				if(k in component){
					component[k] = object[k];
				}
				else {
					resolveError(component, object, k);
				}
			}
			
			return component;
		}
	}
}