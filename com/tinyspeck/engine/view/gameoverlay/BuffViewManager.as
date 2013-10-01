package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.ui.buff.BuffUI;
	
	import flash.display.Sprite;
	
	public class BuffViewManager extends AbstractTSView {
		
		/* singleton boilerplate */
		public static const instance:BuffViewManager = new BuffViewManager();
		
		private static const GAP:uint = 5;
		
		private var model:TSModelLocator;
		private var buff_elements:Vector.<BuffUI> = new Vector.<BuffUI>();
		
		protected var _w:int;
		protected var active_holder:Sprite = new Sprite();
		
		public function BuffViewManager():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
						
			model = TSModelLocator.instance;
			
			//place it in it's home
			y = 20;
			addChild(active_holder);
		}
		
		public function onBuffAdds(tsids:Array):void {
			var buff:PCBuff;
			var buff_ui:BuffUI;
			var tsid:String;
			for (var i:int=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				buff = model.worldModel.pc.buffs[tsid];
				if (!buff) {
					CONFIG::debugging {
						Console.error('unknown buff');
					}
					continue;
				}
				
				buff_ui = active_holder.getChildByName(tsid) as BuffUI;
				if(!buff_ui) {
					//let's get an element out of the pool
					buff_ui = getBuffUIFromPool();
				}
				
				buff_ui.show(buff);
				active_holder.addChildAt(buff_ui, buff.is_timer && buff.remaining_duration > 0 ? 0 : Math.max(0, active_holder.numChildren-1));
			}
		}
		
		public function onBuffDels(tsids:Array):void {
			var buff:PCBuff;
			var buff_ui:BuffUI;
			var tsid:String;
			for (var i:int=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				buff = model.worldModel.pc.buffs[tsid];
				
				if(!buff) {
					CONFIG::debugging {
						Console.error('unknown buff');
					}
					continue;
				}
				
				//clear out the remaining duration
				buff.remaining_duration = 0;
				
				buff_ui = active_holder.getChildByName(tsid) as BuffUI;
				if(buff_ui) {
					//go away now
					buff_ui.hide();
				} 
				else {
					CONFIG::debugging {
						Console.error('onBuffDels called but no buff display exists '+tsid);
					}
				}
			}
		}
		
		public function onBuffUpdates(tsids:Array):void {
			var buff:PCBuff;
			var buff_ui:BuffUI;
			var tsid:String;
			for (var i:int=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				buff = model.worldModel.pc.buffs[tsid];
				if (!buff) {
					CONFIG::debugging {
						Console.error('unknown buff');
					}
					continue;
				}
				buff_ui = active_holder.getChildByName(tsid) as BuffUI;
				if(buff_ui) {
					buff_ui.refresh();
				} else {
					CONFIG::debugging {
						Console.error('onBuffUpdates called but no buff display exists '+tsid);
					}
				}
			}
		}
		
		public function refresh():void {
			//see how fat that energy read out is
			x = YouDisplayManager.instance.player_info_w + BuffUI.RADIUS + 10;
		}
		
		private function getBuffUIFromPool():BuffUI {
			const total:int = buff_elements.length;
			var i:int;
			var buff_ui:BuffUI;
			
			for(i; i < total; i++){
				//loop through, find one without a parent and return that
				buff_ui = buff_elements[int(i)];
				if(!buff_ui.parent) return buff_ui;
			}
			
			//if we made it down this far, we gotz to make one
			buff_ui = new BuffUI();
			buff_ui.addEventListener(TSEvent.CHANGED, onBuffChanged, false, 0, true);
			buff_elements.push(buff_ui);
			
			return buff_ui;
		}
		
		private function onBuffChanged(event:TSEvent = null):void {
			//this will make sure the buffs are all still lined up proper
			const total:int = active_holder.numChildren;
			var i:int;
			var next_x:int;
			var buff_ui:BuffUI;
			
			for(i; i < total; i++){
				buff_ui = active_holder.getChildAt(i) as BuffUI;
				buff_ui.x = next_x;
				next_x += buff_ui.width + GAP;
			}
		}
	}
}