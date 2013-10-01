package com.tinyspeck.engine.view.itemstack.commands
{
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.OverlayMouse;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.itemstack.SpecialConfig;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.spritesheet.ISpriteSheetView;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSAnimationCommand;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.itemstack.ISpecialConfigDisplayer;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	public class HandleSpecialConfigsCmd implements ICommand {
		public var displayer:ISpecialConfigDisplayer;
		public var ss:SSAbstractSheet;
		public var used_swf_url:String;
		public var itemstack:Itemstack;
		CONFIG::god private var log_str:String;
		
		public function HandleSpecialConfigsCmd() {
			//
		}
		
		private function checkDependencies():Boolean {
			if (!displayer || !used_swf_url || !itemstack) {
				return false;
				throw new Error("Must set HandleSpecialConfigsCmd's dependencies.");
			}
			
			return true;
		}
		
		private function dispose():void {
			displayer = null;
			ss = null;
			used_swf_url = null;
		}
		
		public function execute():void {
			if (!checkDependencies()) return;
			
			if (itemstack.itemstack_state.is_any_special_config_dirty) {
				
				CONFIG::god {
					log_str = 's:'+itemstack.itemstack_state.value+' ';
				}
				
				var sconfigV:Vector.<SpecialConfig> = itemstack.itemstack_state.special_configV;
				if (sconfigV) {
					for (var i:int;i<sconfigV.length;i++) {
						var sconfig:SpecialConfig = sconfigV[i];
						var uid:String = sconfig.uid+'_'+displayer;
						
						if (!sconfig.is_dirty) {
							CONFIG::god {
								log_str+= '[not dirty:'+sconfig.uid+'] ';
							}
							continue;
						}
						
						AnnouncementController.instance.cancelOverlay(uid, true);
						var removalResultLog:String = displayer.removeSpecialConfigDO(uid);
						CONFIG::god {
							if (removalResultLog) log_str += '['+removalResultLog+'] ';
						}
						
						switch (sconfig.type) {
							case SpecialConfig.TYPE_FURN_PRICE_TAG:
								do_TYPE_FURN_PRICE_TAG(sconfig, uid);
								break;
							case SpecialConfig.TYPE_TOWER_SIGN:
								do_TYPE_TOWER_SIGN(sconfig, uid);
								break;
							case SpecialConfig.TYPE_TOWER_SCAFFOLDING:
								do_TYPE_TOWER_SCAFFOLDING(sconfig, uid);
								break;
							case SpecialConfig.TYPE_TOWER_EDIT:
								do_TYPE_TOWER_EDIT(sconfig, uid);
								break;
							case SpecialConfig.TYPE_SDB_COLLECT:
								do_TYPE_SDB_COLLECT(sconfig, uid);
								break;
							case SpecialConfig.TYPE_SDB_COST:
								do_TYPE_SDB_COST(sconfig, uid);
								break;
							case SpecialConfig.TYPE_SNAP_FRAME:
								do_TYPE_SNAP_FRAME(sconfig, uid);
								break;
							default:
								if (sconfig.item_class) {
									doItemClass(sconfig, uid);
								} else {
									// there is no sconfig.item_class and no known type, we can mark it clean in all cases
									sconfig.is_dirty = false;
									CONFIG::god {
										log_str+= '[clean:'+uid+'] ';
									}
								}
						}
					}
				}
				
				CONFIG::debugging {
					CONFIG::god {
						Console.priinfo('740', log_str);
					}
				}
				
				dispose();
			}
		}
		
		private function doItemClass(sconfig:SpecialConfig, uid:String):void {
			
			if (sconfig.state_triggers && sconfig.state_triggers.length) {
				// in this case we do not want to mark it clean, because we need to keep recehcking
				// every time this  method is called to see if itemstack_state.value matches a state_trigger 
				
				if (sconfig.state_triggers.indexOf(itemstack.itemstack_state.value) == -1) {
					// not in the correct state, do nothing else
					CONFIG::god {
						log_str+= '[s not in '+sconfig.state_triggers+'] ';
					}
					return;
				}
			} else {
				sconfig.is_dirty = false;
			}
			
			if (itemstack.item.tsid == sconfig.item_class) {
				var annc:Object;
				
				// it is the same class, so just go ahead and create a new ss_view for it.
				
				var my_ss_view:ISpriteSheetView = ss.getViewSprite();
				var my_ss_view_do:DisplayObject = my_ss_view as DisplayObject;
				my_ss_view_do.x = -Math.round((ss.ss_options.movieWidth*itemstack.scale)/2);
				my_ss_view_do.y = -ss.ss_options.movieHeight*itemstack.scale;
				my_ss_view_do.name = uid;
				
				var fnum:int = 1;
				
				// get from pool
				var anim_cmd:SSAnimationCommand = EnginePools.SSAnimationCommandPool.borrowObject();
				anim_cmd.state_ob = sconfig.state //((this is LocationItemstackView && itemstack.itemstack_state.type == ItemstackState.TYPE_DEFAULT) ? itemstack.count : _ss_state);
				anim_cmd.config = itemstack.itemstack_state.config_for_swf;
				anim_cmd.scale = itemstack.scale;
				CONFIG::debugging {
					Console.log(111, itemstack.item.tsid+' playSSViewForItem: anim_cmd.state_ob:'+anim_cmd.state_ob);
				}
				ItemSSManager.playSSViewForItemSWFByUrl(used_swf_url, itemstack.item, my_ss_view, fnum, anim_cmd, null, 0);
				// return to pool
				EnginePools.SSAnimationCommandPool.returnObject(anim_cmd);
				
				if (sconfig.under_itemstack) {
					displayer.addToSpecialBack(my_ss_view_do);
					CONFIG::god {
						log_str+= '[added back:'+uid+'] ';
					}
				} else {
					displayer.addToSpecialFront(my_ss_view_do);
					CONFIG::god {
						log_str+= '[added front:'+uid+'] ';
					}
				}
			} else {
				CONFIG::god {
					log_str+= '[annc:'+uid+'] ';
				}
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: true,
					allow_bubble:true,
					
					center_view: sconfig.center_view,
					uid: uid,
					item_class: sconfig.item_class,
					state: sconfig.state,
					under_itemstack: sconfig.under_itemstack,
					width: sconfig.width,
					delta_x: sconfig.delta_x,
					delta_y: sconfig.delta_y,
					special_config_displayer: displayer
				};
				
				annc.opacity = sconfig.opacity || 1;
				if (sconfig.furniture) annc.config = FurnitureConfig.fromAnonymous(sconfig.furniture, '');
				if (!isNaN(sconfig.fade_in_sec)) annc.fade_in_sec = sconfig.fade_in_sec;
				if (!isNaN(sconfig.fade_out_sec)) annc.fade_out_sec = sconfig.fade_out_sec;
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
			}
		}
		
		private function do_TYPE_SNAP_FRAME(sconfig:SpecialConfig, uid:String):void {
			
			sconfig.is_dirty = false;
			
			if (sconfig.img_url) {
				
				var local_sconfig:SpecialConfig = sconfig; // so we maintain a ref for the callback below
				var local_holder:ISpecialConfigDisplayer = displayer; // so we maintain a ref for the callback below
				var func:Function = function onImageLoad(filename:String, bm:Bitmap):void {
					if (!bm) {
						CONFIG::debugging {
							Console.error('filename could not be loaded');
						}
						return;
					}
					bm.name = 'special_img_bm'
					bm.smoothing = true;
					bm.width = local_sconfig.width;
					bm.height = local_sconfig.height;
					//bm.filters = StaticFilters.black8px90DegreesInner_DropShadowA;
					
					if (local_sconfig.center_view) {
						bm.x = -Math.round(bm.width/2);
						bm.y = -Math.round(bm.height/2);
						if (local_holder is LocationItemstackView) {
							bm.y+= local_sconfig.delta_y;
						}
					}
					//bm.x = local_sconfig.delta_x;
					//bm.y = local_sconfig.delta_y;
					
					var special_img_holder:DisposableSprite = new DisposableSprite();
					special_img_holder.filters = StaticFilters.black1px90DegreesInner_DropShadowA;
					special_img_holder.name = 'special_img_holder';
					special_img_holder.addChild(bm);
					
					if (local_sconfig.under_itemstack) {
						local_holder.addToSpecialBack(special_img_holder);
						CONFIG::god {
							log_str+= 'added back:'+local_sconfig.uid+'_'+local_holder+' ';
						}
					} else {
						local_holder.addToSpecialFront(special_img_holder);
						CONFIG::god {
							log_str+= 'added front:'+local_sconfig.uid+'_'+local_holder+' ';
						}
					}
				}
				
				AssetManager.instance.loadBitmapFromWeb(sconfig.img_url, func, 'SpecialConfig');
				
			}
		}
		
		private function do_TYPE_SDB_COST(sconfig:SpecialConfig, uid:String):void {
			sconfig.is_dirty = false;
			
			if (sconfig.is_selling && sconfig.sale_price) {
				var annc:Object;
				
				CONFIG::god {
					log_str+= 'annc:'+uid+' ';
				}
				
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: true,
					allow_bubble:true,
					uid: uid,
					show_text_shadow:false,
					bubble_placard:true,
					special_config_displayer: displayer,
					
					under_itemstack: sconfig.under_itemstack,
					text: ['<span class="sale_price">'+StringUtil.formatNumberWithCommas(sconfig.sale_price)+'₡</span>'],
					delta_x: (sconfig.h_flipped) ? -sconfig.delta_x : sconfig.delta_x,
					delta_y: sconfig.delta_y,
					h_flipped: sconfig.h_flipped
				};
				
				if (!isNaN(sconfig.fade_in_sec)) annc.fade_in_sec = sconfig.fade_in_sec;
				if (!isNaN(sconfig.fade_out_sec)) annc.fade_out_sec = sconfig.fade_out_sec;
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
			}
		}
		
		private function do_TYPE_SDB_COLLECT(sconfig:SpecialConfig, uid:String):void {
			sconfig.is_dirty = false;
			
			if (sconfig.income) {
				var annc:Object;
				
				CONFIG::god {
					log_str+= 'annc:'+uid+' ';
				}
				
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: true,
					allow_bubble:true,
					uid: uid,
					show_text_shadow:true,
					special_config_displayer: displayer,
					text: ['<span class="income">₡</span>'],
					
					under_itemstack: sconfig.under_itemstack,
					delta_x: (sconfig.h_flipped) ? -sconfig.delta_x : sconfig.delta_x,
					delta_y: sconfig.delta_y,
					h_flipped: sconfig.h_flipped
				};
				
				if (!isNaN(sconfig.fade_in_sec)) annc.fade_in_sec = sconfig.fade_in_sec;
				if (!isNaN(sconfig.fade_out_sec)) annc.fade_out_sec = sconfig.fade_out_sec;
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
			}
		}
		
		private function do_TYPE_TOWER_EDIT(sconfig:SpecialConfig, uid:String):void {
			sconfig.is_dirty = false;
			
			if (sconfig.swf_url) {
				var annc:Object;
				
				CONFIG::god {
					log_str+= 'annc:'+uid+' ';
				}
				
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: false,
					above_itemstack: true,
					follow:true,
					allow_bubble:true,
					uid: uid,
					special_config_displayer: displayer,
					under_itemstack: false,
					fade_in_sec:0,
					fade_out_sec:0,
					mouse: {
						is_clickable: true,
						allow_multiple_clicks: true,
						click_client_action: {
							type:OverlayMouse.TYPE_CHANGE_TOWER
						},
						dismiss_on_click: false,
						txt: "Click to change tower",
						txt_delta_y: -100
					},
					
					//swf_url: sconfig.swf_url,
					item_class:'sign_stake',
					// I would think I would want to reverse polarity on the delta_x, if h_flipped, but this works without it
					delta_x: 200,//(sconfig.h_flipped) ? sconfig.delta_x : sconfig.delta_x,
					//width: 40,//sconfig.width,
					
					delta_y: sconfig.delta_y,
					h_flipped: sconfig.h_flipped
				};
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
			}
		}
		
		private function do_TYPE_TOWER_SCAFFOLDING(sconfig:SpecialConfig, uid:String):void {
			sconfig.is_dirty = false;
			
			var A:Array = tryAndGetSignCoordsFromMC();
			var delta_x:int = (A) ? A[0] : sconfig.delta_x;
			var delta_y:int = (A) ? A[1] : sconfig.delta_y;
			
			if (sconfig.swf_url && !sconfig.no_display) {
				var annc:Object;
				
				CONFIG::god {
					log_str+= 'annc:'+uid+' ';
				}
				
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: true,
					allow_bubble:true,
					uid: uid,
					special_config_displayer: displayer,
					under_itemstack: false,
					fade_in_sec:0,
					fade_out_sec:0,
					
					swf_url: sconfig.swf_url,
					// I would think I would want to reverse polarity on the delta_x, if h_flipped, but this works without it
					delta_x: (sconfig.h_flipped) ? delta_x : delta_x,
					
					delta_y: delta_y,
					h_flipped: sconfig.h_flipped
				};
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
			}
		}
		
		private function tryAndGetSignCoordsFromMC():Array {
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(used_swf_url);
			var sign_pt:MovieClip = swf_data.mc.sign_pt;
			if (!sign_pt) return null;
			return [-(swf_data.mc_w/2)+sign_pt.x, -(swf_data.mc_h)+sign_pt.y];
		}
		
		private function do_TYPE_TOWER_SIGN(sconfig:SpecialConfig, uid:String):void {
			sconfig.is_dirty = false;
			
			var A:Array = tryAndGetSignCoordsFromMC();
			var delta_x:int = (A) ? A[0] : sconfig.delta_x;
			var delta_y:int = (A) ? A[1]-30 : sconfig.delta_y;
			
			if (sconfig.label) {
				var annc:Object;
				
				CONFIG::god {
					log_str+= 'annc:'+uid+' ';
				}
				
				var text_filtersA:Array;
				if (sconfig.h_flipped) {
					text_filtersA = StaticFilters.greyText_DropShadowA.concat(StaticFilters.black7px0Degrees_DropShadowA)
				} else {
					text_filtersA = StaticFilters.copyFilterArrayFromObject({angle:180}, StaticFilters.greyText_DropShadowA).concat(
						StaticFilters.copyFilterArrayFromObject({angle:180}, StaticFilters.black7px0Degrees_DropShadowA)
					)
				}
				
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: true,
					allow_bubble:true,
					uid: uid,
					show_text_shadow:true,
					special_config_displayer: displayer,
					under_itemstack: false,
					center_text:true,
					text_filterA: text_filtersA,
					fade_in_sec:0,
					fade_out_sec:0,
					
					text: ['<span class="tower_sign">'+sconfig.label+'</span>'],
					
					// I would think I would want to reverse polarity on the delta_x, if h_flipped, but this works without it
					delta_x: (sconfig.h_flipped) ? delta_x : delta_x,
					
					delta_y: delta_y,
					width: sconfig.width,
					h_flipped: sconfig.h_flipped
				};
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
			}
		}
		
		private function do_TYPE_FURN_PRICE_TAG(sconfig:SpecialConfig, uid:String):void {
			sconfig.is_dirty = false;
			
			if (sconfig.sale_price) {
				var annc:Object;
				
				CONFIG::god {
					log_str+= 'annc:'+uid+' ';
				}
				
				annc = {
					type: 'itemstack_overlay',
					itemstack_tsid: itemstack.tsid,
					place_at_bottom: true,
					in_itemstack: true,
					allow_bubble:true,
					uid: uid,
					show_text_shadow:false,
					bubble_price_tag:true,
					tf_delta_x: 2,
					under_itemstack: sconfig.under_itemstack,
					text: ['<span class="price_tag">'+StringUtil.formatNumberWithCommas(sconfig.sale_price)+'₡</span>'],
					h_flipped: sconfig.h_flipped
				};
				
				if (!isNaN(sconfig.fade_in_sec)) annc.fade_in_sec = sconfig.fade_in_sec;
				if (!isNaN(sconfig.fade_out_sec)) annc.fade_out_sec = sconfig.fade_out_sec;
				
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(itemstack.swf_url);
				if (swf_data && swf_data.mc) {
					if (swf_data.mc.price_tag_pt) {
						annc.delta_x = Math.round((-swf_data.mc_w/2)+swf_data.mc.price_tag_pt.x);
						annc.delta_y =  Math.round(-swf_data.mc_h+swf_data.mc.price_tag_pt.y);
					} else {
						CONFIG::debugging {
							Console.warn('no swf_data.mc.price_tag_pt in '+itemstack.swf_url);
						}
					}
				} else {
					CONFIG::debugging {
						Console.error('no swf_data or swf_data.mc for '+itemstack.swf_url);
					}
				}
				
				annc.special_config_displayer = displayer;
				
				TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([annc]);
				
			}
		}
		
		
	}
}