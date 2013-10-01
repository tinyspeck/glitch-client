/**
 * Knob.as
 * Keith Peters
 * version 0.97
 * 
 * A knob component for choosing a numerical value.
 * 
 * Copyright (c) 2009 Keith Peters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
 package com.bit101.components
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class Knob extends Component
	{
		private var _knob:Sprite;
		private var _label:Label;
		private var _labelText:String = "";
		private var _max:Number = 100;
		private var _min:Number = 0;
		private var _mouseRange:Number = 100;
		private var _precision:int = 1;
		private var _startY:Number;
		private var _value:Number = 0;
		private var _valueLabel:Label;
		
		
		/**
		 * Constructor
		 * @param parent The parent DisplayObjectContainer on which to add this Knob.
		 * @param xpos The x position to place this component.
		 * @param ypos The y position to place this component.
		 * @param label String containing the label for this component.
		 * @param defaultHandler The event handling function to handle the default event for this component (change in this case).
		 */
		public function Knob(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0, label:String = "", defaultHandler:Function = null)
		{
			_labelText = label;
			super(parent, xpos, ypos);
			if(defaultHandler != null)
			{
				addEventListener(Event.CHANGE, defaultHandler);
			}
		}

		/**
		 * Initializes the component.
		 */
		override protected function init():void
		{
			super.init();
			setSize(40, 40);
		}
		
		/**
		 * Creates the children for this component
		 */
		override protected function addChildren():void
		{
			_knob = new Sprite();
			_knob.buttonMode = true;
			_knob.useHandCursor = true;
			_knob.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addChild(_knob);
			
			_label = new Label();
			_label.autoSize = true;
			addChild(_label);
			
			_valueLabel = new Label();
			_valueLabel.autoSize = true;
			addChild(_valueLabel);
		}
		
		/**
		 * Draw the knob at the specified radius.
		 * @param radius The radius with which said knob will be drawn.
		 */
		protected function drawKnob(radius:Number):void
		{
			_knob.graphics.clear();
			_knob.graphics.beginFill(Style.BACKGROUND);
			_knob.graphics.drawCircle(0, 0, radius);
			_knob.graphics.endFill();
			
			_knob.graphics.beginFill(Style.BUTTON_FACE);
			_knob.graphics.drawCircle(0, 0, radius - 2);
			_knob.graphics.endFill();
			
			_knob.graphics.beginFill(Style.BACKGROUND);
			var s:Number = radius * .1;
			_knob.graphics.drawRect(radius, -s, s*1.5, s * 2);
			_knob.graphics.endFill();
			
			_knob.x = _width / 2;
			_knob.y = _height / 2 + 20;
			updateKnob();
		}
		
		/**
		 * Updates the rotation of the knob based on the value, then formats the value label.
		 */
		protected function updateKnob():void
		{
			_knob.rotation = -225 + (_value - _min) / (_max - _min) * 270;
			formatValueLabel();
		}
		
		/**
		 * Adjusts value to be within minimum and maximum.
		 */
		protected function correctValue():void
		{
			if(_max > _min)
			{
				_value = Math.min(_value, _max);
				_value = Math.max(_value, _min);
			}
			else
			{
				_value = Math.max(_value, _max);
				_value = Math.min(_value, _min);
			}
		}
		
		/**
		 * Formats the value of the knob to a string based on the current level of precision.
		 */
		protected function formatValueLabel():void
		{
			var mult:Number = Math.pow(10, _precision);
			var val:String = (Math.round(_value * mult) / mult).toString();
			var parts:Array = val.split(".");
			if(parts[1] == null)
			{ 
				if(_precision > 0)
				{
					val += "."
				}
				for(var i:uint = 0; i < _precision; i++)
				{
					val += "0";
				}
			}
			else if(parts[1].length < _precision)
			{
				for(i = 0; i < _precision - parts[1].length; i++)
				{
					val += "0";
				}
			}
			_valueLabel.text = val;
			_valueLabel.draw();
			_valueLabel.x = width / 2 - _valueLabel.width / 2;
		}
		
		///////////////////////////////////
		// public methods
		///////////////////////////////////
		
		/**
		 * Draws the visual ui of the component.
		 */
		override public function draw():void
		{
			super.draw();
			
			var radius:Number = Math.min(_width, _height) / 2;
			drawKnob(radius);
			
			_label.text = _labelText;
			_label.draw();
			_label.x = _width / 2 - _label.width / 2;
			_label.y = 0;
			
			formatValueLabel();
			_valueLabel.y = _height + 20;
		}
		
		///////////////////////////////////
		// event handler
		///////////////////////////////////
		
		/**
		 * Internal handler for when user clicks on the knob. Starts tracking up/down motion of the mouse.
		 */
		protected function onMouseDown(event:MouseEvent):void
		{
			_startY = mouseY;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		/**
		 * Internal handler for mouse move event. Updates value based on how far mouse has moved up or down.
		 */
		protected function onMouseMove(event:MouseEvent):void
		{
			var oldValue:Number = _value;
			var diff:Number = _startY - mouseY;
			var range:Number = _max - _min;
			var percent:Number = range / _mouseRange;
			_value += percent * diff;
			correctValue();
			if(_value != oldValue)
			{
				updateKnob();
				dispatchEvent(new Event(Event.CHANGE));
			}
			_startY = mouseY;
		}
		
		/**
		 * Internal handler for mouse up event. Stops mouse tracking.
		 */
		protected function onMouseUp(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		
		///////////////////////////////////
		// getter/setters
		///////////////////////////////////
		
		/**
		 * Gets / sets the maximum value of this knob.
		 */
		public function set maximum(m:Number):void
		{
			_max = m;
			correctValue();
			updateKnob();
		}
		public function get maximum():Number
		{
			return _max;
		}
		
		/**
		 * Gets / sets the minimum value of this knob.
		 */
		public function set minimum(m:Number):void
		{
			_min = m;
			correctValue();
			updateKnob();
		}
		public function get minimum():Number
		{
			return _min;
		}
		
		/**
		 * Sets / gets the current value of this knob.
		 */
		public function set value(v:Number):void
		{
			_value = v;
			correctValue();
			updateKnob();
		}
		public function get value():Number
		{
			return _value;
		}
		
		/**
		 * Sets / gets the number of pixels the mouse needs to move to make the value of the knob go from min to max.
		 */
		public function set mouseRange(value:Number):void
		{
			_mouseRange = value;
		}
		public function get mouseRange():Number
		{
			return _mouseRange;
		}
		
		/**
		 * Gets / sets the number of decimals to format the value label.
		 */
		public function set labelPrecision(decimals:int):void
		{
			_precision = decimals;
		}
		public function get labelPrecision():int
		{
			return _precision;
		}
		
		/**
		 * Gets / sets whether or not to show the value label.
		 */
		public function set showValue(value:Boolean):void
		{
			_valueLabel.visible = value;
		}
		public function get showValue():Boolean
		{
			return _valueLabel.visible;
		}
		
		/**
		 * Gets / sets the text shown in this component's label.
		 */
		public function set label(str:String):void
		{
			_labelText = str;
			draw();
		}
		public function get label():String
		{
			return _labelText;
		}
	}
}