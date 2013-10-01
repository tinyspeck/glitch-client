package com.tinyspeck.engine.net
{
	import com.tinyspeck.core.memory.IDisposable;

	public interface INetDelegate extends IDisposable
	{
		function connect(host:String, port:int, token:String):void;
		function disconnect():void;
		function addRequest(msg:NetOutgoingMessageVO):int;
		function addAnonRequest(msg:Object):void;
		function sendRequests():void;
		function parseIncomingMessage(ob:Object, logit:Boolean=false):Boolean;
		function socketReport():String;
	}
}