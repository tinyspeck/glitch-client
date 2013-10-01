package com.tinyspeck.engine.model {
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.bridge.PrefsModel;
	
	public class TSModelLocator {
		/* singleton boilerplate */
		public static const instance:TSModelLocator = new TSModelLocator();
		
		public var prefsModel:PrefsModel;
		public var flashVarModel:FlashVarModel;
		public var netModel:NetModel;
		public var moveModel:MoveModel;
		public var worldModel:WorldModel;
		public var stateModel:StateModel;
		public var timeModel:TimeModel;
		public var activityModel:ActivityModel;
		public var physicsModel:PhysicsModel;
		public var layoutModel:LayoutModel;
		public var interactionMenuModel:InteractionMenuModel;
		public var rookModel:RookModel;
		public var decorateModel:DecorateModel;
		
		public function TSModelLocator() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			// we used to do this, but now we take care not to reference the
			// flashVarmodel until it has been passed to the main model from the boot model
			//flashVarModel = new FlashVarModel();
			netModel = new NetModel();
			moveModel = new MoveModel();
			worldModel = new WorldModel();
			stateModel = new StateModel();
			timeModel = new TimeModel();
			activityModel = new ActivityModel();
			physicsModel = new PhysicsModel();
			layoutModel = new LayoutModel();
			interactionMenuModel = new InteractionMenuModel();
			rookModel = new RookModel();
			decorateModel = new DecorateModel();
		}
	}
}