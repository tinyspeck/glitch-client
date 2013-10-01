package com.tinyspeck.engine.view
{
	import com.tinyspeck.engine.data.house.CultivationsChoice;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	
	public class CultCarryUI extends TSSpriteWithModel {
		private var iiv:ItemIconView;
		private var invoke_bt:Button;
		private var _is_good:Boolean;
		private var tip:CultCarryTip;
		private var ban:Ban;

		public function get is_good():Boolean {
			return _is_good;
		}

		public var loaded:Boolean;
		
		public function CultCarryUI():void {
			super('CultCarryUI');
			
			invoke_bt = new Button({
				label: 'Place',
				name: 'place',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			invoke_bt.addEventListener(MouseEvent.CLICK, onBtClicked);
			addChild(invoke_bt);
			
			ban = new Ban();
			ban.visible = false;
			addChild(ban);
			
			tip = new CultCarryTip();
			addChild(tip);
		}
		
		private function onBtClicked(e:MouseEvent):void {
			CultManager.instance.enterKeyHandler();
		}
		
		private function makeUiGood():void {
			invoke_bt.disabled = false;
			if (iiv) {
				iiv.alpha = 1;
				ban.visible = false;
			}
		}
		
		private function makeUiBad():void {
			invoke_bt.disabled = true;
			if (iiv) {
				iiv.alpha = .5;
				ban.visible = true;
			}
		}
		
		public function good():void {
			if (current_choice) tip.update();
			if (_is_good) return;
			_is_good = true;
			makeUiGood();
		}
		
		public function bad():void {
			if (current_choice) tip.update();
			if (!_is_good) return;
			_is_good = false;
			makeUiBad();
		}
		
		private var current_choice:CultivationsChoice;
		private var current_item:Item;
		private var current_nudge_itemstack:Itemstack;
		public function start(choice:CultivationsChoice, item:Item, nudge_itemstack:Itemstack):void {
			current_choice = choice;
			current_item = item;
			current_nudge_itemstack = current_nudge_itemstack;
			
			if (current_choice) {
				tip.setChoice(choice);
				invoke_bt.label = 'Place ('+current_choice.imagination_cost+' iMG)';
			} else if (current_item) {
				invoke_bt.label = 'Move Here';
			}
			
			if (iiv && iiv.tsid != current_item.tsid) {
				iiv.parent.removeChild(iiv);
				iiv.dispose();
				iiv = null;
			}
			
			if (!iiv) {
				loaded = false;
				iiv = new ItemIconView(current_item.tsid, 0, '1', 'center_bottom');
				if (iiv.loaded) {
					onIconLoad();
				} else {
					iiv.addEventListener(TSEvent.COMPLETE, onIconLoad, false, 0, true);
				}
			}
			
			// hide it if we have no choice (which means we are nudging, and just moving the existing itemsstack in location)
			iiv.visible = Boolean(current_choice);
			
			makeUiBad();
			bad();
			
			addChildAt(iiv, 0);
		}
		
		private function onIconLoad(e:TSEvent=null):void {
			loaded = true;
			
			invoke_bt.x = -Math.round(invoke_bt.width/2);
			invoke_bt.y = 10;
			
			iiv.x = 0;
			iiv.y = 0;
			
			if (current_choice) {
				if (tip.for_display_above) {
					tip.y = iiv.y - (iiv.art_h+5);
				} else {
					tip.y = invoke_bt.y+invoke_bt.height+5;
				}
			}
			
			ban.x = -(ban.width/2);
			ban.y = -(iiv.art_h/2)-(ban.height/2);
						
			draw();
		}
		
		public function get art_w():int {
			if (!iiv || !iiv.loaded) return 0;
			return iiv.art_w;
		}
		
		private function draw():void {
			var g:Graphics = graphics;
			g.clear();
			
			if (!current_item) return;

			// draw placement_w |-------------------| line
			var w:int = art_w;
			g.lineStyle(2, 0xffffff, 1);
			/*
			// left vert line
			g.moveTo(-w/2, -3);
			g.lineTo(-w/2, 3);
			// right vert line
			g.moveTo(w/2, -3);
			g.lineTo(w/2, 3);
			*/
			w = current_item.placement_w
			// horiz line
			g.moveTo(-w/2, 0);
			g.lineTo(w/2, 0);
			// left vert line
			g.moveTo(-w/2, -3);
			g.lineTo(-w/2, 3);
			// right vert line
			g.moveTo(w/2, -3);
			g.lineTo(w/2, 3);
			
			if (!iiv || !iiv.loaded) return;
			g.lineStyle(0, 0, 0);
			g.beginFill(0, 0);
			g.drawRect(-iiv.art_w/2, -iiv.art_h, iiv.art_w, iiv.art_h);
		}
		
	}
}
