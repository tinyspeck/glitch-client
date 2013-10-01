package com.tinyspeck.engine.net
{

	public interface INetResponder
	{
		function connectHandler():void;
		function disconnectHandler():void;
		function netServerMessageHandler(netServerMessage:NetServerMessage):void;
		function responseMessageHandler(incomingMessage:NetResponseMessageVO):void;
		function eventMessageHandler(incomingMessage:NetIncomingMessageVO):void;
	}
}