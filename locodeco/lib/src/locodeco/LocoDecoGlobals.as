package locodeco
{
import flash.events.EventDispatcher;
import flash.net.SharedObject;

import locodeco.models.DecoModel;
import locodeco.models.GeoModel;
import locodeco.models.LayerModel;
import locodeco.models.LocationModel;

import mx.collections.ArrayCollection;
import mx.collections.ArrayList;
import mx.events.PropertyChangeEvent;

public final class LocoDecoGlobals extends EventDispatcher
{
	public static const instance:LocoDecoGlobals = new LocoDecoGlobals();

	// view
	[Bindable] public var sideBarHeight:uint;
	[Bindable] public var sideBarWidth:uint;
	
	// models
	[Bindable] public var location:LocationModel = new LocationModel();
	
	// interactivity
	[Bindable] public var selectedDeco:DecoModel;
	[Bindable] public var selectedLayer:LayerModel;
	[Bindable] public var multiSelectedDecos:ArrayList = new ArrayList();
	
	/** Hack so we know when to ignore keystrokes in the client */
	[Bindable] public var currentlyEditingALabel:Boolean;
	
	/**
	 * When the selection changes, this will be true during the databinding
	 * model update if the click origin was in the DecoPanel (versus clicking
	 * a deco directly in the viewport).
	 */ 
	public var selectionSourceIsDecoPanelUglyHack:Boolean;
	
	[Bindable] public var onlySelectGeos:Boolean = false;
	[Bindable] public var groundYMode:Boolean = false;
	
	[Bindable] public var invokingSets:ArrayCollection = new ArrayCollection();
	[Bindable] public var userdecoSets:ArrayCollection = new ArrayCollection();
	
	// preferences (stored as Flash cookies)
	private static var STORED_PROPERTIES:Array = [
		'decoSelectorZoom',
		'decoSelectorColor',
		'centerVPOnSelection',
		'overlayHoverGlow',
		'overlayInteractionRegion',
		'overlayItemstacks',
		'overlayJumpArc',
		'overlayPlatforms',
		'overlayPCs',
		'overlayRuler',
		'overlaySelectionGlow',
		'toolTips'
	];
	[Bindable] public var decoSelectorZoom:Number = 80;
	[Bindable] public var decoSelectorColor:uint = 0;
	[Bindable] public var viewportScale:Number = 1;
	// start with the size as big as possible
	[Bindable] public var viewportWidth:Number = int.MAX_VALUE;
	// start with the size as big as possible
	[Bindable] public var viewportHeight:Number = int.MAX_VALUE;
	[Bindable] public var centerVPOnSelection:Boolean = true;
	[Bindable] public var overlayHoverGlow:Boolean = true;
	[Bindable] public var overlayInteractionRegion:Boolean = false;
	[Bindable] public var overlayItemstacks:Boolean = true;
	[Bindable] public var overlayJumpArc:Boolean = false;
	[Bindable] public var overlayPlatforms:Boolean = true;
	[Bindable] public var overlayPCs:Boolean = true;
	[Bindable] public var overlayRuler:Boolean = false;
	[Bindable] public var overlaySelectionGlow:Boolean = true;
	[Bindable] public var toolTips:Boolean = true;
	
	private var sharedObject:SharedObject;
	
	public function LocoDecoGlobals() {
		sharedObject = SharedObject.getLocal('TS_DATA', '/');
		if (!sharedObject.data.hasOwnProperty('locodeco')) sharedObject.data.locodeco = {};
		load();
		addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, store);
	}
	
	public function isSelected(dm:DecoModel):Boolean {
		if (isSingleSelectionActive) {
			return (selectedDeco == dm);
		} else if (isMultiSelectionActive) {
			return (multiSelectedDecos.getItemIndex(dm) != -1);
		}
		return false;
	}
	
	/** Returns all selected decos, whether it's single or multi */
	public function get selectedDecos():Array {
		if (isSingleSelectionActive) {
			return [selectedDeco];
		} else if (isMultiSelectionActive) {
			return multiSelectedDecos.source;
		}
		return [];
	}
	
	public function get isSelectionActive():Boolean {
		return (isSingleSelectionActive || isMultiSelectionActive);
	}
	
	/** When true, selectedDeco is non-null and is not geometry */
	public function get isSingleSelectionADeco():Boolean {
		return ((selectedDeco != null) && !(selectedDeco is GeoModel));
	}
	
	/** When true, selectedDeco is non-null and is geometry */
	public function get isSingleSelectionAGeo():Boolean {
		return ((selectedDeco != null) && (selectedDeco is GeoModel));
	}
	
	/** When true, selectedDeco is non-null and multiSelectedDecos is zero length, and vice-versa */
	public function get isSingleSelectionActive():Boolean {
		return (selectedDeco != null);
	}
	
	/** When true, selectedDeco is null and multiSelectedDecos has a length, and vice-versa */
	public function get isMultiSelectionActive():Boolean {
		return (multiSelectedDecos.length > 0);
	}
	
	private function store(pce:PropertyChangeEvent):void {
		if (STORED_PROPERTIES.indexOf(pce.property) != -1) {
			sharedObject.data.locodeco[pce.property] = pce.newValue;
		}
	}
	
	private function load():void {
		for (var prop:String in sharedObject.data.locodeco) {
			if (hasOwnProperty(prop)) {
				this[prop] = sharedObject.data.locodeco[prop];
			}
		}
	}
}
}