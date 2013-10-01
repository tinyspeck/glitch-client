package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.AvatarFaceUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.text.TextField;

	public class LoadingLocationPOLView extends TSSpriteWithModel
	{
		private static const EXT_X:uint = 135;
		private static const INT_X:uint = 290;
		private static const LAST_HERE_W:uint = 326;
		private static const LAST_HERE_H:uint = 28;
		private static const GRAD_RADIUS:Number = 200;
		private static const GRAD_COLORS:Array = [0xd5ede1, 0xadccbd];
		private static const GRAD_ALPHAS:Array = [1,1];
		private static const GRAD_SPREAD:Array = [90,255];
		
		private const bg_matrix:Matrix = new Matrix();
		private const faces:Vector.<AvatarFaceUI> = new Vector.<AvatarFaceUI>();
		
		private const interior_holder:Sprite = new Sprite();
		private const exterior_holder:Sprite = new Sprite();
		private const avatar_holder:Sprite = new Sprite();
		private const last_here_holder:Sprite = new Sprite();
		private const neighbor_holder:Sprite = new Sprite();
		private var door:DisplayObject;
		private var tower_door:DisplayObject;
		private var spinner:DisplayObject;
		
		private const entering_tf:TextField = new TextField();
		private const name_tf:TextField = new TextField();
		private const street_tf:TextField = new TextField();
		private const last_here_tf:TextField = new TextField();
		private const features_tf:TextField = new TextField();
		private const neighbor_tf:TextField = new TextField();
		
		private var pc_tsid:String;
		private var pol_type:String;
		
		private var is_built:Boolean;
		private var vag_ok:Boolean;
		
		public function LoadingLocationPOLView(){}
		
		private function buildBase():void {
			//interior
			door = new AssetManager.instance.assets.enter_home_door();
			addChild(interior_holder);
			
			//tower
			tower_door = new AssetManager.instance.assets.enter_tower_door();
			tower_door.x = -105;
			tower_door.y = -10;
			
			//exterior
			addChild(exterior_holder);
			
			//avatar spinner
			spinner = new AssetManager.instance.assets.spinner();
			spinner.x = 80;
			spinner.y = 80;
			
			//last here
			var g:Graphics = last_here_holder.graphics;
			g.beginFill(0x769e8f, .7);
			g.drawRoundRect(0, 0, LAST_HERE_W, LAST_HERE_H, 8);
			last_here_holder.filters = StaticFilters.copyFilterArrayFromObject({}, StaticFilters.white1px90Degrees_DropShadowA).concat(StaticFilters.black3px90DegreesInner_DropShadowA);
			
			TFUtil.prepTF(last_here_tf, false);
			last_here_tf.x = 5;
			last_here_tf.y = 5;
			last_here_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.4}, StaticFilters.black1px90Degrees_DropShadowA);
			last_here_holder.addChild(last_here_tf);
			
			//tfs
			TFUtil.prepTF(entering_tf, false);
			entering_tf.alpha = .8;
			TFUtil.prepTF(name_tf, false);
			TFUtil.prepTF(street_tf, false);
			street_tf.alpha = .8;
			TFUtil.prepTF(features_tf);
			features_tf.width = LAST_HERE_W;
			
			//neighbor stuff
			TFUtil.prepTF(neighbor_tf, false);
			neighbor_tf.y = 8;
			neighbor_tf.htmlText = '<p class="loading_location_pol_neighbors">Neighbors:</p>';
			neighbor_tf.alpha = .7;
			neighbor_holder.addChild(neighbor_tf);
			
			is_built = true;
		}
		
		public function show(pc_tsid:String, pol_type:String):void {
			if(!is_built) buildBase();
			
			this.pc_tsid = pc_tsid;
			this.pol_type = pol_type;
			
			//show what needs to be shown
			interior_holder.visible = pol_type == LoadingInfo.POL_TYPE_INTERIOR || pol_type == LoadingInfo.POL_TYPE_TOWER;
			exterior_holder.visible = pol_type == LoadingInfo.POL_TYPE_EXTERIOR;
			
			//clean this sucker out
			SpriteUtil.clean(interior_holder, false);
			
			setText();
			setAvatar();
			setDetails();
			
			//show the neighbors
			if(neighbor_holder.parent) neighbor_holder.parent.removeChild(neighbor_holder);
			if(exterior_holder.visible){
				setNeighbors();
			}
			
			refresh();
		}
		
		public function hide():void {
			
		}
		
		public function refresh():void {
			var tf_scale:Number;
			var g:Graphics = graphics;
			var features_padd:int;
			var enter_y:int;
			var all_width:int;
			var holder:Sprite;
			
			//set the vars based on what pol type we have
			if(pol_type == LoadingInfo.POL_TYPE_INTERIOR || pol_type == LoadingInfo.POL_TYPE_TOWER){
				enter_y = 50;
				features_padd = 20;
				holder = interior_holder;
				all_width = INT_X + LAST_HERE_W;
			}
			else if(pol_type == LoadingInfo.POL_TYPE_EXTERIOR){								
				enter_y = 0;
				features_padd = 12;
				holder = exterior_holder;
				all_width = EXT_X + LAST_HERE_W;
			}
			else {
				CONFIG::debugging {
					Console.warn('NEW POL TYPE?!', pol_type);
				}
				return;
			}
			
			//position the avatar
			setAvatar();
			
			//scale the name if it's too damn big
			name_tf.scaleX = name_tf.scaleY = 1;
			if(name_tf.width > LAST_HERE_W){
				tf_scale = LAST_HERE_W / name_tf.width;
				name_tf.scaleX = name_tf.scaleY = tf_scale;
			}
			
			entering_tf.y = enter_y;
			name_tf.y = int(entering_tf.y + entering_tf.height - (!vag_ok ? 4 : 8));
			street_tf.y = int(name_tf.y + name_tf.height - (!vag_ok ? 4 : 8));
			
			last_here_holder.y = int(street_tf.y + street_tf.height + 4);
			features_tf.y = int(last_here_holder.y + LAST_HERE_H + features_padd);
			neighbor_holder.y = int(features_tf.y + features_tf.height + 10);
			
			//center it (y needs math so that it doesn't shift while loading - cause flash sucks at masks)
			holder.x = int(model.layoutModel.loc_vp_w/2 - all_width/2);
			holder.y = int(model.layoutModel.loc_vp_h/2 - Math.max(neighbor_holder.y + AvatarFaceUI.RADIUS*2, avatar_holder.y + avatar_holder.height)/2);
			
			//set the matrix
			bg_matrix.createGradientBox(GRAD_RADIUS*2, GRAD_RADIUS*2, Math.PI/2, holder.x - GRAD_RADIUS + 30, model.layoutModel.loc_vp_h/2 - GRAD_RADIUS);
			
			//draw
			g.clear();
			g.beginGradientFill(GradientType.RADIAL, GRAD_COLORS, GRAD_ALPHAS, GRAD_SPREAD, bg_matrix);
			g.drawRect(0, 0, model.layoutModel.loc_vp_w, model.layoutModel.loc_vp_h);
		}
		
		private function setText():void {
			var x_pos:int;
			var holder:Sprite;
			
			if(pol_type == LoadingInfo.POL_TYPE_INTERIOR || pol_type == LoadingInfo.POL_TYPE_TOWER){
				x_pos = INT_X;
				holder = interior_holder;
			}
			else if(pol_type == LoadingInfo.POL_TYPE_EXTERIOR){
				x_pos = EXT_X;
				holder = exterior_holder;
			}
			else {
				//unknown type
				return;
			}
			
			//set the players name
			const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			var enter_txt:String = 'Entering';
			var name_txt:String = (pc != model.worldModel.pc ? StringUtil.nameApostrophe(pc.label) : 'Your');
			var street_txt:String = pol_type == LoadingInfo.POL_TYPE_INTERIOR ? 'House' : 'Home Street';
			var enter_class:String = 'loading_location_pol_ext';
			var name_class:String = 'loading_location_pol_ext_name';
			var street_class:String = 'loading_location_pol_ext_street';
			
			//handle the tower street name
			if(pol_type == LoadingInfo.POL_TYPE_TOWER) street_txt = 'Tower';
			
			//if this has a custom name, let's handle that
			const loading_info:LoadingInfo = model.moveModel.loading_info;
			if(loading_info.custom_name){
				if(pol_type == LoadingInfo.POL_TYPE_TOWER){
					//if this is a tower, let's set the street name to be proper
					street_txt = '('+name_txt+' Tower)';
				}
				name_txt = loading_info.custom_name;
			}
			
			vag_ok = StringUtil.VagCanRender(name_txt);
			entering_tf.embedFonts = vag_ok;
			name_tf.embedFonts = vag_ok;
			street_tf.embedFonts = vag_ok;
			
			//drop them down to arial
			if(!vag_ok){
				name_txt = '<font face="Arial">'+name_txt+'</font>';
				enter_txt = '<font face="Arial">'+enter_txt+'</font>';
				street_txt = '<font face="Arial">'+street_txt+'</font>';
			}
			
			entering_tf.htmlText = '<p class="'+enter_class+'">'+enter_txt+'</p>';
			name_tf.htmlText = '<p class="'+enter_class+'"><span class="'+name_class+'">'+name_txt+'</span></p>';
			street_tf.htmlText = '<p class="'+enter_class+'"><span class="'+street_class+'">'+street_txt+'</span></p>';
			
			entering_tf.x = x_pos;
			name_tf.x = x_pos + 2;
			street_tf.x = x_pos;
			
			//add them to the holder
			holder.addChild(entering_tf);
			holder.addChild(name_tf);
			holder.addChild(street_tf);
		}
		
		private function setDetails():void {
			var x_pos:int;
			var holder:Sprite;
			
			if(pol_type == LoadingInfo.POL_TYPE_INTERIOR || pol_type == LoadingInfo.POL_TYPE_TOWER){
				x_pos = INT_X;
				holder = interior_holder;
			}
			else if(pol_type == LoadingInfo.POL_TYPE_EXTERIOR){
				x_pos = EXT_X;
				holder = exterior_holder;
			}
			else {
				//unknown type
				return;
			}
			
			const loading_info:LoadingInfo = model.moveModel.loading_info;
			
			//last visit
			var last_txt:String = '<p class="loading_location_pol_last_here">';
			if(loading_info.first_visit){
				last_txt += '<b>First time here!</b>';
			}
			else {
				if(loading_info.last_visit_mins && !isNaN(loading_info.last_visit_mins)){
					//if this is more than 10 days old, just show the days, otherwise you get days+hours
					last_txt += 'Last here <b>'+StringUtil.formatTime(loading_info.last_visit_mins*60, true, false, (loading_info.last_visit_mins < (1440*10) ? 2 : 1))+
								' ago</b>';
				}
				else {
					last_txt += 'Last here <b>just moments ago</b>';
				}
				
				//if we have visit counts
				if(loading_info.visit_count && !isNaN(loading_info.visit_count)){
					last_txt += ' &#8212; ';
				}
			}
			
			//show the visit count
			//visit count is 0 based. so first visit = 0, 2nd = 1, etc.
			if(loading_info.visit_count && !isNaN(loading_info.visit_count) && !loading_info.first_visit){
				last_txt += 'this is your '+StringUtil.addSuffix(loading_info.visit_count+1)+' visit';
			}
			
			last_txt += '</p>';
			last_here_tf.htmlText = last_txt;
			
			//features
			var features_txt:String = '<p class="loading_location_pol_features">';
			if(loading_info.street_details && loading_info.street_details.features.length){
				features_txt += 'Features: '+loading_info.street_details.features[0];
			}
			features_txt += '</p>';
			features_tf.htmlText = features_txt;
			
			//place it
			last_here_holder.x = x_pos + 3;
			holder.addChild(last_here_holder);
			features_tf.x = x_pos;
			holder.addChild(features_tf);
		}
		
		private function setAvatar():void {
			const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			if(pc && pc.singles_url && avatar_holder.name != pc.singles_url){
				SpriteUtil.clean(avatar_holder);
				avatar_holder.name = pc.singles_url;
				avatar_holder.addChild(spinner);
				AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_172.png', onAvatarLoad, 'Location loading screen');
			}
			
			//see where the holder needs to go
			if(pol_type == LoadingInfo.POL_TYPE_INTERIOR || pol_type == LoadingInfo.POL_TYPE_TOWER){
				interior_holder.addChildAt(pol_type == LoadingInfo.POL_TYPE_INTERIOR ? door : tower_door, 0);
				interior_holder.addChild(avatar_holder);
				avatar_holder.x = -20;
				avatar_holder.y = 15;
			}
			else if(pol_type == LoadingInfo.POL_TYPE_EXTERIOR){
				exterior_holder.addChild(avatar_holder);
				avatar_holder.x = -40;
				avatar_holder.y = -20;
			}
		}
		
		private function onAvatarLoad(filename:String, bm:Bitmap):void {
			SpriteUtil.clean(avatar_holder);
			if(bm){
				bm.scaleX = -1;
				bm.x = bm.width;
				avatar_holder.addChild(bm);
				
				//just in case, saw it once
				if(spinner && spinner.parent) spinner.parent.removeChild(spinner);
				
				refresh();
			}
			else {
				CONFIG::debugging {
					Console.warn('no bitmap from file? --> bm:'+bm+' filename: '+filename);
				}
			}
		}
		
		private function setNeighbors():void {
			//on the external streets, we show our neighbors
			const loading_info:LoadingInfo = model.moveModel.loading_info;
			
			//reset the pool
			var i:int;
			var total:int = faces.length;
			var avatar_face:AvatarFaceUI;
			
			for(i = 0; i < total; i++){
				avatar_face = faces[int(i)];
				avatar_face.hide();
			}
			
			if(loading_info && loading_info.neighbors && loading_info.neighbors.length){
				const MAX_VIEW:uint = 5;
				const GAP:uint = 11;
				
				var pc:PC;
				var next_x:int = neighbor_tf.width + GAP;
				
				total = loading_info.neighbors.length;
				
				for(i = 0; i < total; i++){
					pc = model.worldModel.getPCByTsid(loading_info.neighbors[int(i)]);
					if(pc && pc.singles_url && i < MAX_VIEW){
						//get one from the pool, or make a new one
						if(i < faces.length){
							avatar_face = faces[int(i)];
						}
						else {
							avatar_face = new AvatarFaceUI(pc.tsid);
							avatar_face.setBackground(0xffffff, .7);
							avatar_face.filters = StaticFilters.copyFilterArrayFromObject({alpha:.2, inner:false}, StaticFilters.black3pxInner_GlowA);
							faces.push(avatar_face);
						}
						
						//show it
						avatar_face.show(pc.tsid, true);
						avatar_face.x = next_x;
						next_x += avatar_face.width + GAP;
						
						neighbor_holder.addChild(avatar_face);
					}
					else if(i >= MAX_VIEW){
						//no more!
						break;
					}
				}
			}
			
			//if we have some results, go ahead and show it!
			if(neighbor_holder.numChildren > 1){
				neighbor_holder.x = EXT_X;
				exterior_holder.addChild(neighbor_holder);
			}
		}
	}
}