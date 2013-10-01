package com.tinyspeck.engine.data.item {
	import com.tinyspeck.debug.Console;
	
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	public class Verb extends AbstractItemEntity {
		public var sort_on:uint = 50;
		public var is_client:Boolean;
		public var ok_states:Array;
		public var requires_target_pc:Boolean;
		public var label:String;
		public var is_default:Boolean; // deprecated
		public var is_single:Boolean;
		public var is_all:Boolean;
		public var enabled:Boolean = true;
		public var disabled_reason:String;
		public var requires_target_item:Boolean;
		public var target_item_class:String;
		public var target_item_class_max_count:int = -1;
		public var choices_are_stacks:Boolean;
		public var requires_target_item_count:Boolean = false;
		public var include_target_items_from_location:Boolean = false;
		public var limit_target_count_to_stack_count:Boolean = false;
		public var limit_target_count_to_stackmax:Boolean = false;
		public var is_emote:Boolean;
		public var tsid:String;
		public var tooltip:String;
		public var from_anywhere:Boolean;
		public var effects:Object = {};
		public var default_to_one:Boolean;
		public var default_to_one_for_target:Boolean;
		
		public function Verb(hashName:String) {
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Dictionary {
			var verbs:Dictionary = new Dictionary()
			var verb:Verb;
			for(var i:String in object){
				verbs[i] = fromAnonymous(object[i],i);
			}
			return verbs;
		}
		
		public function toString():String {
			return getQualifiedClassName(this)+' '+tsid;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Verb {
			var verb:Verb = new Verb(hashName);
			verb.tsid = hashName;
			return Verb.updateFromAnonymous(object, verb);
		}
		
		public static function updateFromAnonymous(object:Object, verb:Verb):Verb {
			
			for (var j:String in object) {
				if (j in verb) {
					verb[j] = object[j];
				} else if (j == 'is_drop_target' || j == 'id' || j == 'is_drop_target' || j == 'disable_proximity' || j == 'conditions') { // <-- ask myles to remove these from messaging?
					// don't warn on these! (but call resolveError so they get added to unexpected
					resolveError(verb, object, j, true);
				} else {
					resolveError(verb,object,j);
				}
			}
			
			// until we have a way to mark the verbs as such in the web app
			/*if (['eat', 'drink', 'eat_img', 'eat_bonus_img'].indexOf(verb.tsid) != -1) {
				verb.default_to_one = true;
			}*/
			
			// until we have a way to mark the verbs as such in the web app
			/*if (['feed'].indexOf(verb.tsid) != -1) {
				verb.default_to_one_for_target = true;
			}*/
			
			// temp!!!
			/*
			if (verb.tsid == 'deposit') {
				verb.include_target_items_from_location = true;
			}
			*/
			/*
			if (verb.tsid == 'remove') {
			verb.from_anywhere = true;
			}
			*/
			
			return verb;
		}
		
		public function get is_admin():Boolean {
			return sort_on < 50;
		}
	}
}