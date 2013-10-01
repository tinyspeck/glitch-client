package com.tinyspeck.engine.data.group {
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	
	public class Group extends AbstractTSDataEntity
	{
		public static const MODE_PUBLIC:String = 'public';
		public static const MODE_PUBLIC_APPLY:String = 'public_apply';
		public static const MODE_PRIVATE:String = 'private';
		
		public var tsid:String;
		public var label:String;
		public var members:uint;
		public var mode:String;
		public var desc:String;
		public var is_member:Boolean;
		public var owns_property:Boolean;  //does this group own a group hall?
		
		public function Group(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Group
		{
			var group:Group = new Group(hashName);
			group.tsid = hashName; // this will eb the tsd of the pc playing
			
			for(var j:String in object){
				var val:* = object[j];
				if(j in group){
					group[j] = val;
				}else if(j == 'name'){
					group.label = val;
				}else{
					resolveError(group,object,j);
				}
			}
			return group;
		}
	}
}
