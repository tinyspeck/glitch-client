package com.tinyspeck.engine.data.client {
	import com.tinyspeck.engine.model.TSModelLocator;

	public class DebugMessages {
		
		public function DebugMessages() {
			
		}
		
		public static function getCrownTextReplayMessages(model:TSModelLocator):Array {
			return [
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:49:855",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:08:49:860",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:49:867",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:49:871",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:08:49:876",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:49:881",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:08:49:886",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"92%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:08:49:891",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:08:49:956"
				},
				{
					"type":"time_passes",
					"changes":{
						"stat_values":{
							"mood":140
						},
						"location_tsid":model.worldModel.location.tsid
					},
					"ts":"2011:08:18 19:08:50:194"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:50:880",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 19:08:50:885",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:51:177",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:08:51:223",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:51:229",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:18 19:08:51:233",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:51:233",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:51:238",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:08:51:243",
					"announcements":[
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:51:253",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:08:51:258",
					"announcements":[
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"93%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:08:51:265",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"PM41015CDB1BB",
							"type":"pc_overlay",
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"PM41015CDB1BB",
						"label":"Myles?"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:08:51:275"
				},
				{
					"ts":"2011:08:18 19:08:51:555",
					"x":-579,
					"type":"move_xy",
					"s":"-15",
					"y":-1626
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:52:130",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 19:08:52:135",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"PM41015CDB1BB",
							"type":"pc_overlay",
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:53:210",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:18 19:08:53:214",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"tsid":"PM41015CDB1BB",
						"label":"Myles?"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:53:244",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:08:53:249",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:53:253",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:53:257",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:08:53:262",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:53:267",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:08:53:271",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"92%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:08:53:276",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:08:53:282"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:54:129",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 19:08:54:133",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				},
				{
					"__SOURCE__":"TIMER_P001_onPeriodicEnergyLoss",
					"changes":{
						"stat_values":{
							"energy":141
						},
						"location_tsid":model.worldModel.location.tsid
					},
					"ts":"2011:08:18 19:08:54:726",
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:56:045",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:08:56:050",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:56:055",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:18 19:08:56:077",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:56:078",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:56:082",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:08:56:087",
					"announcements":[
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:56:097",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:08:56:102",
					"announcements":[
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"93%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:08:56:107",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"PM41015CDB1BB",
							"type":"pc_overlay",
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"PM41015CDB1BB",
						"label":"Myles?"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:08:56:115"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:57:104",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 19:08:57:108",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"PM41015CDB1BB",
							"type":"pc_overlay",
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:57:524",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:18 19:08:57:529",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"tsid":"PM41015CDB1BB",
						"label":"Myles?"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:57:531",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:08:57:535",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:57:558",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:57:565",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:08:57:571",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:57:576",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:08:57:580",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"92%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:08:57:585",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:08:57:591"
				},
				{
					"ts":"2011:08:18 19:08:57:632",
					"x":-579,
					"type":"move_xy",
					"s":"-7",
					"y":-1626
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:58:598",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 19:08:58:622",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:58:822",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:08:58:826",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:58:832",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:18 19:08:58:836",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:58:837",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:58:854",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:08:58:858",
					"announcements":[
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:58:868",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:08:58:873",
					"announcements":[
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"93%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:08:58:880",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"PM41015CDB1BB",
							"type":"pc_overlay",
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"PM41015CDB1BB",
						"label":"Myles?"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:08:58:888"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:08:59:856",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 19:08:59:861",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"PM41015CDB1BB",
							"type":"pc_overlay",
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:09:00:166",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:18 19:09:00:170",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"tsid":"PM41015CDB1BB",
						"label":"Myles?"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:09:00:172",
					"uid":"it_game_tip"
				},
				{
					"type":"location_event",
					"ts":"2011:08:18 19:09:00:176",
					"announcements":[
						{
							"click_to_advance":false,
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"locking":false,
							"uid":"it_game_tip",
							"top_y":"15%",
							"duration":3000
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:09:00:182",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:09:00:220",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 19:09:00:224",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:09:00:229",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 19:09:00:233",
					"announcements":[
						{
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"show_text_shadow":false,
							"y":"92%",
							"uid":"crown_game_score",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"locking":false,
							"duration":0
						}
					],
					"type":"location_event"
				},
				{
					"ts":"2011:08:18 19:09:00:238",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"locking",
							"delta_y":-115
						}
					],
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"tsid":"P001",
						"label":"Eric"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 19:09:00:244"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 19:09:01:103",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 19:09:01:108",
					"announcements":[
						{
							"item_class":"game_crown",
							"width":42,
							"pc_tsid":"P001",
							"type":"pc_overlay",
							"uid":"P001-it_game_crown-game",
							"dismissible":false,
							"bubble":false,
							"duration":0,
							"height":42,
							"delta_x":0,
							"state":"unlocking",
							"delta_y":-115
						}
					],
					"type":"location_event"
				}
			];
		}
		
		public static function getCrownReplayMessages(model:TSModelLocator):Array {
			return [
				
				
				{
					"type":"location_event",
					"__SOURCE__":"RPCCall_exec_apiSendAnnouncement",
					"ts":"2011:08:17 20:42:43:357",
					"announcements":[
						{
							"duration":0,
							"width":400,
							"locking":true,
							"type":"vp_overlay",
							"y":"45%",
							"x":"50%",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313020149_8576.swf",
							"click_to_advance":false,
							"uid":"game_instructions"
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"RPCCall_exec_apiSendAnnouncement",
					"ts":"2011:08:17 20:42:43:380",
					"announcements":[
						{
							"duration":0,
							"width":200,
							"locking":true,
							"type":"vp_overlay",
							"y":"58%",
							"mouse":{
								"allow_multiple_clicks":false,
								"click_payload":{
									"instance_id":"it_game_instance",
									"pc_callback":"games_accept_start_button",
									"id":"it_game"
								},
								"is_clickable":true,
								"dismiss_on_click":false
							},
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313020184_4151.swf",
							"click_to_advance":false,
							"x":"50%",
							"uid":"click_to_start"
						}
					]
				},
				{
					"auto_prepend":false,
					"type":"activity",
					"ts":"2011:08:17 20:42:43:403",
					"pc":{
						
					},
					"txt":"Other players here: RICKY"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:45:027",
					"uid":"click_to_start"
				},
				{
					"type":"location_event",
					"__SOURCE__":"RPCCall_exec_apiSendAnnouncement",
					"ts":"2011:08:17 20:42:45:042",
					"announcements":[
						{
							"duration":0,
							"width":200,
							"locking":true,
							"type":"vp_overlay",
							"y":"58%",
							"x":"50%",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313020233_3841.swf",
							"click_to_advance":false,
							"uid":"game_waiting"
						}
					]
				},
				{
					"escape_value":null,
					"type":"prompt",
					"txt":"You must wait for more players before this game can begin.",
					"choices":[
						{
							"value":"leave",
							"label":"Leave"
						}
					],
					"is_modal":false,
					"icon_buttons":false,
					"ts":"2011:08:17 20:42:45:062",
					"uid":"1313613765",
					"timeout":0
				},
				{
					"auto_prepend":true,
					"type":"activity",
					"ts":"2011:08:17 20:42:45:107",
					"pc":{
						"tsid":"P001",
						"is_admin":true,
						"label":"Eric"
					},
					"txt":"is ready to play. LET'S GO!"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:45:121",
					"uid":"game_instructions"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:45:135",
					"uid":"game_waiting"
				},
				{
					"type":"prompt_remove",
					"ts":"2011:08:17 20:42:45:149",
					"uid":"1313613765"
				},
				{
					"type":"location_event",
					"__SOURCE__":"RPCCall_exec_apiSendAnnouncement",
					"ts":"2011:08:17 20:42:45:162",
					"announcements":[
						{
							"duration":5000,
							"width":500,
							"locking":true,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog\">YAY! THE GAME IS STARTING SOON.</span></p>"
							],
							"top_y":"15%",
							"x":"50%",
							"click_to_advance":false,
							"uid":"game_waiting"
						}
					]
				},
				{
					"type":"time_passes",
					"ts":"2011:08:17 20:42:45:233",
					"changes":{
						"stat_values":{
							"mood":90
						},
						"location_tsid":model.worldModel.location.tsid
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:50:073",
					"uid":"game_instructions"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:50:088",
					"uid":"game_waiting"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:50:102",
					"uid":"click_to_start"
				},
				{
					"type":"location_event",
					"__SOURCE__":"RPCCall_exec_apiSendAnnouncement",
					"ts":"2011:08:17 20:42:50:147",
					"announcements":[
						{
							"duration":4000,
							"width":350,
							"x":"50%",
							"type":"vp_overlay",
							"top_y":"50%",
							"locking":true,
							"swf_url":"http://c2.glitch.bz/overlays/2011-06-10/1307726364_4503.swf",
							"height":350,
							"dismissible":false,
							"uid":"game_countdown"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:251",
					"uid":"game_countdown"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:268",
					"uid":"game_instructions"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:283",
					"uid":"game_waiting"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:298",
					"uid":"crown_game_indicator",
					"announcements":[
						{
							"duration":3000,
							"width":500,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"top_y":"15%",
							"x":"50%",
							"click_to_advance":false,
							"uid":"it_game_tip"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:337",
					"uid":"crown_game_king"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:352",
					"uid":"crown_game_score",
					"announcements":[
						{
							"duration":0,
							"width":140,
							"locking":false,
							"type":"vp_overlay",
							"y":"88%",
							"x":70,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"uid":"crown_game_indicator"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:389",
					"uid":"it_game_tip",
					"announcements":[
						{
							"duration":0,
							"width":140,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"x":70,
							"uid":"crown_game_score",
							"show_text_shadow":false
						}
					]
				},
				{
					"pc":{
						"tsid":"P001",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"label":"Eric"
					},
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:55:429",
					"announcements":[
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"P001",
							"width":42,
							"state":"locking",
							"delta_y":-115,
							"dismissible":false,
							"uid":"P001-it_game_crown-game"
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"RPCCall_exec_startInstancedGame",
					"ts":"2011:08:17 20:42:55:442"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:55:444",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"location_event",
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:17 20:42:55:447",
					"announcements":[
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"P001",
							"width":42,
							"state":"unlocking",
							"delta_y":-135,
							"dismissible":false,
							"uid":"P001-it_game_crown-game"
						}
					]
				},
				{
					"auto_prepend":false,
					"type":"activity",
					"ts":"2011:08:17 20:42:55:463",
					"pc":{
						"tsid":"P001",
						"is_admin":true,
						"label":"Eric"
					},
					"txt":"Braiiiiiiiiins!"
				},
				{
					"ts":"2011:08:17 20:42:55:565",
					"x":-357,
					"type":"move_xy",
					"s":"-7",
					"y":-1762
				},
				{
					"ts":"2011:08:17 20:42:55:714",
					"x":-357,
					"type":"move_xy",
					"s":"-7",
					"y":-1760
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:56:199",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:56:216",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:56:232",
					"pc":{
						"tsid":"P001",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"label":"Eric"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:56:244",
					"uid":"crown_game_indicator",
					"announcements":[
						{
							"duration":3000,
							"width":500,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"top_y":"15%",
							"x":"50%",
							"click_to_advance":false,
							"uid":"it_game_tip"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:56:284",
					"uid":"crown_game_king"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:56:316",
					"uid":"crown_game_score",
					"announcements":[
						{
							"duration":0,
							"width":100,
							"locking":false,
							"type":"vp_overlay",
							"y":"91%",
							"x":"94%",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"uid":"crown_game_indicator"
						},
						{
							"duration":0,
							"width":100,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">RICKY</span></p>"
							],
							"y":"81%",
							"x":"94%",
							"uid":"crown_game_king"
						}
					]
				},
				{
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"tsid":"PM41015CDB1BB",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"label":"RICKY"
					},
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:56:382",
					"announcements":[
						{
							"duration":0,
							"width":100,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"x":"94%",
							"uid":"crown_game_score",
							"show_text_shadow":false
						},
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"PM41015CDB1BB",
							"width":42,
							"state":"locking",
							"delta_y":-155,
							"dismissible":false,
							"uid":"PM41015CDB1BB-it_game_crown-game"
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:17 20:42:56:430"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:57:256",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"location_event",
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:17 20:42:57:274",
					"announcements":[
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"PM41015CDB1BB",
							"width":42,
							"state":"unlocking",
							"delta_y":-175,
							"dismissible":false,
							"uid":"PM41015CDB1BB-it_game_crown-game"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:58:009",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:58:050",
					"pc":{
						"tsid":"PM41015CDB1BB",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"label":"RICKY"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:58:064",
					"uid":"crown_game_indicator",
					"announcements":[
						{
							"duration":3000,
							"width":500,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"top_y":"15%",
							"x":"50%",
							"click_to_advance":false,
							"uid":"it_game_tip"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:58:108",
					"uid":"crown_game_king"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:58:127",
					"uid":"crown_game_score",
					"announcements":[
						{
							"duration":0,
							"width":140,
							"locking":false,
							"type":"vp_overlay",
							"y":"88%",
							"x":70,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"uid":"crown_game_indicator"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:58:177",
					"uid":"it_game_tip",
					"announcements":[
						{
							"duration":0,
							"width":140,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"x":70,
							"uid":"crown_game_score",
							"show_text_shadow":false
						}
					]
				},
				{
					"pc":{
						"tsid":"P001",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"label":"Eric"
					},
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:58:220",
					"announcements":[
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"P001",
							"width":42,
							"state":"locking",
							"delta_y":-195,
							"dismissible":false,
							"uid":"P001-it_game_crown-game"
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:17 20:42:58:260"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:59:005",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"location_event",
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:17 20:42:59:035",
					"announcements":[
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"P001",
							"width":42,
							"state":"unlocking",
							"delta_y":-215,
							"dismissible":false,
							"uid":"P001-it_game_crown-game"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:59:117",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:59:134",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:59:163",
					"pc":{
						"tsid":"P001",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":null,
						"label":"Eric"
					}
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:59:177",
					"uid":"crown_game_indicator",
					"announcements":[
						{
							"duration":3000,
							"width":500,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"top_y":"15%",
							"x":"50%",
							"click_to_advance":false,
							"uid":"it_game_tip"
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:59:241",
					"uid":"crown_game_king"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:42:59:259",
					"uid":"crown_game_score",
					"announcements":[
						{
							"duration":0,
							"width":100,
							"locking":false,
							"type":"vp_overlay",
							"y":"91%",
							"x":"94%",
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"uid":"crown_game_indicator"
						},
						{
							"duration":0,
							"width":100,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">RICKY</span></p>"
							],
							"y":"81%",
							"x":"94%",
							"uid":"crown_game_king"
						}
					]
				},
				{
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"tsid":"PM41015CDB1BB",
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"color_group":"#e5c33f",
						"label":"RICKY"
					},
					"type":"pc_color_group_change",
					"ts":"2011:08:17 20:42:59:322",
					"announcements":[
						{
							"duration":0,
							"width":100,
							"locking":false,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"x":"94%",
							"uid":"crown_game_score",
							"show_text_shadow":false
						},
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"PM41015CDB1BB",
							"width":42,
							"state":"locking",
							"delta_y":-235,
							"dismissible":false,
							"uid":"PM41015CDB1BB-it_game_crown-game"
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:17 20:42:59:338"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:17 20:43:00:274",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"location_event",
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:17 20:43:00:297",
					"announcements":[
						{
							"duration":0,
							"bubble":false,
							"delta_x":0,
							"type":"pc_overlay",
							"height":42,
							"item_class":"game_crown",
							"pc_tsid":"PM41015CDB1BB",
							"width":42,
							"state":"unlocking",
							"delta_y":-255,
							"dismissible":false,
							"uid":"PM41015CDB1BB-it_game_crown-game"
						}
					]
				}
			];
			
		}
		
		// has overlay cancels carrying anncs they are meant to cancel
		public static function getCrownTextReplayMessagesBAD(model:TSModelLocator):Array {
			return [
				{
					"ts":"2011:08:18 16:47:45:466",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:47:45:572",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:45:591"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:46:070",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:47:46:124",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:47:137",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:47:177",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:47:231"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:47:293",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:47:347",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:47:383",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:47:514",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:47:564",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:47:47:635",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:47:680"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:52:900",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:47:52:910",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:52:924",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:52:931"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:52:934",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:52:941",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:52:948",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:52:959",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:52:966",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:47:52:976",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYou're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:47:52:999",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:53:016"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:018",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:47:53:026",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"time_passes",
					"changes":{
						"stat_values":{
							"mood":230
						},
						"location_tsid":model.worldModel.location.tsid
					},
					"ts":"2011:08:18 16:47:53:043"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:117",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:125",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:53:136"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:137",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:147",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:53:156",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:185",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:53:193",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:47:53:212",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:53:251"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:253",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:47:53:262",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:277",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:53:284"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:288",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:296",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:53:303",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:319",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:53:327",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:47:53:342",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:47:53:369",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:53:384"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:386",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:47:53:396",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:410",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:419",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:53:426"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:427",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:435",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:53:440",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:470",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:53:478",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:47:53:495",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:53:534"
				},
				{
					"ts":"2011:08:18 16:47:53:735",
					"x":373,
					"type":"move_xy",
					"s":"17",
					"y":-1759
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:756",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:47:53:764",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:777",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:53:785"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:787",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:797",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:53:871",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:53:882",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:53:892",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:47:53:903",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:47:53:925",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:53:940"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:54:910",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:47:54:921",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:54:995",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:55:001",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:47:55:009"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:55:010",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:55:022",
					"uid":"crown_game_king"
				},
				{
					"ts":"2011:08:18 16:47:55:038",
					"x":373,
					"type":"move_xy",
					"s":"7",
					"y":-1759
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:47:55:039",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:55:067",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:47:55:076",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:47:55:088",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:47:55:116"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:47:56:077",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:47:56:088",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"ts":"2011:08:18 16:48:12:950",
					"x":373,
					"type":"move_xy",
					"s":"16",
					"y":-1759
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:12:952",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:13:002"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:005",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:059",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:13:110",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:168",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:13:215",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:48:13:282",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:48:13:398",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:13:409"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:411",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:48:13:419",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:431",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:437",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:13:445"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:445",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:453",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:13:458",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:477",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:13:484",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:48:13:495",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:13:519"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:13:582",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:48:13:590",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:15:795",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:15:851"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:15:854",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:15:925",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:15:978",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:16:054",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:16:118",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:48:16:195",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:48:16:320",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:16:333"
				},
				{
					"ts":"2011:08:18 16:48:16:382",
					"x":373,
					"type":"move_xy",
					"s":"7",
					"y":-1759
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:16:755",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:48:16:805",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:17:104",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:17:155",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:17:223"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:17:224",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:17:379",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:17:421",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:17:509",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:17:518",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:48:17:528",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:17:554"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:18:148",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:48:18:157",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:18:604",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:18:660"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:18:662",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:18:722",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:18:783",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:18:847",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:18:905",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:48:18:984",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:48:19:146",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:19:161"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:19:573",
					"uid":"P001-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_P001_games_it_game_unlock",
					"ts":"2011:08:18 16:48:19:583",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:19:827",
					"uid":"it_game_tip"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:19:871",
					"uid":"P001-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:19:930"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:19:930",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:19:989",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:20:040",
					"type":"location_event",
					"announcements":[
						{
							"width":100,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043065_4286.swf",
							"x":"94%",
							"type":"vp_overlay",
							"y":"91%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						},
						{
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_king\">Myles?</span></p>"
							],
							"y":"81%",
							"uid":"crown_game_king",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:20:162",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:20:170",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":100,
							"x":"94%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"93%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're no longer it! Get it back and go through the play line to win!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						},
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					],
					"ts":"2011:08:18 16:48:20:184",
					"type":"pc_color_group_change",
					"changes":{
						"location_tsid":model.worldModel.location.tsid
					},
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":"#e5c33f"
					}
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:20:209"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:20:834",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"__SOURCE__":"TIMER_PM41015CDB1BB_games_it_game_unlock",
					"ts":"2011:08:18 16:48:20:895",
					"type":"location_event",
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"PM41015CDB1BB-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"PM41015CDB1BB",
							"state":"unlocking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:21:019",
					"uid":"PM41015CDB1BB-it_game_crown-game"
				},
				{
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"PM41015CDB1BB",
						"label":"Myles?",
						"color_group":null
					},
					"ts":"2011:08:18 16:48:21:094"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:21:097",
					"uid":"crown_game_indicator"
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:21:165",
					"uid":"crown_game_king"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_start_scores",
					"ts":"2011:08:18 16:48:21:232",
					"type":"location_event",
					"announcements":[
						{
							"width":140,
							"swf_url":"http://c2.glitch.bz/overlays/2011-08-10/1313043034_6652.swf",
							"x":70,
							"type":"vp_overlay",
							"y":"88%",
							"uid":"crown_game_indicator",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"type":"overlay_cancel",
					"ts":"2011:08:18 16:48:21:315",
					"uid":"crown_game_score"
				},
				{
					"__SOURCE__":"RPCCall_exec_games_it_game_update_scores",
					"ts":"2011:08:18 16:48:21:379",
					"type":"location_event",
					"announcements":[
						{
							"show_text_shadow":false,
							"width":140,
							"x":70,
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"crowns_counter\">0</span></p>"
							],
							"y":"92%",
							"uid":"crown_game_score",
							"locking":false,
							"duration":0
						}
					]
				},
				{
					"ts":"2011:08:18 16:48:21:430",
					"type":"overlay_cancel",
					"announcements":[
						{
							"width":500,
							"x":"50%",
							"type":"vp_overlay",
							"text":[
								"<p align=\"center\"><span class=\"nuxp_vog_brain\">You're it! Go through the play line to start the timer!</span></p>"
							],
							"uid":"it_game_tip",
							"locking":false,
							"top_y":"15%",
							"duration":3000,
							"click_to_advance":false
						}
					],
					"uid":"it_game_tip"
				},
				{
					"ts":"2011:08:18 16:48:21:448",
					"type":"pc_color_group_change",
					"pc":{
						"location":{
							"tsid":model.worldModel.location.tsid,
							"label":"Game of Crowns"
						},
						"tsid":"P001",
						"label":"Eric",
						"color_group":"#e5c33f"
					},
					"announcements":[
						{
							"width":42,
							"dismissible":false,
							"type":"pc_overlay",
							"bubble":false,
							"duration":0,
							"uid":"P001-it_game_crown-game",
							"delta_x":0,
							"delta_y":-115,
							"pc_tsid":"P001",
							"state":"locking",
							"item_class":"game_crown",
							"height":42
						}
					]
				},
				{
					"type":"location_event",
					"__SOURCE__":"processMessage_loc",
					"ts":"2011:08:18 16:48:21:459"
				}
			];
		}
		
	
	}
	
}