package com.tinyspeck.engine.model.signals
{
	import com.tinyspeck.engine.memory.EnginePools;
	
	import de.polygonal.core.IPoolableObject;
	
	import flash.utils.Dictionary;

	final public class PropertyProviderLink implements IPoolableObject
	{
		protected var proplist:Array;
		protected var parent:PropertyProviderLink;
		
		protected var propertyProvider:AbstractPropertyProvider;
		protected var propertyName:String;
		
		protected var callBacks:Vector.<Function>;
		protected var subProperties:Vector.<PropertyProviderLink>;
		protected var subPropertyIndices:Dictionary;
		
		protected var depth:int = 0;

		public static function resetInstance(obj:PropertyProviderLink):void {
			obj.reset();
		}
		
		public function initWith(propertyName:String, propertyProvider:AbstractPropertyProvider, parent:PropertyProviderLink):void
		{
			this.propertyName = propertyName;
			this.propertyProvider = propertyProvider;
			this.parent = parent;
			if(parent){
				this.depth = parent.depth+1;
			}
			var tempParent:PropertyProviderLink = this.parent;
			proplist = new Array();
			while(tempParent){
				proplist.unshift(tempParent.propertyName);
				tempParent = tempParent.parent;
			}
		}
		
		public function registerCBProp(callBack:Function, properties:Array):void
		{
			if(properties.length != depth){
				var prop:String = properties[int(depth)];
				
				if(subProperties == null){
					subProperties = new Vector.<PropertyProviderLink>();
					subPropertyIndices = new Dictionary();
				}
				if(subPropertyIndices[prop] == null){
					var ppl:PropertyProviderLink = EnginePools.PropertyProviderLinkPool.borrowObject();
					ppl.initWith(prop, propertyProvider,this);
					subPropertyIndices[prop] = subProperties.push(ppl)-1;
				}
				
				var subProperty:PropertyProviderLink = subProperties[int(subPropertyIndices[prop])];
				subProperty.registerCBProp(callBack, properties);
			}else{
				if(callBacks == null){
					callBacks = new Vector.<Function>();
				}
				if(callBacks.indexOf(callBack) == -1){
					callBacks.push(callBack);
				}else{
					//Throw an error?
				}
			}
		}
		
		public function unRegisterCBProp(callBack:Function, properties:Array):void
		{
			if(properties.length != depth){
				var prop:String = properties[int(depth)];
				if(subPropertyIndices != null && subProperties != null && subPropertyIndices[prop] != null){
					var subProperty:PropertyProviderLink = subProperties[int(subPropertyIndices[prop])];
					subProperty.unRegisterCBProp(callBack,properties);
				}
			}else{
				var ind:int = callBacks.indexOf(callBack);
				if(ind != -1){
					callBacks.splice(ind,1);
				}
				checkClean();
			}
		}
		
		protected function checkClean():void
		{
			if(callBacks != null && callBacks.length == 0){
				callBacks = null;
			}
			
			if(subProperties != null && subProperties.length == 0){
				subProperties = null;
				subPropertyIndices = null;
			}
			
			if((callBacks == null)&&(subProperties == null)){
				subPropertyIndices = null;
				parent.removeLink(this);
				// return to the pool
				EnginePools.PropertyProviderLinkPool.returnObject(this);
			}
		}
		
		// from IPoolableObject
		public function reset():void
		{
			this.parent = null;
			this.propertyName = null;
			this.propertyProvider = null;
			this.proplist.length = 0;
			this.depth = 0;
		}
		
		protected function removeLink(ppl:PropertyProviderLink):void
		{
			if(subProperties != null){
				var ind:int = subProperties.indexOf(ppl);
				if(ind != -1){
					subProperties.splice(ind,1);
					subPropertyIndices[ppl.propertyName] = null;
					delete subPropertyIndices[ppl.propertyName];
					if(subProperties.length > 0){
						for(var i:int = 0; i<subProperties.length; i++){
							var pp:PropertyProviderLink = subProperties[int(i)];
							subPropertyIndices[pp.propertyName] = i;
						}
					}
				}
			}
			checkClean();
		}
				
		public function triggerCBProp(triggerChildProperties:Boolean = false, triggerParentProperties:Boolean = false, properties:Array = null):void
		{
			if(properties.length != depth){
				var prop:String = properties[int(depth)];
				if(subPropertyIndices != null && subProperties != null && subPropertyIndices[prop] != null){
					var subProperty:PropertyProviderLink = subProperties[int(subPropertyIndices[prop])];
					subProperty.triggerCBProp(triggerChildProperties,triggerParentProperties,properties);
				}
			}else{
				triggerCallBacks(triggerChildProperties, triggerParentProperties,propertyProvider,1);
			}
		}
		
		protected function triggerCallBacks(triggerChildProperties:Boolean, triggerParentProperties:Boolean, obj:Object, startDepth:int):void
		{
			var val:Object = null;
			//Retrieve the value, if any
			var parentObj:Object = null;
			for(var i:int=startDepth; i<depth; i++){
				var prop:String = proplist[int(i)];
				if(obj && obj.hasOwnProperty(prop)){
					if(triggerParentProperties && obj && i==parent.depth){
						parentObj = obj;
					}
					obj = obj[prop];
				}else{
					obj = null;
					break;
				}
			}
									
			if(obj && obj.hasOwnProperty(propertyName)){
				val = obj[propertyName];
			}
						
			//Tell the parent property listeners about the update of one of it's properties.
			if(triggerParentProperties){
				if(parent){
					parent.triggerCallBacks(false,true,parentObj,depth-1);
				}
			}
			
			//Update callbacks for this property
			if(callBacks){
				for(i=0; i<callBacks.length; i++){
					var callback:Function = callBacks[int(i)];
					callback(val);
				}
			}
			
			//trigger callbacks for child properties
			if(triggerChildProperties && subProperties){
				for(i=0; i<subProperties.length; i++){
					var child:PropertyProviderLink = subProperties[int(i)];
					child.triggerCallBacks(true,false,obj,depth);
				}
			}
		}
	}
}