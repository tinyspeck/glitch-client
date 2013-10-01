package com.tinyspeck.engine.data.acl
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class ACL extends AbstractTSDataEntity
	{
		public var keys_given:Vector.<ACLKey> = new Vector.<ACLKey>();
		public var keys_received:Vector.<ACLKey> = new Vector.<ACLKey>();
		
		public function ACL(){
			super('acl');
		}
		
		public static function fromAnonymous(object:Object):ACL {
			var acl:ACL = new ACL();
			return updateFromAnonymous(object, acl);
		}
		
		public static function updateFromAnonymous(object:Object, acl:ACL):ACL {
			var k:String;
			var val:*;
			
			for(k in object){
				val = object[k];
				
				if(k == 'keys_given' && val){
					acl.keys_given = ACLKey.parseMultiple(val);
					
					SortTools.vectorSortOn(acl.keys_given, ['received'], [Array.NUMERIC | Array.DESCENDING]);
				}
				else if(k == 'keys_received' && val){
					acl.keys_received = ACLKey.parseMultiple(val);
				}
				else if(k in acl){
					acl[k] = val;
				}
				else {
					resolveError(acl,object,k);
				}
			}
			
			return acl;
		}
	}
}