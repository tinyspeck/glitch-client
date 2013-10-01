package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.LocationView;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	
	import flash.utils.Dictionary;

	public class ViewController extends AbstractController {
		protected var main_view:TSMainView;
		
		private const disposable_sp_dic:Dictionary = new Dictionary();
		
		public function ViewController() {
			//
		}
		
		public function init():void {
			//Creating the game view
			main_view = new TSMainView();
			main_view.init();
			main_view.visible = false;
			StageBeacon.game_parent.addChildAt(main_view, StageBeacon.game_parent.numChildren-1);
			StageBeacon.resize_sig.add(onResize);
			onResize();
			Cursor.instance.init();
		}
		
		public function registerDisposableSpriteChangeSubscriber(subscriber:IDisposableSpriteChangeHandler, sp:DisposableSprite):void {
			if (!sp) {
				return;
			}
			
			if (!disposable_sp_dic[sp]) {
				disposable_sp_dic[sp] = new Vector.<IDisposableSpriteChangeHandler>();
			} else if (disposable_sp_dic[sp].indexOf(subscriber) > -1) {
				subscriber.worldDisposableSpriteChangeHandler(sp);
				return;
			}
			
			disposable_sp_dic[sp].push(subscriber);
			subscriber.worldDisposableSpriteSubscribedHandler(sp);
			subscriber.worldDisposableSpriteChangeHandler(sp);
		}
		
		// no sp and it unregisters from all in disposable_sp_dic
		public function unregisterDisposableSpriteChangeSubscriber(subscriber:IDisposableSpriteChangeHandler, sp:DisposableSprite = null):void {
			if (sp && !disposable_sp_dic[sp]) {
				return;
			}
			
			var V:Vector.<IDisposableSpriteChangeHandler>;
			
			for (var each_sp:Object in disposable_sp_dic) {
				if (sp && each_sp != sp) continue;
				V = disposable_sp_dic[each_sp];
				var index:int = V.indexOf(subscriber);
				
				if (index > -1) {
					V.splice(index, 1);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						if (sp) Console.warn('Could not find change subscriber! (not nec. a problem)');
					}
				}
			}
		}
		
		public function removeDisposableSprite(sp:DisposableSprite):void {
			if (!sp) {
				return;
			}
			
			if (!disposable_sp_dic[sp]) {
				return;
			}
			
			var V:Vector.<IDisposableSpriteChangeHandler> = disposable_sp_dic[sp];
			// make a copy so we can safely iterate without worrying if
			// worldDisposableSpriteDestroyedHandler removes it from the original V
			V = V.concat();
			for (var i:int = V.length-1; i>=0 ; --i) {
				V[int(i)].worldDisposableSpriteDestroyedHandler(sp as DisposableSprite);
			}
			
			disposable_sp_dic[sp].length = 0;
			disposable_sp_dic[sp] = null;
			delete disposable_sp_dic[sp];
		}
		
		// this is laregly untested
		public function isRegisteredWithDisposableSprite(subscriber:IDisposableSpriteChangeHandler, sp:DisposableSprite):Boolean {
			if (!sp) {
				return false;
			}
			
			if (!disposable_sp_dic[sp]) {
				return false;
			}

			var V:Vector.<IDisposableSpriteChangeHandler> = disposable_sp_dic[sp];
			for (var i:int = V.length-1; i>=0 ; --i) {
				if (V[int(i)] == subscriber) return true;
			}
		
			return false;
		}
		
		public function get tsMainView():TSMainView {
			return main_view;
		}
		
		public function onEnterFrame(ms_elapsed:int):void {
			var V:Vector.<IDisposableSpriteChangeHandler>;
			var i:int;
			
			var called:int = 0;
			CONFIG::debugging {
				Console.trackValue('AAAVC called', '');
			}
			var dsp:DisposableSprite;
			for (var sp:Object in disposable_sp_dic) {
				dsp = sp as DisposableSprite;
				// TODO need to do a special thing for thing for sps in the gamerenderer, and detect if it has scrolled
				// and call worldDisposableSpriteChangeHandler if needed, instead of below
				if (dsp.dirty || dsp is AbstractAvatarView || dsp is LocationItemstackView) {
					V = disposable_sp_dic[dsp];
					for each (var handler:IDisposableSpriteChangeHandler in V) {
						called++;
						handler.worldDisposableSpriteChangeHandler(dsp);
					}
					dsp.dirty = false;
				}
			}
			CONFIG::debugging {
				Console.trackValue('AAAVC called', called);
			}
		}
		
		/**
		 * Adds new decos to any existing layer.
		 * 
		 * Takes an Object of the following format:
		 * layers: {
		 *   middleground: {
		 *     tsid: {
		 *       x: -226,
		 *       y: 15,
		 *       z: 1,
		 *       w: 111,
		 *       h: 184,
		 *       sprite_class: "fire1",
		 *       name: "fire1_1311661932850",
		 *       animated: true
		 *     }
		 *   }
		 * }
		 */
		public function addDeco(layers:Object):void {
			layers = layers.layers;
			
			const location:Location = model.worldModel.location;
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			const locationView:LocationView = gameRenderer.locationView;
			
			var deco:Deco;
			var decos:Object;
			var layer:Layer;
			const layersToRebuild:Vector.<Layer> = new Vector.<Layer>();
			
			var tsid:String;
			for (tsid in layers) {
				// get layer
				layer = location.getLayerById(tsid);
				if (layer) {
					if (layersToRebuild.indexOf(layer) == -1) {
						layersToRebuild.push(layer);
					}
					decos = layers[tsid];
					for (tsid in decos) {
						// create model
						deco = Deco.fromAnonymous(decos[tsid], tsid);
						// add model 
						layer.decos.push(deco);
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing layer tsid during deco_add: ' + tsid);
					}
				}
			}
			
			if (layersToRebuild.length) {
				LocationCommands.rebuildLayersQuickly(layersToRebuild, gameRenderer);
				TSFrontController.instance.resnapMiniMap();
			}
		}
		
		/**
		 * Updates any properties on existing decos.
		 * 
		 * Takes an Object of the following format:
		 * 
		 * layers: {
		 *   walls: {...},
		 *   platform_lines: {...}
		 * }
		 */
		public function updateDeco(layers:Object):void {
			
			const location:Location = model.worldModel.location;
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			const locationView:LocationView = gameRenderer.locationView;
			
			var deco:Deco;
			var decos:Object;
			var layer:Layer;
			var deco_renderer:DecoRenderer;
			const layersToRebuild:Vector.<Layer> = new Vector.<Layer>();
			
			var tsid:String;
			for (tsid in layers) {
				// get layer
				layer = location.getLayerById(tsid);
				if (layer) {
					decos = layers[tsid];
					for (tsid in decos) {
						// get model
						deco = layer.getDecoByTsid(tsid);
						if (deco) {
							// we need to figure this BEFORE we update the model (else it will never be true)
							var need_to_reload_asset:Boolean = (deco.sprite_class != decos[tsid].sprite_class);
							
							// update model
							deco.updateFromAnonymous(decos[tsid]);
							
							// we need to get this now, so that if the deco was just flipped to a standalone state,
							// but was not previously standalone, we fall back to rebuildLayersQuickly 
							if (deco.should_be_rendered_standalone) {
								deco_renderer = gameRenderer.getDecoRendererByTsid(deco.tsid);
							}
							
							if (deco.should_be_rendered_standalone && deco_renderer) {
								// standalone decos can be re-rendered quickly
								if (deco_renderer) {
									if (need_to_reload_asset) {
										deco_renderer.reloadDecoAsset();
									} else {
										deco_renderer.syncRendererWithModel();
									}
								}
							} else {
								// it is not a standalone, so we must rebuild the whole layer
								if (layersToRebuild.indexOf(layer) == -1) {
									layersToRebuild.push(layer);
								}
							}
							
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.error('missing deco tsid during deco_update: ' + tsid);
							}
						}
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing layer tsid during deco_update: ' + tsid);
					}
				}
			}
			
			if (layersToRebuild.length) {
				LocationCommands.rebuildLayersQuickly(layersToRebuild, gameRenderer);
				TSFrontController.instance.resnapMiniMap();
			}
		}
		
		/**
		 * Removes existing decos.
		 * 
		 * Takes an Object of the following format:
		 * 
		 * layers: {
		 *     middleground: [tsid, ...],
		 *     ...
		 *   }
		 * }
		 */
		public function removeDeco(layers:Object):void {
			layers = layers.layers;
			
			const location:Location = model.worldModel.location;
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			const locationView:LocationView = gameRenderer.locationView;
			
			var deco:Deco;
			var decos:Object;
			var layer:Layer;
			const layersToRebuild:Vector.<Layer> = new Vector.<Layer>();
			
			var tsid:String;
			for (tsid in layers) {
				// get layer
				layer = location.getLayerById(tsid);
				if (layer) {
					if (layersToRebuild.indexOf(layer) == -1) {
						layersToRebuild.push(layer);
					}
					decos = layers[tsid];
					for each (tsid in decos) {
						// get model
						deco = layer.getDecoByTsid(tsid);
						if (deco) {
							// remove model
							layer.decos.splice(layer.decos.indexOf(deco), 1);
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.error('missing deco tsid during deco_remove: ' + tsid);
							}
						}
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing layer tsid during deco_remove: ' + tsid);
					}
				}
			}
			
			if (layersToRebuild.length) {
				LocationCommands.rebuildLayersQuickly(layersToRebuild, gameRenderer);
				TSFrontController.instance.resnapMiniMap();
			}
		}
						
		private function onResize():void {
			if (main_view) {
				main_view.resizeToStage();
			}
		}
	}
}