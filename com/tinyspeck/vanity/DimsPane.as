package com.tinyspeck.vanity {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSSlider;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	public class DimsPane extends Sprite {
		
		private var eyes_holder:Sprite = new Sprite();
		private var ears_holder:Sprite = new Sprite();
		private var nose_holder:Sprite = new Sprite();
		private var mouth_holder:Sprite = new Sprite();
		
		private var slider_dist:int = 40;
		private var slider_w:int = 12;
		private var slider_h:int = 87;
		private var changeCallBack:Function;
		
		public function DimsPane(changeCallBack:Function) {
			super();
			this.changeCallBack = changeCallBack;
			init();
		}
		
		private var configurableA:Array = [
			{
				name: 'eyes',
				settings: ['eye_scale', 'eye_height', 'eye_dist']
			},
			{
				name: 'nose',
				settings: ['nose_scale', 'nose_height']
			},
			{
				name: 'mouth',
				settings: ['mouth_scale', 'mouth_height']
			},
			{
				name: 'ears',
				settings: ['ears_scale', 'ears_height']
			}
		];
		
		private var slider_map:Object = {}
		
		private function init():void {
			draw();
			
			var name_map:Object = VanityModel.dims_name_map;
			var holder:Sprite;
			var slider:TSSlider;
			var tf:TextField;
			var setting_ob:Object;
			var setting_namesA:Array;
			var setting_name:String;
			var part:String;
			var part_w:int = VanityModel.dimensions_panel_w/configurableA.length;
			for (var i:int;i<configurableA.length;i++) {
				part = configurableA[int(i)].name;
				setting_namesA = configurableA[int(i)].settings;
                switch (part) {
                    case 'eyes':
                        holder = eyes_holder;
                        break;
                    case 'ears':
                        holder = ears_holder;
                        break;
                    case 'nose':
                        holder = nose_holder;
                        break;
                    case 'mouth':
                        holder = mouth_holder;
                        break;
                    default:
                        CONFIG::debugging {
                            throw new Error('missing ' + part + '_holder');
                        }
                }
				holder.x = i*(part_w);
				
				var bm:Bitmap = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_'+part+'_icon.png']);
				if (bm) {
					bm.x = Math.round((part_w-bm.width)/2);
					bm.y = VanityModel.dimensions_panel_h - bm.height - 16;
					holder.addChild(bm);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('wtf no bm');
					}
				}
				
				slider = null;
				for (var m:int=0;m<setting_namesA.length;m++) {
					setting_name = setting_namesA[m]
					setting_ob = VanityModel.ava_settings[setting_name];
					
					var divided_w:Number = part_w/setting_namesA.length;
					slider = new TSSlider(
						TSSlider.VERTICAL,
						holder,
						(slider) ? slider.x+slider_dist : Math.round(((part_w-((setting_namesA.length-1)*slider_dist))/2)-(slider_w/2)),
						0
					);
					slider_map[setting_name] = slider;
					slider.name = setting_name;
					slider.setSize(slider_w, slider_h);
					slider.backClick = true;
					slider.fillLevelAlpha = 0;
					
					if (setting_name.indexOf('height') > -1) {
						slider.setSliderParams(setting_ob.max, setting_ob.min, VanityModel.ava_config[setting_name]);
					} else {
						slider.setSliderParams(setting_ob.min, setting_ob.max, VanityModel.ava_config[setting_name]);
					}
					
					slider.addEventListener(Event.CHANGE, onSliderChange, false, 0, true);
					
					tf = new TextField();
					tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
					TFUtil.prepTF(tf, false);
					tf.embedFonts = false;
					tf.htmlText = '<p class="vanity_dims_labels"><b>'+name_map[setting_name]+'</b></p>';
					tf.border = false;
					
					holder.addChild(tf);
					
					tf.x = Math.round(slider.x+(slider_w/2)-(tf.width/2));
					tf.y = slider.y+slider_h+3;
				}
				
				addChild(holder);
			}
		}
		
		public function updateFromAvaConfig():void {
			var name_map:Object = VanityModel.dims_name_map;
			var slider:TSSlider;
			var setting_name:String;
			for (setting_name in name_map) {
				slider = slider_map[setting_name] as TSSlider;
				slider.value = VanityModel.ava_config[setting_name]
			}
		}
		
		private function onSliderChange(e:Event):void {
			var slider:TSSlider = e.currentTarget as TSSlider;
			var value:Number = slider.value;
			changeCallBack(slider.name, value);
		}
		
		private function draw():void {
			
			var draw_alpha:Number = 0;
			var g:Graphics = this.graphics;
			g.clear();
			g.lineStyle(0, VanityModel.panel_line_c, draw_alpha, true);
			g.beginFill(VanityModel.panel_bg_c, draw_alpha);
			g.drawRoundRect(0, 0, VanityModel.dimensions_panel_w, VanityModel.dimensions_panel_h, VanityModel.panel_corner_radius);
		}
	}
}
