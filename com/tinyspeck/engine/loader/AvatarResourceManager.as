package com.tinyspeck.engine.loader {
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.data.pc.AvatarConfigArticle;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	public class AvatarResourceManager {
		
		/* singleton boilerplate */
		public static const instance:AvatarResourceManager = new AvatarResourceManager();
		
		public static var avatar_url:String;
		
		private var swf_url_map:Dictionary = new Dictionary();
		private var aap_map:Dictionary = new Dictionary();
		private var acr_map:Dictionary = new Dictionary();
		private var thread_loader:ThreadLoader;
		private var loading_listeners:Array = [];
		
		public function AvatarResourceManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			CONFIG::debugging {
				Console.priwarn(89, 'making AvatarResourceManager.instance');
			}
			
			thread_loader = new ThreadLoader('arm', 1, false);
			Benchmark.addCheck('AvatarResourceManager thread_loader threads:'+thread_loader.threads);
		}
		
		// START HACKED UP
		// these are kind of hacked up to provide some loading progress data for intitial game load
		// but really you shoudl be able to subscribe for loading progress for a particular ACR, not
		// all loading, as it is now.
		
		public function addLoadingListener(func:Function):void {
			if (func == null) return;
			if (loading_listeners.indexOf(func) > -1) return;
			loading_listeners.push(func);
		}
		
		public function removeLoadingListener(func:Function):void {
			if (func == null) return;
			if (loading_listeners.indexOf(func) == -1) return;
			loading_listeners.splice(loading_listeners.indexOf(func), 1);
		}
		
		private function anncLoadingProgress(perc:Number):void {
			for (var i:int=0;i<loading_listeners.length;i++) {
				loading_listeners[int(i)](perc);
			}
		}
		
		// END HACKED UP
		
		public function articlePartExists(aca:AvatarConfigArticle, class_name:String):Boolean {
			if (!aca) return false;
			var aap:AvatarAssetPackage = aap_map[aca.package_swf_url];
			if (!aap) return false;
			return aap.articlePartExists(aca.article_class_name, class_name);
			return aap.articlePartExists(aca.type+'_'+aca.article_class_name, class_name);
		}
		
		public function getArticlePartMC(aca:AvatarConfigArticle, class_name:String):MovieClip {
			if (!aca) return null;
			var aap:AvatarAssetPackage = aap_map[aca.package_swf_url];
			if (!aap) return null;
			return aap.getArticlePartMC(aca.article_class_name, class_name);
			return aap.getArticlePartMC(aca.type+'_'+aca.article_class_name, class_name);
		}
		
		private function onPackageSWFLoadProgress(loader_item:LoaderItem):void {
			//var aap:AvatarAssetPackage = aap_map[loader_item.urlRequest.url];
			anncLoadingProgress(loader_item.bytesLoaded/loader_item.bytesTotal);
			//Console.info(loader_item.urlRequest.url+' '+(loader_item.bytesLoaded/loader_item.bytesTotal));
		}
		
		private function onPackageSWFLoadFail(loader_item:LoaderItem):void {
			CONFIG::debugging {
				Console.log(89, 'LOAD FAILED, USING FAKE MC '+loader_item.urlRequest.url);
			}
			
			var aap:AvatarAssetPackage = aap_map[loader_item.urlRequest.url];
			if (!aap) {
				CONFIG::debugging {
					Console.error('WWWTTTFFF no aap?');
				}
				return;
			}
			
			if (aap.swf) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('WTF '+loader_item.urlRequest.url+' already has a swf!!!!');
				}
			} else {
				var mc:MovieClip = new MovieClip();
				swf_url_map[mc] = loader_item.urlRequest.url;
				CONFIG::debugging {
					Console.log(88, (loader_item.load_end_ms-loader_item.load_start_ms)+'ms ('+(loader_item.load_end_ms-loader_item.in_q)+'ms after qd) to load '+loader_item.urlRequest.url);
				}
				aap.setSwf(mc, onPackageSWFEmbedsLoad);
			}
		}
		
		private function onAvaSWFLoad(loader_item:LoaderItem):void {
			var mc:MovieClip = loader_item.content;
			for (var k:String in acr_map) {
				if (!acr_map[k].ava_swf) {
					acr_map[k].ava_swf = new AvatarSwf(mc, false);
					checkForReadyACRs();
					return;
				}
			}
		}
		
		private function onAvaSWFLoadFail(loader_item:LoaderItem):void {
		}
		
		private function onAvaSWFLoadProgress(loader_item:LoaderItem):void {
			anncLoadingProgress(loader_item.bytesLoaded/loader_item.bytesTotal);
			//Console.info(loader_item.urlRequest.url+' '+(loader_item.bytesLoaded/loader_item.bytesTotal));
		}
		
		private function onPackageSWFLoad(loader_item:LoaderItem):void {
			CONFIG::debugging {
				Console.log(89, 'LOADED '+loader_item.urlRequest.url);
			}
			
			var aap:AvatarAssetPackage = aap_map[loader_item.urlRequest.url];
			if (!aap) {
				CONFIG::debugging {
					Console.error('WWWTTTFFF no aap?');
				}
				return;
			}
			
			if (aap.swf) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('WTF '+loader_item.urlRequest.url+' already has a swf!!!!');
				}
			} else {
				var mc:MovieClip = loader_item.content;
				swf_url_map[mc] = loader_item.urlRequest.url;
				CONFIG::debugging {
					Console.log(88, (loader_item.load_end_ms-loader_item.load_start_ms)+'ms ('+(loader_item.load_end_ms-loader_item.in_q)+'ms after qd) to load '+loader_item.urlRequest.url);
				}
				aap.setSwf(mc, onPackageSWFEmbedsLoad);
			}
		}
		
		private function onPackageSWFEmbedsLoad(loaded_aap:AvatarAssetPackage):void {
			CONFIG::debugging {
				Console.log(89, 'URL:'+swf_url_map[loaded_aap.swf]);
			}
			checkForReadyACRs();
		}
		
		private function checkForReadyACRs():void {
			var acr:AvatarConfigRecord;
			var aap:AvatarAssetPackage;
			var package_url:String;
			
			// loop over all acrs and do callbacks if needed
			acr_loop: for (var k:String in acr_map) {
				acr = acr_map[k] as AvatarConfigRecord;
				CONFIG::debugging {
					Console.priwarn(89, acr.ac.pc_tsid+' acr check');
				}
				if (acr.ready) {
					CONFIG::debugging {
						Console.priwarn(89, acr.ac.pc_tsid+' acr is rdy already');
					}
					continue acr_loop;
				}
				
				if (!acr.swf_urlsA.length) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.priinfo(89, 'whoa acr.swf_urlsA.length:'+acr.swf_urlsA.length);
						if (acr.ac.pc_tsid=='P001') {
							Console.dir(acr.ac.AMF());
						}
					}
				} else {
					// check if all the packages for this acr have loaded; if not, continue, else mark it as ready and doCallbacks()
					aap_loop: for (var i:int=0;i<acr.swf_urlsA.length;i++) {
						package_url = acr.swf_urlsA[int(i)];
						aap = aap_map[package_url];
						CONFIG::debugging {
							Console.priinfo(89, 'checking '+package_url+' for '+acr.article_classes_per_swf[package_url]);
						}
						if (!aap.hasLoaded(acr.article_classes_per_swf[package_url])) {
							CONFIG::debugging {
								Console.priwarn(89, acr.ac.pc_tsid+' acr aap:'+package_url+' has not loaded all');
							}
							continue acr_loop;
						}
					}
				}
				
				if (!acr.ava_swf) {
					continue;
				}
				
				CONFIG::debugging {
					Console.priwarn(89, acr.ac.pc_tsid+' acr is NOW RDY!!!!!!');
				}
				
				acr.ready = true;
				acr.doCallbacks();
			}
		}
		
		private function getAvatarConfigRecordOrMake(ac:AvatarConfig):AvatarConfigRecord {
			var acr:AvatarConfigRecord = acr_map[ac.sig] as AvatarConfigRecord;
			if (!acr) acr = acr_map[ac.sig] = new AvatarConfigRecord(ac);
			
			return acr;
		}
		
		public function getAvatarConfigRecord(ac:AvatarConfig, ava_swf:AvatarSwf):AvatarConfigRecord {
			
			var acr:AvatarConfigRecord = getAvatarConfigRecordOrMake(ac);
			if (ava_swf) acr.ava_swf = ava_swf;
			ac.acr = acr;
			
			if (acr.ready) return acr;
			
			var to_load_swf_urlsA:Array;
			var ready_package_cnt:int;
			var loader_item:LoaderItem;
			var aca:AvatarConfigArticle;
			var i:int;
			var aap:AvatarAssetPackage;
			var package_url:String;
			
			// we do not know if this is ready to display yet
			to_load_swf_urlsA = [];
			
			// compile array of unique swfs (urls) that need to be available to display this ac
			for (i=0;i<ac.article_typesA.length;i++) {
				aca = ac.getArticleByType(ac.article_typesA[int(i)]);
				package_url = aca.package_swf_url;
				if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_package_url') == '1') package_url+= 'SWF_fake_bad_package_url';
				if (package_url) {
					// add the package url if it does not exist already
					if (acr.swf_urlsA.indexOf(package_url) == -1) {
						//Console.warn(aca.article_class_name+' needs '+package_url)
						acr.swf_urlsA.push(package_url);
					}
					
					// keep track of which articel_class_names are needed from which which package
					if (!acr.article_classes_per_swf[package_url]) acr.article_classes_per_swf[package_url] = [];
					if (aca.article_class_name != 'none' && acr.article_classes_per_swf[package_url].indexOf(aca.article_class_name) == -1) {
						acr.article_classes_per_swf[package_url].push(aca.article_class_name);
					}
				}
			}
			
			// check and see which swf urls (if any) need loading
			for (i=0;i<acr.swf_urlsA.length;i++) {
				package_url = acr.swf_urlsA[int(i)];
				aap = aap_map[package_url] as AvatarAssetPackage;
				if (aap) {
					//Console.warn('aap.loaded_all '+aap.loaded_all)
					if (aap.hasLoaded(acr.article_classes_per_swf[package_url])) {
						// this one is good to go!
						ready_package_cnt++;
					} else {
						// is loading, make sure it knows about these articles it needs to load
						aap.addSomeArticlesToLoad(acr.article_classes_per_swf[package_url]);
					}
				} else {
					// need to load
					to_load_swf_urlsA.push(package_url);
				}
			}
			
			// load any package swfs that need it
			for (i=0;i<to_load_swf_urlsA.length;i++) {
				package_url = to_load_swf_urlsA[int(i)];
				aap = aap_map[package_url] = new AvatarAssetPackage(thread_loader);
				aap.addSomeArticlesToLoad(acr.article_classes_per_swf[package_url]);
				loader_item = new LoaderItem(package_url, package_url, null, onPackageSWFLoad, onPackageSWFLoadFail, onPackageSWFLoadProgress);
				thread_loader.addLoaderItem(loader_item);
				//Console.info(ac.pc_tsid+' ARM needs to load '+package_url)
			}
			
			// if they're all loaded, mark the acr as ready
			if (ready_package_cnt == acr.swf_urlsA.length) {
				acr.ready = true;
			}
			
			if (!acr.ava_swf) {
				if (!avatar_url) {
					CONFIG::debugging {
						Console.error('WTF NO avatar_url');
					}
					return null;
				}
				loader_item = new LoaderItem('avatr', avatar_url, null, onAvaSWFLoad, onAvaSWFLoadFail, onAvaSWFLoadProgress);
				thread_loader.addLoaderItem(loader_item);
				//Console.info(ac.pc_tsid+' ARM needs to load '+avatar_url)
				acr.ready = false;
			}
			
			return acr;
		}
	}
}