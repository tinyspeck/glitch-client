package com.tinyspeck.engine.port {
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	public class JS_interface extends JS_interface_base {
		/* singleton boilerplate */
		public static const instance:JS_interface = new JS_interface();
		
		//TODO remove if we keep SWF_better_focus_handling
		private static var flash_had_focus_before_blur:Boolean = false;
		
		/* list the methods we want to make available to JS */
		private const METHODS_OPEN_TO_JS:Object = {
			'simple_as_log': function(params:Object):void {
				CONFIG::debugging {
					Console.warn('simple_as_log params.txt: '+params.txt)
				}
			},
			
			'key_down': function(params:Object):void {
				KeyBeacon.instance.jsKeyDown(params.keycode);
			},
			
			'key_up': function(params:Object):void {
				KeyBeacon.instance.jsKeyUp(params.keycode);
			},
			
			'window_blur': function(params:Object):void {
				CONFIG::debugging {
					Console.log(99, 'window_blur');
				}
				Benchmark.addCheck('JS.window_blur');
				
				if (TSModelLocator.instance.flashVarModel.better_focus_handling) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.log(99, 'window_blur set flash_has_focus = false');
					}
					// window_blur is not guaranteed to cause Flash to lose
					// focus, as Chrome sends a window_blur event when Flash
					// *receives* focus (presumably because of its plugin
					// isolation system);
					// we will get an Event.DEACTIVATE instead
					// (except in Safari on OS X when you click Safari UI;
					//  it will, however, send it when you change tabs/apps)
					//StageBeacon.flash_has_focus = false;
				} else {
					if (StageBeacon.flash_has_focus) {
						CONFIG::debugging {
							Console.log(99, 'window_blur set flash_has_focus = false');
						}
						flash_had_focus_before_blur = true;
						StageBeacon.flash_has_focus = false;
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.log(99, 'window_blur changes nothing');
						}
					}
				}
			},
			
			'window_focus': function(params:Object):void {
				// I thought this RETURN was needed for Firefox mac, but it was causing trouble, and seems to not be needed by 3.6.3. probably need to check older versions though 
				//if (EnvironmentUtil.is_mac && !EnvironmentUtil.is_safari) return; // probably need to make sure it is Safari 4+ not just safari
				Benchmark.addCheck('JS.window_focus');
				if (TSModelLocator.instance.flashVarModel.better_focus_handling) {
					// window_focus is not guaranteed to return Flash focus,
					// just JavaScript focus; when JS has focus in Chrome on
					// Windows, it revokes focus from Flash;
					// Event.ACTIVATE, KeyboardEvent.KEY_DOWN,
					// or MouseEvent.MOUSE_DOWN will tell us when it is regained
					//StageBeacon.flash_has_focus = true;
				} else {
					if (flash_had_focus_before_blur) {
						CONFIG::debugging {
							Console.log(99, 'window_focus sets flash_has_focus = true');
						}
						StageBeacon.flash_has_focus = true;
					}
				}
			},
			
			'window_close': function(params:Object):void {
				//if (SocketProxy.instance.socket) SocketProxy.instance.socket.logout();
				TSFrontController.instance.sendLogoutAtWindowClose();
			}
		}
		
		/* constructor */
		public function JS_interface() {
			super(METHODS_OPEN_TO_JS);
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		/* public method to kick things off, called from Boot after it is added to stage */
		override public function init():void {
			super.init();
			call_JS({
				meth: 'go'
			})
		}
	}
}
