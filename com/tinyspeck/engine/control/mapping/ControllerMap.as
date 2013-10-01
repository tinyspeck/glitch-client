package com.tinyspeck.engine.control.mapping
{
	import com.tinyspeck.engine.control.InteractionMenuController;
	import com.tinyspeck.engine.control.MainEngineController;
	import com.tinyspeck.engine.control.engine.AvatarController;
	import com.tinyspeck.engine.control.engine.DataLoaderController;
	import com.tinyspeck.engine.control.engine.NetController;
	import com.tinyspeck.engine.control.engine.PhysicsController;
	import com.tinyspeck.engine.control.engine.TimeController;
	import com.tinyspeck.engine.control.engine.ViewController;
	
	final public class ControllerMap
	{
		public var mainEngineController:MainEngineController;
		public var dataLoaderController:DataLoaderController;
		public var netController:NetController;
		public var viewController:ViewController;
		public var timeController:TimeController;
		public var physicsController:PhysicsController;
		public var avatarController:AvatarController;
		public var interactionMenuController:InteractionMenuController;
	}
}