package com.tinyspeck.engine.data.client
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.StringUtil;

	public class WordProgress extends AbstractTSDataEntity
	{
		public var type:String;
		public var gradient_top:int = -1;
		public var gradient_bottom:int = -1;
		
		public function WordProgress(){
			super('word_progress');
		}
		
		public static function fromAnonymous(object:Object):WordProgress {
			var word:WordProgress = new WordProgress();
			var j:String;
			
			for(j in object){
				if(j == 'gradient_top'){
					word.gradient_top = StringUtil.cssHexToUint(object[j]);
				}
				else if(j == 'gradient_bottom'){
					word.gradient_bottom = StringUtil.cssHexToUint(object[j]);
				}
				else if(j in word){
					word[j] = object[j];
				}
				else{
					resolveError(word,object,j);
				}
			}
			
			return word
		}
	}
}