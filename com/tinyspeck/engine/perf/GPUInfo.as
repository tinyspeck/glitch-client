package com.tinyspeck.engine.perf
{
import flash.display.Stage;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.system.ApplicationDomain;

CONFIG::fp11 { import flash.display.Stage3D; }
CONFIG::fp11 { import flash.display3D.Context3D; }
CONFIG::fp11 { import flash.display3D.Context3DRenderMode; }

internal class GPUInfo
{
    CONFIG::fp11 private var stage3D:Stage3D;
	private var _ready:Boolean = false;
	private var _GPUAvailable:Boolean;
	private var _stage3DAvailable:Boolean;
	private var _driverInfo:String;
	
    public function GPUInfo(stage:Stage) {
		if (CONFIG::fp11 && ApplicationDomain.currentDomain.hasDefinition("flash.display.Stage3D")) {
			_stage3DAvailable = true;
			CONFIG::fp11 {
		        stage3D = stage.stage3Ds[0];
		        stage3D.addEventListener(Event.CONTEXT3D_CREATE, contextCreated);
		        stage3D.addEventListener(ErrorEvent.ERROR, contextCreationError);
		        stage3D.requestContext3D(Context3DRenderMode.AUTO);
			}
		} else {
			_stage3DAvailable = false;
			_driverInfo = 'none';
			_ready = true;
		}
    }
	
	public function get ready():Boolean {
		return _ready;
	}
	
	public function get stage3DAvailable():Boolean {
		return _stage3DAvailable;
	}
	
	public function get driverInfo():String {
		return _driverInfo;
	}
	
	public function get GPUAvailable():Boolean {
		return _GPUAvailable;
	}
    
    CONFIG::fp11 private function contextCreated(event:Event):void {
        //trace("driverInfo: " + renderContext.driverInfo);
        const renderContext:Context3D = Stage3D(event.target).context3D;
		
		if (renderContext) {
			if ((renderContext.driverInfo == Context3DRenderMode.SOFTWARE) || (renderContext.driverInfo.indexOf('oftware')>-1)) {
				_GPUAvailable = false;
				_driverInfo = 'software';
				_ready = true;
			} else {
				_GPUAvailable = true;
				_driverInfo = renderContext.driverInfo;
				_ready = true;
			}
		} else {
			_GPUAvailable = false;
			_driverInfo = 'unknown';
			_ready = true;
		}
		dispose();
    }
    
    CONFIG::fp11 private function contextCreationError(error:ErrorEvent):void {
        //trace(error.errorID + ": " + error.text);
		_GPUAvailable = false;
		_driverInfo = 'error';
		_ready = true;
		dispose();
    }
	
	CONFIG::fp11 private function dispose():void {
		if (stage3D) {
			stage3D.removeEventListener(Event.CONTEXT3D_CREATE, contextCreated);
        	stage3D.removeEventListener(ErrorEvent.ERROR, contextCreationError);
			if (stage3D.context3D) stage3D.context3D.dispose();
			stage3D = null;
		}
	}
}
}