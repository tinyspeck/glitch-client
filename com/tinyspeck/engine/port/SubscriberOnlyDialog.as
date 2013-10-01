package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	
	import flash.display.Bitmap;
	import flash.text.TextField;

	public class SubscriberOnlyDialog extends Dialog
	{
		/* singleton boilerplate */
		public static const instance:SubscriberOnlyDialog = new SubscriberOnlyDialog();
		
		private static const X_OFFSET:uint = 140;
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		
		private var subscribe_bt:Button;
		private var cancel_bt:Button;
		
		private var is_built:Boolean;
		
		public function SubscriberOnlyDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 646;
			_base_padd = 20;
			_construct();
		}
		
		private function buildBase():void {
			//get the image
			AssetManager.instance.loadBitmapFromWeb('wardrobe/large-lock.gif', onImageLoad, 'SubscriberOnlyDialog');
			
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="subscriber_only_title">That item is only available to subscribers</p>';
			title_tf.x = X_OFFSET;
			title_tf.y = 24;
			addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.x = X_OFFSET;
			body_tf.y = int(title_tf.y + title_tf.height + 4);
			body_tf.width = _w - X_OFFSET - _base_padd;
			addChild(body_tf);
			
			var body_txt:String = '<p class="subscriber_only_body">';
			body_txt += 'Dang — you don’t have a subscription! There are so many good things that can be had with a subscription, like that thing you just tried to get.';
			body_txt += '<br><br>Good news! During beta, there are crazy good deals on subscriptions. Support Glitch and subscribe now!';
			body_txt += '<p>';
			body_tf.htmlText = body_txt;
			
			//buttons
			subscribe_bt = new Button({
				name: 'sub',
				label: 'View Subscription Options',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			subscribe_bt.addEventListener(TSEvent.CHANGED, onSubscribeClick, false, 0, true);
			subscribe_bt.y = body_tf.y + body_tf.height + 15;
			subscribe_bt.x = X_OFFSET;
			addChild(subscribe_bt);
			
			cancel_bt = new Button({
				name: 'cancel',
				label: 'No thanks',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			cancel_bt.y = subscribe_bt.y;
			cancel_bt.x = int(subscribe_bt.x + subscribe_bt.width + 10);
			addChild(cancel_bt);
			
			//set the height
			_h = int(subscribe_bt.y + subscribe_bt.height + _base_padd);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			super.start();
		}
		
		private function onImageLoad(filename:String, bm:Bitmap):void { 
			//toss that bad boy on
			bm.x = bm.y = 25;
			addChild(bm);
		}
		
		private function onSubscribeClick(event:TSEvent):void {
			//open the subscriptions page
			TSFrontController.instance.openSubscribePage();
			end(true);
		}
	}
}