package com.tinyspeck.vanity {
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	
	public class VanityModel {
		
		public function VanityModel() {
			
		}
		
		public static function updateFromCSS():void {
			var cssm:CSSManager = CSSManager.instance;
			var style_name:String = 'vanity_layout';
			var style:Object = cssm.getStyle(style_name);
			for (var k:String in style) {
				if (k in VanityModel) {
					//Console.warn(k+' '+style[k])
					if (String(style[k]).indexOf(',') > -1) {
						VanityModel[k] = cssm.getArrayValueFromStyle(style_name, k, VanityModel[k]);
					} else if (String(style[k]).indexOf('#') == 0) {
						VanityModel[k] = cssm.getUintColorValueFromStyle(style_name, k, VanityModel[k]);
					} else {
						VanityModel[k] = cssm.getNumberValueFromStyle(style_name, k, VanityModel[k]);
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn(k+' from '+style_name+' has no analog on VanityModel');
					}
				}
			}
			for (var i:int;i<loading_colors.length;i++) {
				loading_colors[int(i)] = ColorUtil.colorStrToNum(loading_colors[int(i)]);
			}
		}
		
		public static var fvm:FlashVarModel;
		
		public static var logo_y:int;
		public static var sub_url:String = '/subscribe/?src=v2';
		public static var features_bt_border_hi_c:uint;
		public static var features_bt_border_c:uint;
		public static var features_bt_wh:int;
		public static var features_bt_mg:int;
		public static var features_bt_corner_radius:int;
		public static var features_bt_c:uint;
		public static var features_bt_border_w:uint;
		public static var features_bt_border_hi_w:uint;
		public static var features_bt_border_sel_c:uint;
		public static var features_bt_border_sel_w:uint;
		public static var features_bt_border_sel_outer_c:uint;
		public static var features_bt_border_sel_outer_w:uint;
		
		public static var colors_bt_border_hi_c:uint;
		public static var colors_bt_border_c:uint;
		public static var colors_bt_wh:int;
		public static var colors_bt_mg:int;
		public static var colors_bt_corner_radius:int;
		public static var colors_bt_c:uint;
		public static var colors_bt_border_w:uint;
		public static var colors_bt_border_hi_w:uint;
		public static var colors_bt_border_sel_c:uint;
		public static var colors_bt_border_sel_w:uint;
		public static var colors_bt_border_sel_outer_c:uint;
		public static var colors_bt_border_sel_outer_w:uint;
		
		public static var ui_w:int;
		public static var tab_panel_h:int = 320;
		public static var tab_h:int = 32;
		public static var features_tab_panel_w:int = 347;
		public static var colors_tab_panel_w:int = 187;
		public static var dimensions_panel_w:int = 546;
		public static var dimensions_panel_h:int = 178;
		public static var tab_panel_y:int = 67;
		public static var mirror_column_w:int = 195;
		public static var panel_margin:int;
		public static var panel_line_c:uint;
		public static var panel_bg_c:uint;
		public static var panel_corner_radius:int;
		public static var base_hash:Object;
		public static var base_hash_saved:Object;
		public static var features_pane_padd:int;
		public static var features_paging_sp_height:int;
		public static var colors_pane_padd:int;
		public static var colors_paging_sp_height:int;
		public static var fade_secs:Number;
		public static var ava_frame:int = 14;
		
		public static var dialog_title_bottom_margin:int;
		public static var dialog_body_bottom_margin:int;
		public static var dialog_w:int;
		public static var dialog_padd:int;
		
		public static var button_font_size:int;
		
		
		public static var features_pane_per_page:int;
		public static var features_pane_rows:int;
		public static var features_pane_cols:int;
		public static var colors_pane_per_page:int;
		public static var colors_pane_rows:int;
		public static var colors_pane_cols:int;
		public static var sample_hair_c:uint;
		
		public static var mirror_y:int;
		public static var mirror_frame_y:int = 114;
		public static var mirror_emo_button_y:int = 66;
		public static var mirror_emo_button_y_padd:int = 8;
		public static var mirror_test_x:int;
		public static var mirror_test_y:int;
		public static var mirror_ava_scale:Number;
		public static var mirror_ava_x:int;
		public static var mirror_ava_y:int;
		public static var mirror_bg_x:int;
		public static var mirror_bg_y:int;
		public static var feature_options:Object;
		public static var color_options:Object;
		public static var ava_settings:Object;
		public static var ava_config:Object;
		public static var ava_config_saved:Object;
		public static var loading_colors:Array = [];
		public static var options_ava_config:Object = {
			articles: {}
		};
		
		public static var color_tabs_sortA:Array = [
			'skin', 'hair'
		];
		
		
		public static var feature_tabs_sortA:Array = [
			'eyes', 'nose', 'mouth', 'ears', 'hair'
		];
		
		public static var dims_name_map:Object = {
			'eye_scale': 'Size',
			'eye_height': 'Height',
			'eye_dist': 'Width',
			'ears_scale': 'Size',
			'ears_height': 'Height',
			'nose_scale': 'Size',
			'nose_height': 'Height',
			'mouth_scale': 'Size',
			'mouth_height': 'Height'
		}
		
		public static var features_name_map:Object = {
			'eyes': 'Eyes',
			'nose': 'Nose',
			'ears': 'Ears',
			'mouth': 'Mouth',
			'hair': 'Hair'
		}
		
		public static var colors_name_map:Object = {
			'skin': 'Skin Color',
			'hair': 'Hair Color'
		}
		
		public static var features_required_map:Object = {
			'eyes': true,
			'nose': false,
			'ears': false,
			'mouth': true,
			'hair': false
		}
		
		public static var features_class_map:Object = {
			'eyes': AvatarSwf.SIDEEYECLOSE,
			'nose': AvatarSwf.SIDENOSE,
			'ears': AvatarSwf.SIDEEARCLOSE,
			'mouth': AvatarSwf.SIDEMOUTH,
			'hair': AvatarSwf.SIDEHAIR
		}
		
		public static var imgs_to_loadH:Object = {}
		
		public static var base64_bitmaps_to_load_for_preloaderA:Array = [
			{
				key:'vanity_logo_str',
				str:
				'iVBORw0KGgoAAAANSUhEUgAAAEAAAAAcCAYAAADRJblSAAAGB0lEQVRYw9VZbUxbVRju' +
				'H2P8zDVqoonOGjXGxB9NNH7EqNXoD81Mqv6QxA/uHOIEP6pDGDDw0sHGRqBsQyYi1BG2' +
				'MWGBbUzA6IpgrHNgFd26rGRlY8gcYwW3Dt1+XM/bnEPevj23vcWauZu8ofeee+45z/N+' +
				'Hyy6rlvMSqrXZa8st4JY/ieXFNN/RQADrjLRudgvaQIAABMHE42JMxkgNm5D4PVF75QN' +
				'XnIEcPP1MAljMEj8TBTZQjdkF++n719M4ByL3TQBXNN6MmFAKw0Wk71vM7lZQbg7TeDd' +
				'VGmGBMAgE68Z8CAFW3d30QWt77pqxfj9xdXz72Zu2pplYrN28f61r6/4Kw3gNZnSDAm4' +
				'IvPDERnQ5a1d+s9jE7q44De/V+mi9+StCcGcG7NX6uWdXx0X33C2dDqTbRjeSZfbgDKv' +
				'WVIwR7HA/qQEEFOZ1yAH6mZiQ8HEhu/JwtG5T6yqu/B8TXNvKgQ8Wf5xXboIuDVXyxHf' +
				'ce3o0+90VkR/P1jiDscRgE0Pgz91JjLCwZpKg9j/l3yybfxx10a/uG/9bihDaIavF5dJ' +
				'MGH/lgCm6WHxnWOnwpWPlW2cMyTg5rdK/XhhMN/DkycPsDEllTrg2bUNGeIbr9Vv8THW' +
				'p8U9u4AchbiZG5HnEO6TjvpBWVp4XigScFyXVXQB7p9evWkqBpNM+9V7vOdgw6kWQtiH' +
				'F69r9InfT1XURyffm792sSw9sr+dSQKuO1X/F3OfqWyYwXVJUVv3SAymu96v6MGLga+w' +
				'y7mQShAT8FBJ7Sh2Bxhfs/PrLLoWPGdamkpEACNuPBUCMNE5zR0BhrFV3G/3+atiMGEz' +
				'Bclt7phdaCmMCbglV4uI33v8B1tF8ISABBaxtKFNHz0xFQXm/rI/AM/A9fBe4BkIjKdC' +
				'AN5HxoaW/puWlcwid7BRF4hZtGVgf3s6CCAWhTOIxsTLxANuxp+p8AwyBw7C/D0vTbe8' +
				'z+jkNYuX/1Zl2QQH4rq+waNxmOiG2WVfKAEwl36vcFt32MA/w7RThAgt5j3y0fozBj2G' +
				'P1msoNkEEaqaIWDB3SCAo2YMKcjIP20rqvKMCIDf9Nsssh+i2QrfQ9yBd8HsKS7mhkEp' +
				'JrMEoPytcZMLIU1GzU9WSZa299xmVOywtNlllgDmx4UYeP/BUdhreGxqWl/fMxAtdtiz' +
				'vfDum5990UsrWSPLtkjMyCoB704Upa9S8yM49WC5w1n+slGxc19RdcAsASySB8VYk/eH' +
				'CADibmflWUsTsebh0tp92PQnTs/Uo9ihYYwWiLJ4w2CWEgKSNkZQbADT1CwfWFmzCwPB' +
				'5gnpLwUXwEFVTeCGHrz+Sxs2T4MV4iaPWer4PAFaR28QT2DdXCAZAbAJAEsLGt4zhDGp' +
				't7+36qSsWZKBNEMAlLRmCiCk0MkrM/MHJUqLuoTl28Coy2hQyM6hX6P5GHWFIUiX2Mzw' +
				'RiBvU7eSgYTyNFUCFr1dNpcgCynUoo2Eff9z0QtYoSjBg9e/URwkBwcOno/nu0JcQWY3' +
				'bo/RMusjcvD37v5gtUuMvVDTPGnU8CQigLiWMwEJXlCSDPSLbk9cWxwFyCa0U9+9Wi3o' +
				'jjs9kR946kNHjjVRTWBSWVV4XIxlfdrmNyIASmay6Xmg7EDlbzKmia6SixW366L9xS3x' +
				'jn2/UFdQBDgrRFbK2OWv5h3lYBUeCxy0ceEpJu7ou+37n3pkbgCnSEYEsGDVJ9GcB8Zk' +
				'Skp07PZcVWMExyyoRyBz4G9EMxTSsLp54Efd7HEYTTGyqhD7I7TKwj3EJmjsgD1QzbF5' +
				'QZHuho+M/0nHMchvfjv8qPjWut17h1ED9Ido7R3VTedjMhSJ+CoUGEaL0EaFH5goRv4Y' +
				'mDjhE2DFiRC8z0zxLJikLzh2iM6BBgncRzRMv4dnt5CTqBD4OCgLvgFFEC+KQngvgAXG' +
				'IIBDDBPH4pgYdjZwQFb1QQYIwQKyiApagzEeFJUkvYH19NlzM3yDdvTcgQsXOoc3SqJh' +
				'UiTv2Hhdr/EiyG6wvlOAR/8XUAEDKAbcNNE/RFS+CXr5ZU1FAlESNVgXSQADHI3Z/wGJ' +
				'Ho1UKwlwVAAAAABJRU5ErkJggg=='
			},
			{
				key:'eye_icon_str',
				str:
				'iVBORw0KGgoAAAANSUhEUgAAAB4AAAARCAYAAADKZhx3AAACXklEQVRIx2NgIAMoyyvw' +
				'ArEUFLP9//+fgVRMrEUgCyyBOBiI07DgBCB2A2I1Yh1CyEKQQZE4LMOK1ZSUE6GOZCPZ' +
				'YqgPUSy0trDI6Wxvb0pNTi4P8vMvBImBaJDY9GnTOmBiaA7QJcpikCuhroUbADLw1MmT' +
				'c+/cvr3A1dEpE5sv66prcr9//7747t27KyvKymvQ5N2w+R7FUg0V1VBkH+7bu3cGUNHy' +
				'mzdu+mipqSejWwhy1PNnz9cB1ZQDMQ8QGwBxP8gByCEANZcNw2KgoDA0aMAKQa5+9/bd' +
				'KqCCEJC8nZW1JzafHjl8pA+oRgVLUBqAQgAUDbgsB1uqrqySBFMAii+Qq4FYAik0sCak' +
				'7du2BaBbimQ4KASaQeZhs5xBX1snDiYBiktQsGFJaFgt9nJ3D0WzVDcmMkoZzTHl6JbD' +
				'fAwWgManB3oK3751mxWBLOQDxMZA7ADiL1640A5L0JejpXpdBlBCuHL58uLJEyfFQFMg' +
				'L7LFoDgkJR+fPnXaHD3ooeaC5UHZ8f3796EM0JRoA5OAxrcasuXIQYUPgxIlKG0gWSqM' +
				'nFNAln779m06KP7hhoOCGksQgn3/5cuXMlD2wmcpSP7B/QftSL40RpYHpXCYpSj5GJR1' +
				'0PMfFDuAEszTp0+XgFyMzVKQHpA80PE6IAuRsyYIb9q4cRIohcMsxSi5YPkPpBDdcFAU' +
				'dHd2VYEshzkARIOCd97cuU0mhoZR2IIeGJ9bgOYmECyroa5KAGkAxS2hIMYV16DQg5UH' +
				'JNVOUA2gonAzKNWDHIErqGEVCCidQH3YD020OGsnAGJ37loO4bzSAAAAAElFTkSuQmCC'
			},
			{
				key:'ear_icon_str',
				str:
				'iVBORw0KGgoAAAANSUhEUgAAABIAAAAaCAYAAAC6nQw6AAAC4ElEQVQ4y42VX0xScRTHeerJnnxxveSCrFUaaOWfrPWisbTaNFYiqYAoSX8EDKyVtVpRyyhsgq21RWZttFBrs4VptpzNXu0hH6WRT8kLA97ofNn90fXyu6u7nd17z+/cz+/8+52rUHAu5ebiQpIKknqSRpFAVyi2zWQyWZECNgofdP1DWkg2cUHYaZtSZWLG+6uqzt71eG68nZwcguC56dhxuwRYsg4ETxgEgNmZmZFUKhV+HQq5HL29nad0us4+h+PC+6mpe4DCRgQrzoEq1JomBonFYi+ePwvqS7Yojbyw1LtKu6YjER/zbq+m3JgFCYnNGsHAabfXsncYw4Nvi4tP4aXFbHZDX7Zjp2X+y7xXHKLitL61jnkTj8d1MMJ7wO+/Qzu9Iukg0ZKcIHnS73JfwbrFZGplz0ePNLQpED9eHvmGbtZUVlVnjWhn+sjNa43vS0u3YFNetrt7Ijx+lXml0NbV2/DwODBy/kB1TdabczabU+iZEimINlDD++p9lbZPs7MtOdBDr/caFqgiJpmeOSSFrf1eC0FGg8GDORBCIHk3/iZ8mCkR2suxsfviEku8KoKsA7Grp9vawCqVTCYDZGhjMCrISV6+uCDv4KAZCmrC2wQpgO5jZPoMdMa29h4eyOXs07KK54FwZzqrpas52wrDw/08ULvB0IH1iw7nJVkQGhUlhg6e8UB7NBor1inEy1wQyi5OPIVayxk1ORvqLWNuIbqyYkQ3Xx8YMDMDdC4Sz/MG3SzaSLWupIlEwsXCEY7IA5Z4iTelbLPPc3OevMH2P0cEuWPnUbDT5oHYucMuMpANlGA9K/nPaNTHHbXIPhpy+cdyI8+T7aqtrSykrwsLfuSGCxJGBkZHkdgL4QDnzh/mE0KSHf6cH0GFeFIiHCr1KIPIDn8cThIkvFk6BVBFzHFpT0mHf6ncrweA1V+rYWFKFHDm018QTUeDuJPxMfKQTqc/CACVXAoY6A+z7x5M5j3sNwAAAABJRU5ErkJggg=='
			},
			{
				key:'mouth_icon_str',
				str:
				'iVBORw0KGgoAAAANSUhEUgAAACUAAAAQCAYAAACRKbYdAAACNUlEQVRIx61WO0gDQRC96qpY2QQbxcRoEwik8QdaifgFY1C7xKhNbGw8ET+ghVqIYKGCRAjxgxaCfwSjtbbaplCIVpoy6eI8mJO99e6SGA8eObK7M29n3sycopTwuKprKglegl+Ah6AK634JVXY28/n8LxRDRGXjI4QJM3hqXWH6DVitE0KEdkJF2aRAhh0anLQ0Nk7OTGtzViTGIxFtoK9/ymLdQK5oUpwGw83h5D6Z3MlkMpd08IKwQXh4enyMgST2bG9treZyuVv6f5dwhPeX5+fE2srKkmir3uUeRdqLJgUN8KEfMnAMJ4RBglMKf2c6nd4/PDhYp3eN4BDWHIRWwjIuYxLddlNStNBE6AAZFrEhTXux2NLC3PyQiYC9fEYlQ25CVL8Ui9+wv7eruy0Rj88itRIx3bef3ysUG3GWggBrpWxbIK8g7P9ErGxAKm+vr2HkMArBplKpYx3nZ2ebyD9EijUzQMTYi0uJQscZLgbLcxA+9oo+P94/Tlm3TlGwPh3DweCYcAOvRdNz8P7o1+fXCRvVWNhOq57X4K4L6rZvrq6bBb9u25aQvEsumohRtenKThgtNA3EnodIiUQK9imUOUKqp0Xo2h7lD49c1UxIK7mjI6RIi0lvGWEnahFkPPJ4gl51Qn8aM5yWDbFrS+iRelaN0G9CcmUh+mQvVPZA1tOZzWZPMWZsZpopcBlEh86jkn3/8pUgVRvGzBEqDa3AaiiDOHTD4wlzMiSOn0KkvgHOgeZ/JtHb7wAAAABJRU5ErkJggg=='
			},
			{
				key:'nose_icon_str',
				str:
				'iVBORw0KGgoAAAANSUhEUgAAABIAAAAZCAYAAAA8CX6UAAAB8ElEQVQ4y2NgwAOU5RXUgDgNiBVwqfn//z8Y4wXmxiZJIINKiooCyTYIyTVpjx4+TCTbIJhrpk+b1gFUKEGWQUADpGCuOXvmTDE+7+M1yNHOPgJkSEVZeQ1QkQFZBgENEIa55uSJE00MBABOg7zdPfxAhgT5+RcCFdiQZRDQAF6Ya44cPtLHQATAapCbs4sLyBBrC4scoKQHWQYBDWAz0tNPBxm0fu26HgYiAYZBVuYWljDXfPz4MYFsg2wtrVJBBk2eOKkZKMFDlkHI2eH5s+elDCQAFINg2aGzvb0JX3bAaxBydrh44WINMZqBaoOBOBKIjeEGkZIdYMDCxDQLZjkQ+8BcBBbYu2dvPbHeeff23SpQqYBkmBrcIGITIDRcJIC4HBSmIL2RYeGxDEimSuEJEzZoWAoji+/csaMCpDc1OTmXAZQ5QZzggMAgHIa4IVkGwgmwMry7ozMUJJaVnlHAsHrVqjYkRZZQm9lgBrk6OmWiGQTDxnpa2uBEXFleXgzybwLQaeVYFIKi12He3LlN+/bunQFUt//9+/dbYD6AYVCWunv3bi3Y1m/fvk3ftHHjJFASwGE7CAuDAhlUvIDUgTAo5kAxCBRXgcUCD8hlQNwPshlow0qQK0CxAnIByFYgXweq1gOqDoTLoTHIAABienDHV+sSXgAAAABJRU5ErkJggg=='
			}
		];
			
		
	}
}