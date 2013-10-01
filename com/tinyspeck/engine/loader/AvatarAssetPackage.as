package com.tinyspeck.engine.loader {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	
	import flash.display.MovieClip;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	public class AvatarAssetPackage {
		private var _swf:MovieClip;
		public function get swf():MovieClip {
			return _swf;
		}
		
		private var article_bytes:Dictionary = new Dictionary();
		private var article_swfs:Dictionary = new Dictionary();
		private var article_app_domains:Dictionary = new Dictionary();
		private var article_names_to_loadA:Array = [];
		private var article_names_being_loadedA:Array = [];
		private var article_namesA:Array = [];
		
		private var embedsLoadedCallback:Function;
		private var thread_loader:ThreadLoader;
		private var no_classes:Boolean;
		
		public function AvatarAssetPackage(thread_loader:ThreadLoader) {
			this.thread_loader = thread_loader;
			//
		}
		
		internal function setSwf(swf:MovieClip, embedsLoadedCallback:Function = null):void {
			this._swf = swf;
			this.embedsLoadedCallback = embedsLoadedCallback;
			
			// extract embedded swfs as ByteArrays
			var typeDesc:XML = describeType(swf);
			var packageName:String = typeDesc.@name;
			var classes:XMLList = typeDesc..variable.(@type=="Class");
			
			if (!classes.length()) {
				CONFIG::debugging {
					Console.error('Well this is odd! The package swf has no classes!');
				}
				no_classes = true;
				checkIfDone();
				return;
			}
			
			//extract the bytes from the loaded package
			for each(var xml:XML in classes){
				var article_name:String = xml.@name;
				var fullDefinitionName:String = packageName+"_"+article_name+"_dataClass";
				var byteClass:Class = swf.loaderInfo.applicationDomain.getDefinition(fullDefinitionName) as Class;

				// add to the proper arrays and dics
				article_namesA.push(article_name);
				article_bytes[article_name] = new byteClass() as ByteArray;
				article_app_domains[article_name] = new ApplicationDomain();
			}
			
			loadSomeArticles();
		}
		
		internal function addSomeArticlesToLoad(A:Array):void {
			// let's make sure we only load ones we have not already started or finished loading
			var article_name:String
			for (var i:int;i<A.length;i++) {
				article_name = A[int(i)];
				
				// have we already loaded it?
				if (article_swfs[article_name]) continue;
				
				// are we already loading it?
				if (article_names_being_loadedA.indexOf(article_name) > -1) continue;
				
				// is it scheduled for load
				if (article_names_to_loadA.indexOf(article_name) > -1) continue;
				
				// we have not loaded it and are not loading it, so go!
				article_names_to_loadA.push(article_name);
			}
			
			// if we aleady have the package swf, start loading out the classes
			if (_swf) loadSomeArticles();
		}
		
		internal function hasLoaded(A:Array):Boolean {
			// return true if we have loaded them all
			var article_name:String
			for (var i:int;i<A.length;i++) {
				article_name = A[int(i)];
				if (!article_swfs[article_name]) return false;
			}
			
			return true;
		}
		
		private function loadSomeArticles():void {
			if (!article_names_to_loadA.length) return;
			
			CONFIG::debugging {
				Console.log(89, 'load only: '+article_names_to_loadA);
			}
			
			var loader_item:LoaderItem;
			var article_name:String
			while (article_names_to_loadA.length) {
				article_name = article_names_to_loadA.shift();
				
				// we surely need to do more than this
				if (!article_bytes[article_name]) continue;
				
				article_names_being_loadedA.push(article_name);

				CONFIG::debugging {
					Console.log(89, 'loading '+article_name);
				}
				
				// make the loader item
				loader_item = new LoaderItem(article_name, '', article_bytes[article_name], onByteLoad, onByteLoadFail, onByteLoadProgress);
				loader_item.appDomain = article_app_domains[article_name];
				
				// go
				thread_loader.addLoaderItem(loader_item);
			}
		}
		
		private function onByteLoadProgress(loader_item:LoaderItem):void {
			
		}
		
		private function onByteLoadFail(loader_item:LoaderItem):void {
			CONFIG::debugging {
				Console.warn('onByteLoadFail '+article_name);
			}
			var article_name:String = loader_item.label;
			var i:int = article_names_being_loadedA.indexOf(article_name);
			if (i>-1) article_names_being_loadedA.splice(i, 1);
		}
		
		private function onByteLoad(loader_item:LoaderItem):void {
			var article_name:String = loader_item.label;
			
			var i:int = article_names_being_loadedA.indexOf(article_name);
			if (i>-1) article_names_being_loadedA.splice(i, 1);
			
			CONFIG::debugging {
				Console.log(89, 'loaded '+article_name);
			}				
			
			// add it to the hash of articles
			article_swfs[article_name] = loader_item.loader_info.content as MovieClip;
			
			// remove it from the to laod array
			article_names_to_loadA.splice(article_names_to_loadA.indexOf(article_name), 1);
			
			// remove it from the hash of bytes
			article_bytes[article_name] = null;
			delete article_bytes[article_name];
			
			StageBeacon.waitForNextFrame(checkIfDone);
		}
		
		private function checkIfDone():Boolean {
			if (no_classes) return true;
			if (article_names_to_loadA.length == 0) {
				if (embedsLoadedCallback != null) embedsLoadedCallback(this);
				return true;
			}
			return false;
		}
		
		// return one of the embedded swfs
		private function getArticleSwfByName(class_name:String):MovieClip {
			return article_swfs[class_name];
		}
		
		// returns a symbol from the library of a an embedded swf
		public function getArticlePartMC(article_name:String, class_name:String):MovieClip {
			var mc:MovieClip;
			CONFIG::debugging {
				Console.log(89, 'article_name:'+article_name+' class_name:'+class_name)
			}
			if (class_name && class_name.indexOf('none') != class_name.length-4 && class_name.indexOf('null') != class_name.length-4) {
				var article:MovieClip = getArticleSwfByName(article_name);
				
				if (!article) {
					CONFIG::debugging {
						Console.error('WTF no article for '+article_name);
					}
					return mc;
				}
				
				var appDomain:ApplicationDomain = article_app_domains[article_name];
				
				if (!appDomain) {
					return mc;
				}
				
				if (appDomain.hasDefinition(class_name)) {
					var C:Class = appDomain.getDefinition(class_name) as Class;
					if (!C) return mc
					mc = new C();
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.priwarn(89, 'NO DEFINITION IN '+article_name+' FOR: '+class_name);
					}
				}
			}
			
			return mc;
		}
		
		// returns a symbol from the library of a an embedded swf
		public function articlePartExists(article_name:String, class_name:String):Boolean {
			//Console.log(89, 'article_name:'+article_name+' class_name:'+class_name)
			
			var appDomain:ApplicationDomain = article_app_domains[article_name];
			
			if (!appDomain) {
				return false;
			}
			
			var article:MovieClip = getArticleSwfByName(article_name);
			
			if (!article) {
				CONFIG::debugging {
					Console.error('WTF no article for '+article_name);
				}
				return false;
			}
			
			if (article && appDomain.hasDefinition(class_name)) {
				return true;
			}
			
			return false;
			
		}
		
	}
}