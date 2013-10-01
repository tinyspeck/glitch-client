package com.tinyspeck.engine.view.ui.glitchr.filters {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.memory.DisposableSprite;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/**
	 * A horizontally scrolling DisplayObject container.  Children are added to a page until the maximum
	 * page width is reached, at which point a new page is created.
	 */
	public class HorizScrollingContainer extends DisposableSprite {
				
		private const pagesContainer:Sprite = new Sprite();
		private const pages:Vector.<Sprite> = new Vector.<Sprite>();
		private const pageMask:Sprite = new Sprite();

		private var scrollLeft:Sprite;
		private var scrollRight:Sprite;
		private var nextChildX:Number;
		private var pagePadding:Number;
		private var scrollSpritesMarginTop:Number;
		private var currentPageIndex:uint = 0;
		
		private var _maxPageWidth:Number;
		
		public function HorizScrollingContainer(maxPageWidth:Number, pagePadding:Number = 0, scrollSpritesMarginTop:Number = 0) {
			super();
			
			this._maxPageWidth = maxPageWidth;
			this.pagePadding = pagePadding;
			this.scrollSpritesMarginTop = scrollSpritesMarginTop;
			nextChildX = pagePadding;
			
			addChild(pagesContainer);
			
			setupPageMask();
			setupScrollSprites();
		}
		
		private function setupPageMask():void {
			pageMask.graphics.beginFill(0x00ff00);
			pageMask.graphics.drawRect(0, 0, 1, 1);
			pageMask.graphics.endFill();
			addChild(pageMask);
			pagesContainer.mask = pageMask;
		}
		
		private function setupScrollSprites():void {
			
			scrollLeft = drawScrollSprite(true);
			scrollLeft.y = scrollSpritesMarginTop;
			scrollLeft.addEventListener(MouseEvent.CLICK, onScrollLeftClicked);
			scrollLeft.visible = false;

			scrollRight = drawScrollSprite();
			scrollRight.x = maxPageWidth;
			scrollRight.y = scrollSpritesMarginTop;
			scrollRight.addEventListener(MouseEvent.CLICK, onScrollRightClicked);
			scrollRight.visible = false;
			
			addChild(scrollLeft);
			addChild(scrollRight);
		}
		
		protected function drawScrollSprite(pointsLeft:Boolean = false):Sprite {
			var scrollSprite:Sprite = new Sprite();
			scrollSprite.buttonMode = true;
			var scaleX:int = pointsLeft ? -1 : 1;
			
			scrollSprite.graphics.beginFill(0xffff00, 0);
			scrollSprite.graphics.drawRect(0, 0, 50, 50);
			scrollSprite.graphics.endFill();
			
			var lineWidth:Number = 5;
			var offsetY:Number = 15;
			var offsetX:Number = 0;
			scrollSprite.graphics.lineStyle(lineWidth, 0x477888);
			scrollSprite.graphics.moveTo(0 + lineWidth + offsetX, 0 + lineWidth + offsetY);
			scrollSprite.graphics.lineTo(7 + lineWidth + offsetX, 7 + lineWidth + offsetY);
			scrollSprite.graphics.lineTo(0 + lineWidth + offsetX, 14 + lineWidth + offsetY);
			
			scrollSprite.scaleX *= pointsLeft ? -1 : 1;
			return scrollSprite;
		}
		
		private function onScrollLeftClicked(e:MouseEvent):void {
			if (currentPageIndex == 0) return;
			
			var previousPage:Sprite = pages[currentPageIndex];
			var newPage:Sprite = pages[--currentPageIndex];
			tweenPagesContainer(newPage, previousPage);
			
			if (currentPageIndex == 0) {
				scrollLeft.visible = false;
			}
			scrollRight.visible = true;
		}
		
		private function onScrollRightClicked(e:MouseEvent):void {
			if (currentPageIndex == pages.length - 1) {
				return;
			}

			var previousPage:Sprite = pages[currentPageIndex];
			var newPage:Sprite = pages[++currentPageIndex]
			tweenPagesContainer(newPage, previousPage);
			
			if (currentPageIndex == pages.length - 1) {
				scrollRight.visible = false;
			}
			scrollLeft.visible = true;
		}
		
		private function tweenPagesContainer(newPage:Sprite, previousPage:Sprite):void {
			TSTweener.removeTweens(previousPage);
			TSTweener.addTween(previousPage, {alpha:0, time:0.5, transition:'easeinoutquad'});
			
			TSTweener.removeTweens(pagesContainer);
			TSTweener.addTween(pagesContainer, {x:-newPage.x, time:0.5, transition:'easeinoutquad'});
			newPage.alpha = 1;
		}
		
		private function addNewPage():Sprite {
			var page:Sprite = new Sprite();
			pagesContainer.addChild(page);
			page.x = _maxPageWidth * pages.length
			pages.push(page);
			
			return page;
		}
		
		/** Adds a child to a page. */
		public function appendChild(child:DisplayObject, leftMargin:Number = 10, forceChildWidth:Number = 0):void {
			
			var childBounds:Rectangle = child.getRect(child);
			if (childBounds.width > _maxPageWidth) {
				throw new Error("Child is larger than maximum allowed page width.");
			}
			
			var page:Sprite;
			var childWidth:Number = (forceChildWidth > 0) ? forceChildWidth : childBounds.width;
			var updatedPageWidth:Number = nextChildX + leftMargin + childWidth + pagePadding;
			if (pages.length && updatedPageWidth <= _maxPageWidth) {
				 page = pages[pages.length - 1];
			} else {
				page = addNewPage();
				nextChildX = pagePadding;
				if (pages.length > 1) scrollRight.visible = true;
			}

			page.addChild(child);
			child.x = nextChildX + leftMargin;
			nextChildX = child.x + childWidth;
			
			updateMask();
		}
		
		private function updateMask():void {
			var pageContainerBounds:Rectangle = pagesContainer.getBounds(pagesContainer);
			pageMask.width = maxPageWidth;
			pageMask.height = pageContainerBounds.height;
			pageMask.y = pageContainerBounds.y;
		}

		public function get maxPageWidth():Number { return _maxPageWidth; }
	}
}