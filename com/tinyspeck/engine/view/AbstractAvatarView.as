package com.tinyspeck.engine.view
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.avatar.AvaChatBubbleManager;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.renderer.util.AvatarAnimationState;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import org.osflash.signals.Signal;
	
	public class AbstractAvatarView extends TSSpriteWithModel implements IWorthRenderable, IDisposable {
		private static const labelGlowFilter:GlowFilter = new GlowFilter();
		{ // static init
			labelGlowFilter.color = 0xffffff;
			labelGlowFilter.alpha = .7;
			labelGlowFilter.blurX = 2;
			labelGlowFilter.blurY = 2;
			labelGlowFilter.strength = 9;
			labelGlowFilter.quality = 4;
		}
		private static const labelGlowFilterA:Array = [labelGlowFilter];
		
		public var sheets_reloaded_sig:Signal = new Signal();
		
		// keep public for tweener
		public var final_scale_to:Number = NaN;
		// keep public for tweener
		public var pc_scale_to:Number = NaN;
		
		protected var _chatBubbleManager:AvaChatBubbleManager;
		
		protected var ss_view:SSViewSprite;
		protected var ss:SSAbstractSheet;
		protected var rooked_overlay_rect:Rectangle;
		protected var rooked_overlay:DisplayObject;
		protected var rooked_overlay_iiv:ItemIconView;
		
		protected var _tf:TextField;
		protected var _colored_sp:Sprite;
		protected var _colored_tf:TextField;
		
		protected var ss_view_holder:Sprite = new Sprite();
		protected var hit_box:Sprite;
		
		protected var current_aas:int;
		protected var _orientation:int;

		protected var current_msg:String;
		
		protected var rooked:Boolean;
		protected var _stopped:Boolean = false;
		protected var _show_tf:Boolean = true;
		protected var make_all_sheets:Boolean = false;
		
		protected var _worth_rendering:Boolean = true;
		protected var default_dot_r:int = 15;
		
		public function AbstractAvatarView(tsid:String):void {
			super(tsid);
			name = tsid || 'avatar_'+String(new Date().getTime());
			_animateXY_duration = .1;
			mouseEnabled = false;
			final_scale_to = final_scale;
			pc_scale_to = model.worldModel.getPCByTsid(tsid).scale;
			
			_chatBubbleManager = new AvaChatBubbleManager(this);
		}
		
		public function get orientation():int {
			return _orientation;
		}
		
		protected function init():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			if (!pc) {
				CONFIG::debugging {
					Console.error('no pc in the model for this tsid:'+tsid);
				}
				return;
			}
			_tf = new TextField();
			TFUtil.prepTF(_tf, false);
			_tf.autoSize = TextFieldAutoSize.CENTER;
			_tf.x = 0;
			updateNameField();
			_tf.visible = _show_tf;
			_tf.filters = labelGlowFilterA;
			updateLabelTF(pc);
			addChild(_tf);
			
			cacheAsBitmap = (EnvironmentUtil.getUrlArgValue('SWF_cab') == '1');
			
			addChild(ss_view_holder);
			if (_worth_rendering) {
				ss = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url, null, make_all_sheets);
				setUpSS();
			} else {
				_stopped = true;
			}
			
			if (pc.rs > 0) {
				rook();
			}
			
			hideShowColorDot(true);
			
			_animateAndOrientFromS(pc.s);
			
			hit_box = new Sprite();
			hit_box.mouseEnabled = true;
			addChild(hit_box);
			
			drawHitBox();
		}
		
		protected function drawHitBox():void {
			var hit_box_width:int = Math.round(CSSManager.instance.getNumberValueFromStyle('avatar_settings', 'hit_box_width', 66)*final_scale);
			var hit_box_height:int = Math.round(CSSManager.instance.getNumberValueFromStyle('avatar_settings', 'hit_box_height', 123)*final_scale);
			var hit_box_offset_y:int = Math.round(CSSManager.instance.getNumberValueFromStyle('avatar_settings', 'hit_box_offset_y', 10)*final_scale);
			
			var g:Graphics = hit_box.graphics;
			g.clear();
			g.beginFill(0, hit_target_alpha);
			g.drawRect(-(hit_box_width/2), -hit_box_height, hit_box_width, hit_box_height);
			g.endFill();
			hit_box.y = hit_box_offset_y;
			
			if (model.flashVarModel.avatar_trail_buffer) {
				/*
				 * A temporary fix that draws an invisible sprite box behind an avatar.
				 * This helps reslove the issue that FP 11.1 introduced with incorrect redraw
				 * region clearing with 2 overlapping sprites that are moving.
				 */  
				const buffer_w:int = 300;
				const buffer_h:int = 400;
				graphics.clear();
				graphics.beginFill(0, 0);
				graphics.drawRect(-buffer_w * .5, -(buffer_h + height)*.5, buffer_w, buffer_h);
				graphics.endFill();
			}
		}
		
		// this takes into account the scale at which the spritesheets are generated, and adjusts for model.worldModel.location.display_scale
		private function get final_scale():Number {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			return AvatarSSManager.ss_options.scale * pc.scale;
		}
		
		private function hideShowColorDot(force:Boolean=false):void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			if (!force && pc.last_game_flag_sig == pc.game_flag_sig) return;
			
			if (pc.show_color_dot && pc.color_group != '#888888') {
				// lazy creation
				if (!_colored_sp) {
					_colored_sp = new Sprite();
					_colored_tf = new TextField();
					TFUtil.prepTF(_colored_tf, false);
					_colored_tf.embedFonts = false; // I do not understand this, but if we specify true then font face="HelveticaEmbed" renders differently
					_colored_tf.autoSize = TextFieldAutoSize.CENTER;
				}
				showColorDot();
			} else {
				hideColorDot();
			}
		}
		
		private function showGameText():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			if (pc.game_text) {
				_colored_tf.htmlText = '<font face="HelveticaEmbed" size="22" color="#ffffff">'+pc.game_text+'</font>';
				_colored_tf.x = -Math.round(_colored_tf.width/2);
				_colored_tf.y = -Math.round(_colored_tf.height/2);
				_colored_sp.addChild(_colored_tf);
			} else {
				if (_colored_tf.parent) _colored_tf.parent.removeChild(_colored_tf);
			}
		}
		
		private function showColorDot():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			const c:int = ColorUtil.getDotColor(pc.color_group);
			
			const border_w:int = 2;
			const r:int = (pc.game_text) ? 22 : default_dot_r;
			
			_colored_sp.y = -(h+r);
			
			const g:Graphics = _colored_sp.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			
			g.beginFill(c, 1);
			g.drawCircle(0, 0, r);
			g.endFill();
			
			g.beginFill(0, .5);
			g.drawCircle(0, 0, r);
			g.endFill();
			
			g.beginFill(c, 1);
			g.drawCircle(0, 0, r-border_w);
			g.endFill();
			
			if (pc.secondary_color_group && this is AvatarView) {
				const sc:int = ColorUtil.getDotColor(pc.secondary_color_group);
				const sr:int = r/2;
				const sx:int = r/1.5;
				const sy:int = -sx;
				
				g.beginFill(sc, 1);
				g.drawCircle(sx, sy, sr);
				g.endFill();
				
				g.beginFill(0, .5);
				g.drawCircle(sx, sy, sr);
				g.endFill();
				
				g.beginFill(sc, 1);
				g.drawCircle(sx, sy, sr-border_w);
				g.endFill();
			}
			
			showGameText();
			
			addChildAt(_colored_sp, 0);
			updateNameField();
		}
		
		private function hideColorDot():void {
			if (_colored_sp && _colored_sp.parent) {
				_colored_sp.parent.removeChild(_colored_sp);
				updateNameField();
			}
		}
		
		// set and get worth_rendering required as part of IWorthRenderable
		public function get worth_rendering():Boolean {
			// only really used for PCView, but needs to be here so thinsg that have refs to PCview as AbstractAvatarViews can reference it (see InLocationAnnouncementOverlay.placeByLocationItemstackView)
			return _worth_rendering;
		}
		public function set worth_rendering(value:Boolean):void { _worth_rendering = value; }
		
		public function showHide():void {
			//
		}
		
		// this only gets called when the initial call to AvatarSSManager.getSSForAva returned the default ss
		// because the assets were not yet fully loaded, and &SWF_use_default_ava != 1
		private function onAvaAssetsRdy(ac:AvatarConfig):void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			AvatarSSManager.removeSSViewforDefaultSS(ss_view);
			ss = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url);
			setUpSS();
			
			current_aas = 0; // to force _animateAndOrientFromS to work
			_animateAndOrientFromS(pc.s);
			
			/*
			var aswf:AvatarSwf = ss_view_holder.parent.addChildAt(pc.ac.acr.ava_swf,0) as AvatarSwf;
			var self:Sprite = this;
			setTimeout(function():void{
				aswf.graphics.clear();
				aswf.graphics.beginFill(0x2e1d18, parseFloat(EnvironmentUtil.getUrlArgValue('ffffff')));
				aswf.graphics.drawRect(-20, -200, 50, 330);
				aswf.x = 50;
				aswf.y = -120;
				
				ss_view_holder.graphics.clear();
				ss_view_holder.graphics.beginFill(0x2e1d18, 1);
				ss_view_holder.graphics.drawRect(0, 0, -50, -330);
				
				Sprite(self).graphics.clear();
				Sprite(self).graphics.beginFill(0x2e1d18, 1);
				Sprite(self).graphics.drawRect(90, 0, 100, -330);
			}, 100);
			
			setInterval(function():void {
				var blend:String = (self.blendMode == BlendMode.NORMAL) ? BlendMode.LAYER : BlendMode.NORMAL;
				var str:String = self.blendMode+' -> '+blend;
				var p:* = aswf;
				while (p && !(p is Stage)) {
					if (p['blendMode']) p.blendMode = blend;
					str+= ' '+p.name
					p = p['parent'];
				}
				Console.warn(str)
				
			}, 3000);
			*/
		}
		
		public function rescale():void {
			if (!ss) return;
			if (!ss_view) return;
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			if (pc.scale != last_scale) {
				scaleAndPositionSS();
			}
			
			last_scale = pc.scale;
			
			if (pc && pc.apo) {
				// EC: I upped this to 150 height (from 120) because it was a litle too restrictive (colliding with firefly_whistle, for example, was too hard where it is placed on the stand)
				pc.apo.avatarViewBounds.width = 63*pc.scale;
				pc.apo.avatarViewBounds.height = 150*pc.scale;
			}
			
			drawHitBox();
		}
		
		public function reloadSSWithNewSheet():void {
			if (!ss) return;
			if (!ss_view) return;
			if (!_worth_rendering) return;
			if (disposed) return;
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			var load_count:int
			var loaded:int;
			var required_sheetsA:Array = AvatarAnimationDefinitions.sheetsA;
			
			if (this is AvatarView && model.stateModel.newbie_chose_new_avatar) {
				// in this case to make it faster, just load two sheets
				required_sheetsA = ['base', 'jump'];
			} else if (!make_all_sheets) {
				required_sheetsA = ['base'];
			}
			
			for each(var sheet:String in required_sheetsA) {
				
				var bmd_key:String = AvatarSSManager.getSheetPngUrl(pc.sheet_url, sheet);
				if (AssetManager.instance.getLoadedBitmapData(bmd_key)) {
					continue;
				}

				load_count++;
				AssetManager.instance.loadBitmapFromWeb(bmd_key, function(filename:String, bm:Bitmap):void {
					loaded++;
					if (!bm) {
						CONFIG::debugging {
							Console.error('WTF failed to load '+bmd_key);
						}
						return;
					}
					
					if (loaded == load_count) {
						// need a little delay here to make sure shot don't get removed below by AssetManager.instance.removeLoadedBitmapData too fast
						StageBeacon.waitForNextFrame(reloadSSWithNewSheet);
					}
				}, 'reloadSSWithNewSheet');
			}
			
			if (load_count > 0) {
				return;
			}
			
			AvatarSSManager.removeSSViewforAva(pc.ac, ss.name, ss_view);
			ss = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url, null, required_sheetsA.length > 1);
			setUpSS();
			
			// go ahead and delete those sheet pngs we loaded
			for each(sheet in required_sheetsA) {
				bmd_key = AvatarSSManager.getSheetPngUrl(pc.sheet_url, sheet);
				AssetManager.instance.removeLoadedBitmapData(bmd_key);
				//Console.info('removed '+bmd_key+' in reloadSSWithNewSheet');
			}
			
			current_aas = 0; // to force _animateAndOrientFromS to work
			_animateAndOrientFromS(pc.s);
			
			if (this is AvatarView) {
				YouDisplayManager.instance.updateAvatarSS();
			}
			sheets_reloaded_sig.dispatch();
		}
		
		private var last_scale:Number = NaN;
		protected function scaleAndPositionSS():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			TSTweener.removeTweens(this, 'final_scale_to', 'pc_scale_to');
			TSTweener.addTween(this, {final_scale_to:final_scale, pc_scale_to:pc.scale, time:.5, onUpdate:onZoomUpdate});
			onZoomUpdate();
		}
		
		private function onZoomUpdate():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			ss_view.x = -Math.round(w/2);
			ss_view.y = -h;
			ss_view.y-= Math.round(2.8*final_scale_to);
			ss_view.scaleX = ss_view.scaleY = pc_scale_to;
			updateLabelTF(pc);
			updateNameField();
		}
		
		protected function setUpSS():void {
			if (!ss) return;
			var was_ss_view:SSViewSprite = ss_view;
			
			ss_view = ss.getViewSprite();
			ss_view_holder.addChildAt(ss_view, 0);
			
			scaleAndPositionSS();
			
			if (was_ss_view) {
				//was_ss_view.x+= 100;
				TSTweener.addTween(was_ss_view, {alpha:0, transition:'linear', time:.6, onComplete:function():void {
					if (was_ss_view.parent) was_ss_view.parent.removeChild(was_ss_view);
					//was_ss_view.dispose();// can't do this like so, causes null ref errors we need to find and fix. i think when disposeing an ss_view it needs to be removed properly from
				}});
			}
			
			// what is is this for??
			var g:Graphics = ss_view.graphics;
			g.clear();
			g.beginFill(0, 1);
			g.drawRect(0, 0, ss_view.width, ss_view.height);
		}
		
		protected function updateLabelTF(pc:PC):void {
			var txt:String = pc.label;
			CONFIG::god {
				//txt+= '';//((pc.level) ? '&nbsp;&nbsp;('+pc.level+') ' : '')+pc.s;
				txt+= (pc.level) ? '&nbsp;&nbsp;('+pc.level+') ' : '';
			}
			_tf.htmlText = '<p class="abstract_avatar">'+txt+'</p>';
		}
		
		public function updateNameField():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			if (_chatBubbleManager.currentChatBubble && _chatBubbleManager.currentChatBubble.parent) {
				_tf.visible = false;
			} else {
				if (_colored_sp && _colored_sp.parent) {
					_tf.y = -h-_tf.height-(20+((30*pc.scale)));
				} else {
					_tf.y = -h-_tf.height-(30*pc.scale);
				}
				_tf.visible = _show_tf;
			}
		}
		
		override public function get hit_target():DisplayObject {
			return hit_box;
		}
		
		override public function get interaction_target():DisplayObject {
			return (ss_view_holder ? ss_view_holder : this);
		}
				
		public function get chatBubbleManager():AvaChatBubbleManager {
			return _chatBubbleManager;
		}
		
		/*
		protected function positionRookedOverlay():void {
			if (!rooked) return;
			if (!rooked_overlay) return;
			if (!rooked_overlay_rect) return;
			
			rooked_overlay.x = -Math.round(rooked_overlay_rect.width/2)-rooked_overlay_rect.x;
			rooked_overlay.y = ss_view_holder.getRect(ss_view_holder).y-Math.round(rooked_overlay_rect.height/2)-rooked_overlay_rect.y;
		}
		protected function rook():void {
			if (rooked) return;
			rooked = true;
			if (!rooked_overlay) {
				rooked_overlay = new AssetManager.instance.assets.rooked();
				rooked_overlay.addEventListener(Event.COMPLETE, function():void {
					rooked_overlay.removeEventListener(Event.COMPLETE, arguments.callee);
					rooked_overlay_rect = rooked_overlay.getRect(rooked_overlay)
					positionRookedOverlay();
				});
			}
			
			addChild(rooked_overlay);
			positionRookedOverlay();
			
			rooked_overlay.alpha = 0;
			TSTweener.removeTweens(rooked_overlay);
			TSTweener.addTween(rooked_overlay, {alpha:1, transition:'linear', time:.6});
		}
		
		protected function unrook():void {
			if (!rooked) return;
			rooked = false;
			if (rooked_overlay) {
				TSTweener.removeTweens(rooked_overlay);
				TSTweener.addTween(rooked_overlay, {alpha:0, transition:'linear', time:.6, onComplete:function():void {
					if (rooked_overlay.parent) rooked_overlay.parent.removeChild(rooked_overlay);
				}});
			}
		}*/
		
		protected function positionRookedOverlay():void {
			if (!rooked) return;
			if (!rooked_overlay_iiv) return;
			
			rooked_overlay_iiv.x = 0;
			rooked_overlay_iiv.y = ss_view_holder.getRect(ss_view_holder).y+12;
		}
		
		protected function rook():void {
			if (rooked) return;
			rooked = true;
			if (!rooked_overlay_iiv) {
				rooked_overlay_iiv = new ItemIconView('emotional_bear', 108, 'rooked_halo', 'center_bottom');
			}
			addChild(rooked_overlay_iiv);
			positionRookedOverlay();
			
			rooked_overlay_iiv.alpha = 0;
			TSTweener.removeTweens(rooked_overlay_iiv);
			TSTweener.addTween(rooked_overlay_iiv, {alpha:1, transition:'linear', time:.6});
		}
		
		protected function unrook():void {
			if (!rooked) return;
			rooked = false;
			if (rooked_overlay_iiv) {
				if (rooked_overlay_iiv.parent) {
					TSTweener.removeTweens(rooked_overlay_iiv);
					TSTweener.addTween(rooked_overlay_iiv, {alpha:0, transition:'linear', time:.6, onComplete:function():void {
						if (rooked_overlay_iiv.parent) rooked_overlay_iiv.parent.removeChild(rooked_overlay_iiv);
					}});
				}
			}
		}
		
		public function changeHandler():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			CONFIG::god {
				updateLabelTF(pc);
			}

			if (_worth_rendering){
				if (model.flashVarModel.use_vec) {
					x = pc.x;
					y = pc.y;
				} else {
					animateXY(pc.x, pc.y);
				}
			}
			
			_animateAndOrientFromS(pc.s);
			
			specialChangeHandlers();
		}
		
		protected function specialChangeHandlers():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			if (pc.rs > 0 && !rooked) {
				rook();
			} else if (pc.rs == 0 && rooked) {
				unrook();
			}
			
			hideShowColorDot();
		}
		
		protected function _animateAndOrientFromS(s:String):void {
			if (!_worth_rendering) {
				if (ss_view) {
					ss_view.stop();
					_stopped = true;
				}
				return;
			}
			
			s = s || String(AvatarSSManager.anims.indexOf('idle_stand')+1); // idle_stand, facing right default
			
			// trailing "-" means pasused
			var paused:Boolean = (s.length && s.charAt(s.length-1) == '-');
			var i:int = Math.abs(parseInt(s))-1;
			var orient:int = (parseInt(s) > 0) ? -1 : 1;
			
			if (orient > 0) {
				faceLeft();
			} else {
				faceRight();
			}
			
			setAvatarViewAnimationState(paused, Math.abs(i));
			positionRookedOverlay();
			
			showHide();
		}
		
		// for testing only
		public function testAnimation(name:String, loop:Boolean = false):void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			if (loop) {
				AvatarSSManager.playSSViewForAva(pc.ac, pc.sheet_url, ss_view, ss_view.gotoAndLoop, 0, name);
			}  else {
				AvatarSSManager.playSSViewForAva(pc.ac, pc.sheet_url, ss_view, ss_view.gotoAndPlay, 0, name);
			}
		}
		
		// for testing only
		public function testAnimationSequence(anim_sequenceA:Array, loop_sequence:Boolean = false):void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			if (loop_sequence) {
				AvatarSSManager.playSSViewSequenceForAva(pc.ac, pc.sheet_url, ss_view, ss_view.gotoAndLoopSequence, anim_sequenceA);
			} else {
				AvatarSSManager.playSSViewSequenceForAva(pc.ac, pc.sheet_url, ss_view, ss_view.gotoAndPlaySequence, anim_sequenceA);
			}
		}
		
		protected function setAvatarViewAnimationState(paused:Boolean, aas:int):void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			CONFIG::debugging {
				if (this is AvatarView) Console.trackPhysicsValue('AAV setAvatarViewAnimationState', AvatarAnimationState.MAP[aas]+' current_aas:'+AvatarAnimationState.MAP[current_aas]);
			}
			
			if (aas != current_aas || _stopped) {
				//Console.warn('aas changed, now: '+AvatarAnimationState.MAP[aas])
				_stopped = false;
				var was_ass:int = current_aas;
				current_aas = aas;
				
				// Default animation for unrecognized aas is STAND
				var avatarAnimationState:AvatarAnimationState = AvatarAnimationState.getStateByID(aas);
				var func:Function;
				
				if (avatarAnimationState == AvatarAnimationState.CLIMB_PAUSE) {
					if (was_ass == AvatarAnimationState.CLIMB.ID || was_ass == AvatarAnimationState.CLIMB_PAUSE.ID) {
						ss_view.stop();
						func = null;
					}
				} else if (avatarAnimationState.sequence) {
					func = ss_view.gotoAndLoopSequence;
				} else if (avatarAnimationState.loop) {
					func = ss_view.gotoAndLoop;
				} else if (avatarAnimationState.stop) {
					func = ss_view.gotoAndStop;
				} else {
					func = ss_view.gotoAndPlay;
				}		
				
				if (avatarAnimationState && func != null && !model.flashVarModel.no_avatar_anim) {
					CONFIG::debugging {
                        if (this is AvatarView) Console.trackPhysicsValue('AAV str', avatarAnimationState.name);
					}
					if (avatarAnimationState.sequence) {
						AvatarSSManager.playSSViewSequenceForAva(pc.ac, pc.sheet_url, ss_view, func, avatarAnimationState.name.split(','));
					} else {
						AvatarSSManager.playSSViewForAva(pc.ac, pc.sheet_url, ss_view, func, 0, avatarAnimationState.name);
					}
				} 
			}
			
			if (paused) {
				ss_view.stop();
				_stopped = true;
			}
		}
		
		override public function get h():int {
			return Math.round(112 * final_scale_to);
		}
		
		override public function get w():int {
			return Math.round(59 * final_scale_to);
		}
		
		public function faceRight():void {
			//Console.info('faceRight')
			_orientation = 1;
			ss_view_holder.scaleX = 1;
			_chatBubbleManager.orientBubble();
		}
		
		public function faceLeft():void {
			//Console.error('faceLeft')
			_orientation = -1;
			ss_view_holder.scaleX = -1;
			_chatBubbleManager.orientBubble();
		}
		
		public function get animationScaleX():Number {
			return ss_view_holder.scaleX;
		}
		
		override public function dispose():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			if (ss_view) AvatarSSManager.removeSSViewforAva(pc.ac, pc.sheet_url, ss_view);
			
			_chatBubbleManager.dispose();
			
			super.dispose();
		}

		override public function toString():String {
			return 'AbstractAvatarView[tsid:' + tsid +
				', x:' + x +
				', y:' + y +
				', w:' + w +
				', h:' + h +
				', ss_view.x:' + (ss_view ? ss_view.x : 'no ss_view yet') +
				', ss_view.y:' + (ss_view ? ss_view.y : 'no ss_view yet') +
				']';
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			
			// _chat_bubble isn't on our display list
			if (_chatBubbleManager.currentChatBubble) _chatBubbleManager.currentChatBubble.visible = value;
		}

		public function get colored_sp():Sprite {
			return _colored_sp;
		}

	}
}