package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.LoginTool;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.ScreenViewQueueVO;
	import com.tinyspeck.engine.data.decorate.Swatch;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.itemstack.ItemstackStatus;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MapInfo;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.data.map.MapData;
	import com.tinyspeck.engine.data.map.MapPathInfo;
	import com.tinyspeck.engine.data.pc.ImaginationCard;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.data.pc.PCParty;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.prompt.Prompt;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.rook.RookDamage;
	import com.tinyspeck.engine.data.rook.RookStun;
	import com.tinyspeck.engine.data.rook.RookedStatus;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.data.transit.Transit;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.net.NetIncomingMessageVO;
	import com.tinyspeck.engine.net.NetOutgoingContactListOpenedVO;
	import com.tinyspeck.engine.net.NetOutgoingImSendVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.CabinetManager;
	import com.tinyspeck.engine.port.ConversationManager;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.EmblemManager;
	import com.tinyspeck.engine.port.GetInfoDialog;
	import com.tinyspeck.engine.port.HouseExpandYardDialog;
	import com.tinyspeck.engine.port.HouseManager;
	import com.tinyspeck.engine.port.HouseSignDialog;
	import com.tinyspeck.engine.port.HouseStylesDialog;
	import com.tinyspeck.engine.port.InputDialog;
	import com.tinyspeck.engine.port.InputTalkBubble;
	import com.tinyspeck.engine.port.JS_interface;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.MakingDialog;
	import com.tinyspeck.engine.port.MakingManager;
	import com.tinyspeck.engine.port.NewAvaConfigDialog;
	import com.tinyspeck.engine.port.NoteManager;
	import com.tinyspeck.engine.port.NoticeBoardManager;
	import com.tinyspeck.engine.port.PartySpaceManager;
	import com.tinyspeck.engine.port.PlayerInfoDialog;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.QuestsDialog;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.RookManager;
	import com.tinyspeck.engine.port.ScoreManager;
	import com.tinyspeck.engine.port.ShrineManager;
	import com.tinyspeck.engine.port.SignpostDialog;
	import com.tinyspeck.engine.port.StoreDialog;
	import com.tinyspeck.engine.port.StoreManager;
	import com.tinyspeck.engine.port.TeleportationManager;
	import com.tinyspeck.engine.port.TeleportationScriptManager;
	import com.tinyspeck.engine.port.TradeDialog;
	import com.tinyspeck.engine.port.TradeManager;
	import com.tinyspeck.engine.port.TransitManager;
	import com.tinyspeck.engine.port.TrophyCaseManager;
	import com.tinyspeck.engine.port.TrophyGetInfoDialog;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.gameoverlay.AchievementView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.CollectionCompleteView;
	import com.tinyspeck.engine.view.gameoverlay.DisconnectedScreenView;
	import com.tinyspeck.engine.view.gameoverlay.GiantView;
	import com.tinyspeck.engine.view.gameoverlay.ImaginationManager;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.LevelUpView;
	import com.tinyspeck.engine.view.gameoverlay.LocationCheckListView;
	import com.tinyspeck.engine.view.gameoverlay.NewDayView;
	import com.tinyspeck.engine.view.gameoverlay.SnapTravelView;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.itemstack.AbstractItemstackView;
	import com.tinyspeck.engine.view.itemstack.PackItemstackView;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.avatar.Lantern;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.glitchr.filters.commands.GlitchrFilterCommands;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationHandUI;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationPurchaseUpgradeUI;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationSkillsUI;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationYourLooksUI;
	
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	public class NCMsgHandler {
		
		private var model:TSModelLocator;
		private var world:WorldModel;
		private var nc:NetController;
		private var loc_event_no_props:int;
		
		public const type_to_func:Dictionary = new Dictionary();
		
		public function NCMsgHandler(nc:NetController, model:TSModelLocator) {
			this.nc = nc;
			this.model = model;
			world = model.worldModel;
			setUpFunctionMap();
		}
		
		private function setUpFunctionMap():void {
			// As far as I can tell, these were never handled; they should pobably be removed, as nothing references them
			type_to_func[MessageTypes.CONVERSATION_END] = null;
			type_to_func[MessageTypes.LOGGED_IN_FROM_OTHER_CLIENT] = null;
			
			// these are accounted for:
			type_to_func[MessageTypes.ACHIEVEMENT_COMPLETE] = do_ACHIEVEMENT_COMPLETE;
			type_to_func[MessageTypes.ACL_KEY_CHANGE] = null; //handled in ACLManager
			type_to_func[MessageTypes.ACL_KEY_INFO] = do_ACL_KEY_INFO;
			type_to_func[MessageTypes.ACL_KEY_START] = do_ACL_KEY_START;
			type_to_func[MessageTypes.ACTION_REQUEST_BROADCAST] = null; // handled by TSLinkedTextField's onReply for all action request replys; broadcast comes from the client and doesn't need handling here
			type_to_func[MessageTypes.ACTION_REQUEST_CANCEL] = do_ACTION_REQUEST_CANCEL;
			type_to_func[MessageTypes.ACTION_REQUEST_REPLY] = null; //handled by TSLinkedTextField's onReply for all action request replys; broadcast comes from the client and doesn't need handling here
			type_to_func[MessageTypes.ACTION_REQUEST_UPDATE] = do_ACTION_REQUEST_UPDATE;
			type_to_func[MessageTypes.ACTION_REQUEST] = do_ACTION_REQUEST;
			type_to_func[MessageTypes.ACTIVITY] = do_ACTIVITY;
			type_to_func[MessageTypes.ADMIN_TELEPORT] = null;
			type_to_func[MessageTypes.AFK] = null;
			type_to_func[MessageTypes.ANIMATE_PACK_SLOTS] = do_ANIMATE_PACK_SLOTS;
			type_to_func[MessageTypes.ANNC_FLUSH] = null;
			type_to_func[MessageTypes.AVATAR_GET_CHOICES] = do_AVATAR_GET_CHOICES;
			type_to_func[MessageTypes.AVATAR_ORIENTATION] = do_AVATAR_ORIENTATION;
			type_to_func[MessageTypes.AVATAR_PRELOAD] = do_AVATAR_PRELOAD;
			type_to_func[MessageTypes.AVATAR_UPDATE] = do_AVATAR_UPDATE;
			type_to_func[MessageTypes.BOOTED] = do_BOOTED;
			type_to_func[MessageTypes.BUDDY_ADD] = do_BUDDY_ADD;
			type_to_func[MessageTypes.BUDDY_ADDED] = do_BUDDY_ADDED;
			type_to_func[MessageTypes.BUDDY_IGNORE] = do_BUDDY_IGNORE;
			type_to_func[MessageTypes.BUDDY_OFFLINE] = do_BUDDY_OFFLINE;
			type_to_func[MessageTypes.BUDDY_ONLINE] = do_BUDDY_ONLINE;
			type_to_func[MessageTypes.BUDDY_REMOVE] = null;
			type_to_func[MessageTypes.BUDDY_REMOVED] = do_BUDDY_REMOVED;
			type_to_func[MessageTypes.BUDDY_UNIGNORE] = do_BUDDY_UNIGNORE;
			type_to_func[MessageTypes.BUFF_REMOVE] = do_BUFF_REMOVE;
			type_to_func[MessageTypes.BUFF_START] = do_BUFF_START;
			type_to_func[MessageTypes.BUFF_UPDATE] = do_BUFF_UPDATE;
			type_to_func[MessageTypes.CABINET_END] = do_CABINET_END;
			type_to_func[MessageTypes.CABINET_START] = do_CABINET_START;
			type_to_func[MessageTypes.CAMERA_ABILITIES_CHANGE] = do_CAMERA_ABILITIES_CHANGE;
			type_to_func[MessageTypes.CAMERA_CENTER] = do_CAMERA_CENTER;
			type_to_func[MessageTypes.CAMERA_MODE_ENDED] = null;
			type_to_func[MessageTypes.CAMERA_MODE_START] = do_CAMERA_MODE_START;
			type_to_func[MessageTypes.CAMERA_MODE_STARTED] = do_CAMERA_MODE_STARTED;
			type_to_func[MessageTypes.CAMERA_OFFSET] = do_CAMERA_OFFSET;
			type_to_func[MessageTypes.CLEAR_LOCATION_PATH] = do_CLEAR_LOCATION_PATH;
			type_to_func[MessageTypes.CLOSE_IMG_MENU] = do_CLOSE_IMG_MENU;
			type_to_func[MessageTypes.COLLECTION_COMPLETE] = do_COLLECTION_COMPLETE;
			type_to_func[MessageTypes.CONTACT_LIST_OPENED] = null;
			type_to_func[MessageTypes.CONVERSATION_CANCEL] = do_CONVERSATION_CANCEL;
			type_to_func[MessageTypes.CONVERSATION_CHOICE] = do_CONVERSATION_CHOICE;
			type_to_func[MessageTypes.CONVERSATION] = do_CONVERSATION;
			type_to_func[MessageTypes.CRAFTYBOT_ADD] = null; //handled in CraftyManager
			type_to_func[MessageTypes.CRAFTYBOT_COST] = null; //handled in CraftyManager
			type_to_func[MessageTypes.CRAFTYBOT_LOCK] = null; //handled in CraftyManager
			type_to_func[MessageTypes.CRAFTYBOT_PAUSE] = null; //handled in CraftyManager
			type_to_func[MessageTypes.CRAFTYBOT_REMOVE] = null; //handled in CraftyManager
			type_to_func[MessageTypes.CRAFTYBOT_REFUEL] = null; //handled in CraftyManager
			type_to_func[MessageTypes.CRAFTYBOT_START] = do_CRAFTYBOT_START;
			type_to_func[MessageTypes.CRAFTYBOT_UPDATE] = do_CRAFTYBOT_UPDATE;
			type_to_func[MessageTypes.CULTIVATION_MODE_END] = do_CULTIVATION_MODE_END;
			type_to_func[MessageTypes.CULTIVATION_MODE_ENDED] = null;
			type_to_func[MessageTypes.CULTIVATION_MODE_START] = do_CULTIVATION_MODE_START;
			type_to_func[MessageTypes.CULTIVATION_PURCHASE] = null;
			type_to_func[MessageTypes.CULTIVATION_START] = do_CULTIVATION_START;
			type_to_func[MessageTypes.DECO_ADD] = do_DECO_ADD;
			type_to_func[MessageTypes.DECO_REMOVE] = do_DECO_REMOVE;
			type_to_func[MessageTypes.DECO_SIGN_TXT] = do_DECO_SIGN_TXT;
			type_to_func[MessageTypes.DECO_UPDATE] = do_DECO_UPDATE;
			type_to_func[MessageTypes.DECO_VISIBILITY] = do_DECO_VISIBILITY;
			type_to_func[MessageTypes.DECORATION_MODE_END] = do_DECORATION_MODE_END;
			type_to_func[MessageTypes.DOOR_ADD] = do_DOOR_ADD;
			type_to_func[MessageTypes.DOOR_CHANGE] = do_DOOR_CHANGE;
			type_to_func[MessageTypes.DOOR_MOVE_END] = locationMoveEndHandler;
			type_to_func[MessageTypes.DOOR_MOVE_START] = do_DOOR_MOVE_START;
			type_to_func[MessageTypes.DRAWDOTS] = do_DRAWDOTS;
			type_to_func[MessageTypes.DRAWPOLY] = do_DRAWPOLY;
			type_to_func[MessageTypes.DUMP_DATA] = do_DUMP_DATA;
			type_to_func[MessageTypes.EDIT_LOCATION] = null;
			type_to_func[MessageTypes.EMBLEM_SPEND] = null; //handled in EmblemManager
			type_to_func[MessageTypes.EMBLEM_START] = do_EMBLEM_START;
			type_to_func[MessageTypes.EMOTE] = null;
			type_to_func[MessageTypes.FAMILIAR_DIALOG_START] = do_FAMILIAR_DIALOG_START;
			type_to_func[MessageTypes.FAMILIAR_STATE_CHANGE] = do_FAMILIAR_STATE_CHANGE;
			type_to_func[MessageTypes.FOLLOW_END] = do_FOLLOW_END;
			type_to_func[MessageTypes.FOLLOW_MOVE_END] = locationMoveEndHandler;
			type_to_func[MessageTypes.FOLLOW_MOVE_START] = do_FOLLOW_MOVE_START;
			type_to_func[MessageTypes.FOLLOW_START] = null;
			type_to_func[MessageTypes.FORCE_RELOAD] = do_FORCE_RELOAD;
			type_to_func[MessageTypes.FURNITURE_DROP] = do_FURNITURE_DROP;
			type_to_func[MessageTypes.FURNITURE_MOVE] = null;
			type_to_func[MessageTypes.FURNITURE_PICKUP] = null;
			type_to_func[MessageTypes.FURNITURE_SET_USER_CONFIG] = null;
			type_to_func[MessageTypes.FURNITURE_SET_ZEDS] = null;
			type_to_func[MessageTypes.FURNITURE_UPGRADE_PURCHASE] = null;
			type_to_func[MessageTypes.FURNITURE_UPGRADE_START] = do_FURNITURE_UPGRADE_START;
			type_to_func[MessageTypes.FURNITURE_ZEDS] = null;
			type_to_func[MessageTypes.GAME_END] = do_GAME_END;
			type_to_func[MessageTypes.GAME_SPLASH_SCREEN] = do_GAME_SPLASH_SCREEN;
			type_to_func[MessageTypes.GAME_START] = do_GAME_START;
			type_to_func[MessageTypes.GAME_UPDATE] = do_GAME_UPDATE;
			type_to_func[MessageTypes.GARDEN_ACTION] = null; //handled in the GardenManager
			type_to_func[MessageTypes.GEO_ADD] = do_GEO_ADD;
			type_to_func[MessageTypes.GEO_REMOVE] = do_GEO_REMOVE;
			type_to_func[MessageTypes.GEO_UPDATE] = do_GEO_UPDATE;
			type_to_func[MessageTypes.GET_HI_EMOTE_LEADERBOARD] = do_HI_EMOTE_LEADERBOARD;
			type_to_func[MessageTypes.GET_ITEM_ASSET] = do_GET_ITEM_ASSET;
			type_to_func[MessageTypes.GET_ITEM_INFO] = do_GET_ITEM_INFO;
			type_to_func[MessageTypes.GET_ITEM_PLACEMENT] = do_GET_ITEM_PLACEMENT;
			type_to_func[MessageTypes.GET_PATH_TO_LOCATION] = do_GET_PATH_TO_LOCATION;
			type_to_func[MessageTypes.GET_TROPHY_INFO] = do_GET_TROPHY_INFO;
			type_to_func[MessageTypes.GIANT_SCREEN] = do_GIANT_SCREEN;
			type_to_func[MessageTypes.GLOBAL_CHAT] = null;
			type_to_func[MessageTypes.GO_URL] = do_GO_URL;
			type_to_func[MessageTypes.GROUPS_CHAT_JOIN] = null;
			type_to_func[MessageTypes.GROUPS_CHAT_LEAVE] = null;
			type_to_func[MessageTypes.GROUPS_CHAT] = null;
			type_to_func[MessageTypes.GROUPS_JOIN] = do_GROUPS_JOIN;
			type_to_func[MessageTypes.GROUPS_LEAVE] = do_GROUPS_LEAVE;
			type_to_func[MessageTypes.GROUPS_SWITCH] = do_GROUPS_SWITCH;
			type_to_func[MessageTypes.GUIDE_STATUS_CHANGE] = null; //it's handled in RightSideManager
			type_to_func[MessageTypes.HAS_DONE_INTRO] = do_HAS_DONE_INTRO;
			type_to_func[MessageTypes.HI_EMOTE_LEADERBOARD] = do_HI_EMOTE_LEADERBOARD;
			type_to_func[MessageTypes.HI_EMOTE_MISSILE_HIT] = null;
			type_to_func[MessageTypes.HI_EMOTE_VARIANT_SET] = do_HI_EMOTE_VARIANT_SET;
			type_to_func[MessageTypes.HI_EMOTE_VARIANT_WINNER] = do_HI_EMOTE_VARIANT_WINNER;
			type_to_func[MessageTypes.HOUSES_ADD_NEIGHBOR] = null; //handled in SignpostManager
			type_to_func[MessageTypes.HOUSES_CEILING_BUY] = null;
			type_to_func[MessageTypes.HOUSES_CEILING_CHOICES] = null;
			type_to_func[MessageTypes.HOUSES_CEILING_PREVIEW] = null;
			type_to_func[MessageTypes.HOUSES_CEILING_PURCHASED] = do_HOUSES_CEILING_PURCHASED;
			type_to_func[MessageTypes.HOUSES_CEILING_REMOVED] = do_HOUSES_CEILING_REMOVED;
			type_to_func[MessageTypes.HOUSES_CEILING_SET] = null;
			type_to_func[MessageTypes.HOUSES_CHANGE_CHASSIS_START] = do_HOUSES_CHANGE_CHASSIS_START;
			type_to_func[MessageTypes.HOUSES_CHANGE_STYLE_START] = do_HOUSES_CHANGE_STYLE_START;
			type_to_func[MessageTypes.HOUSES_EXPAND_COSTS] = null;
			type_to_func[MessageTypes.HOUSES_EXPAND_START] = do_HOUSES_EXPAND_START;
			type_to_func[MessageTypes.HOUSES_EXPAND_TOWER] = null;
			type_to_func[MessageTypes.HOUSES_EXPAND_WALL] = null;
			type_to_func[MessageTypes.HOUSES_EXPAND_YARD] = null;
			type_to_func[MessageTypes.HOUSES_FLOOR_BUY] = null;
			type_to_func[MessageTypes.HOUSES_FLOOR_CHOICES] = null;
			type_to_func[MessageTypes.HOUSES_FLOOR_PREVIEW] = null;
			type_to_func[MessageTypes.HOUSES_FLOOR_PURCHASED] = do_HOUSES_FLOOR_PURCHASED;
			type_to_func[MessageTypes.HOUSES_FLOOR_REMOVED] = do_HOUSES_FLOOR_REMOVED;
			type_to_func[MessageTypes.HOUSES_FLOOR_SET] = null;
			type_to_func[MessageTypes.HOUSES_REMOVE_NEIGHBOR] = null; //handled in SignpostManager
			type_to_func[MessageTypes.HOUSES_SIGNPOST] = null;
			type_to_func[MessageTypes.HOUSES_STYLE_CHOICES] = null;
			type_to_func[MessageTypes.HOUSES_STYLE_SWITCH] = null;
			type_to_func[MessageTypes.HOUSES_UNEXPAND_WALL] = null;
			type_to_func[MessageTypes.HOUSES_UPGRADE_START] = do_HOUSES_UPGRADE_START;
			type_to_func[MessageTypes.HOUSES_VISIT] = do_HOUSES_VISIT;
			type_to_func[MessageTypes.HOUSES_WALL_BUY] = null;
			type_to_func[MessageTypes.HOUSES_WALL_CHOICES] = null;
			type_to_func[MessageTypes.HOUSES_WALL_PREVIEW] = null;
			type_to_func[MessageTypes.HOUSES_WALL_PURCHASED] = do_HOUSES_WALL_PURCHASED;
			type_to_func[MessageTypes.HOUSES_WALL_REMOVED] = do_HOUSES_WALL_REMOVED;
			type_to_func[MessageTypes.HOUSES_WALL_SET] = null;
			type_to_func[MessageTypes.IM_CLOSE] = do_IM_CLOSE;
			type_to_func[MessageTypes.IM_RECV] = do_IM_RECV;
			type_to_func[MessageTypes.IM_SEND] = do_IM_SEND;
			type_to_func[MessageTypes.IMAGINATION_HAND] = do_IMAGINATION_HAND;
			type_to_func[MessageTypes.IMAGINATION_PURCHASE_CONFIRMED] = null; //handled in ImaginationManager
			type_to_func[MessageTypes.IMAGINATION_PURCHASE_SCREEN] = do_IMAGINATION_PURCHASE_SCREEN;
			type_to_func[MessageTypes.IMAGINATION_PURCHASE] = null; //handled in ImaginationManager
			type_to_func[MessageTypes.IMAGINATION_SHUFFLE] = null; //handled in ImaginationManager
			type_to_func[MessageTypes.INPUT_CANCEL] = do_INPUT_CANCEL;
			type_to_func[MessageTypes.INPUT_REQUEST] = do_INPUT_REQUEST;
			type_to_func[MessageTypes.INPUT_RESPONSE] = null;
			type_to_func[MessageTypes.INVENTORY_DRAG_TARGETS] = null;
			type_to_func[MessageTypes.INVENTORY_MOVE] = null;
			type_to_func[MessageTypes.IS_AFK] = do_IS_AFK;
			type_to_func[MessageTypes.ITEM_CONFIG] = do_ITEMSTACK_CONFIG; // yes, not do_ITEM_CONFIG (deprecated msg)
			type_to_func[MessageTypes.ITEM_STATE] = do_ITEMSTACK_STATE; // yes, not do_ITEM_STATE (deprecated msg)
			type_to_func[MessageTypes.ITEMSTACK_BUBBLE] = do_ITEMSTACK_BUBBLE;
			type_to_func[MessageTypes.ITEMSTACK_CONFIG_START] = do_ITEMSTACK_CONFIG_START;
			type_to_func[MessageTypes.ITEMSTACK_CONFIG] = do_ITEMSTACK_CONFIG;
			type_to_func[MessageTypes.ITEMSTACK_CREATE] = null;
			type_to_func[MessageTypes.ITEMSTACK_INVOKE] = null;
			type_to_func[MessageTypes.ITEMSTACK_MENU_UP] = null;
			type_to_func[MessageTypes.ITEMSTACK_MODIFY] = null;
			type_to_func[MessageTypes.ITEMSTACK_MOUSE_OVER] = null;
			type_to_func[MessageTypes.ITEMSTACK_NUDGE] = null;
			type_to_func[MessageTypes.ITEMSTACK_SET_USER_CONFIG] = null;
			type_to_func[MessageTypes.ITEMSTACK_STATE] = do_ITEMSTACK_STATE;
			type_to_func[MessageTypes.ITEMSTACK_STATUS] = do_ITEMSTACK_STATUS;
			type_to_func[MessageTypes.ITEMSTACK_VERB_CANCEL] = null;
			type_to_func[MessageTypes.ITEMSTACK_VERB_MENU] = do_ITEMSTACK_VERB_MENU;
			type_to_func[MessageTypes.ITEMSTACK_VERB] = null;
			type_to_func[MessageTypes.JOB_APPLY_WORK] = null; // handled in JobManager
			type_to_func[MessageTypes.JOB_CLAIM] = null; // handled in JobManager
			type_to_func[MessageTypes.JOB_CONTRIBUTE_CURRANTS] = null; // handled in JobManager
			type_to_func[MessageTypes.JOB_CONTRIBUTE_ITEM] = null; // handled in JobManager
			type_to_func[MessageTypes.JOB_CONTRIBUTE_WORK] = null; // handled in JobManager
			type_to_func[MessageTypes.JOB_CREATE_NAME] = null; // handled in JobManager
			type_to_func[MessageTypes.JOB_LEADERBOARD] = do_JOB_LEADERBOARD;
			type_to_func[MessageTypes.JOB_REQ_STATE] = do_JOB_REQ_STATE;
			type_to_func[MessageTypes.JOB_STATUS] = do_JOB_STATUS;
			type_to_func[MessageTypes.JOB_STOP_WORK] = do_JOB_STOP_WORK;
			type_to_func[MessageTypes.LANTERN_HIDE] = do_LANTERN_HIDE;
			type_to_func[MessageTypes.LANTERN_SHOW] = do_LANTERN_SHOW;
			type_to_func[MessageTypes.LOC_CHECKMARK] = do_LOC_CHECKMARK;
			type_to_func[MessageTypes.LOCAL_CHAT_START] = null;
			type_to_func[MessageTypes.LOCAL_CHAT] = null;
			type_to_func[MessageTypes.LOCATION_DRAG_TARGETS] = null;
			type_to_func[MessageTypes.LOCATION_EVENT] = do_LOCATION_EVENT;
			type_to_func[MessageTypes.LOCATION_ITEM_MOVES] = null;
			type_to_func[MessageTypes.LOCATION_LOCK_RELEASE] = null;
			type_to_func[MessageTypes.LOCATION_LOCK_REQUEST] = null;
			type_to_func[MessageTypes.LOCATION_MOVE] = null;
			type_to_func[MessageTypes.LOCATION_ROOKED_STATUS] = do_LOCATION_ROOKED_STATUS;
			type_to_func[MessageTypes.LOGIN_END] = locationMoveEndHandler;
			type_to_func[MessageTypes.LOGIN_START] = do_LOGIN_START;
			type_to_func[MessageTypes.MAIL_ARCHIVE] = null;
			type_to_func[MessageTypes.MAIL_CANCEL] = null; //handled in the MailManager
			type_to_func[MessageTypes.MAIL_CHECK] = do_MAIL_CHECK;
			type_to_func[MessageTypes.MAIL_COST] = null; //handled in the MailManager
			type_to_func[MessageTypes.MAIL_DELETE] = null; //handled in the MailManager
			type_to_func[MessageTypes.MAIL_READ] = null; //handled in the MailManager
			type_to_func[MessageTypes.MAIL_RECEIVE] = null; //handled in the MailManager
			type_to_func[MessageTypes.MAIL_SEND] = null; //handled in the MailManager
			type_to_func[MessageTypes.MAIL_START] = do_MAIL_START;
			type_to_func[MessageTypes.MAKE_FAILED] = do_MAKE_FAILED;
			type_to_func[MessageTypes.MAKE_KNOWN_COMPLETE] = do_MAKE_KNOWN_COMPLETE;
			type_to_func[MessageTypes.MAKE_KNOWN] = null;
			type_to_func[MessageTypes.MAKE_UNKNOWN_COMPLETE] = do_MAKE_UNKNOWN_COMPLETE;
			type_to_func[MessageTypes.MAKE_UNKNOWN_MISSING] = do_MAKE_UNKNOWN_MISSING;
			type_to_func[MessageTypes.MAKE_UNKNOWN] = null;
			type_to_func[MessageTypes.MAKING_START] = do_MAKING_START;
			type_to_func[MessageTypes.MAP_GET] = do_MAP_GET;
			type_to_func[MessageTypes.MAP_OPEN_DELAYED] = do_MAP_OPEN_DELAYED;
			type_to_func[MessageTypes.MAP_OPEN] = do_MAP_OPEN;
			type_to_func[MessageTypes.MOVE_AVATAR] = do_MOVE_AVATAR;
			type_to_func[MessageTypes.MOVE_VEC] = null;
			type_to_func[MessageTypes.MOVE_XY] = do_MOVE_XY;
			type_to_func[MessageTypes.NEW_API_TOKEN] = do_NEW_API_TOKEN;
			type_to_func[MessageTypes.NEW_DAY] = do_NEW_DAY;
			type_to_func[MessageTypes.NEW_LEVEL] = do_NEW_LEVEL;
			type_to_func[MessageTypes.NO_ENERGY_MODE] = null;
			type_to_func[MessageTypes.NOTE_CLOSE] = null; //handled by NoteManager
			type_to_func[MessageTypes.NOTE_SAVE] = null; //handled by NoteManager
			type_to_func[MessageTypes.NOTE_VIEW] = do_NOTE_VIEW;
			type_to_func[MessageTypes.NOTICE_BOARD_ACTION] = null;
			type_to_func[MessageTypes.NOTICE_BOARD_START] = do_NOTICE_BOARD_START;
			type_to_func[MessageTypes.NOTICE_BOARD_STATUS] = do_NOTICE_BOARD_STATUS;
			type_to_func[MessageTypes.NPC_LOCAL_CHAT] = do_NPC_LOCAL_CHAT;
			type_to_func[MessageTypes.NUDGERY_START] = null;
			type_to_func[MessageTypes.OFFER_QUEST_NOW] = do_OFFER_QUEST_NOW;
			type_to_func[MessageTypes.OPEN_AVATAR_PICKER] = do_OPEN_AVATAR_PICKER;
			type_to_func[MessageTypes.OPEN_IMG_MENU] = do_OPEN_IMG_MENU;
			type_to_func[MessageTypes.OVERLAY_CANCEL] = do_OVERLAY_CANCEL;
			type_to_func[MessageTypes.OVERLAY_CLICK] = null;
			type_to_func[MessageTypes.OVERLAY_DISMISSED] = do_OVERLAY_DISMISSED;
			type_to_func[MessageTypes.OVERLAY_DONE] = null;
			type_to_func[MessageTypes.OVERLAY_OPACITY] = do_OVERLAY_OPACITY;
			type_to_func[MessageTypes.OVERLAY_SCALE] = do_OVERLAY_SCALE;
			type_to_func[MessageTypes.OVERLAY_STATE] = do_OVERLAY_STATE;
			type_to_func[MessageTypes.OVERLAY_TEXT] = do_OVERLAY_TEXT;
			type_to_func[MessageTypes.PARTY_ACTIVITY] = do_PARTY_ACTIVITY;
			type_to_func[MessageTypes.PARTY_ADD] = do_PARTY_ADD;
			type_to_func[MessageTypes.PARTY_CHAT] = null;
			type_to_func[MessageTypes.PARTY_INVITE] = null;
			type_to_func[MessageTypes.PARTY_JOIN] = do_PARTY_JOIN;
			type_to_func[MessageTypes.PARTY_LEAVE] = do_PARTY_LEAVE;
			type_to_func[MessageTypes.PARTY_OFFLINE] = do_PARTY_OFFLINE;
			type_to_func[MessageTypes.PARTY_ONLINE] = do_PARTY_ONLINE;
			type_to_func[MessageTypes.PARTY_REMOVE] = do_PARTY_REMOVE;
			type_to_func[MessageTypes.PARTY_SPACE_CHANGE] = do_PARTY_SPACE_CHANGE;
			type_to_func[MessageTypes.PARTY_SPACE_JOIN] = null;
			type_to_func[MessageTypes.PARTY_SPACE_RESPONSE] = null; //handled in PartySpaceManager
			type_to_func[MessageTypes.PARTY_SPACE_START] = do_PARTY_SPACE_START;
			type_to_func[MessageTypes.PC_DOOR_MOVE] = pcLocationMoveHandler;
			type_to_func[MessageTypes.PC_FOLLOW_MOVE] = pcLocationMoveHandler;
			type_to_func[MessageTypes.PC_GAME_FLAG_CHANGE] = do_PC_LOCATION_CHANGE;
			type_to_func[MessageTypes.PC_GROUPS_CHAT] = do_PC_GROUPS_CHAT;
			type_to_func[MessageTypes.PC_ITEMSTACK_VERB] = null;
			type_to_func[MessageTypes.PC_LEVEL_UP] = null; //// do somethign with {"level":4,"ts":"2011:6:9 19:10:53","type":"pc_level_up","tsid":"PM41015CDB1BB","label":"RIcky"},
			type_to_func[MessageTypes.PC_LOCAL_CHAT] = do_PC_LOCAL_CHAT;
			type_to_func[MessageTypes.PC_LOCATION_CHANGE] = do_PC_LOCATION_CHANGE;
			type_to_func[MessageTypes.PC_LOGIN] = pcLoginHandler;
			type_to_func[MessageTypes.PC_LOGOUT] = do_PC_LOGOUT;
			type_to_func[MessageTypes.PC_MENU] = null;
			type_to_func[MessageTypes.PC_MOVE_VEC] = do_PC_MOVE_VEC;
			type_to_func[MessageTypes.PC_MOVE_XY] = do_PC_MOVE_XY;
			type_to_func[MessageTypes.PC_PARTY_CHAT] = do_PC_PARTY_CHAT;
			type_to_func[MessageTypes.PC_PHYSICS_CHANGES] = do_PC_PHYSICS_CHANGES;
			type_to_func[MessageTypes.PC_RELOGIN] = pcLoginHandler;
			type_to_func[MessageTypes.PC_RENAME] = do_PC_RENAME;
			type_to_func[MessageTypes.PC_RS_CHANGE] = do_PC_LOCATION_CHANGE;
			type_to_func[MessageTypes.PC_SIGNPOST_MOVE] = pcLocationMoveHandler;
			type_to_func[MessageTypes.PC_TELEPORT_MOVE] = pcLocationMoveHandler;
			type_to_func[MessageTypes.PC_VERB_MENU] = null;
			type_to_func[MessageTypes.PERF_TELEPORT] = null;
			type_to_func[MessageTypes.PHYSICS_CHANGES] = do_PHYSICS_CHANGES;
			type_to_func[MessageTypes.PING] = null;
			type_to_func[MessageTypes.PLAY_DO] = do_PLAY_DO;
			type_to_func[MessageTypes.PLAY_EMOTION] = do_PLAY_EMOTION;
			type_to_func[MessageTypes.PLAY_HIT] = do_PLAY_HIT;
			type_to_func[MessageTypes.PLAY_MUSIC] = null;
			type_to_func[MessageTypes.POL_CHANGE] = do_POL_CHANGE;
			type_to_func[MessageTypes.POOF_IN] = do_POOF_IN;
			type_to_func[MessageTypes.PRELOAD_ITEM] = do_PRELOAD_ITEM;
			type_to_func[MessageTypes.PRELOAD_SWF] = do_PRELOAD_SWF;
			type_to_func[MessageTypes.PROMPT_CHOICE] = null;
			type_to_func[MessageTypes.PROMPT_REMOVE] = do_PROMPT_REMOVE;
			type_to_func[MessageTypes.PROMPT] = do_PROMPT;
			type_to_func[MessageTypes.QUEST_ACCEPTED] = do_QUEST_ACCEPTED;
			type_to_func[MessageTypes.QUEST_BEGIN] = do_QUEST_BEGIN;
			type_to_func[MessageTypes.QUEST_CONVERSATION_CHOICE] = do_QUEST_CONVERSATION_CHOICE;
			type_to_func[MessageTypes.QUEST_DIALOG_CLOSED] = do_QUEST_DIALOG_CLOSED;
			type_to_func[MessageTypes.QUEST_DIALOG_START] = do_QUEST_DIALOG_START;
			type_to_func[MessageTypes.QUEST_FAILED] = do_QUEST_FAILED;
			type_to_func[MessageTypes.QUEST_FINISHED] = do_QUEST_FINISHED;
			type_to_func[MessageTypes.QUEST_OFFERED] = do_QUEST_OFFERED;
			type_to_func[MessageTypes.QUEST_REMOVE] = do_QUEST_REMOVE;
			type_to_func[MessageTypes.QUEST_REQ_STATE] = do_QUEST_REQ_STATE;
			type_to_func[MessageTypes.RECIPE_REQUEST] = do_RECIPE_REQUEST;
			type_to_func[MessageTypes.RELOGIN_END] = locationMoveEndHandler;
			type_to_func[MessageTypes.RELOGIN_START] = do_RELOGIN_START;
			type_to_func[MessageTypes.RESNAP_MINIMAP] = do_RESNAP_MINIMAP;
			type_to_func[MessageTypes.ROOK_ATTACK] = do_ROOK_ATTACK;
			type_to_func[MessageTypes.ROOK_DAMAGE] = do_ROOK_DAMAGE;
			type_to_func[MessageTypes.ROOK_STUN] = do_ROOK_STUN;
			type_to_func[MessageTypes.ROOK_TEXT] = do_ROOK_TEXT;
			type_to_func[MessageTypes.SCREEN_VIEW_CLOSE] = null;
			type_to_func[MessageTypes.SERVER_MESSAGE] = null;
			type_to_func[MessageTypes.SET_PREFS] = do_SET_PREFS;
			type_to_func[MessageTypes.SHARE_TRACK] = null;
			type_to_func[MessageTypes.SHRINE_FAVOR_REQUEST] = null; // do nothing, handled by listener where the message is sent - ShrineManager.instance.spend(im.payload);
			type_to_func[MessageTypes.SHRINE_FAVOR_UPDATE] = do_SHRINE_FAVOR_UPDATE;
			type_to_func[MessageTypes.SHRINE_SPEND] = null; // do nothing, handled by listener where the message is sent - ShrineManager.instance.spend(im.payload);
			type_to_func[MessageTypes.SHRINE_START] = do_SHRINE_START;
			type_to_func[MessageTypes.SIGNPOST_CHANGE] = do_SIGNPOST_CHANGE;
			type_to_func[MessageTypes.SIGNPOST_MOVE_END] = locationMoveEndHandler;
			type_to_func[MessageTypes.SIGNPOST_MOVE_START] = do_SIGNPOST_MOVE_START;
			type_to_func[MessageTypes.SKILL_TRAIN_COMPLETE] = do_SKILL_TRAIN_COMPLETE;
			type_to_func[MessageTypes.SKILL_TRAIN_PAUSE] = do_SKILL_TRAIN_PAUSE;
			type_to_func[MessageTypes.SKILL_TRAIN_RESUME] = do_SKILL_TRAIN_START; //same as start
			type_to_func[MessageTypes.SKILL_TRAIN_START] = do_SKILL_TRAIN_START;
			type_to_func[MessageTypes.SKILL_UNLEARN_CANCEL] = do_SKILL_UNLEARN_CANCEL;
			type_to_func[MessageTypes.SKILL_UNLEARN_COMPLETE] = do_SKILL_UNLEARN_COMPLETE;
			type_to_func[MessageTypes.SKILL_UNLEARN_START] = do_SKILL_UNLEARN_START;
			type_to_func[MessageTypes.SKILLS_CAN_LEARN] = do_SKILLS_CAN_LEARN;
			type_to_func[MessageTypes.SNAP_AUTO] = do_SNAP_AUTO;
			type_to_func[MessageTypes.SNAP_TRAVEL_FORGET] = null;
			type_to_func[MessageTypes.SNAP_TRAVEL_SCREEN] = do_SNAP_TRAVEL_SCREEN;
			type_to_func[MessageTypes.SNAP_TRAVEL] = null;
			type_to_func[MessageTypes.SPLASH_SCREEN_BUTTON_PAYLOAD] = null;
			type_to_func[MessageTypes.STAT_MAX_CHANGED] = do_STAT_MAX_CHANGED;
			type_to_func[MessageTypes.STORE_BUY] = null;
			type_to_func[MessageTypes.STORE_CHANGED] = do_STORE_CHANGED;
			type_to_func[MessageTypes.STORE_END] = do_STORE_END;
			type_to_func[MessageTypes.STORE_SELL_CHECK] = null;
			type_to_func[MessageTypes.STORE_SELL] = null;
			type_to_func[MessageTypes.STORE_START] = do_STORE_START;
			type_to_func[MessageTypes.TELEPORT_MOVE_END] = do_TELEPORT_MOVE_END;
			type_to_func[MessageTypes.TELEPORT_MOVE_START] = do_TELEPORT_MOVE_START;
			type_to_func[MessageTypes.TELEPORTATION_GO] = null;
			type_to_func[MessageTypes.TELEPORTATION_MAP] = null;
			type_to_func[MessageTypes.TELEPORTATION_SCRIPT_CREATE] = null; //handled in TeleportationScriptManager
			type_to_func[MessageTypes.TELEPORTATION_SCRIPT_IMBUE] = null; //handled in TeleportationScriptManager
			type_to_func[MessageTypes.TELEPORTATION_SCRIPT_USE] = null; //handled in TeleportationScriptManager
			type_to_func[MessageTypes.TELEPORTATION_SCRIPT_VIEW] = do_TELEPORTATION_SCRIPT_VIEW;
			type_to_func[MessageTypes.TELEPORTATION_SET] = null;
			type_to_func[MessageTypes.TELEPORTATION] = do_TELEPORTATION;
			type_to_func[MessageTypes.TIME_PASSES] = null;
			type_to_func[MessageTypes.TOWER_CHANGE_CHASSIS_START] = do_TOWER_CHANGE_CHASSIS_START;
			type_to_func[MessageTypes.TOWER_SET_FLOOR_NAME] = null; //handled in the LocationSelectorDialog
			type_to_func[MessageTypes.TOWER_SET_NAME] = null;
			type_to_func[MessageTypes.TRADE_ACCEPT] = do_TRADE_ACCEPT;
			type_to_func[MessageTypes.TRADE_ADD_ITEM] = do_TRADE_ADD_ITEM;
			type_to_func[MessageTypes.TRADE_CANCEL] = do_TRADE_CANCEL;
			type_to_func[MessageTypes.TRADE_CHANGE_ITEM] = do_TRADE_CHANGE_ITEM;
			type_to_func[MessageTypes.TRADE_CHANNEL_ENABLE] = do_TRADE_CHANNEL_ENABLE;
			type_to_func[MessageTypes.TRADE_COMPLETE] = do_TRADE_COMPLETE;
			type_to_func[MessageTypes.TRADE_CURRANTS] = do_TRADE_CURRANTS;
			type_to_func[MessageTypes.TRADE_REMOVE_ITEM] = do_TRADE_REMOVE_ITEM;
			type_to_func[MessageTypes.TRADE_START] = do_TRADE_START;
			type_to_func[MessageTypes.TRADE_UNLOCK] = do_TRADE_UNLOCK;
			type_to_func[MessageTypes.TRANSIT_STATUS] = do_TRANSIT_STATUS;
			type_to_func[MessageTypes.TROPHY_END] = do_TROPHY_END;
			type_to_func[MessageTypes.TROPHY_START] = do_TROPHY_START;
			type_to_func[MessageTypes.UI_CALLOUT_CANCEL] = do_UI_CALLOUT_CANCEL;
			type_to_func[MessageTypes.UI_CALLOUT] = do_UI_CALLOUT;
			type_to_func[MessageTypes.UI_VISIBLE] = do_UI_VISIBLE;
			type_to_func[MessageTypes.UPDATE_HELP_CASE] = do_UPDATE_HELP_CASE;
			type_to_func[MessageTypes.VIEWPORT_ORIENTATION] = do_VIEWPORT_ORIENTATION;
			type_to_func[MessageTypes.VIEWPORT_SCALE] = do_VIEWPORT_SCALE;
			type_to_func[MessageTypes.LOGOUT] = null;

			
			CONFIG::debugging {
				var MessageTypesXML:XML = describeType(MessageTypes);
				var null_str:String = '';
				var const_name:String;
				var msg_type:String;
				
				// iterate over static constants on the class, which are our message types
				for each (var c:XML in MessageTypesXML.constant) {
					msg_type = MessageTypes[c.@name];
					
					// make sure we have an entry for the message type
					if (msg_type in type_to_func) {
						if (type_to_func[msg_type] == null) {
							// this is fine, it is set to null so we don't do anything with it
							null_str+= ' '+msg_type;
						}
					} else {
						Console.error('there is no entry in type_to_func for '+msg_type+' !!!!! make it = null if you don\'t want to do anything with the message');
					}
				}
				
				if (null_str) {
					Console.info('these message types are set to go to null, which is fine, I\'m just saying:\n'+null_str);
				}
			}
		}
		
		// we handle all msgs of type *_end with this
		private function locationMoveEndHandler(im:NetIncomingMessageVO):void {
			Benchmark.addCheck('NC.locationMoveEndHandler before parsing: '+im.type);
			var payload:Object = im.payload;
			var world:WorldModel = world;
			var loc:Location = world.location;
			var k:String;
			var pc:PC;
			var pcs:Object;
			var itemstacks:Object;
			
			// reset
			loc.pc_tsid_list = new Dictionary();
			loc.itemstack_tsid_list = new Dictionary();
			TransitManager.instance.clear();
			
			if (payload.location) {
				if (payload.location.pcs){
					pcs = payload.location.pcs;
					for (k in pcs) {
						pc = world.upsertPc(pcs[k]);
						pc.online = true;
						
						CONFIG::god {
							// stick in a dot to show where the GS says your avatar is
							if (k == world.pc.tsid) {
								model.activityModel.dots_to_draw = {clear:true, coords:[[pc.x, pc.y]]};
							}	
						}
						
						loc.pc_tsid_list[k] = k;
						Benchmark.addCheck('PC: '+pc.label+' '+pc.tsid);
					}
					delete payload.location.pcs;
				}
				
				var g:String;
				if (payload.location.itemstacks){
					itemstacks = payload.location.itemstacks;
					for (k in itemstacks) {
						if (itemstacks[k].itemstacks) {
							for (g in itemstacks[k].itemstacks) {
								if (world.getItemstackByTsid(g)) {
									world.itemstacks[g] = Itemstack.updateFromAnonymous(itemstacks[k].itemstacks[g], world.getItemstackByTsid(g));
								} else {
									if (!Item.confirmValidClass(itemstacks[k].itemstacks[g].class_tsid, g)) {
										continue;
									}
									world.itemstacks[g] = Itemstack.fromAnonymous(itemstacks[k].itemstacks[g], g);
								}
								loc.itemstack_tsid_list[g] = g;
								
							}
							delete itemstacks[k].itemstacks;
							
						}
						if (world.getItemstackByTsid(k)) {
							world.itemstacks[k] = Itemstack.updateFromAnonymous(itemstacks[k], world.getItemstackByTsid(k));
						} else {
							if (!Item.confirmValidClass(itemstacks[k].class_tsid, k)) {
								continue;
							}
							world.itemstacks[k] = Itemstack.fromAnonymous(itemstacks[k], k);
						}
						loc.itemstack_tsid_list[k] = k;
						Benchmark.addCheck('STACK: '+world.itemstacks[k].label+' '+world.itemstacks[k].tsid);
					}
					delete payload.location.itemstacks;
				}
				
				if (payload.location.tsid){
					delete payload.location.tsid;
				}
				
				CONFIG::debugging {
					for(k in payload.location){
						if (k.indexOf('__') != 0) Console.warn("Not parsing yet in payload.location: "+ k +' '+ payload.location[k]);
					}
				}
				
				delete payload.location;
			}
			
			if (payload.relogin_type) delete payload.relogin_type;
			
			if(payload.teleportation){
				TeleportationManager.instance.update(payload.teleportation);
				delete payload.teleportation;
			}
			
			//is the player dead?
			if('is_dead' in payload){
				world.pc.is_dead = payload.is_dead;
				delete payload.is_dead;
			}
			
			//set the PCs previous location
			if('previous_location' in payload){
				loc = world.getLocationByTsid(payload.previous_location.tsid);
				if(!loc){
					//add it to the world
					loc = new Location(payload.previous_location.tsid);
					loc.tsid = payload.previous_location.tsid;
					loc.label = payload.previous_location.name;
					world.locations[loc.tsid] = loc;
				}
				
				//update the map info
				loc.mapInfo = MapInfo.fromAnonymous(payload.previous_location);
				
				//set the tsid on the player
				world.pc.previous_location_tsid = loc.tsid;
				delete payload.previous_location;
			}
			
			CONFIG::debugging {
				for(k in payload){
					if (k.indexOf('__') != 0) Console.warn("Not parsing yet in payload: "+ k +' '+ payload[k]);
				}
			}
			
			//if we have music playing, stop it
			if(model.moveModel.loading_music){
				SoundMaster.instance.stopSound(model.moveModel.loading_music, 1);
			}
			model.moveModel.loading_music = '';
			
			model.moveModel.relogin = false;
			Benchmark.addCheck('NC.locationMoveEndHandler after parsing: '+im.type);
			nc.moveHasEnded('locationMoveEndHandler');
			CONFIG::debugging {
				nc.logTsidLists();
			}
			/*
			setTimeout(TSFrontController.instance.simulateIncomingMsg, 10, {
				"type":"location_event",
				"announcements":[
					{
						"type":"location_overlay",
						"x":1037,
						"swf_url":"http://c2.glitch.bz/overlays/2011-09-01/1314921210_3043.swf",
						"y":-179,
						"msg":"Displaying phantom Glitch.",
						"under_decos":true,
						"uid":"phantom_glitch",
						"mouse":{
							"is_clickable":true,
							"dismiss_on_click":false,
							"click_payload":{
								"quest_callback":"clickPhantom",
								"pc_tsid":"PIF1SSTQT4T70"
							},
							"allow_multiple_clicks":false
						}
					}
				]
			})
			*/
		}
				
		// we handle all msgs of pc_login with this
		private function pcLoginHandler(im:NetIncomingMessageVO):void {
			if (im.payload.pc) {
				//update the model
				const pc_data:Object = im.payload.pc;
				const pc:PC = world.upsertPc(pc_data);
				pc.online = true;
				
				if (pc.location.tsid == world.location.tsid) {
					world.location.pc_tsid_list[pc.tsid] = pc.tsid;
					world.loc_pc_adds = [pc.tsid];
				}
				
				//update the right side chats if they are open
				RightSideManager.instance.pcStatus(pc.tsid);
				
				//update the player info window if it's open
				PlayerInfoDialog.instance.playerUpdate(pc.tsid);
			}
		}
		
		// we handle all msgs of pc_*_move with this
		private function pcLocationMoveHandler(im:NetIncomingMessageVO):void {
			if (im.payload.pc) {
				const pc_data:Object = im.payload.pc;
				const pc:PC = world.upsertPc(pc_data);
				pc.online = true;
				
				// if the im.payload.pc == world.location.tsid then the user has entered
				// if not, the user has left
				if (pc.location.tsid == world.location.tsid) {
					world.location.pc_tsid_list[pc.tsid] = pc.tsid;
					world.loc_pc_adds = [pc.tsid];
				} else {
					if (world.location.pc_tsid_list[pc.tsid]) {
						delete world.location.pc_tsid_list[pc.tsid];
					}
					world.loc_pc_dels = [pc.tsid];
				}
			}
		}
		
		private function do_PC_MOVE_XY(im:NetIncomingMessageVO):void {
			if (model.flashVarModel.use_vec) return;
			if (!im.payload.pc) return;
			
			var pc:PC = world.upsertPc(im.payload.pc);
			if (pc) world.loc_pc_updates = [pc.tsid]; // calls a trigger when set
		}
		
		private function do_PC_MOVE_VEC(im:NetIncomingMessageVO):void {
			if (!model.flashVarModel.use_vec)  
			if (!im.payload.pc) return;
			if (im.payload.pc.tsid == world.pc.tsid) return;
			
			var pc:PC = world.upsertPc(im.payload.pc);
			if (pc) world.loc_pc_updates = [pc.tsid]; // calls a trigger when set
			
			// do some logging
			CONFIG::god {
				if (!pc.tsid in nc.move_vec_count_hash) nc.move_vec_count_hash[pc.tsid] = 0;
				nc.move_vec_count_hash[pc.tsid]++;
			}
		}
		
		private function do_LOGIN_START(im:NetIncomingMessageVO):void {
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_no_login') == '1') return;
			if (!LoginTool.reportStep(10, 'nc_got_login_start')) return;
			model.netModel.should_reconnect = true; // if we've logged in, after a disconnect we should by default reconnect
			nc.remembered_login_start_im = im; // remember this, TSFC will call back to doLoginStartHandlerAfterLoading which will sent it to loginStartHandler
			TSFrontController.instance.endLoginProgressDisplay();
		}
		
		private function do_DUMP_DATA(im:NetIncomingMessageVO):void {
			var error_str:String = ''+
				'\n\nMessageTypes.DUMP_DATA ADDING BENCHMARK DETAILS:\n\n'+Benchmark.getShortLog()+
				'\n\nMessageTypes.DUMP_DATA ADDING DECO LOADING DETAILS:\n\n'+model.stateModel.getDecoCountReport()+
				'\n\nMessageTypes.DUMP_DATA ADDING MSGS:\n----------------------------------------------------\n\n'+BootError.buildMsgsString();
			
			API.reportError(error_str, 'DUMP_DATA', true, '', '', ['dump'],
				function(success:Boolean, ret_error_id:String, ret_case_id:String):void {
					if (success && ret_error_id) {
						API.attachErrorImageToError(ret_error_id, TSFrontController.instance.getMainView());
					}
				}
			);
		}
		
		private function do_FORCE_RELOAD(im:NetIncomingMessageVO):void {
			// check whether we need to reload
			if (!EnvironmentUtil.clientVersionIsBetween(im.payload.after_revision, im.payload.before_revision)) return;
			
			CONFIG::locodeco {
				if (model.stateModel.editing) {
					model.activityModel.god_message = 'CLIENTS HAVE BEEN ASKED TO RELOAD. But you are editing so I won\'t force it on you.';
					return;
				}
			}
			
			model.netModel.reload_message = im.payload.msg || '';
			
			if (im.payload.at_next_move) {
				Benchmark.addCheck('NC msg type:'+MessageTypes.FORCE_RELOAD+' at_next_move:true');
				model.netModel.should_reload_at_next_location_move = true;
				
				var softReloadTimeoutInMinutes:int = parseInt(im.payload.timeout);
				if (isNaN(softReloadTimeoutInMinutes)) softReloadTimeoutInMinutes = 0;
				if (softReloadTimeoutInMinutes > 0) {
					// set a countdown to hard-reload after the timeout
					StageBeacon.setTimeout(nc.reloadClient, softReloadTimeoutInMinutes*60*1000);
				}
				
				//toss a buff there if we can see the imagination menu
				if(world.location && !world.location.no_imagination){
					world.pc.buffs['game_update'] = PCBuff.fromAnonymous({
						"is_debuff":true,
						"duration": (softReloadTimeoutInMinutes * 60),
						"is_timer": (softReloadTimeoutInMinutes > 0),
						"name":"Reload is Coming",
						"tsid":"game_update",
						"desc":"The world will be reloaded the next time you change locations. This is why: " + model.netModel.reload_message
					}, "game_update");
					world.buff_adds = ['game_update'];
				}
			} else {
				// immediately
				nc.reloadClient();
			}
		}
		
		private function do_BOOTED(im:NetIncomingMessageVO):void {
			model.netModel.disconnected_msg = im.payload.msg || 'You have been booted.';
			DisconnectedScreenView.instance.show(model.netModel.disconnected_msg, 0);
			StageBeacon.setTimeout(navigateToURL, 5000, new URLRequest(im.payload.url), '_self');
		}
		
		private function do_DRAWDOTS(im:NetIncomingMessageVO):void {
			model.activityModel.dots_to_draw = im.payload;
		}
		
		private function do_DRAWPOLY(im:NetIncomingMessageVO):void {
			model.activityModel.poly_to_draw = im.payload;
		}
		
		private function do_SET_PREFS(im:NetIncomingMessageVO):void {
			model.prefsModel.updateFromAnonymous(im.payload.prefs);
		}
		
		private function do_IS_AFK(im:NetIncomingMessageVO):void {
			// myles will tell me what to do with these!
			//  {"type":"is_afk","afk":false,"pc":"PMF16PJ4LCB2BGM"}
		}
		
		private function do_HI_EMOTE_VARIANT_WINNER(im:NetIncomingMessageVO):void {
			world.yesterdays_hi_emote_variant_winner_count = im.payload.count;
			
			if (im.payload.top_infector_pc) {
				world.upsertPc(im.payload.top_infector_pc);
			}
			
			world.yesterdays_hi_emote_top_infector_count = im.payload.top_infector_count;
			world.yesterdays_hi_emote_top_infector_tsid = im.payload.top_infector_tsid;
			world.yesterdays_hi_emote_top_infector_variant = im.payload.top_infector_variant;
			world.yesterdays_hi_emote_variant_winner = im.payload.variant; // fires a signal when set
		}
		
		private function do_HI_EMOTE_VARIANT_SET(im:NetIncomingMessageVO):void {
			world.pc.hi_emote_variant = im.payload.variant;
			world.hi_emote_variant_sig.dispatch();
		}
		
		private function do_HI_EMOTE_LEADERBOARD(im:NetIncomingMessageVO):void {
			world.hi_emote_leaderboard = im.payload.leaderboard; // fires a signal when set
		}
		
		private function do_GET_ITEM_ASSET(im:NetIncomingMessageVO):void {
			var item:Item = world.getItemByTsid(im.payload.item_class);
			if (item) {
				item.is_fetching_missing_asset = false;
				item.has_fetched_missing_asset = true;
				item.has_fetched_placement = true;
				item.missing_asset = im.payload.asset_str;
				if (im.payload.position) {
					item.setPlacementRect(im.payload.position);
				}
			}
		}
		
		private function do_GET_ITEM_PLACEMENT(im:NetIncomingMessageVO):void {
			var item:Item = world.getItemByTsid(im.payload.item_class);
			if (item) {
				item.is_fetching_placement = false;
				item.has_fetched_placement = true;
				if (im.payload.position) {
					item.setPlacementRect(im.payload.position);
				}
			}
		}
		
		private function do_DECO_SIGN_TXT(im:NetIncomingMessageVO):void {
			TSFrontController.instance.changeDecoSignText(im.payload.deco_name, im.payload.txt, im.payload.css_class)
		}
		
		private function do_DECO_VISIBILITY(im:NetIncomingMessageVO):void {
			if (im.payload.deco_name) {
				if (im.payload.deco_name.indexOf('Teleporter_Beam') == 0) {
					if (im.payload.visible) {
						NewxpLogger.log('show_teleporter_beam');
					} else {
						NewxpLogger.log('hide_teleporter_beam');
					}
				}
			}
			TSFrontController.instance.changeDecoVisibility(im.payload.deco_name, im.payload.visible, im.payload.fade_ms)
		}
		
		private function do_LOC_CHECKMARK(im:NetIncomingMessageVO):void {
			if (im.payload.txt) {
				TSFrontController.instance.showLocationCheckListView();
				if (im.payload.deco_name) {
					LocationCheckListView.instance.addListItemFromDeco(im.payload.txt, im.payload.deco_name);
				} else if (im.payload.annc_uid) {
					LocationCheckListView.instance.addListItemFromAnnc(im.payload.txt, im.payload.annc_uid);
				} else {
					LocationCheckListView.instance.addListItemFromVPCenter(im.payload.txt);
				}
			}
		}
		
		private function do_POOF_IN(im:NetIncomingMessageVO):void {
			if (im.payload.itemstack_tsid) {
				world.poof_ins[im.payload.itemstack_tsid] = im.payload.swf_url;
			}
		}
		
		private function do_FOLLOW_END(im:NetIncomingMessageVO):void {
			world.pc.following_pc_tsid = '';
		}
		
		private function do_BUFF_START(im:NetIncomingMessageVO):void {
			var buff_tsid:String = im.payload.tsid;
			var buff:PCBuff;
			if (buff_tsid in world.pc.buffs && !world.pc.buffs[buff_tsid].client::removed) {
				// we already have this, so treat is as an update
				buff = world.pc.buffs[buff_tsid] = PCBuff.updateFromAnonymous(im.payload, world.pc.buffs[buff_tsid]);
				buff.client::removed = false;
				world.buff_updates = [buff_tsid];
			} else {
				//set the remaining duration to be the total duration
				if('duration' in im.payload) im.payload.remaining_duration = Math.floor(im.payload.duration);
				buff = world.pc.buffs[buff_tsid] = PCBuff.fromAnonymous(im.payload, buff_tsid);
				buff.client::removed = false;
				world.buff_adds = [buff_tsid];
			}
		}
		
		private function do_BUFF_UPDATE(im:NetIncomingMessageVO):void {
			var buff_tsid:String = im.payload.tsid;
			var buff:PCBuff;
			if (buff_tsid in world.pc.buffs) {
				buff = world.pc.buffs[buff_tsid] = PCBuff.updateFromAnonymous(im.payload, world.pc.buffs[buff_tsid]);
				buff.client::removed = false;
				world.buff_updates = [buff_tsid];
			} else {
				;//blarg
				CONFIG::debugging {
					Console.warn('buff_update for unknown buff');
					Console.dir(im.payload);
				}
			}
			
		}
		
		private function do_BUFF_REMOVE(im:NetIncomingMessageVO):void {
			var buff_tsid:String = im.payload.tsid;
			if (buff_tsid in world.pc.buffs) {
				world.pc.buffs[buff_tsid].client::removed = true;
				world.buff_dels = [buff_tsid];
			} else {
				CONFIG::debugging {
					Console.warn('buff_remove for unknown buff');
					Console.dir(im.payload);
				}
			}
		}
		
		private function do_ACHIEVEMENT_COMPLETE(im:NetIncomingMessageVO):void {
			TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
				AchievementView.instance.show,
				im.payload,
				true
			));
		}
		
		private function do_GIANT_SCREEN(im:NetIncomingMessageVO):void {
			TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
				GiantView.instance.show,
				im.payload,
				true
			));
		}
		
		private function do_SNAP_TRAVEL_SCREEN(im:NetIncomingMessageVO):void {
			TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
				SnapTravelView.instance.show,
				im.payload,
				true
			));
		}
		
		private function do_NEW_LEVEL(im:NetIncomingMessageVO):void {
			PC.updateFromAnonymous({stats:im.payload.stats}, world.pc); // a quick hack to get the PCStats updated
			if (!im.payload.do_not_annc) {
				TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
					LevelUpView.instance.show,
					im.payload,
					true
				));
			}
		}
		
		private function do_STAT_MAX_CHANGED(im:NetIncomingMessageVO):void {
			PC.updateFromAnonymous({stats:im.payload.stats}, world.pc); // a quick hack to get the PCStats updated
		}
		
		private function do_GO_URL(im:NetIncomingMessageVO):void {
			//{"type":"go_url","url":"/customize/PM410N97M59K3/"}
			var url:String = im.payload.url;
			if (url.indexOf('/') == 0) {
				var root_url:String = model.flashVarModel.root_url;
				// if root_url ends with a slash, remove the slash
				if (root_url.substr(-1, 1) == '/') root_url = root_url.substr(0, root_url.length-1);
				url = root_url+url;
			} 
			if (im.payload.new_window) {/*
				2011/08/22 REMOVED THIS BECAUSE I THING CHROME WINDOW OPENING WORKS NOW IN LATEST BUILDS
				
				if (EnvironmentUtil.is_chrome && false) {
				navigateToURL(new URLRequest(url), im.payload.new_window);
				} else {*/
				JS_interface.instance.call_JS({
					meth: 'open_window',
					params: {
						name: im.payload.new_window,
						url: url
					}
				})
				/*}*/
			} else {
				navigateToURL(new URLRequest(url), '_self');
			}
			
		}
		
		private function do_PC_LOCATION_CHANGE(im:NetIncomingMessageVO):void {
			if (im.payload && im.payload.pc) {
				var pc:PC = world.upsertPc(im.payload.pc);
				RightSideManager.instance.buddyUpdate(pc.tsid);
				
				if (im.type == MessageTypes.PC_RS_CHANGE || im.type == MessageTypes.PC_GAME_FLAG_CHANGE) {
					if (pc && pc.location.tsid == world.location.tsid) world.loc_pc_updates = [pc.tsid]; // calls a trigger when set
				}
			}
		}
		
		private function do_OFFER_QUEST_NOW(im:NetIncomingMessageVO):void {
			var quest:Quest = world.getQuestById(im.payload.quest_id);
			if (quest) {
				TSFrontController.instance.startFamiliarConversationWithPayload(quest.offer_conversation, true);
			} else {
				CONFIG::debugging {
					Console.warn('unknown quest :'+im.payload.quest_id)
				}
			}
		}
		
		private function do_QUEST_BEGIN(im:NetIncomingMessageVO):void {
			//TODO these should be handled by callbacks passed to frontcontroller
			QuestManager.instance.questBeginHandler(im as NetResponseMessageVO);
		}
		
		private function do_QUEST_CONVERSATION_CHOICE(im:NetIncomingMessageVO):void {
			//TODO these should be handled by callbacks passed to frontcontroller
			QuestManager.instance.questConversationCompleteHandler(im as NetResponseMessageVO);
		}
		
		private function do_QUEST_ACCEPTED(im:NetIncomingMessageVO):void {
			QuestManager.instance.questAcceptedHandler(im);
		}
		
		private function do_QUEST_OFFERED(im:NetIncomingMessageVO):void {
			QuestManager.instance.questOfferedHandler(im);
		}
		
		private function do_QUEST_REQ_STATE(im:NetIncomingMessageVO):void {
			QuestManager.instance.questRequirementHandler(im.payload);
		}
		
		private function do_QUEST_FINISHED(im:NetIncomingMessageVO):void {
			QuestManager.instance.questFinishedHandler(im);
		}
		
		private function do_QUEST_FAILED(im:NetIncomingMessageVO):void {
			QuestManager.instance.questFailedHandler(im);
		}
		
		private function do_QUEST_REMOVE(im:NetIncomingMessageVO):void {
			QuestManager.instance.questRemoveHandler(im.payload);
		}
		
		private function do_MAP_GET(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			
			// only if it is not a response, because those are handled in HubMapDialog
			if (!nrm && im.payload.hub_id && im.payload.mapData) {
				var hub:Hub = world.hubs[im.payload.hub_id];
				if (hub) {
					/*for (var hh:* in im.payload.mapData.objs) {
					im.payload.mapData.objs[hh].type = 'SL';
					}*/
					
					//if we got an "all" hash, update the world
					if(im.payload.mapData.all){
						Hub.updateFromMapDataAll(im.payload.mapData);
					}
					
					//if we got a "transit" hash, update the world
					if(im.payload.mapData.transit){
						Transit.updateFromMapDataTransit(im.payload.mapData);
					}
					
					if(hub.map_data){
						hub.map_data = MapData.updateFromAnonymous(im.payload.mapData, hub.map_data);
					}
					else {
						hub.map_data = MapData.fromAnonymous(im.payload.mapData);
					}
					
					HubMapDialog.instance.updateMapIfShowingHub(hub.tsid);
					HubMapDialog.instance.loadWorldMapIfNeeded(hub.map_data.world_map);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('unknown hub :'+im.payload.hub_id)
					}
				}
			}
			
		}
		
		private function do_GET_PATH_TO_LOCATION(im:NetIncomingMessageVO):void {
			if (im.payload.path_info && im.payload.path_info.path){
				model.stateModel.current_path = MapPathInfo.fromAnonymous(im.payload.path_info);
				
				if (im.payload.path_info.path is Array && im.payload.path_info.path.length > 1) {
					if (im.payload.path_info.destination) {
						Location.fromAnonymousLocationStub(im.payload.path_info.destination);
					}
				}
				
				//start showing the path!
				TSFrontController.instance.startLocationPath(im.payload.path_info.path);
			}
		}
		
		private function do_CLEAR_LOCATION_PATH(im:NetIncomingMessageVO):void {
			model.stateModel.current_path = null;
			TSFrontController.instance.clearLocationPath();
		}
		
		private function do_PC_RENAME(im:NetIncomingMessageVO):void {
			if (im.payload.pc) {
				var pc:PC = world.upsertPc(im.payload.pc);
			}
			YouDisplayManager.instance.updatePCName(pc ? pc.tsid : '');
		}
		
		private function do_IM_RECV(im:NetIncomingMessageVO):void {
			var pc:PC;
			var itemstack:Itemstack;
			var tsid:String;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.online = true;
				tsid = pc.tsid;
			}
			
			if (im.payload.itemstack){
				itemstack = world.upsertItemstack(im.payload.itemstack);
				tsid = itemstack.tsid;
			}
			
			CONFIG::god {
				// for automated snapshot taking
				if (im.payload.txt == 'take_snap') {
					// plloyd: can you do a /buffless before every snap
					TSFrontController.instance.sendLocalChat(
						new NetOutgoingLocalChatVO('/buffless')
					);
					// plloyd: can you just call /make_traps_go_now  one second before you take snap shots?
					// plloyd: that will reset any dust traps that go boing when player enters
					TSFrontController.instance.sendLocalChat(
						new NetOutgoingLocalChatVO('/make_traps_go_now')
					);
					// plloyd: can you do a /max also
					TSFrontController.instance.sendLocalChat(
						new NetOutgoingLocalChatVO('/max')
					);
					StageBeacon.setTimeout(function():void {
						TSFrontController.instance.saveLocationLoadingImg(false, function ():void {
							// tell plloyd that we're done
							TSFrontController.instance.genericSend(
								new NetOutgoingImSendVO(pc.tsid, 'snap_taked')
							);
						});
					}, 1000);
				}
			}
			
			if('force' in im.payload && im.payload.force === true && !(StageBeacon.stage.focus is TextField)){
				//bring it to the front
				RightSideManager.instance.chatStart(tsid, true, false);
			}
			
			RightSideManager.instance.chatUpdate(tsid, tsid, im.payload.txt);
			
		}
		
		private function do_IM_CLOSE(im:NetIncomingMessageVO):void {
			var pc:PC;
			var itemstack:Itemstack;
			var tsid:String;
			
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				tsid = pc.tsid;
			}
			
			if (im.payload.itemstack){
				itemstack = world.upsertItemstack(im.payload.itemstack);
				tsid = itemstack.tsid;
			}
			
			//try and close the chat
			RightSideManager.instance.chatEnd(tsid);
		}
		
		private function do_PROMPT(im:NetIncomingMessageVO):void {
			if (im.payload.uid) {
				model.activityModel.addPrompt(Prompt.fromAnonymous(im.payload));
			}
		}
		
		private function do_PROMPT_REMOVE(im:NetIncomingMessageVO):void {
			if (im.payload.uid) {
				model.activityModel.removePrompt(im.payload.uid);
			}
		}
		
		private function do_PARTY_SPACE_CHANGE(im:NetIncomingMessageVO):void {
			var party:PCParty = world.party;
			Benchmark.addCheck('recv: '+im.type+' '+ StringUtil.getJsonStr(im.payload));
			if (!party) {
				Benchmark.addCheck('CANT CHANGE PARTY, NOT IN PARTY');
				CONFIG::debugging {
					Console.error('CANT CHANGE PARTY, NOT IN PARTY');
				}
			}
			party.space_tsids = im.payload.space_tsids || [];
		}
		
		private function do_PARTY_LEAVE(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			Benchmark.addCheck('recv: '+im.type+' '+ StringUtil.getJsonStr(im.payload));
			if (nrm && !nrm.success) return; // if it is a fail response to a message we sent, ignore.
			
			// if we're here it must be an event.
			world.party = null; // calls a trigger when set
		}
		
		private function do_PARTY_JOIN(im:NetIncomingMessageVO):void {
			var party:PCParty = world.party;
			Benchmark.addCheck('recv: '+im.type);
			if (!party) {
				nc.handleBeingInAParty(im.payload);
			} else {
				Benchmark.addCheck('ALREADY IN PARTY');
			}
		}
		
		private function do_PARTY_ADD(im:NetIncomingMessageVO):void {
			var pc:PC;
			var party:PCParty = world.party;
			CONFIG::debugging {
				if (!party) {
					Console.error('CANT ADD TO PARTY, NOT IN PARTY');
				}
			}
			
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				if (party.member_tsids.indexOf(pc.tsid) > -1) return; // already in party
				if (pc.tsid == party.tsid) return; //don't add yourself
				party.member_tsids.push(pc.tsid);
				world.party_member_adds = [pc.tsid]; // calls a trigger when set
			}
		}
		
		private function do_PARTY_REMOVE(im:NetIncomingMessageVO):void {
			var party:PCParty = world.party;
			CONFIG::debugging {
				if (!party) {
					Console.error('CANT REMOVE FROM PARTY, NOT IN PARTY');
				}
			}
			
			if (im.payload.pc_tsid && world.getPCByTsid(im.payload.pc_tsid)) {
				var i:int = party.member_tsids.indexOf(im.payload.pc_tsid);
				if (i>-1) {
					party.member_tsids.splice(i, 1); // remove it
					world.party_member_dels = [im.payload.pc_tsid]; // calls a trigger when set
				}
			}
			
		}
		
		private function do_PARTY_ONLINE(im:NetIncomingMessageVO):void {
			var party:PCParty = world.party;
			var pc:PC;
			CONFIG::debugging {
				if (!party) {
					Console.error('CANT MARK ONLINE IN PARTY, NOT IN PARTY');
				}
			}
			
			if (im.payload.pc_tsid) {
				pc = world.getPCByTsid(im.payload.pc_tsid);
				if(pc){
					pc.online = true;
					world.party_member_updates = [pc.tsid]; // calls a trigger when set
				}
			}
			
		}
		
		private function do_PARTY_OFFLINE(im:NetIncomingMessageVO):void {
			var party:PCParty = world.party;
			var pc:PC;
			CONFIG::debugging {
				if (!party) {
					Console.error('CANT MARK OFFLINE IN PARTY, NOT IN PARTY');
				}
			}
			
			if (im.payload.pc_tsid) {
				pc = world.getPCByTsid(im.payload.pc_tsid);
				if(pc){
					pc.online = false;
					world.party_member_updates = [pc.tsid]; // calls a trigger when set
				}
			}
			
			
		}
		
		private function do_IM_SEND(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			var pc_tsid:String = NetOutgoingImSendVO(nrm.request).pc_tsid;
			var itemstack_tsid:String = NetOutgoingImSendVO(nrm.request).itemstack_tsid;
			
			if (pc_tsid && world.getPCByTsid(pc_tsid)) {
				if(RightSideManager.instance.right_view.getChatArea(pc_tsid)){
					RightSideManager.instance.chatUpdate(pc_tsid, world.pc.tsid, nrm.payload.txt);
				}
				else if(TradeDialog.instance.visible && TradeManager.instance.player_tsid == pc_tsid){
					TradeDialog.instance.addChatElement(world.pc.tsid, nrm.payload.txt);
				}
			} else if (itemstack_tsid && world.getItemstackByTsid(itemstack_tsid)) {
				RightSideManager.instance.chatUpdate(itemstack_tsid, world.pc.tsid, nrm.payload.txt);
			}
		}
		
		private function do_PC_PARTY_CHAT(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.online = true;
				RightSideManager.instance.chatUpdate(ChatArea.NAME_PARTY, pc.tsid, im.payload.txt);
			}
		}
		
		private function do_PC_LOCAL_CHAT(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				// check whether this broadcast is necessary
				if (im.payload.pc.tsid == 'god') {
					if ('above_level' in im.payload && world.pc.level < im.payload.above_level) return;
					if (!EnvironmentUtil.clientVersionIsBetween(im.payload.after_revision, im.payload.before_revision)) return;
				}
				
				pc = world.upsertPc(im.payload.pc);
				pc.online = true;
				RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, pc.tsid, im.payload.txt);
			}
		}
		
		private function do_NPC_LOCAL_CHAT(im:NetIncomingMessageVO):void {
			if (im.payload.tsid) {
				RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, im.payload.tsid, im.payload.txt);
			}
		}
		
		private function do_ACTION_REQUEST(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.online = true;
				RightSideManager.instance.actionRequest(ActionRequest.fromAnonymous(im.payload));
			}
		}
		
		private function do_ACTION_REQUEST_CANCEL(im:NetIncomingMessageVO):void {
			if(im.payload.event_type && im.payload.event_tsid){
				RightSideManager.instance.actionRequestCancel(ActionRequest.fromAnonymous(im.payload));
			}
		}
		
		private function do_ACTION_REQUEST_UPDATE(im:NetIncomingMessageVO):void {
			if(im.payload.uid){
				RightSideManager.instance.actionRequestUpdate(ActionRequest.fromAnonymous(im.payload));
			}
		}
		
		private function do_MAKING_START(im:NetIncomingMessageVO):void {
			MakingManager.instance.start(im.payload);
		}
		
		private function do_RESNAP_MINIMAP(im:NetIncomingMessageVO):void {
			// we just ignore this if this client sent the message
			if (!(im is NetResponseMessageVO)) {
				TSFrontController.instance.resnapMiniMap(true);
			}
		}
		
		private function do_CULTIVATION_START(im:NetIncomingMessageVO):void {
			if ('can_nudge_cultivations' in im.payload) {
				world.pc.can_nudge_cultivations = im.payload.can_nudge_cultivations;
				delete im.payload.can_nudge_cultivations;
			} else {
				world.pc.can_nudge_cultivations = false;
			}
			if ('can_nudge_others' in im.payload) {
				world.pc.can_nudge_others = im.payload.can_nudge_others;
				delete im.payload.can_nudge_others;
			} else {
				world.pc.can_nudge_others = false;
			}
			CultManager.instance.nudgeAbilityChanged();
		}
		
		private function do_CULTIVATION_MODE_START(im:NetIncomingMessageVO):void {
			if (!model.stateModel.cult_mode) {
				HouseManager.instance.startCultivation();
			}
		}
		
		private function do_CULTIVATION_MODE_END(im:NetIncomingMessageVO):void {
			if (model.stateModel.cult_mode) {
				TSFrontController.instance.stopCultMode();
			}
		}
		
		private function do_STORE_START(im:NetIncomingMessageVO):void {
			StoreManager.instance.start(im.payload);
		}
		
		private function do_STORE_CHANGED(im:NetIncomingMessageVO):void {
			StoreManager.instance.changed(im.payload);
		}
		
		private function do_STORE_END(im:NetIncomingMessageVO):void {
			//close the dialog if it's open
			if(StoreDialog.instance.parent){
				StoreDialog.instance.end(true);
			}
		}
		
		private function do_MAKE_KNOWN_COMPLETE(im:NetIncomingMessageVO):void {
			nc.handleRecipesFromMake(im.payload.knowns, true);
			nc.handleRecipesFromMake(im.payload.effects, false);
			MakingManager.instance.makeRecipeComplete(im.payload);
		}
		
		private function do_MAKE_UNKNOWN_COMPLETE(im:NetIncomingMessageVO):void {
			nc.handleRecipesFromMake(im.payload.knowns, true);
			nc.handleRecipesFromMake(im.payload.effects, false);
			MakingManager.instance.makeRecipeComplete(im.payload, false);
		}
		
		private function do_MAKE_UNKNOWN_MISSING(im:NetIncomingMessageVO):void {
			MakingManager.instance.makeRecipeFailed(im.payload);
		}
		
		private function do_MAKE_FAILED(im:NetIncomingMessageVO):void {
			MakingManager.instance.makeRecipeFailed(im.payload);
		}
		
		private function do_SIGNPOST_CHANGE(im:NetIncomingMessageVO):void {
			if (im.payload.signpost && im.payload.signpost.id && im.payload.location_tsid == world.location.tsid) {
				var signpost:SignPost = world.location.mg.getSignpostById(im.payload.signpost.id);
				if (signpost) {
					signpost = SignPost.updateFromAnonymous(im.payload.signpost, signpost);
					TSFrontController.instance.refreshSignPostInAllViews(signpost);
					
					//if this was the dialog's tsid, make sure we update it
					if(SignpostDialog.instance.signpost_tsid == signpost.tsid){
						SignpostDialog.instance.update(true);
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('signpost not found '+im.payload);
					}
					//world.location.mg.signposts.push(SignPost.fromAnonymous(im.payload.signpost, im.payload.signpost.id));
				}
			}
			
		}
		
		private function do_DOOR_ADD(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				TSFrontController.instance.addGeo(im.payload);
			}
		}
		
		private function do_DOOR_CHANGE(im:NetIncomingMessageVO):void {
			var itemstack:Itemstack;
			if (im.payload.door && im.payload.door.id && im.payload.location_tsid == world.location.tsid) {
				var door:Door = world.location.mg.getDoorById(im.payload.door.id);
				if (door) {
					
					// the client places these doors with itemstack_tsids, so ignore the positioning from the GS
					if (door.itemstack_tsid) {
						delete im.payload.door.x;
						delete im.payload.door.y;
						delete im.payload.door.w;
						delete im.payload.door.h;
					}
					
					var was_itemstack_tsid:String = door.itemstack_tsid;
					door = Door.updateFromAnonymous(im.payload.door, door);
					TSFrontController.instance.refreshDoorInAllViews(door);
					
					// force FancyDoor to see a change if the door's itemstack_tsid has changed
					if (door.itemstack_tsid && was_itemstack_tsid != door.itemstack_tsid) {
						itemstack = world.getItemstackByTsid(door.itemstack_tsid);
						if (itemstack && itemstack.itemstack_state.furn_config) {
							itemstack.itemstack_state.furn_config.is_dirty = true;
							FancyDoor.instance.onLocItemstackUpdates([door.itemstack_tsid]);
						}
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('door not found '+im.payload);
					}
					//world.location.mg.doors.push(Door.fromAnonymous(im.payload.door, im.payload.door.id));
				}
			}
			
		}
		
		private function do_PLAY_EMOTION(im:NetIncomingMessageVO):void {
			TSFrontController.instance.playEmotionAnimation(im.payload.emotion);
		}
		
		private function do_PLAY_DO(im:NetIncomingMessageVO):void {
			if (im.payload.stop) {
				TSFrontController.instance.stopDoAnimation();
			} else {
				TSFrontController.instance.playDoAnimation(im.payload.duration);
			}
		}
		
		private function do_PLAY_HIT(im:NetIncomingMessageVO):void {
			if (im.payload.stop) {
				TSFrontController.instance.stopHitAnimation();
			} else {
				TSFrontController.instance.playHitAnimation(im.payload.hit, im.payload.duration);
			}
		}
		
		private function do_POL_CHANGE(im:NetIncomingMessageVO):void {
			nc.handlePOLInfo(im.payload.pol_info, true);
			if (im.payload.home_info) {
				nc.handleHomeInfo(im.payload.home_info, true);
			}
		}
		
		private function do_ROOK_ATTACK(im:NetIncomingMessageVO):void {
			// this should trigger a wing beat attack
			RookManager.instance.startWingBeat();
		}
		
		private function do_LOCATION_ROOKED_STATUS(im:NetIncomingMessageVO):void {
			if (im.payload.status && im.payload.location_tsid) {
				model.rookModel.rooked_status = RookedStatus.fromAnonymous(im.payload.status, im.payload.location_tsid); // calls a trigger when set
			}
		}
		
		private function do_ROOK_STUN(im:NetIncomingMessageVO):void {
			model.rookModel.rook_stun = RookStun.fromAnonymous(im.payload);
			RookManager.instance.stun();
		}
		
		private function do_ROOK_DAMAGE(im:NetIncomingMessageVO):void {
			model.rookModel.rook_damage = RookDamage.fromAnonymous(im.payload);
			RookManager.instance.damage();
		}
		
		private function do_ROOK_TEXT(im:NetIncomingMessageVO):void {
			if (im.payload.txt) {
				RookManager.instance.text(im.payload.txt);
			}
		}
		
		private function do_GROUPS_JOIN(im:NetIncomingMessageVO):void {
			if (im.payload.tsid && im.payload.name) {
				im.payload.is_member = true;
				world.groups[im.payload.tsid] = Group.fromAnonymous(im.payload, im.payload.tsid);
				RightSideManager.instance.groupManage(im.payload.tsid, true);
			}
		}
		
		private function do_PC_GROUPS_CHAT(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.online = true;
			}
			RightSideManager.instance.groupUpdate(im.payload.tsid, pc.tsid, im.payload.txt);
		}
		
		private function do_GROUPS_LEAVE(im:NetIncomingMessageVO):void {
			if (im.payload.tsid && world.getGroupByTsid(im.payload.tsid)) {
				//[SY] no longer deleting the groups from the world model because
				//there is a flag 'is_member'. If this messes things up, uncomment the delete
				world.getGroupByTsid(im.payload.tsid).is_member = false;
				//delete world.groups[im.payload.tsid];
				
				RightSideManager.instance.groupManage(im.payload.tsid, false);
			}
		}
		
		private function do_GROUPS_SWITCH(im:NetIncomingMessageVO):void {
			if(im.payload.old_tsid && im.payload.new_tsid){
				//if the group has had a change in TSID handle that here
				RightSideManager.instance.groupSwitch(im.payload.old_tsid, im.payload.new_tsid);
			}
		}
		
		private function do_BUDDY_IGNORE(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.ignored = true;
				var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				cdVO.callback =	function(value:*):void {
					if (value === true) {
						TSFrontController.instance.startReportAbuseDialog(pc.tsid);
					}
				}
				cdVO.title = 'Blocked!';
				cdVO.txt = '<b>'+pc.label+'</b> has been blocked. Would you also like to report any abuse to us?'
				cdVO.choices = [
					{value: false, label: 'No thanks'},
					{value: true, label: 'Report abuse'}
				];
				cdVO.escape_value = false;
				TSFrontController.instance.confirm(cdVO);
			}
		}
		
		private function do_BUDDY_UNIGNORE(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.ignored = false;
			}
		}
		
		private function do_BUDDY_ADD(im:NetIncomingMessageVO):void {
			var pc:PC;
			//after buddy_added, what is this used for?
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
			}
		}
		
		private function do_BUDDY_ADDED(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				world.pc.buddy_tsid_list[pc.tsid] = pc.tsid;
				
				RightSideManager.instance.buddyManage(pc.tsid, true);
			}
		}
		
		private function do_BUDDY_REMOVED(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				delete world.pc.buddy_tsid_list[pc.tsid];
				
				RightSideManager.instance.buddyManage(pc.tsid, false);
			}
		}
		
		private function do_BUDDY_ONLINE(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.online = true;
				
				RightSideManager.instance.buddyUpdate(pc.tsid);
			}
		}
		
		private function do_BUDDY_OFFLINE(im:NetIncomingMessageVO):void {
			var pc:PC;
			if (im.payload.pc) {
				pc = world.upsertPc(im.payload.pc);
				pc.online = false;
				
				RightSideManager.instance.buddyUpdate(pc.tsid);
			}
		}
		
		private function do_CONVERSATION(im:NetIncomingMessageVO):void {
			// I'm only 100% sure this is a problem with familiar convos
			// So I am only erroring out in this case
			if (im.payload.itemstack_tsid == world.pc.familiar.tsid) {
				if (!im.payload.choices && !im.payload.txt) {
					BootError.handleError('msg type:conversation lacked data '+StringUtil.getJsonStr(im.payload)+'', new Error('Lacking data'), ['net'], !CONFIG::god);
				}
			}
			
			ConversationManager.instance.startWithIncomingMsg(im.payload);
			/*
			// FOR TESTING!
			setTimeout(function():void {
			TSFrontController.instance.simulateIncomingMsg({type:"conversation_cancel", itemstack_tsid:im.payload.itemstack_tsid});
			}, 2000);
			*/
		}
		
		private function do_OVERLAY_CANCEL(im:NetIncomingMessageVO):void {
			if (im.payload.uid) {
				NewxpLogger.log('recvd_'+MessageTypes.OVERLAY_CANCEL, im.payload.uid);
				// go ahead and process anncs now, so they can be cancelled by this annc if needed (edge case)
				nc.postProcessMessage(im);
				AnnouncementController.instance.cancelOverlay(im.payload.uid, false, im.payload.fade_out_sec?im.payload.fade_out_sec:NaN);
			}
			else if('all' in im.payload && im.payload.all === true){
				//kill the ones we can.
				nc.postProcessMessage(im);
				AnnouncementController.instance.cancelAllOverlaysWeCan();
			}
		}
		
		private function do_OVERLAY_STATE(im:NetIncomingMessageVO):void {
			if (im.payload.uid && (im.payload.state || im.payload.config)) {
				AnnouncementController.instance.setOverlayState(im.payload);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					if (!im.payload.uid) {
						Console.warn(im.type+' missing uid');
					}
					if (!im.payload.state) {
						Console.warn(im.type+' missing state');
					}
					if (!im.payload.config) {
						Console.warn(im.type+' missing config');
					}
				}
			}
		}
		
		private function do_OVERLAY_SCALE(im:NetIncomingMessageVO):void {
			if (im.payload.uid && im.payload.scale && im.payload.time) {
				AnnouncementController.instance.setOverlayScale(im.payload);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					if (!im.payload.uid) {
						Console.warn(im.type+' missing uid');
					}
					if (!im.payload.scale) {
						Console.warn(im.type+' missing scale');
					}
					if (!im.payload.time) {
						Console.warn(im.type+' missing time');
					}
				}						
			}
		}
		
		private function do_OVERLAY_OPACITY(im:NetIncomingMessageVO):void {
			if (im.payload.uid && 'opacity' in im.payload) {
				AnnouncementController.instance.setOverlayOpacity(im.payload);
			} else {
				CONFIG::debugging {
					if (!im.payload.uid) {
						Console.warn(im.type+' missing opacity');
					}
				}						
			}
		}
		
		private function do_OVERLAY_TEXT(im:NetIncomingMessageVO):void {
			if (im.payload.uid && 'text' in im.payload) {
				AnnouncementController.instance.setOverlayText(im.payload);
			} else {
				CONFIG::debugging {
					if (!im.payload.uid) {
						Console.warn(im.type+' missing text');
					}
				}						
			}
		}
		
		private function do_CONVERSATION_CHOICE(im:NetIncomingMessageVO):void {
			//Console.info((nrm.time_recv-nrm.request.time_sent)+'ms');
			//TODO these should be handled by callbacks passed to frontcontroller
			if (!im.msg_id) {
				//	// this is temporary! Myles is doing this for crabs I think (sending CONVERSATION_CHOICE with no msg_id to cancel the conversation)
				ConversationManager.instance.conversationCancelHandler(im);
			} else {
				ConversationManager.instance.conversationChoiceHandler(im as NetResponseMessageVO);
			}
		}
		
		private function do_CONVERSATION_CANCEL(im:NetIncomingMessageVO):void {
			//TODO these should be handled by callbacks passed to frontcontroller (if responses; as of now, CONVERSATION_CANCEL can also be an evt)
			ConversationManager.instance.conversationCancelHandler(im);
		}
		
		private function do_ITEMSTACK_STATUS(im:NetIncomingMessageVO):void {
			if (im.payload.itemstack_tsid && im.payload.status) {
				var itemstack:Itemstack = world.getItemstackByTsid(im.payload.itemstack_tsid);
				if (itemstack) {							
					if (itemstack.status) {
						itemstack.status = ItemstackStatus.resetAndUpdateFromAnonymous(im.payload.status, itemstack.status);
					} else {
						itemstack.status = ItemstackStatus.fromAnonymous(im.payload.status, im.payload.itemstack_tsid);
					}
					
					if (itemstack.status.is_dirty) world.triggerCBProp(false,false,"itemstacks", im.payload.itemstack_tsid, "status");
					itemstack.status.is_dirty = false;
					
				} else {
					//this may be the first time the item was created, let's see if we have it in the changes
					if(im.payload.changes){
						nc.changesHandler(im.payload.changes);
						itemstack = world.getItemstackByTsid(im.payload.itemstack_tsid);
						if(itemstack){
							if (itemstack.status) {
								itemstack.status = ItemstackStatus.resetAndUpdateFromAnonymous(im.payload.status, itemstack.status);
							} else {
								itemstack.status = ItemstackStatus.fromAnonymous(im.payload.status, im.payload.itemstack_tsid);
							}
							
							if (itemstack.status.is_dirty) world.triggerCBProp(false,false,"itemstacks", im.payload.itemstack_tsid, "status");
							itemstack.status.is_dirty = false;
						}
					}
					else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('unknown itemstack: '+im.payload.itemstack_tsid);
						}
					}
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('missing vital information!');
				}
			}
		}
		
		private function do_ACTIVITY(im:NetIncomingMessageVO):void {
			var pc:PC;
			//update the player if it's there
			if('pc' in im.payload) pc = world.upsertPc(im.payload.pc);
			
			//we need text to show!
			if (im.payload.txt) {
				NewxpLogger.log('recvd_'+MessageTypes.ACTIVITY, im.payload.txt);
				//build the activity to use
				const activity:Activity = Activity.fromAnonymous(im.payload);
				if (!activity.no_growl) {
					if(!pc && activity.pc_tsid){
						//get the PC if it's not set yet (but it should be)
						pc = world.getPCByTsid(activity.pc_tsid);
					}
					
					var growl_txt:String = activity.txt;
					if(pc && activity.auto_prepend){
						//put the player's name before the growl
						growl_txt = pc.label+' '+growl_txt;
					}
					if(!pc || !pc.ignored) model.activityModel.growl_message = growl_txt; // calls a trigger when set
				}
				if (!activity.growl_only){
					model.activityModel.activity_message = activity; // calls a trigger when set
				}
			}
		}
		
		private function do_PARTY_ACTIVITY(im:NetIncomingMessageVO):void {
			if (im.payload.txt) {
				model.activityModel.party_activity_message = im.payload.txt; // calls a trigger when set
			}
		}
		
		private function do_ITEMSTACK_BUBBLE(im:NetIncomingMessageVO):void {
			var itemstack:Itemstack;
			
			NewxpLogger.log('recvd_'+MessageTypes.ITEMSTACK_BUBBLE, im.payload.msg);
			
			if (model.stateModel.no_itemstack_bubbles) {
			}
			
			if (im.payload.itemstack_tsid && im.payload.msg) {
				itemstack = world.getItemstackByTsid(im.payload.itemstack_tsid);
				if (itemstack) {
					itemstack.bubble_duration = (im.payload.hasOwnProperty('duration')) ? im.payload.duration : 0;
					itemstack.bubble_msg = {
						txt: im.payload.msg,
							rewards: im.payload.rewards,
							offset_x: im.payload.offset_x || 0,
							offset_y: im.payload.offset_y || 0,
							allow_out_of_viewport_top: ('allow_out_of_viewport_top' in im.payload) && im.payload.allow_out_of_viewport_top === true
					};
					
					var lis_view:AbstractItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(itemstack.tsid);
					if (lis_view) {
						lis_view.bubbleHandler(itemstack.bubble_msg);
					} else {
						var piv:PackItemstackView = PackDisplayManager.instance.getItemstackViewByTsid(itemstack.tsid);
						if (piv) {
							piv.bubbleHandler(itemstack.bubble_msg);
						}
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('ITEMSTACK_BUBBLE for unknown itemstack');
					}
				}
			}
		}
		
		private function do_LOCATION_EVENT(im:NetIncomingMessageVO):void {
			CONFIG::god {
				var props_num:int;
				for (var kk:String in im.payload) {
					if (kk == 'type') continue;
					if (kk == '__SOURCE__') continue;
					props_num++;
				}
				if (!props_num) {
					Console.trackValue('  NC LE WITH NO PROPS', loc_event_no_props++)
				}
			}
		}
		
		private function do_RELOGIN_START(im:NetIncomingMessageVO):void {
			model.netModel.should_reconnect = true; // if we've logged in, after a disconnect we should by default reconnect
			nc.locationMoveStartHandler(im);
		}
		
		private function do_DOOR_MOVE_START(im:NetIncomingMessageVO):void {
			nc.locationMoveStartHandler(im);
		}
		
		private function do_SIGNPOST_MOVE_START(im:NetIncomingMessageVO):void {
			nc.locationMoveStartHandler(im);
		}
		
		private function do_FOLLOW_MOVE_START(im:NetIncomingMessageVO):void {
			nc.locationMoveStartHandler(im);
		}
		
		private function do_TELEPORT_MOVE_START(im:NetIncomingMessageVO):void {
			//TODO debug the problem with lost talk_to message
			if (EnvironmentUtil.getUrlArgValue('SWF_send_talk_to_at_teleport') == '1') {
				TSFrontController.instance.sendItemstackVerb(
					new NetOutgoingItemstackVerbVO(world.pc.familiar.tsid, 'talk_to', 1)
				);
			}
			NewxpLogger.log('recvd_'+MessageTypes.TELEPORT_MOVE_START);
			nc.locationMoveStartHandler(im);
		}
		
		private function do_TELEPORT_MOVE_END(im:NetIncomingMessageVO):void {
			NewxpLogger.log('recvd_'+MessageTypes.TELEPORT_MOVE_END);
			locationMoveEndHandler(im);
		}
		
		private function do_ITEMSTACK_STATE(im:NetIncomingMessageVO):void {
			if (im.payload.itemstack_tsid) {
				var itemstack:Itemstack = world.getItemstackByTsid(im.payload.itemstack_tsid);
				
				if (!itemstack) {
					//this may be the first time the item was created, let's see if we have it in the changes
					if(im.payload.changes){
						nc.changesHandler(im.payload.changes);
						itemstack = world.getItemstackByTsid(im.payload.itemstack_tsid);
						
					}
					
					if (!itemstack) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('non-existing itemstack:'+im.payload.itemstack_tsid);
						}
						return;
					}	
				}
				
				// should check and make sure it is in location, I think
				Itemstack.updateFromAnonymous({s:im.payload.s}, itemstack);
				world.loc_itemstack_updates = [im.payload.itemstack_tsid]; // calls a trigger when set
				
			}
		}
		
		private function do_ITEMSTACK_CONFIG(im:NetIncomingMessageVO):void { // deprecated in favor of ITEMSTACK_CONFIG
			
			if (im.payload.itemstack_tsid) {
				
				var itemstack:Itemstack = world.getItemstackByTsid(im.payload.itemstack_tsid);
				
				if (!itemstack) {
					CONFIG::debugging {
						Console.error('non-existing itemstack:'+im.payload.itemstack_tsid)
					}
					return;
				}
				
				// should check and make sure it is in location, I think
				Itemstack.updateFromAnonymous({config:im.payload.config}, itemstack);
				world.loc_itemstack_updates = [im.payload.itemstack_tsid]; // calls a trigger when set
				
			}
		}
		
		private function do_PC_LOGOUT(im:NetIncomingMessageVO):void {
			if (im.payload.pc) {
				const pc_data:Object = im.payload.pc;
				
				//see if they are in the model at all
				var pc:PC = world.getPCByTsid(pc_data.tsid);
				if (!pc) {
					CONFIG::debugging {
						Console.warn('pc_logout msg about a pc we do not know about: '+pc_data.tsid);
					}
					//world.pcs[pc_data.tsid] = PC.fromAnonymous(pc_data, pc_data.tsid);
					return; // why do anyhting else? they'e logged out ans we do not know about them. [GS shoudl not be sending these]
				}
				
				// update the PC model
				pc = world.upsertPc(pc_data);
				pc.online = false;
				
				if (world.location && pc.location.tsid == world.location.tsid) {
					if (world.location.pc_tsid_list[pc.tsid]) {
						delete world.location.pc_tsid_list[pc.tsid];
					}
					world.loc_pc_dels = [pc.tsid];
				}
				
				//update the right side chats if they are open
				RightSideManager.instance.pcStatus(pc.tsid);
				
				//update the player info window if it's open
				PlayerInfoDialog.instance.playerUpdate(pc.tsid);
			}
		}
		
		private function do_INPUT_CANCEL(im:NetIncomingMessageVO):void {
			if (InputTalkBubble.instance.request_uid && InputTalkBubble.instance.request_uid == im.payload.uid) {
				InputTalkBubble.instance.forceCancel();
			}
			InputDialog.instance.cancelUID(im.payload.uid);
		}
		
		private function do_INPUT_REQUEST(im:NetIncomingMessageVO):void {
			NewxpLogger.log('input_request_'+im.payload.uid, im.payload.uid+' '+im.payload.itemstack_tsid+' '+im.payload.input_label);
			if('itemstack_tsid' in im.payload && im.payload.itemstack_tsid && !im.payload.no_bubble){
				InputTalkBubble.instance.start(im.payload);
			}
			else {
				InputDialog.instance.startWithPayload(im.payload);
			}
		}
		
		private function do_AVATAR_GET_CHOICES(im:NetIncomingMessageVO):void {
			if (im.payload.choices) {
				ConfigOption.ava_default_options = im.payload.default_options;
				ConfigOption.ava_raw_options = im.payload.choices;
				ConfigOption.ava_option_names_sort = im.payload.option_names_sort;
				ConfigOption.ava_option_names = im.payload.option_names;
				ConfigOption.ava_option_names_breaks = im.payload.option_names_breaks;
			}
		}
		
		private function do_AVATAR_PRELOAD(im:NetIncomingMessageVO):void {
			NewAvaConfigDialog.instance.loadChoices();
			NewAvaConfigDialog.instance.loadAvatar();
		}
		
		private function do_OPEN_AVATAR_PICKER(im:NetIncomingMessageVO):void {
			NewxpLogger.log('recvd_'+MessageTypes.OPEN_AVATAR_PICKER);
			NewAvaConfigDialog.instance.start();
		}
		
		private function do_ITEMSTACK_VERB_MENU(im:NetIncomingMessageVO):void {
			var key:String;
			if (im.payload.itemDef && im.payload.itemDef.class_tsid && im.payload.itemDef.verbs) {
				var item:Item;
				item = world.getItemByTsid(im.payload.itemDef.class_tsid);
				if (item) {
					for (key in item.verbs) {
						if (!item.verbs[key].is_client) {
							item.verbs[key] = null;
							delete item.verbs[key];
						}
					}
					for (var verb_tsid:String in im.payload.itemDef.verbs) {
						if (item.verbs[verb_tsid]) {
							item.verbs[verb_tsid] = Verb.updateFromAnonymous(im.payload.itemDef.verbs[verb_tsid], item.verbs[verb_tsid]);
						} else {
							item.verbs[verb_tsid] = Verb.fromAnonymous(im.payload.itemDef.verbs[verb_tsid], verb_tsid);
						}
					}
					
					//Console.dir(im.payload.itemDef.emote_verbs)
					if (im.payload.itemDef.emote_verbs) { 
						for (verb_tsid in im.payload.itemDef.emote_verbs) {
							if (item.verbs[verb_tsid]) {
								item.verbs[verb_tsid] = Verb.updateFromAnonymous(im.payload.itemDef.emote_verbs[verb_tsid], item.verbs[verb_tsid]);
							} else {
								item.verbs[verb_tsid] = Verb.fromAnonymous(im.payload.itemDef.emote_verbs[verb_tsid], verb_tsid);
							}
							//Console.warn(verb_tsid)
						}
					}
				}
			}
		}
		
		private function do_MOVE_XY(im:NetIncomingMessageVO):void {
			
		}
		
		private function do_OVERLAY_DISMISSED(im:NetIncomingMessageVO):void {
		}
		
		private function do_AVATAR_ORIENTATION(im:NetIncomingMessageVO):void {
			if (im.payload.reversed) {
				world.pc.reversed = true;
			} else {
				world.pc.reversed = false;
			}
			
			try {
				TSFrontController.instance.getMainView().gameRenderer.getAvatarView().onOrientationChanged();
			} catch (err:Error) {
				//
			}
		}
		
		private function do_MOVE_AVATAR(im:NetIncomingMessageVO):void {
			var moveFunc:Function
			if ('x' in im.payload) {
				moveFunc = function():void {
					TSFrontController.instance.startMovingAvatarOnGSPath(new Point(im.payload.x, im.payload.y), im.payload.face);
				}
			} else if ('face' in im.payload) {
				if ('force' in im.payload && im.payload.force === true) {
					moveFunc = function():void {
						TSFrontController.instance.stopAndFaceAvatar(im.payload.face);
					}
				} else {
					moveFunc = function():void {
						TSFrontController.instance.faceAvatarIfNotMoving(im.payload.face);
					}
				}
			} else {
			}
			
			if (im.payload.delay_ms) {
				StageBeacon.setTimeout(moveFunc, im.payload.delay_ms);
			} else {
				moveFunc();
			}
		}
		
		private function do_CAMERA_OFFSET(im:NetIncomingMessageVO):void {
			model.stateModel.camera_offset_from_edge = ('camera_offset_from_edge' in im.payload && im.payload.camera_offset_from_edge === true);
			model.stateModel.camera_offset_x = im.payload.x;
			
			TSFrontController.instance.setCameraOffset();
		}
		
		private function do_CAMERA_CENTER(im:NetIncomingMessageVO):void {
			var px_sec:int = im.payload.px_sec || 0;
			if (im.payload.pt && 'x' in im.payload.pt && 'y' in im.payload.pt) {
				TSFrontController.instance.setCameraCenter(null, null, new Point(im.payload.pt.x, im.payload.pt.y), im.payload.duration_ms, im.payload.force == true, px_sec);
			} else if (im.payload.pc_tsid || im.payload.itemstack_tsid) {
				TSFrontController.instance.setCameraCenter(im.payload.pc_tsid, im.payload.itemstack_tsid, null, im.payload.duration_ms, im.payload.force == true, px_sec);
			} else {
				TSFrontController.instance.resetCameraCenter();
				if (px_sec) {
					CameraMan.instance.imposeHardDistLimitByPxPerSecond(px_sec);
				}
			}
			
		}
		
		private function do_QUEST_DIALOG_START(im:NetIncomingMessageVO):void {
			QuestsDialog.instance.start();
		}
		
		private function do_QUEST_DIALOG_CLOSED(im:NetIncomingMessageVO):void {
			//server just echoing, don't need to do anything
		}
		
		private function do_FAMILIAR_DIALOG_START(im:NetIncomingMessageVO):void {
			// this msg is sent by GS in newxp to open the fam dialog
			//open the skill cloud
			ImgMenuView.instance.cloud_to_open = Cloud.TYPE_SKILLS;
			ImgMenuView.instance.close_payload = 'close_payload' in im.payload ? im.payload.close_payload : null;
			ImgMenuView.instance.show();
		}
		
		private function do_UI_VISIBLE(im:NetIncomingMessageVO):void {
			if ('pack' in im.payload) {
				world.location.no_pack_overide = im.payload.pack ? 0 : 1;
				TSFrontController.instance.changePackVisibility();
			}
			if ('avatar' in im.payload) {
				world.location.no_avatar_overide = im.payload.avatar ? 0 : 1;
				TSFrontController.instance.changeAvatarVisibility();
			}
			if ('map' in im.payload) {
				world.location.no_map_overide = im.payload.map ? 0 : 1;
				TSFrontController.instance.changeMiniMapVisibility();
			}
			if ('hubmap' in im.payload) {
				world.location.no_hubmap_overide = im.payload.hubmap ? 0 : 1;
				TSFrontController.instance.changeHubMapVisibility();
			}
			if ('world_map' in im.payload) {
				world.location.no_world_map_overide = im.payload.world_map ? 0 : 1;
				HubMapDialog.instance.refreshNavButtons();
			}
			if ('stats' in im.payload) {
				world.location.no_stats_overide = im.payload.stats ? 0 : 1;
				TSFrontController.instance.changePCStatsVisibility();
			}
			if ('familiar' in im.payload) {
				world.location.no_familiar_overide = im.payload.familiar ? 0 : 1;
				TSFrontController.instance.changeTeleportDialogVisibility();
			}
			if ('status_bubbles' in im.payload) {
				world.location.no_status_bubbles_overide = im.payload.status_bubbles ? 0 : 1;
				TSFrontController.instance.changeStatusBubbleVisibility();
			}
			if ('tips' in im.payload) TSFrontController.instance.changeTipsVisibility(im.payload.tips, 'gs_says_so');
			if ('furniture_bag' in im.payload) {
				world.location.no_furniture_bag = !im.payload.furniture_bag;
				YouDisplayManager.instance.pack_tabber.changeVisibility();
			}
			if ('swatches_button' in im.payload) {
				world.location.no_swatches_button = !im.payload.swatches_button;
				YouDisplayManager.instance.decorate_toolbar.showHideButtons();
			}
			if ('expand_buttons' in im.payload) {
				world.location.no_expand_buttons = !im.payload.expand_buttons;
				YouDisplayManager.instance.decorate_toolbar.showHideButtons();
			}
			if ('mood' in im.payload) {
				world.location.no_mood = !im.payload.mood;
				YouDisplayManager.instance.showHideMood();
			}
			if ('energy' in im.payload) {
				world.location.no_energy = !im.payload.energy;
				YouDisplayManager.instance.showHideEnergy();
			}
			if ('imagination' in im.payload) {
				world.location.no_imagination = !im.payload.imagination;
				YouDisplayManager.instance.showHideImagination();
			}
			if ('decorate_button' in im.payload) {
				world.location.no_decorate_button = !im.payload.decorate_button;
				YouDisplayManager.instance.showHideCultDecoButtons();
			}
			if ('cultivate_button' in im.payload) {
				world.location.no_cultivate_button = !im.payload.cultivate_button;
				YouDisplayManager.instance.showHideCultDecoButtons();
			}
			if ('current_location' in im.payload) {
				world.location.no_current_location = !im.payload.current_location;
				YouDisplayManager.instance.showHideCurrentLocation();
			}
			if ('currants' in im.payload) {
				world.location.no_currants = !im.payload.currants;
				YouDisplayManager.instance.is_currants_hidden = world.location.no_currants;
			}
			if ('inventory_search' in im.payload) {
				world.location.no_inventory_search = !im.payload.inventory_search;
				YouDisplayManager.instance.showHideInventorySearch();
			}
			if ('home_street_visiting' in im.payload) {
				world.location.no_home_street_visiting = !im.payload.home_street_visiting;
				PlayerInfoDialog.instance.reloadIfOpen();
			}
			if ('create_account' in im.payload) {
				if (model.flashVarModel.is_stub_account && !im.payload.create_account) {
					NewxpLogger.log('created_account');
				}
				// assume that if we want to show this, the user is a stub account,
				// and that if we are hiding it, the user is no longer a stub account
				model.flashVarModel.is_stub_account = world.pc.needs_account = Boolean(im.payload.create_account);
				RightSideManager.instance.right_view.createAccountShowHide(im.payload.create_account === true);
			}
			if ('account_required_features' in im.payload) {
				world.location.no_account_required_features = !im.payload.account_required_features;
				RightSideManager.instance.right_view.accountFeaturesShowHide();
			}
			
			//refresh our views in case we have to redraw things
			TSFrontController.instance.getMainView().refreshViews();
		}
		
		private function do_HAS_DONE_INTRO(im:NetIncomingMessageVO):void {
			if (im.payload.value) {
				NewxpLogger.log('finished_newxp');
				model.flashVarModel.has_not_done_intro = false;
			}
		}
		
		private function do_NEW_API_TOKEN(im:NetIncomingMessageVO):void {
			if (im.payload.token) {
				var old_token:String = model.flashVarModel.api_token;
				model.flashVarModel.api_token = im.payload.token;
				API.setAPIUrl(model.flashVarModel.api_url, model.flashVarModel.api_token);
				PNGUtil.setAPIUrl(model.flashVarModel.api_url, model.flashVarModel.api_token);
				NewxpLogger.log('recvd_'+MessageTypes.NEW_API_TOKEN, old_token+' -> '+model.flashVarModel.api_token);
			}
		}
		
		private function do_ANIMATE_PACK_SLOTS(im:NetIncomingMessageVO):void {
			if('is_showing' in im.payload){
				PackDisplayManager.instance.animateEmptySlots(im.payload.is_showing === true);
			}
		}
		
		private function do_CABINET_START(im:NetIncomingMessageVO):void {
			var itemstacks:Object = im.payload.itemstacks;
			// add the stacks to the model
			if (itemstacks) {
				for (var k:String in itemstacks) {
					if (world.getItemstackByTsid(k)) {
						world.itemstacks[k] = Itemstack.updateFromAnonymous(itemstacks[k], world.getItemstackByTsid(k));
					} else {
						if (!Item.confirmValidClass(itemstacks[k].class_tsid, k)) {
							continue;
						}
						world.itemstacks[k] = Itemstack.fromAnonymous(itemstacks[k], k);
					}
					// hrm... do we add these to location??
					world.location.itemstack_tsid_list[k] = k;
				}
			}
			CONFIG::debugging {
				nc.logTsidLists();
			}
			TSFrontController.instance.startCabinetDialog(im.payload);
		}
		
		private function do_CABINET_END(im:NetIncomingMessageVO):void {
			CabinetManager.instance.cabinetEndHandler(im.payload);
		}
		
		private function do_SKILLS_CAN_LEARN(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			if (im is NetResponseMessageVO) {
				// upadte the model with the skills that can be learned
				if(nrm.success && nrm.payload.skills){
					//reset
					world.learnable_skills.length = 0;
					
					//parse
					var details:SkillDetails;
					var skill_id:String;
					for(skill_id in nrm.payload.skills){
						details = SkillDetails.fromAnonymous(nrm.payload.skills[skill_id], skill_id);
						world.learnable_skills.push(details);
					}
					
					//sort
					SortTools.vectorSortOn(world.learnable_skills, 
						['can_learn', 'seconds', 'name'], 
						[Array.DESCENDING, Array.NUMERIC, Array.CASEINSENSITIVE]
					);
				}
			} else {
				//this is the server asking to refresh the skills
				ImaginationSkillsUI.instance.getSkillsFromServer();
			}
		}
		
		private function do_SKILL_TRAIN_START(im:NetIncomingMessageVO):void {
			world.pc.skill_training = PCSkill.fromAnonymous(im.payload, im.payload.tsid);
			if(!('is_accelerated' in im.payload) && world.pc.familiar){
				//if it wasn't sent with the message, check to see if it was set on the familiar
				world.pc.skill_training.is_accelerated = world.pc.familiar.accelerated;
			}
			world.triggerCBProp(false,false,"pc","skill_training");
			world.triggerCBProp(false,false,"pc","skill_training_change");
		}
		
		private function do_SKILL_TRAIN_PAUSE(im:NetIncomingMessageVO):void {
			world.pc.skill_training = null;
			if(world.pc.familiar){
				//not doing anything while paused are we
				world.pc.familiar.accelerated = false;
			}
			world.triggerCBProp(false,false,"pc","skill_training");
			world.triggerCBProp(false,false,"pc","skill_training_change");
		}
		
		private function do_SKILL_TRAIN_COMPLETE(im:NetIncomingMessageVO):void {
			if(im.payload.stats){
				PC.updateFromAnonymous({stats:im.payload.stats}, world.pc); // a quick hack to get the PCStats updated
			}
			if (world.pc.skill_training && world.pc.skill_training.tsid == im.payload.tsid) {
				world.pc.skill_training = null;
			}
			
			if (im.payload.tsid == 'nudgery_1') {
				world.pc.can_nudge_cultivations = true;
				CultManager.instance.nudgeAbilityChanged();
			}
			
			//no more accelerating
			if(world.pc.familiar){
				world.pc.familiar.accelerated = false;
			}
			
			//update the world with the knowledge of the skill
			TSFrontController.instance.updateWorldSkill(im.payload.tsid, 
				function():void {
					world.triggerCBProp(false,false,"pc","skill_api_complete");
				}
			);
			
			world.triggerCBProp(false,false,"pc","skill_training");
			world.triggerCBProp(false,false,"pc","skill_training_complete");
			TSFrontController.instance.startFamiliarSkillMessageWithPayload(im.payload);
		}
		
		private function do_SKILL_UNLEARN_START(im:NetIncomingMessageVO):void {
			world.pc.skill_unlearning = PCSkill.fromAnonymous(im.payload, im.payload.tsid);
			
			//no more accelerating
			if(world.pc.familiar){
				world.pc.familiar.accelerated = false;
			}
			
			world.triggerCBProp(false,false,"pc","skill_training");
			world.triggerCBProp(false,false,"pc","skill_training_change");
		}
		
		private function do_SKILL_UNLEARN_COMPLETE(im:NetIncomingMessageVO):void {
			if (world.pc.skill_unlearning && world.pc.skill_unlearning.tsid == im.payload.tsid) {
				world.pc.skill_unlearning = null;
			}
			
			//no more accelerating
			if(world.pc.familiar){
				world.pc.familiar.accelerated = false;
			}
			
			world.triggerCBProp(false,false,"pc","skill_training");
			world.triggerCBProp(false,false,"pc","skill_training_complete");
		}
		
		private function do_SKILL_UNLEARN_CANCEL(im:NetIncomingMessageVO):void {
			world.pc.skill_unlearning = null;
			
			//no more accelerating
			if(world.pc.familiar){
				world.pc.familiar.accelerated = false;
			}
			
			world.triggerCBProp(false,false,"pc","skill_training");
			world.triggerCBProp(false,false,"pc","skill_training_change");
		}
		
		private function do_TROPHY_START(im:NetIncomingMessageVO):void {
			var display_itemstacks:Object = im.payload.display_itemstacks;
			var private_itemstacks:Object = im.payload.private_itemstacks;
			var k:String;
			
			// add the stacks to the model
			if (display_itemstacks) {
				for (k in display_itemstacks) {
					if (world.getItemstackByTsid(k)) {
						world.itemstacks[k] = Itemstack.updateFromAnonymous(display_itemstacks[k], world.getItemstackByTsid(k));
					} else {
						if (!Item.confirmValidClass(display_itemstacks[k].class_tsid, k)) {
							continue;
						}
						world.itemstacks[k] = Itemstack.fromAnonymous(display_itemstacks[k], k);
					}
					// hrm... do we add these to location??
					world.location.itemstack_tsid_list[k] = k;
				}
			}
			
			if (private_itemstacks) {
				for (k in private_itemstacks) {
					if (world.getItemstackByTsid(k)) {
						world.itemstacks[k] = Itemstack.updateFromAnonymous(private_itemstacks[k], world.getItemstackByTsid(k));
					} else {
						if (!Item.confirmValidClass(private_itemstacks[k].class_tsid, k)) {
							continue;
						}
						world.itemstacks[k] = Itemstack.fromAnonymous(private_itemstacks[k], k);
					}
					// hrm... do we add these to location??
					world.pc.itemstack_tsid_list[k] = k;
				}
			}
			CONFIG::debugging {
				nc.logTsidLists();
			}
			TSFrontController.instance.startTrophyDialog(im.payload);
		}
		
		private function do_TROPHY_END(im:NetIncomingMessageVO):void {
			TrophyCaseManager.instance.end(im.payload);
		}
		
		private function do_TRADE_START(im:NetIncomingMessageVO):void {
			TSFrontController.instance.startTradeDialog(im.payload);
		}
		
		private function do_TRADE_ADD_ITEM(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverAddItem(im.payload);
		}
		
		private function do_TRADE_CHANGE_ITEM(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverChangeItem(im.payload);
		}
		
		private function do_TRADE_REMOVE_ITEM(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverRemoveItem(im.payload);
		}
		
		private function do_TRADE_CURRANTS(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverCurrants(im.payload);
		}
		
		private function do_TRADE_CANCEL(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverCancel(im.payload);
		}
		
		private function do_TRADE_ACCEPT(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverAccept(im.payload);
		}
		
		private function do_TRADE_UNLOCK(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverUnlock(im.payload);
		}
		
		private function do_TRADE_COMPLETE(im:NetIncomingMessageVO):void {
			TradeManager.instance.serverComplete(im.payload);
		}
		
		private function do_TELEPORTATION(im:NetIncomingMessageVO):void {
			TeleportationManager.instance.update(im.payload);
		}
		
		private function do_SHRINE_START(im:NetIncomingMessageVO):void {
			ShrineManager.instance.start(im.payload);
		}
		
		private function do_SHRINE_FAVOR_UPDATE(im:NetIncomingMessageVO):void {
			//check to see if this is the server updating things
			if('favor' in im.payload && 'name' in im.payload.favor) {
				//update the player's favor
				var giant_favor:GiantFavor = world.pc.stats.favor_points.getFavorByName(im.payload.favor.name);
				if(giant_favor){
					giant_favor = GiantFavor.updateFromAnonymous(im.payload.favor, giant_favor);
				}
			}
		}
		
		private function do_COLLECTION_COMPLETE(im:NetIncomingMessageVO):void {
			TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
				CollectionCompleteView.instance.show,
				im.payload,
				true
			));
		}
		
		private function do_FAMILIAR_STATE_CHANGE(im:NetIncomingMessageVO):void {
			if (world.pc.familiar) {
				if (im.payload.hasOwnProperty('accelerated')) {
					world.pc.familiar.accelerated = (im.payload.accelerated === true);
					if(world.pc.skill_training){
						//make sure the skill_training is also set
						world.pc.skill_training.is_accelerated = world.pc.familiar.accelerated;
					}
				}
			}
		}
		
		private function do_JOB_STATUS(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			// because this might be a job for a stack created in the changes of this message, let's preprocess the changes in this case
			if (im.payload.changes) {
				try {
					nc.changesHandler(im.payload.changes);
				} catch (err:Error) {
					BootError.handleError('changesHandler failed '+im.type+' '+StringUtil.getJsonStr(im.payload)+'', err, ['net'], !CONFIG::god);
				}
				im.payload.changes = null;
				delete im.payload.changes;
			}
			if (!nrm) {
				// it is an event message
				JobManager.instance.status(im.payload);
			} else if (nrm.success && nrm.payload.status) {
				// it is a rsp to a job_status req msg and has a status section
				JobManager.instance.status(nrm.payload.status);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn(MessageTypes.JOB_STATUS +' request failed '+nrm.payload.msg);
				}
			}
		}
		
		private function do_JOB_REQ_STATE(im:NetIncomingMessageVO):void {
			JobManager.instance.requirementState(im.payload);
		}
		
		private function do_JOB_LEADERBOARD(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			
			if (nrm && !nrm.success) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn(MessageTypes.JOB_LEADERBOARD +' request failed '+nrm.payload.msg);
				}
			}
			
			if (im.payload.leaderboard) {
				nc.handlePCsInOrderedHash(im.payload.leaderboard);
			}
		}
		
		private function do_JOB_STOP_WORK(im:NetIncomingMessageVO):void {
			JobManager.instance.stopWorkFromServer(im.payload);
		}
		
		private function do_PHYSICS_CHANGES(im:NetIncomingMessageVO):void {
			// this is you
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('NetController.dealWithMessageType(PHYSICS_CHANGES):\n' +
						StringUtil.deepTrace(im.payload.adjustments));
				}
			}
			model.physicsModel.pc_adjustments = im.payload.adjustments; // calls a trigger when set
		}
		
		private function do_PC_PHYSICS_CHANGES(im:NetIncomingMessageVO):void {
			// this is another player
			TSFrontController.instance.setOtherPCPhysics(im.payload.pc_tsid, im.payload.adjustments);
		}
		
		private function do_UI_CALLOUT(im:NetIncomingMessageVO):void {
			// if contacts, we should just tell the server it is already opened!
			if (im.payload.section == UICalloutView.CONTACTS) {
				if (RightSideManager.instance.right_view.contactListOpen()) {
					TSFrontController.instance.genericSend(new NetOutgoingContactListOpenedVO());
				}
			}
			
			UICalloutView.instance.show(im.payload);
		}
		
		private function do_UI_CALLOUT_CANCEL(im:NetIncomingMessageVO):void {
			UICalloutView.instance.hide();
		}
		
		private function do_GET_ITEM_INFO(im:NetIncomingMessageVO):void {
			GetInfoDialog.instance.startFromServer(im.payload);
		}
		
		private function do_GET_TROPHY_INFO(im:NetIncomingMessageVO):void {
			TrophyGetInfoDialog.instance.startFromServer(im.payload);
		}
		
		private function do_NEW_DAY(im:NetIncomingMessageVO):void {
			if (im.payload.hi_emote_leaderboard) {
				world.hi_emote_leaderboard = im.payload.hi_emote_leaderboard; // fires a signal when set
				delete im.payload.hi_emote_leaderboard
			}
			
			TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
				NewDayView.instance.show,
				im.payload,
				false
			));
			
			//as soon as the server sends this in, clear out the daily 
			//energy spent and xp gained from the pc stats
			if(world.pc){
				world.pc.stats.energy_spent_today = 0;
				world.pc.stats.xp_gained_today = 0;
				world.pc.stats.imagination_gained_today = 0;
				
				//also the imagination dealing
				world.pc.stats.imagination_shuffled_today = false;
				
				//and the current daily giant favor
				world.pc.stats.favor_points.resetCurrentDailyFavor();
				
				world.triggerCBProp(false,false,"pc","stats");
			}
			world.pc.hi_emote_variant = '';
			world.hi_emote_variant_sig.dispatch();
		}
		
		private function do_NOTE_VIEW(im:NetIncomingMessageVO):void {
			NoteManager.instance.start(im.payload);
		}
		
		private function do_RECIPE_REQUEST(im:NetIncomingMessageVO):void {
			//add to the world model if we need to
			
			var k:String;
			var val:*;
			var recipe:Recipe;
			var index:int;
			
			for(k in im.payload){
				val = im.payload[k];
				recipe = world.getRecipeByOutputClass(k);
				
				if(!recipe){
					if(val && val.id){
						recipe = Recipe.fromAnonymous(val, val.id);
						world.recipes.push(recipe);
					}
						//if this item doesn't have any sort of recipe, throw it in the world so it doesn't ask for it again
					else {
						recipe = new Recipe(k);
						recipe.outputs.push(new RecipeComponent(k, 0, false));
						world.recipes.push(recipe);
					}
				}
					//update the world
				else {
					index = world.recipes.indexOf(recipe);
					recipe = Recipe.updateFromAnonymous(val, recipe);
					world.recipes.splice(index, 1, recipe);
				}
				
				//if the current tool matches the recipe's tool, we need to refresh the recipes
				if(MakingManager.instance.making_info && MakingManager.instance.making_info.item_class == recipe.tool){
					if(!MakingManager.instance.isRecipeInKnowns(recipe.id)){
						MakingManager.instance.making_info.knowns.push(recipe);
						//needs_refresh = true;
					}
				}
			}
			
			//tell the dialog that we had some changes go down
			MakingDialog.instance.onPackChange();
		}
		
		private function do_AVATAR_UPDATE(im:NetIncomingMessageVO):void {
			var pc_view:AbstractAvatarView;
			var pc:PC;
			if (im.payload.tsid && im.payload.sheet_url) {
				CONFIG::debugging {
					Console.info(im.payload.tsid +' '+ im.payload.sheet_url);
				}
				
				if (im.payload.tsid == world.pc.tsid) {
					// you
					pc = world.pc;
					pc_view = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
				} else {
					// other pc
					pc = world.getPCByTsid(im.payload.tsid);
					if (!pc) {
						;// shut of compiler
						CONFIG::debugging {
							Console.warn('WHO???');
						}
					}
					pc_view = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(pc.tsid);
					if (!pc_view) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('WHAT???')
						}
					}
				}
				
				//go update the history
				ImaginationYourLooksUI.instance.loadHistory();
				
				if (im.payload.sheet_pending) {
					pc.sheet_pending = true;
				} else {
					pc.sheet_url = im.payload.sheet_url;
					pc.sheet_pending = false;
					if (pc_view) pc_view.reloadSSWithNewSheet();
				}
			} else {
				CONFIG::debugging {
					Console.warn(MessageTypes.AVATAR_UPDATE+' msg lacks tsid or sheet_url');
				}
			}
			
		}
		
		private function do_PRELOAD_ITEM(im:NetIncomingMessageVO):void {
			var item:Item = world.getItemByTsid(im.payload.item_tsid);
			if (item) {
				// this primes the pump for the item assets, making any subsequent renders of the item
				// much faster. we pass null for a callback because we don't actually want to do anything with it.
				ItemSSManager.getSSForItemSWFByUrl(item.asset_swf_v, item);
			}
		}
		
		private function do_PRELOAD_SWF(im:NetIncomingMessageVO):void {
			if (im.payload.url) {
				var sl:SmartLoader = new SmartLoader(im.payload.url);
				sl.complete_sig.add(function(sl:SmartLoader):void {
					CONFIG::debugging {
						Console.warn(sl.name+' has been preloaded!')
					}
				});
				CONFIG::debugging {
					Console.warn('preloading '+im.payload.url);
				}
				sl.load(new URLRequest(im.payload.url));
			}
		}
		
		private function do_NOTICE_BOARD_START(im:NetIncomingMessageVO):void {
			NoticeBoardManager.instance.start(im.payload);
		}
		
		private function do_NOTICE_BOARD_STATUS(im:NetIncomingMessageVO):void {
			NoticeBoardManager.instance.status(im.payload);
		}
		
		private function do_MAP_OPEN(im:NetIncomingMessageVO):void {
			if(im.payload.transit_tsid){
				HubMapDialog.instance.startWithTransitTsid(im.payload.transit_tsid);
			}
			else {
				HubMapDialog.instance.start();
				
				//if they want to open a map to a specific street
				if(im.payload.hub_id && im.payload.location_tsid){
					HubMapDialog.instance.goToHubFromClick(im.payload.hub_id, im.payload.location_tsid, '', true);
				}
			}
		}
		
		private function do_MAP_OPEN_DELAYED(im:NetIncomingMessageVO):void {
			// this tells the client to open the map to a street when the user next opens the map
			model.stateModel.hub_to_open_map_to = im.payload.hub_id;
			model.stateModel.street_to_open_map_to = im.payload.location_tsid;
			HubMapDialog.instance.open_map_chat_when_closed = true;
		}
		
		private function do_MAIL_START(im:NetIncomingMessageVO):void {
			if(im.payload.station_tsid){
				MailManager.instance.start(im.payload);
			}
			else {
				CONFIG::debugging {
					Console.warn('Need a station_tsid to send a message!');
				}
			}
		}
		
		private function do_MAIL_CHECK(im:NetIncomingMessageVO):void {
			MailManager.instance.parseMessages(im.payload);
		}
		
		private function do_TELEPORTATION_SCRIPT_VIEW(im:NetIncomingMessageVO):void {
			if(im.payload.itemstack_tsid){
				TeleportationScriptManager.instance.viewScript(im.payload);
			}
			else {
				CONFIG::debugging {
					Console.warn('Trying to view a teleportation script without a tsid!');
				}
			}
		}
		
		private function do_UPDATE_HELP_CASE(im:NetIncomingMessageVO):void {
			/*{
			'type' : 'update_help_case',
			'case_id' : 123,
			}*/
			
			var error_str:String = MessageTypes.UPDATE_HELP_CASE+
				'\n\nMessageTypes.UPDATE_HELP_CASE ADDING BENCHMARK DETAILS:\n\n'+Benchmark.getShortLog()+
				'\n\nMessageTypes.UPDATE_HELP_CASE ADDING DECO LOADING DETAILS:\n\n'+model.stateModel.getDecoCountReport();
			
			if (BootError.msgs_at_user_bug_click) {
				error_str+= '\n\nMessageTypes.UPDATE_HELP_CASE ADDING BootError.msgs_at_user_bug_click:\n----------------------------------------------------\n\n'+BootError.msgs_at_user_bug_click;
			} else {
				error_str+= '\n\nMessageTypes.UPDATE_HELP_CASE ADDING MSGS:\n----------------------------------------------------\n\n'+BootError.buildMsgsString();
			}
			
			//TODO are updates silent? is there an error ID I can pass?
			API.reportError(error_str, 'UPDATE_HELP_CASE', true, '', '', ['update'],
				function(success:Boolean, ret_error_id:String, ret_case_id:String):void {
					if (success && ret_error_id) {
						API.attachErrorImageToError(ret_error_id, TSFrontController.instance.getMainView());
						var msg:String = 'New client error report: '+model.flashVarModel.root_url+'god/client_error.php?id='+ret_error_id;
						API.updateHelpCase(im.payload.case_id, msg);
					}
				}
			);
		}
		
		private function do_TRANSIT_STATUS(im:NetIncomingMessageVO):void {
			if(im.payload.tsid){
				TransitManager.instance.status(im.payload);
			}
			else {
				CONFIG::debugging {
					Console.warn('Transit status without a transit type! (tsid)');
				}
			}
		}
		
		private function do_GAME_START(im:NetIncomingMessageVO):void {
			if(im.payload.tsid && model.flashVarModel.show_scores){
				ScoreManager.instance.start(im.payload);
			}
		}
		
		private function do_GAME_SPLASH_SCREEN(im:NetIncomingMessageVO):void {
			if(im.payload.tsid){
				ScoreManager.instance.splash_screen(im.payload);
			}
		}
		
		private function do_CAMERA_MODE_START(im:NetIncomingMessageVO):void {
			TSFrontController.instance.maybeStartCameraManUserMode('MessageTypes.CAMERA_MODE_START');
		}
		
		private function do_CAMERA_MODE_STARTED(im:NetIncomingMessageVO):void {
			GlitchrFilterCommands.updateFiltersForPC(world.pc, im.payload.filters);
		}
		
		private function do_CAMERA_ABILITIES_CHANGE(im:NetIncomingMessageVO):void {
			if (im.payload.abilities) {
				nc.updatePCCameraCapabilities(im.payload.abilities);
				if (model.stateModel.in_camera_control_mode) {
					TSFrontController.instance.maybeStartCameraManUserMode('MessageTypes.CAMERA_ABILITIES_CHANGE'); // this will update it with the new values
				}
			}
		}
		
		private function do_SNAP_AUTO(im:NetIncomingMessageVO):void {
			if(TSFrontController.instance.maybeStartCameraManUserMode('MessageTypes.SNAP_AUTO')){
				//snap it now!
				CameraMan.instance.snap();
			}
		}
		
		private function do_GAME_UPDATE(im:NetIncomingMessageVO):void {
			if(im.payload.tsid && model.flashVarModel.show_scores){
				ScoreManager.instance.update(im.payload);
			}
		}
		
		private function do_GAME_END(im:NetIncomingMessageVO):void {
			if(im.payload.tsid && model.flashVarModel.show_scores){
				ScoreManager.instance.end(im.payload.tsid);
			}
		}
		
		private function do_EMBLEM_START(im:NetIncomingMessageVO):void {
			if(im.payload.itemstack_tsid){
				EmblemManager.instance.start(im.payload);
			}
		}
		
		private function do_PARTY_SPACE_START(im:NetIncomingMessageVO):void {
			PartySpaceManager.instance.start(im.payload);
		}
		
		private function do_ACL_KEY_INFO(im:NetIncomingMessageVO):void {
			ACLManager.instance.parseKeyInfo(im.payload);
		}
		
		private function do_FURNITURE_DROP(im:NetIncomingMessageVO):void {
			NewxpLogger.log('furniture_placed');
		}
		
		private function do_HOUSES_WALL_PURCHASED(im:NetIncomingMessageVO):void {
			HandOfDecorator.instance.purchaseCallBack(Swatch.TYPE_WALLPAPER, im.payload.wp_type, im.payload.error);
		}
		
		private function do_HOUSES_FLOOR_PURCHASED(im:NetIncomingMessageVO):void {
			HandOfDecorator.instance.purchaseCallBack(Swatch.TYPE_FLOOR, im.payload.floor_type, im.payload.error);
		}
		
		private function do_HOUSES_CEILING_PURCHASED(im:NetIncomingMessageVO):void {
			HandOfDecorator.instance.purchaseCallBack(Swatch.TYPE_CEILING, im.payload.ceiling_type, im.payload.error);
		}
		
		private function do_HOUSES_WALL_REMOVED(im:NetIncomingMessageVO):void {
			HandOfDecorator.instance.swatchRemoved(Swatch.TYPE_WALLPAPER, im.payload.wp_type);
		}
		
		private function do_HOUSES_FLOOR_REMOVED(im:NetIncomingMessageVO):void {
			HandOfDecorator.instance.swatchRemoved(Swatch.TYPE_FLOOR, im.payload.floor_type);
		}
		
		private function do_HOUSES_CEILING_REMOVED(im:NetIncomingMessageVO):void {
			HandOfDecorator.instance.swatchRemoved(Swatch.TYPE_CEILING, im.payload.ceiling_type);
		}
		
		private function do_HOUSES_UPGRADE_START(im:NetIncomingMessageVO):void {
			HouseManager.instance.parseExpandInfo(im.payload);
			HouseSignDialog.instance.start();
		}
		
		private function do_HOUSES_VISIT(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			if (nrm && !nrm.success) {
				if (nrm.payload.error && nrm.payload.error.msg) {
					model.activityModel.growl_message = 'Visiting that Home Street failed because: '+nrm.payload.error.msg;
				} else {
					model.activityModel.growl_message = 'Visiting that Home Street failed for some reason.';
				}
			}
		}
		
		private function do_HOUSES_EXPAND_START(im:NetIncomingMessageVO):void {
			//open the expand dialog
			if(!HouseExpandYardDialog.instance.parent){
				HouseExpandYardDialog.instance.start();
			}
		}
		
		private function do_HOUSES_CHANGE_STYLE_START(im:NetIncomingMessageVO):void {
			//change the style
			if(!HouseStylesDialog.instance.parent){
				HouseStylesDialog.instance.start();
			}
		}
		
		private function do_HOUSES_CHANGE_CHASSIS_START(im:NetIncomingMessageVO):void {
			//start customizing your house
			HouseManager.instance.openChassisChanger('furniture_chassis');
		}
		
		private function do_TOWER_CHANGE_CHASSIS_START(im:NetIncomingMessageVO):void {
			//start customizing your tower
			HouseManager.instance.openChassisChanger('furniture_tower_chassis');
		}
		
		private function do_FURNITURE_UPGRADE_START(im:NetIncomingMessageVO):void {
			TSFrontController.instance.startFurnitureUpgrade(im.payload);
		}
		
		private function do_ITEMSTACK_CONFIG_START(im:NetIncomingMessageVO):void {
			TSFrontController.instance.startItemstackConfig(im.payload);
		}
		
		private function do_GEO_ADD(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				TSFrontController.instance.addGeo(im.payload);
			}
		}
		
		private function do_GEO_UPDATE(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				TSFrontController.instance.updateGeo(im.payload);
			}
		}
		
		private function do_GEO_REMOVE(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				TSFrontController.instance.removeGeo(im.payload);
			}
		}
		
		private function do_DECO_ADD(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				TSFrontController.instance.addDeco(im.payload);
			}
		}
		
		private function do_DECO_UPDATE(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				var layers:Object = im.payload.layers;
				// TODO, check here for preview key against HandOfDecorator.instance.preview_key, to make sure this is the correct one to store an undo for
				if (HandOfDecorator.instance.stamping_preview_key && layers) {
					var undo_layers:Object = {};
					for (var k:String in layers) {
						undo_layers[k] = {};
						for (var m:String in layers[k]) {
							if (world.location.getDecoById(m)) {
								undo_layers[k][m] = world.location.getDecoById(m).AMF();
								// AMF only return h_flip if it is true (for geo object size reduction)
								// but that results in loss of data when undoing and redoing!
								// quick fix(im:NetIncomingMessageVO):void {
								undo_layers[k][m].h_flip = world.location.getDecoById(m).h_flip;
							}
						}
					}
					HandOfDecorator.instance.stamping_preview_undo_layers = undo_layers;
				}
				TSFrontController.instance.updateDeco(im.payload.layers);
			}
		}
		
		private function do_DECO_REMOVE(im:NetIncomingMessageVO):void {
			// no dynamic shenanigans in LD
			if (CONFIG::locodeco) {
				model.activityModel.growl_message = 'WARNING: Ignoring ' + im.type + ' message because you\'re in LOCODEV';
			} else {
				TSFrontController.instance.removeDeco(im.payload);
			}
		}
		
		private function do_IMAGINATION_PURCHASE_SCREEN(im:NetIncomingMessageVO):void {
			//the server needs to show the cool beans screen
			if('card' in im.payload){
				const card:ImaginationCard = ImaginationCard.fromAnonymous(im.payload.card, im.payload.card.id);
				ImaginationPurchaseUpgradeUI.instance.show(card);
			}
		}
		
		private function do_IMAGINATION_HAND(im:NetIncomingMessageVO):void {
			//new imagination hand
			var pc:PC = world.pc;
			if('hand' in im.payload && pc && pc.stats){
				pc.stats.imagination_hand = ImaginationCard.parseMultiple(im.payload.hand);
			}
			
			//redeal or just update?
			//should we open this sucker now?!
			if('and_open' in im.payload && im.payload.and_open === true){
				//open the imagination menu to the upgrades cloud
				if(!ImaginationHandUI.instance.parent){
					ImgMenuView.instance.cloud_to_open = Cloud.TYPE_UPGRADES;
					ImgMenuView.instance.show();
				}
			}
			
			if ('is_redeal' in im.payload && im.payload.is_redeal === true) {
				ImaginationHandUI.instance.redealHand();
			}
			else {
				ImaginationManager.instance.updateHand();
			}
		}
		
		private function do_OPEN_IMG_MENU(im:NetIncomingMessageVO):void {
			//the server wants to open the menu to a particular section
			var cloud_to_open:String = 'section' in im.payload ? 'cloud_'+im.payload.section : null;
			ImgMenuView.instance.cloud_to_open = cloud_to_open;
			ImgMenuView.instance.hide_close = ('hide_close' in im.payload && im.payload.hide_close === true);
			ImgMenuView.instance.close_payload = 'close_payload' in im.payload ? im.payload.close_payload : null;
			
			NewxpLogger.log('open_img_menu_'+cloud_to_open);
			
			ImgMenuView.instance.show();
		}
		
		private function do_CLOSE_IMG_MENU(im:NetIncomingMessageVO):void {
			//server wants to close the iMG menu
			if(ImgMenuView.instance.parent){
				ImgMenuView.instance.hide();
			}
		}
		
		private function do_VIEWPORT_ORIENTATION(im:NetIncomingMessageVO):void {
			if ('orientation' in im.payload) {
				TSFrontController.instance.setViewportOrientation(im.payload.orientation);
			}
		}
		
		private function do_VIEWPORT_SCALE(im:NetIncomingMessageVO):void {
			if ('scale' in im.payload && 'time' in im.payload) {
				if (im.payload.scale == 'reset') {
					TSFrontController.instance.resetViewportScale(im.payload.time);
				} else {
					TSFrontController.instance.setViewportScale(im.payload.scale, im.payload.time);
				}
				if (im.payload.no_zoom) {
					world.location.no_zoom_overide = Boolean(im.payload.no_zoom) ? 0 : 1;
				}
			}
		}
		
		private function do_TRADE_CHANNEL_ENABLE(im:NetIncomingMessageVO):void {
			//set our trade channel
			if('tsid' in im.payload){
				RightSideManager.instance.trade_chat_tsid = im.payload.tsid;
			}
		}
		
		private function do_LANTERN_SHOW(im:NetIncomingMessageVO):void {
			//show the lantern
			if('on_avatar' in im.payload){
				Lantern.instance.show(
					im.payload.on_avatar === true, 
					'radius' in im.payload ? im.payload.radius : Lantern.DEFAULT_RADIUS
				);
			}
		}
		
		private function do_LANTERN_HIDE(im:NetIncomingMessageVO):void {
			//hide the lantern
			Lantern.instance.hide();
		}
		
		private function do_ACL_KEY_START(im:NetIncomingMessageVO):void {
			//open the dialog via the server
			if(!ACLDialog.instance.parent){
				ACLDialog.instance.start();
			}
		}
		
		private function do_DECORATION_MODE_END(im:NetIncomingMessageVO):void {
			//server wants to stop deco mode
			if (HandOfDecorator.instance.promptForSaveIfPreviewingSwatch(true)) {
			}
			
			TSFrontController.instance.stopDecoratorMode();
		}
		
		private function do_CRAFTYBOT_START(im:NetIncomingMessageVO):void {
			//open the dialog
			CraftyDialog.instance.start();
		}
		
		private function do_CRAFTYBOT_UPDATE(im:NetIncomingMessageVO):void {
			//tell the manager of this update
			CraftyManager.instance.update(im.payload);
		}
		
		
	}
}