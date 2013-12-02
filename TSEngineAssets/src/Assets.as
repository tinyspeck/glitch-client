
package {
	import flash.display.*;
	import flash.system.Security;
	
	public class Assets extends Sprite {
		
		[Embed(source="assets/sounds/Prisencolinensinainciusol.mp3")]
		public var Prisencolinensinainciusol:Class;
		[Embed(source="assets/sounds/trumpet.mp3")]
		public var trumpet:Class;
		
		[Embed(source="assets/graphics/about_energy.png")]
		public var about_energy:Class;
		[Embed(source="assets/graphics/about_mood.png")]
		public var about_mood:Class;
		[Embed(source="assets/graphics/acl_icons.png")]
		public var acl_icons:Class;
		[Embed(source="assets/graphics/acl_icons_no_stroke.png")]
		public var acl_icons_no_stroke:Class;
		[Embed(source="assets/graphics/action_feed.png")]
		public var action_feed:Class;
		[Embed(source="assets/graphics/action_massage.png")]
		public var action_massage:Class;
		[Embed(source="assets/graphics/action_pet.png")]
		public var action_pet:Class;
		[Embed(source="assets/graphics/action_water.png")]
		public var action_water:Class;
		[Embed(source="assets/graphics/announcements_close_x.png")]
		public var announcements_close_x:Class;
		[Embed(source="assets/graphics/audio_control_icon.png")]
		public var audio_control_icon:Class;
		[Embed(source="assets/graphics/audio_music.png")]
		public var audio_music:Class;
		[Embed(source="assets/graphics/audio_sfx.png")]
		public var audio_sfx:Class;
		[Embed(source="assets/graphics/back_arrow.png")]
		public var back_arrow:Class;
		[Embed(source="assets/graphics/back_arrow_disabled.png")]
		public var back_arrow_disabled:Class;
		[Embed(source="assets/graphics/back_arrow_hover.png")]
		public var back_arrow_hover:Class;
		[Embed(source="assets/graphics/back_circle.png")]
		public var back_circle:Class;
		[Embed(source="assets/graphics/back_circle_disabled.png")]
		public var back_circle_disabled:Class;
		[Embed(source="assets/graphics/back_circle_hover.png")]
		public var back_circle_hover:Class;
		[Embed(source="assets/graphics/buff_bang.png")]
		public var buff_bang:Class;
		[Embed(source="assets/graphics/buff_bang_white.png")]
		public var buff_bang_white:Class;
		[Embed(source="assets/graphics/bug_icon.png")]
		public var bug_icon:Class;
		[Embed(source="assets/graphics/bug_icon_disabled.png")]
		public var bug_icon_disabled:Class;
		[Embed(source="assets/graphics/cabinet_shelf_wood_center.png")]
		public var cabinet_shelf_wood_center:Class;
		[Embed(source="assets/graphics/cabinet_shelf_wood_end_left.png")]
		public var cabinet_shelf_wood_end_left:Class;
		[Embed(source="assets/graphics/cabinet_shelf_wood_end_right.png")]
		public var cabinet_shelf_wood_end_right:Class;
		[Embed(source="assets/graphics/cabinet_slot_empty.png")]
		public var cabinet_slot_empty:Class;
		[Embed(source="assets/graphics/cabinet_slot_full.png")]
		public var cabinet_slot_full:Class;
		[Embed(source="assets/graphics/callout_contacts.png")]
		public var callout_contacts:Class;
		[Embed(source="assets/graphics/callout_cultivate.png")]
		public var callout_cultivate:Class;
		[Embed(source="assets/graphics/callout_currants.png")]
		public var callout_currants:Class;
		[Embed(source="assets/graphics/callout_decorate.png")]
		public var callout_decorate:Class;
		[Embed(source="assets/graphics/callout_drink.png")]
		public var callout_drink:Class;
		[Embed(source="assets/graphics/callout_eat.png")]
		public var callout_eat:Class;
		[Embed(source="assets/graphics/callout_energy.png")]
		public var callout_energy:Class;
		[Embed(source="assets/graphics/callout_furniture.png")]
		public var callout_furniture:Class;
		[Embed(source="assets/graphics/callout_furniture_tab.png")]
		public var callout_furniture_tab:Class;
		[Embed(source="assets/graphics/callout_go_home.png")]
		public var callout_go_home:Class;
		[Embed(source="assets/graphics/callout_icon_map.png")]
		public var callout_icon_map:Class;
		[Embed(source="assets/graphics/callout_imagination_menu.png")]
		public var callout_imagination_menu:Class;
		[Embed(source="assets/graphics/callout_live_help.png")]
		public var callout_live_help:Class;
		[Embed(source="assets/graphics/callout_mini_map.png")]
		public var callout_mini_map:Class;
		[Embed(source="assets/graphics/callout_mood.png")]
		public var callout_mood:Class;
		[Embed(source="assets/graphics/callout_quests.png")]
		public var callout_quests:Class;
		[Embed(source="assets/graphics/callout_ready_to_save.png")]
		public var callout_ready_to_save:Class;
		[Embed(source="assets/graphics/callout_resource.png")]
		public var callout_resource:Class;
		[Embed(source="assets/graphics/callout_swatch_drag.png")]
		public var callout_swatch_drag:Class;
		[Embed(source="assets/graphics/callout_swatch_open.png")]
		public var callout_swatch_open:Class;
		[Embed(source="assets/graphics/callout_toolbar_close.png")]
		public var callout_toolbar_close:Class;
		[Embed(source="assets/graphics/callout_upgrades.png")]
		public var callout_upgrades:Class;
		[Embed(source="assets/graphics/camera_icon_small.png")]
		public var camera_icon_small:Class;
		[Embed(source="assets/graphics/camera_icon_with_text.png")]
		public var camera_icon_with_text:Class;
		[Embed(source="assets/graphics/carrat_large.png")]
		public var carrat_large:Class;
		[Embed(source="assets/graphics/cb_checked.png")]
		public var cb_checked:Class;
		[Embed(source="assets/graphics/cb_unchecked.png")]
		public var cb_unchecked:Class;
		[Embed(source="assets/graphics/chassis_flip.png")]
		public var chassis_flip:Class;
		[Embed(source="assets/graphics/chassis_flip_hover.png")]
		public var chassis_flip_hover:Class;
		[Embed(source="assets/graphics/chassis_randomize.png")]
		public var chassis_randomize:Class;
		[Embed(source="assets/graphics/chassis_randomize_hover.png")]
		public var chassis_randomize_hover:Class;
		[Embed(source="assets/graphics/chat_close.png")]
		public var chat_close:Class;
		[Embed(source="assets/graphics/chat_divider.png")]
		public var chat_divider:Class;
		[Embed(source="assets/graphics/chat_refresh.png")]
		public var chat_refresh:Class;
		[Embed(source="assets/graphics/chat_toggle_arrow.png")]
		public var chat_toggle_arrow:Class;
		[Embed(source="assets/graphics/checkmark_crafty.png")]
		public var checkmark_crafty:Class;
		[Embed(source="assets/graphics/close_decorate_toast.png")]
		public var close_decorate_toast:Class;
		[Embed(source="assets/graphics/close_gps.png")]
		public var close_gps:Class;
		[Embed(source="assets/graphics/close_swatch.png")]
		public var close_swatch:Class;
		[Embed(source="assets/graphics/close_swatch_hover.png")]
		public var close_swatch_hover:Class;
		[Embed(source="assets/graphics/close_x_grey.png")]
		public var close_x_grey:Class;
		[Embed(source="assets/graphics/close_x_making_slot.png")]
		public var close_x_making_slot:Class;
		[Embed(source="assets/graphics/close_x_small.png")]
		public var close_x_small:Class;
		[Embed(source="assets/graphics/close_x_small_gray.png")]
		public var close_x_small_gray:Class;
		[Embed(source="assets/graphics/collection_check.png")]
		public var collection_check:Class;
		[Embed(source="assets/graphics/contact_add_friend.png")]
		public var contact_add_friend:Class;
		[Embed(source="assets/graphics/contact_add_group.png")]
		public var contact_add_group:Class;
		[Embed(source="assets/graphics/contact_arrow.png")]
		public var contact_arrow:Class;
		[Embed(source="assets/graphics/contact_global.png")]
		public var contact_global:Class;
		[Embed(source="assets/graphics/contact_global_hover.png")]
		public var contact_global_hover:Class;
		[Embed(source="assets/graphics/contact_group.png")]
		public var contact_group:Class;
		[Embed(source="assets/graphics/contact_group_hover.png")]
		public var contact_group_hover:Class;
		[Embed(source="assets/graphics/contact_help.png")]
		public var contact_help:Class;
		[Embed(source="assets/graphics/contact_help_hover.png")]
		public var contact_help_hover:Class;
		[Embed(source="assets/graphics/contact_map.png")]
		public var contact_map:Class;
		[Embed(source="assets/graphics/contact_map_hover.png")]
		public var contact_map_hover:Class;
		[Embed(source="assets/graphics/contact_party.png")]
		public var contact_party:Class;
		[Embed(source="assets/graphics/contact_plus.png")]
		public var contact_plus:Class;
		[Embed(source="assets/graphics/contact_subway.png")]
		public var contact_subway:Class;
		[Embed(source="assets/graphics/contact_subway_hover.png")]
		public var contact_subway_hover:Class;
		[Embed(source="assets/graphics/contact_teleport.png")]
		public var contact_teleport:Class;
		[Embed(source="assets/graphics/contact_teleport_hover.png")]
		public var contact_teleport_hover:Class;
		[Embed(source="assets/graphics/contact_trade.png")]
		public var contact_trade:Class;
		[Embed(source="assets/graphics/contact_trade_hover.png")]
		public var contact_trade_hover:Class;
		[Embed(source="assets/graphics/crafty_bubbles.png")]
		public var crafty_bubbles:Class;
		[Embed(source="assets/graphics/crafty_crystal.png")]
		public var crafty_crystal:Class;
		[Embed(source="assets/graphics/currants_icon.png")]
		public var currants_icon:Class;
		[Embed(source="assets/graphics/daily_calendar_icon.png")]
		public var daily_calendar_icon:Class;
		[Embed(source="assets/graphics/daily_coin_icon.png")]
		public var daily_coin_icon:Class;
		[Embed(source="assets/graphics/decorate_close.png")]
		public var decorate_close:Class;
		[Embed(source="assets/graphics/decorate_icon.png")]
		public var decorate_icon:Class;
		[Embed(source="assets/graphics/dialog_gripper.png")]
		public var dialog_gripper:Class;
		[Embed(source="assets/graphics/edit_disabled.png")]
		public var edit_disabled:Class;
		[Embed(source="assets/graphics/edit_icon.png")]
		public var edit_icon:Class;
		[Embed(source="assets/graphics/edit_icon_hover.png")]
		public var edit_icon_hover:Class;
		[Embed(source="assets/graphics/edit_off.png")]
		public var edit_off:Class;
		[Embed(source="assets/graphics/edit_on.png")]
		public var edit_on:Class;
		[Embed(source="assets/graphics/elevator_disabled.png")]
		public var elevator_disabled:Class;
		[Embed(source="assets/graphics/elevator_hover.png")]
		public var elevator_hover:Class;
		[Embed(source="assets/graphics/elevator_normal.png")]
		public var elevator_normal:Class;
		[Embed(source="assets/graphics/emblem_arrow.png")]
		public var emblem_arrow:Class;
		[Embed(source="assets/graphics/empty_making_slot.png")]
		public var empty_making_slot:Class;
		[Embed(source="assets/graphics/empty_making_slot_small.png")]
		public var empty_making_slot_small:Class;
		[Embed(source="assets/graphics/empty_making_slot_white.png")]
		public var empty_making_slot_white:Class;
		[Embed(source="assets/graphics/empty_making_slot_wide.png")]
		public var empty_making_slot_wide:Class;
		[Embed(source="assets/graphics/encyclopedia_link.png")]
		public var encyclopedia_link:Class;
		[Embed(source="assets/graphics/encyclopedia_link_hover.png")]
		public var encyclopedia_link_hover:Class;
		[Embed(source="assets/graphics/energy_bolt.png")]
		public var energy_bolt:Class;
		[Embed(source="assets/graphics/energy_mood_gradient.png")]
		public var energy_mood_gradient:Class;
		[Embed(source="assets/graphics/enter_home_door.png")]
		public var enter_home_door:Class;
		[Embed(source="assets/graphics/enter_tower_door.png")]
		public var enter_tower_door:Class;
		[Embed(source="assets/graphics/expand_arrow.png")]
		public var expand_arrow:Class;
		[Embed(source="assets/graphics/expand_check.png")]
		public var expand_check:Class;
		[Embed(source="assets/graphics/expand_floor.png")]
		public var expand_floor:Class;
		[Embed(source="assets/graphics/expand_wall.png")]
		public var expand_wall:Class;
		[Embed(source="assets/graphics/expand_yard_arrow.png")]
		public var expand_yard_arrow:Class;
		[Embed(source="assets/graphics/expand_yard_check.png")]
		public var expand_yard_check:Class;
		[Embed(source="assets/graphics/facebook.png")]
		public var facebook:Class;
		[Embed(source="assets/graphics/familiar_dialog_learn_icon.png")]
		public var familiar_dialog_learn_icon:Class;
		[Embed(source="assets/graphics/familiar_dialog_quests.png")]
		public var familiar_dialog_quests:Class;
		[Embed(source="assets/graphics/familiar_dialog_quests_small.png")]
		public var familiar_dialog_quests_small:Class;
		[Embed(source="assets/graphics/familiar_dialog_set_point.png")]
		public var familiar_dialog_set_point:Class;
		[Embed(source="assets/graphics/familiar_dialog_teleport.png")]
		public var familiar_dialog_teleport:Class;
		[Embed(source="assets/graphics/familiar_dialog_teleport_small.png")]
		public var familiar_dialog_teleport_small:Class;
		[Embed(source="assets/graphics/feat_badge_small.png")]
		public var feat_badge_small:Class;
		[Embed(source="assets/graphics/feed_reply.png")]
		public var feed_reply:Class;
		[Embed(source="assets/graphics/feed_reply_close.png")]
		public var feed_reply_close:Class;
		[Embed(source="assets/graphics/filled_making_slot.png")]
		public var filled_making_slot:Class;
		[Embed(source="assets/graphics/find_nearest.png")]
		public var find_nearest:Class;
		[Embed(source="assets/graphics/find_nearest_disabled.png")]
		public var find_nearest_disabled:Class;
		[Embed(source="assets/graphics/furniture_new_badge.png")]
		public var furniture_new_badge:Class;
		[Embed(source="assets/graphics/furniture_new_badge_small.png")]
		public var furniture_new_badge_small:Class;
		[Embed(source="assets/graphics/furn_credits_large.png")]
		public var furn_credits_large:Class;
		[Embed(source="assets/graphics/furn_credits_small.png")]
		public var furn_credits_small:Class;
		[Embed(source="assets/graphics/furn_scroll.png")]
		public var furn_scroll:Class;
		[Embed(source="assets/graphics/furn_scroll_disabled.png")]
		public var furn_scroll_disabled:Class;
		[Embed(source="assets/graphics/furn_subscriber.png")]
		public var furn_subscriber:Class;
		[Embed(source="assets/graphics/furn_zoom.png")]
		public var furn_zoom:Class;
		[Embed(source="assets/graphics/geo_disabled.png")]
		public var geo_disabled:Class;
		[Embed(source="assets/graphics/geo_normal.png")]
		public var geo_normal:Class;
		[Embed(source="assets/graphics/get_info.png")]
		public var get_info:Class;
		[Embed(source="assets/graphics/get_info_hover.png")]
		public var get_info_hover:Class;
		[Embed(source="assets/graphics/giant_alph.png")]
		public var giant_alph:Class;
		[Embed(source="assets/graphics/giant_alph_hover.png")]
		public var giant_alph_hover:Class;
		[Embed(source="assets/graphics/giant_cosma.png")]
		public var giant_cosma:Class;
		[Embed(source="assets/graphics/giant_cosma_hover.png")]
		public var giant_cosma_hover:Class;
		[Embed(source="assets/graphics/giant_friendly.png")]
		public var giant_friendly:Class;
		[Embed(source="assets/graphics/giant_friendly_hover.png")]
		public var giant_friendly_hover:Class;
		[Embed(source="assets/graphics/giant_grendaline.png")]
		public var giant_grendaline:Class;
		[Embed(source="assets/graphics/giant_grendaline_hover.png")]
		public var giant_grendaline_hover:Class;
		[Embed(source="assets/graphics/giant_humbaba.png")]
		public var giant_humbaba:Class;
		[Embed(source="assets/graphics/giant_humbaba_hover.png")]
		public var giant_humbaba_hover:Class;
		[Embed(source="assets/graphics/giant_lem.png")]
		public var giant_lem:Class;
		[Embed(source="assets/graphics/giant_lem_hover.png")]
		public var giant_lem_hover:Class;
		[Embed(source="assets/graphics/giant_mab.png")]
		public var giant_mab:Class;
		[Embed(source="assets/graphics/giant_mab_hover.png")]
		public var giant_mab_hover:Class;
		[Embed(source="assets/graphics/giant_pot.png")]
		public var giant_pot:Class;
		[Embed(source="assets/graphics/giant_pot_hover.png")]
		public var giant_pot_hover:Class;
		[Embed(source="assets/graphics/giant_spriggan.png")]
		public var giant_spriggan:Class;
		[Embed(source="assets/graphics/giant_spriggan_hover.png")]
		public var giant_spriggan_hover:Class;
		[Embed(source="assets/graphics/giant_tii.png")]
		public var giant_tii:Class;
		[Embed(source="assets/graphics/giant_tii_hover.png")]
		public var giant_tii_hover:Class;
		[Embed(source="assets/graphics/giant_zille.png")]
		public var giant_zille:Class;
		[Embed(source="assets/graphics/giant_zille_hover.png")]
		public var giant_zille_hover:Class;
		[Embed(source="assets/graphics/glitchroid_close.png")]
		public var glitchroid_close:Class;
		[Embed(source="assets/graphics/glitchr_discard.png")]
		public var glitchr_discard:Class;
		[Embed(source="assets/graphics/glitchr_download.png")]
		public var glitchr_download:Class;
		[Embed(source="assets/graphics/glitchr_publish.png")]
		public var glitchr_publish:Class;
		[Embed(source="assets/graphics/glitchr_publish_disabled.png")]
		public var glitchr_publish_disabled:Class;
		[Embed(source="assets/graphics/god_menu.png")]
		public var god_menu:Class;
		[Embed(source="assets/graphics/god_pinned.png")]
		public var god_pinned:Class;
		[Embed(source="assets/graphics/god_thumb.png")]
		public var god_thumb:Class;
		[Embed(source="assets/graphics/god_unpinned.png")]
		public var god_unpinned:Class;
		[Embed(source="assets/graphics/guide_slug.png")]
		public var guide_slug:Class;
		[Embed(source="assets/graphics/hand_of_god_disabled.png")]
		public var hand_of_god_disabled:Class;
		[Embed(source="assets/graphics/hand_of_god_off.png")]
		public var hand_of_god_off:Class;
		[Embed(source="assets/graphics/hand_of_god_on.png")]
		public var hand_of_god_on:Class;
		[Embed(source="assets/graphics/help_icon.png")]
		public var help_icon:Class;
		[Embed(source="assets/graphics/help_icon_disabled.png")]
		public var help_icon_disabled:Class;
		[Embed(source="assets/graphics/help_icon_large.png")]
		public var help_icon_large:Class;
		[Embed(source="assets/graphics/help_locodeco.png")]
		public var help_locodeco:Class;
		[Embed(source="assets/graphics/hotkeys.png")]
		public var hotkeys:Class;
		[Embed(source="assets/graphics/imagination_button.png")]
		public var imagination_button:Class;
		[Embed(source="assets/graphics/imagination_button_clouds.png")]
		public var imagination_button_clouds:Class;
		[Embed(source="assets/graphics/imagination_button_down.png")]
		public var imagination_button_down:Class;
		[Embed(source="assets/graphics/imagination_button_hover.png")]
		public var imagination_button_hover:Class;
		[Embed(source="assets/graphics/imagination_no_menu.png")]
		public var imagination_no_menu:Class;
		[Embed(source="assets/graphics/imagination_space.png")]
		public var imagination_space:Class;
		[Embed(source="assets/graphics/iMG_back.png")]
		public var iMG_back:Class;
		[Embed(source="assets/graphics/iMG_close.png")]
		public var iMG_close:Class;
		[Embed(source="assets/graphics/img_icon.png")]
		public var img_icon:Class;
		[Embed(source="assets/graphics/info_auction.png")]
		public var info_auction:Class;
		[Embed(source="assets/graphics/info_tip.png")]
		public var info_tip:Class;
		[Embed(source="assets/graphics/info_warn.png")]
		public var info_warn:Class;
		[Embed(source="assets/graphics/input_check.png")]
		public var input_check:Class;
		[Embed(source="assets/graphics/input_check_disabled.png")]
		public var input_check_disabled:Class;
		[Embed(source="assets/graphics/input_check_hover.png")]
		public var input_check_hover:Class;
		[Embed(source="assets/graphics/int_menu_dis.png")]
		public var int_menu_dis:Class;
		[Embed(source="assets/graphics/int_menu_norm.png")]
		public var int_menu_norm:Class;
		[Embed(source="assets/graphics/inventory_search_pointy.png")]
		public var inventory_search_pointy:Class;
		[Embed(source="assets/graphics/item_info_currants.png")]
		public var item_info_currants:Class;
		[Embed(source="assets/graphics/item_info_durable.png")]
		public var item_info_durable:Class;
		[Embed(source="assets/graphics/item_info_grow_time.png")]
		public var item_info_grow_time:Class;
		[Embed(source="assets/graphics/item_info_pack_slot.png")]
		public var item_info_pack_slot:Class;
		[Embed(source="assets/graphics/item_play_button.png")]
		public var item_play_button:Class;
		[Embed(source="assets/graphics/job_either_arrows.png")]
		public var job_either_arrows:Class;
		[Embed(source="assets/graphics/job_group_divider.png")]
		public var job_group_divider:Class;
		[Embed(source="assets/graphics/job_group_hall_bg.png")]
		public var job_group_hall_bg:Class;
		[Embed(source="assets/graphics/job_leaderboard.png")]
		public var job_leaderboard:Class;
		[Embed(source="assets/graphics/job_map_bg.png")]
		public var job_map_bg:Class;
		[Embed(source="assets/graphics/lightbulb_off.png")]
		public var lightbulb_off:Class;
		[Embed(source="assets/graphics/lightbulb_on.png")]
		public var lightbulb_on:Class;
		[Embed(source="assets/graphics/lock_small.png")]
		public var lock_small:Class;
		[Embed(source="assets/graphics/logo_glitch.png")]
		public var logo_glitch:Class;
		[Embed(source="assets/graphics/mag_glass.png")]
		public var mag_glass:Class;
		[Embed(source="assets/graphics/mag_glass_inventory.png")]
		public var mag_glass_inventory:Class;
		[Embed(source="assets/graphics/mag_glass_item_search.png")]
		public var mag_glass_item_search:Class;
		[Embed(source="assets/graphics/mail_compose.png")]
		public var mail_compose:Class;
		[Embed(source="assets/graphics/mail_compose_hover.png")]
		public var mail_compose_hover:Class;
		[Embed(source="assets/graphics/mail_currants.png")]
		public var mail_currants:Class;
		[Embed(source="assets/graphics/mail_inbox_back.png")]
		public var mail_inbox_back:Class;
		[Embed(source="assets/graphics/mail_inbox_back_hover.png")]
		public var mail_inbox_back_hover:Class;
		[Embed(source="assets/graphics/mail_item_arrow.png")]
		public var mail_item_arrow:Class;
		[Embed(source="assets/graphics/mail_item_empty.png")]
		public var mail_item_empty:Class;
		[Embed(source="assets/graphics/mail_replied.png")]
		public var mail_replied:Class;
		[Embed(source="assets/graphics/mail_trash.png")]
		public var mail_trash:Class;
		[Embed(source="assets/graphics/mail_trash_read.png")]
		public var mail_trash_read:Class;
		[Embed(source="assets/graphics/mail_trash_read_hover.png")]
		public var mail_trash_read_hover:Class;
		[Embed(source="assets/graphics/mail_trash_red.png")]
		public var mail_trash_red:Class;
		[Embed(source="assets/graphics/making_drag_arrow.png")]
		public var making_drag_arrow:Class;
		[Embed(source="assets/graphics/making_info.png")]
		public var making_info:Class;
		[Embed(source="assets/graphics/making_info_small.png")]
		public var making_info_small:Class;
		[Embed(source="assets/graphics/map_expand_arrow.png")]
		public var map_expand_arrow:Class;
		[Embed(source="assets/graphics/map_icon.png")]
		public var map_icon:Class;
		[Embed(source="assets/graphics/map_icon_hover.png")]
		public var map_icon_hover:Class;
		[Embed(source="assets/graphics/map_icon_shop.png")]
		public var map_icon_shop:Class;
		[Embed(source="assets/graphics/map_icon_shrine.png")]
		public var map_icon_shrine:Class;
		[Embed(source="assets/graphics/map_icon_subway.png")]
		public var map_icon_subway:Class;
		[Embed(source="assets/graphics/minus_red.png")]
		public var minus_red:Class;
		[Embed(source="assets/graphics/minus_red_small.png")]
		public var minus_red_small:Class;
		[Embed(source="assets/graphics/mood_emoticons.png")]
		public var mood_emoticons:Class;
		[Embed(source="assets/graphics/newuser_img_menu.png")]
		public var newuser_img_menu:Class;
		[Embed(source="assets/graphics/new_day_mountains.png")]
		public var new_day_mountains:Class;
		[Embed(source="assets/graphics/notice_add_note_bg.png")]
		public var notice_add_note_bg:Class;
		[Embed(source="assets/graphics/notice_board_bg.jpg")]
		public var notice_board_bg:Class;
		[Embed(source="assets/graphics/notice_board_header_bg.png")]
		public var notice_board_header_bg:Class;
		[Embed(source="assets/graphics/notice_frame_bg.jpg")]
		public var notice_frame_bg:Class;
		[Embed(source="assets/graphics/no_sign.png")]
		public var no_sign:Class;
		[Embed(source="assets/graphics/pack_slot_empty.png")]
		public var pack_slot_empty:Class;
		[Embed(source="assets/graphics/pack_slot_full.png")]
		public var pack_slot_full:Class;
		[Embed(source="assets/graphics/pack_tool_broken.png")]
		public var pack_tool_broken:Class;
		[Embed(source="assets/graphics/paper_texture.jpg")]
		public var paper_texture:Class;
		[Embed(source="assets/graphics/path_marker.png")]
		public var path_marker:Class;
		[Embed(source="assets/graphics/pause_icon.png")]
		public var pause_icon:Class;
		[Embed(source="assets/graphics/pause_icon_hover.png")]
		public var pause_icon_hover:Class;
		[Embed(source="assets/graphics/plat_lines_disabled.png")]
		public var plat_lines_disabled:Class;
		[Embed(source="assets/graphics/plat_lines_off.png")]
		public var plat_lines_off:Class;
		[Embed(source="assets/graphics/plat_lines_off2.png")]
		public var plat_lines_off2:Class;
		[Embed(source="assets/graphics/plat_lines_on.png")]
		public var plat_lines_on:Class;
		[Embed(source="assets/graphics/player_face_empty.png")]
		public var player_face_empty:Class;
		[Embed(source="assets/graphics/player_face_rays.png")]
		public var player_face_rays:Class;
		[Embed(source="assets/graphics/play_button.png")]
		public var play_button:Class;
		[Embed(source="assets/graphics/play_icon.png")]
		public var play_icon:Class;
		[Embed(source="assets/graphics/play_icon_hover.png")]
		public var play_icon_hover:Class;
		[Embed(source="assets/graphics/plus_green.png")]
		public var plus_green:Class;
		[Embed(source="assets/graphics/plus_green_small.png")]
		public var plus_green_small:Class;
		[Embed(source="assets/graphics/prompt_check.png")]
		public var prompt_check:Class;
		[Embed(source="assets/graphics/prompt_x.png")]
		public var prompt_x:Class;
		[Embed(source="assets/graphics/pushpin_sm_blue.png")]
		public var pushpin_sm_blue:Class;
		[Embed(source="assets/graphics/pushpin_sm_green.png")]
		public var pushpin_sm_green:Class;
		[Embed(source="assets/graphics/pushpin_sm_red.png")]
		public var pushpin_sm_red:Class;
		[Embed(source="assets/graphics/pushpin_sm_yellow.png")]
		public var pushpin_sm_yellow:Class;
		[Embed(source="assets/graphics/quarter_bg.jpg")]
		public var quarter_bg:Class;
		[Embed(source="assets/graphics/quest_book.png")]
		public var quest_book:Class;
		[Embed(source="assets/graphics/quest_bubble_active.png")]
		public var quest_bubble_active:Class;
		[Embed(source="assets/graphics/quest_bubble_complete.png")]
		public var quest_bubble_complete:Class;
		[Embed(source="assets/graphics/quest_requirement.png")]
		public var quest_requirement:Class;
		[Embed(source="assets/graphics/quest_requirement_complete.png")]
		public var quest_requirement_complete:Class;
		[Embed(source="assets/graphics/qurazy_quoin.png")]
		public var qurazy_quoin:Class;
		[Embed(source="assets/graphics/r3_message_overlay.png")]
		public var r3_message_overlay:Class;
		[Embed(source="assets/graphics/recenter_disabled.png")]
		public var recenter_disabled:Class;
		[Embed(source="assets/graphics/recenter_hover.png")]
		public var recenter_hover:Class;
		[Embed(source="assets/graphics/recenter_link.png")]
		public var recenter_link:Class;
		[Embed(source="assets/graphics/redeal.png")]
		public var redeal:Class;
		[Embed(source="assets/graphics/redeal_no.png")]
		public var redeal_no:Class;
		[Embed(source="assets/graphics/remove.png")]
		public var remove:Class;
		[Embed(source="assets/graphics/renderer_bitmap_disabled.png")]
		public var renderer_bitmap_disabled:Class;
		[Embed(source="assets/graphics/renderer_bitmap_normal.png")]
		public var renderer_bitmap_normal:Class;
		[Embed(source="assets/graphics/renderer_vector_disabled.png")]
		public var renderer_vector_disabled:Class;
		[Embed(source="assets/graphics/renderer_vector_normal.png")]
		public var renderer_vector_normal:Class;
		[Embed(source="assets/graphics/repeating_clouds.png")]
		public var repeating_clouds:Class;
		[Embed(source="assets/graphics/resize_swatch.png")]
		public var resize_swatch:Class;
		[Embed(source="assets/graphics/revert_disabled.png")]
		public var revert_disabled:Class;
		[Embed(source="assets/graphics/revert_disabled2.png")]
		public var revert_disabled2:Class;
		[Embed(source="assets/graphics/revert_normal.png")]
		public var revert_normal:Class;
		[Embed(source="assets/graphics/rook_star_bg.png")]
		public var rook_star_bg:Class;
		[Embed(source="assets/graphics/rook_star_stars.png")]
		public var rook_star_stars:Class;
		[Embed(source="assets/graphics/save_disabled.png")]
		public var save_disabled:Class;
		[Embed(source="assets/graphics/save_disabled2.png")]
		public var save_disabled2:Class;
		[Embed(source="assets/graphics/save_normal.png")]
		public var save_normal:Class;
		[Embed(source="assets/graphics/scroll_arrow.png")]
		public var scroll_arrow:Class;
		[Embed(source="assets/graphics/search_mag_glass.png")]
		public var search_mag_glass:Class;
		[Embed(source="assets/graphics/share_facebook.png")]
		public var share_facebook:Class;
		[Embed(source="assets/graphics/share_google.png")]
		public var share_google:Class;
		[Embed(source="assets/graphics/share_pinterest.png")]
		public var share_pinterest:Class;
		[Embed(source="assets/graphics/share_twitter.png")]
		public var share_twitter:Class;
		[Embed(source="assets/graphics/shelf_level.png")]
		public var shelf_level:Class;
		[Embed(source="assets/graphics/shelf_trophy.png")]
		public var shelf_trophy:Class;
		[Embed(source="assets/graphics/signpost_arm.png")]
		public var signpost_arm:Class;
		[Embed(source="assets/graphics/signpost_friends_base.png")]
		public var signpost_friends_base:Class;
		[Embed(source="assets/graphics/signpost_friends_cancel.png")]
		public var signpost_friends_cancel:Class;
		[Embed(source="assets/graphics/signpost_friends_hover.png")]
		public var signpost_friends_hover:Class;
		[Embed(source="assets/graphics/signpost_friends_icon.png")]
		public var signpost_friends_icon:Class;
		[Embed(source="assets/graphics/signpost_friends_sign_0.png")]
		public var signpost_friends_sign_0:Class;
		[Embed(source="assets/graphics/signpost_friends_sign_1.png")]
		public var signpost_friends_sign_1:Class;
		[Embed(source="assets/graphics/signpost_friends_sign_2.png")]
		public var signpost_friends_sign_2:Class;
		[Embed(source="assets/graphics/signpost_friends_sign_3.png")]
		public var signpost_friends_sign_3:Class;
		[Embed(source="assets/graphics/signpost_friends_sign_4.png")]
		public var signpost_friends_sign_4:Class;
		[Embed(source="assets/graphics/signpost_post.png")]
		public var signpost_post:Class;
		[Embed(source="assets/graphics/signpost_quarter_arm.png")]
		public var signpost_quarter_arm:Class;
		[Embed(source="assets/graphics/signpost_quarter_grid.png")]
		public var signpost_quarter_grid:Class;
		[Embed(source="assets/graphics/signpost_shadow.png")]
		public var signpost_shadow:Class;
		[Embed(source="assets/graphics/skill_book_small.png")]
		public var skill_book_small:Class;
		[Embed(source="assets/graphics/slug_currants_neg.png")]
		public var slug_currants_neg:Class;
		[Embed(source="assets/graphics/slug_currants_pos.png")]
		public var slug_currants_pos:Class;
		[Embed(source="assets/graphics/slug_energy_neg.png")]
		public var slug_energy_neg:Class;
		[Embed(source="assets/graphics/slug_energy_pos.png")]
		public var slug_energy_pos:Class;
		[Embed(source="assets/graphics/slug_favor_neg.png")]
		public var slug_favor_neg:Class;
		[Embed(source="assets/graphics/slug_favor_pos.png")]
		public var slug_favor_pos:Class;
		[Embed(source="assets/graphics/slug_imagination_neg.png")]
		public var slug_imagination_neg:Class;
		[Embed(source="assets/graphics/slug_imagination_pos.png")]
		public var slug_imagination_pos:Class;
		[Embed(source="assets/graphics/slug_mood_neg.png")]
		public var slug_mood_neg:Class;
		[Embed(source="assets/graphics/slug_mood_pos.png")]
		public var slug_mood_pos:Class;
		[Embed(source="assets/graphics/slug_xp_neg.png")]
		public var slug_xp_neg:Class;
		[Embed(source="assets/graphics/slug_xp_pos.png")]
		public var slug_xp_pos:Class;
		[Embed(source="assets/graphics/solid_arrow.png")]
		public var solid_arrow:Class;
		[Embed(source="assets/graphics/solid_arrow_disabled.png")]
		public var solid_arrow_disabled:Class;
		[Embed(source="assets/graphics/solid_arrow_hover.png")]
		public var solid_arrow_hover:Class;
		[Embed(source="assets/graphics/staff_slug.png")]
		public var staff_slug:Class;
		[Embed(source="assets/graphics/store_currants.png")]
		public var store_currants:Class;
		[Embed(source="assets/graphics/store_shelf.png")]
		public var store_shelf:Class;
		[Embed(source="assets/graphics/store_shelf_new.png")]
		public var store_shelf_new:Class;
		[Embed(source="assets/graphics/store_warning.png")]
		public var store_warning:Class;
		[Embed(source="assets/graphics/street_cultivate.png")]
		public var street_cultivate:Class;
		[Embed(source="assets/graphics/street_cultivate_disabled.png")]
		public var street_cultivate_disabled:Class;
		[Embed(source="assets/graphics/street_cultivate_hover.png")]
		public var street_cultivate_hover:Class;
		[Embed(source="assets/graphics/street_expand.png")]
		public var street_expand:Class;
		[Embed(source="assets/graphics/street_expand_disabled.png")]
		public var street_expand_disabled:Class;
		[Embed(source="assets/graphics/street_expand_hover.png")]
		public var street_expand_hover:Class;
		[Embed(source="assets/graphics/street_house_exterior.png")]
		public var street_house_exterior:Class;
		[Embed(source="assets/graphics/street_house_exterior_disabled.png")]
		public var street_house_exterior_disabled:Class;
		[Embed(source="assets/graphics/street_house_exterior_hover.png")]
		public var street_house_exterior_hover:Class;
		[Embed(source="assets/graphics/street_house_keys.png")]
		public var street_house_keys:Class;
		[Embed(source="assets/graphics/street_house_keys_disabled.png")]
		public var street_house_keys_disabled:Class;
		[Embed(source="assets/graphics/street_house_keys_hover.png")]
		public var street_house_keys_hover:Class;
		[Embed(source="assets/graphics/street_style.png")]
		public var street_style:Class;
		[Embed(source="assets/graphics/street_style_disabled.png")]
		public var street_style_disabled:Class;
		[Embed(source="assets/graphics/street_style_hover.png")]
		public var street_style_hover:Class;
		[Embed(source="assets/graphics/street_tower.png")]
		public var street_tower:Class;
		[Embed(source="assets/graphics/street_tower_disabled.png")]
		public var street_tower_disabled:Class;
		[Embed(source="assets/graphics/street_tower_hover.png")]
		public var street_tower_hover:Class;
		[Embed(source="assets/graphics/subway_map_star.png")]
		public var subway_map_star:Class;
		[Embed(source="assets/graphics/super_search_no_results.png")]
		public var super_search_no_results:Class;
		[Embed(source="assets/graphics/teensy_signpost.png")]
		public var teensy_signpost:Class;
		[Embed(source="assets/graphics/teleportation_token_imbued.png")]
		public var teleportation_token_imbued:Class;
		[Embed(source="assets/graphics/teleportation_token_unimbued.png")]
		public var teleportation_token_unimbued:Class;
		[Embed(source="assets/graphics/teleportation_token_unimbued_buymore.png")]
		public var teleportation_token_unimbued_buymore:Class;
		[Embed(source="assets/graphics/teleportation_token_unimbued_coststoken.png")]
		public var teleportation_token_unimbued_coststoken:Class;
		[Embed(source="assets/graphics/teleportation_token_unimbued_noskill.png")]
		public var teleportation_token_unimbued_noskill:Class;
		[Embed(source="assets/graphics/teleport_icon.png")]
		public var teleport_icon:Class;
		[Embed(source="assets/graphics/tend_pet.png")]
		public var tend_pet:Class;
		[Embed(source="assets/graphics/tend_pet_disabled.png")]
		public var tend_pet_disabled:Class;
		[Embed(source="assets/graphics/tend_water.png")]
		public var tend_water:Class;
		[Embed(source="assets/graphics/tend_water_disabled.png")]
		public var tend_water_disabled:Class;
		[Embed(source="assets/graphics/trade_icon.png")]
		public var trade_icon:Class;
		[Embed(source="assets/graphics/trade_icon_small.png")]
		public var trade_icon_small:Class;
		[Embed(source="assets/graphics/trade_lock.png")]
		public var trade_lock:Class;
		[Embed(source="assets/graphics/transit_subway.png")]
		public var transit_subway:Class;
		[Embed(source="assets/graphics/transit_subway_hover.png")]
		public var transit_subway_hover:Class;
		[Embed(source="assets/graphics/trophy_display_slot_empty.png")]
		public var trophy_display_slot_empty:Class;
		[Embed(source="assets/graphics/twitter.png")]
		public var twitter:Class;
		[Embed(source="assets/graphics/unexpand_wall.png")]
		public var unexpand_wall:Class;
		[Embed(source="assets/graphics/upgrade_arrow.png")]
		public var upgrade_arrow:Class;
		[Embed(source="assets/graphics/upgrade_badge.png")]
		public var upgrade_badge:Class;
		[Embed(source="assets/graphics/upgrade_icon.png")]
		public var upgrade_icon:Class;
		[Embed(source="assets/graphics/visit_home.png")]
		public var visit_home:Class;
		[Embed(source="assets/graphics/visit_home_disabled.png")]
		public var visit_home_disabled:Class;
		[Embed(source="assets/graphics/visit_home_hover.png")]
		public var visit_home_hover:Class;
		[Embed(source="assets/graphics/wardrobe_background.png")]
		public var wardrobe_background:Class;
		[Embed(source="assets/graphics/warning.png")]
		public var warning:Class;
		[Embed(source="assets/graphics/white_arrow.png")]
		public var white_arrow:Class;
		[Embed(source="assets/graphics/white_arrow_large.png")]
		public var white_arrow_large:Class;
		[Embed(source="assets/graphics/word_dismisser_cancel.png")]
		public var word_dismisser_cancel:Class;
		[Embed(source="assets/graphics/word_dismisser_cancel_hover.png")]
		public var word_dismisser_cancel_hover:Class;
		[Embed(source="assets/graphics/world_map_disabled.png")]
		public var world_map_disabled:Class;
		[Embed(source="assets/graphics/world_map_hover.png")]
		public var world_map_hover:Class;
		[Embed(source="assets/graphics/world_map_link.png")]
		public var world_map_link:Class;
		[Embed(source="assets/graphics/world_map_zoomin_disabled.png")]
		public var world_map_zoomin_disabled:Class;
		[Embed(source="assets/graphics/world_map_zoomin_hover.png")]
		public var world_map_zoomin_hover:Class;
		[Embed(source="assets/graphics/world_map_zoomin_link.png")]
		public var world_map_zoomin_link:Class;
		
		[Embed(source="assets/swfs/achievement_badge.swf")]
		public var achievement_badge:Class;
		[Embed(source="assets/swfs/advancer.swf")]
		public var advancer:Class;
		[Embed(source="assets/swfs/advancer_triangle.swf")]
		public var advancer_triangle:Class;
		[Embed(source="assets/swfs/advancer_white.swf")]
		public var advancer_white:Class;
		[Embed(source="assets/swfs/advancer_white_enter.swf")]
		public var advancer_white_enter:Class;
		[Embed(source="assets/swfs/avatar_rain.swf")]
		public var avatar_rain:Class;
		[Embed(source="assets/swfs/blue_advancer.swf")]
		public var blue_advancer:Class;
		[Embed(source="assets/swfs/checkmark.swf")]
		public var checkmark:Class;
		[Embed(source="assets/swfs/focus_off.swf")]
		public var focus_off:Class;
		[Embed(source="assets/swfs/gps_assets.swf")]
		public var gps_assets:Class;
		[Embed(source="assets/swfs/greencheck.swf")]
		public var greencheck:Class;
		[Embed(source="assets/swfs/hand_redeal.swf")]
		public var hand_redeal:Class;
		[Embed(source="assets/swfs/imagination_cards.swf")]
		public var imagination_cards:Class;
		[Embed(source="assets/swfs/imagination_clouds.swf")]
		public var imagination_clouds:Class;
		[Embed(source="assets/swfs/invoking_placeable_indicator_a.swf")]
		public var invoking_placeable_indicator_a:Class;
		[Embed(source="assets/swfs/invoking_placeable_indicator_b.swf")]
		public var invoking_placeable_indicator_b:Class;
		[Embed(source="assets/swfs/item_info_burst.swf")]
		public var item_info_burst:Class;
		[Embed(source="assets/swfs/level_up_badge.swf")]
		public var level_up_badge:Class;
		[Embed(source="assets/swfs/level_up_rays.swf")]
		public var level_up_rays:Class;
		[Embed(source="assets/swfs/level_up_words.swf")]
		public var level_up_words:Class;
		[Embed(source="assets/swfs/mini_map_you.swf")]
		public var mini_map_you:Class;
		[Embed(source="assets/swfs/overlay_bubble.swf")]
		public var overlay_bubble:Class;
		[Embed(source="assets/swfs/rays.swf")]
		public var rays:Class;
		[Embed(source="assets/swfs/rooked.swf")]
		public var rooked:Class;
		[Embed(source="assets/swfs/rook_attack_FX.swf")]
		public var rook_attack_FX:Class;
		[Embed(source="assets/swfs/spinner.swf")]
		public var spinner:Class;
		[Embed(source="assets/swfs/talk_bubble_body.swf")]
		public var talk_bubble_body:Class;
		[Embed(source="assets/swfs/talk_bubble_point.swf")]
		public var talk_bubble_point:Class;
		[Embed(source="assets/swfs/word_progress_bar.swf")]
		public var word_progress_bar:Class;
		
		[Embed(source="assets/fonts/Helvetica.ttf", fontName="HelveticaEmbed")]
		public var Helvetica:Class;
		[Embed(source="assets/fonts/Helvetica_bold.ttf",  fontWeight="bold", fontName="HelveticaEmbed")]
		public var Helvetica_bold:Class;
		[Embed(source="assets/fonts/Helvetica_bold_italic.ttf", fontStyle="italic", fontName="HelveticaEmbed")]
		public var Helvetica_bold_italic:Class;
		[Embed(source="assets/fonts/pf_ronda_seven.ttf", fontName="pfEmbed")]
		public var pf_ronda_seven:Class;
		[Embed(source="assets/fonts/VAGRoundedBold.ttf", fontName="VAGRoundedBoldEmbed")]
		public var VAGRoundedBold:Class;
		[Embed(source="assets/fonts/VAGRoundedLight.ttf", fontName="VAGRoundedLightEmbed")]
		public var VAGRoundedLight:Class;
		[Embed(source="assets/fonts/VAGRoundedLight_bold.ttf",  fontWeight="bold", fontName="VAGRoundedLightEmbed")]
		public var VAGRoundedLight_bold:Class;
		
		
		public var soundsA:Array = ['Prisencolinensinainciusol','trumpet']

		public var graphicsA:Array = ['about_energy','about_mood','acl_icons','acl_icons_no_stroke','action_feed','action_massage','action_pet','action_water','announcements_close_x','audio_control_icon','audio_music','audio_sfx','back_arrow','back_arrow_disabled','back_arrow_hover','back_circle','back_circle_disabled','back_circle_hover','buff_bang','buff_bang_white','bug_icon','bug_icon_disabled','cabinet_shelf_wood_center','cabinet_shelf_wood_end_left','cabinet_shelf_wood_end_right','cabinet_slot_empty','cabinet_slot_full','callout_contacts','callout_cultivate','callout_currants','callout_decorate','callout_drink','callout_eat','callout_energy','callout_furniture','callout_furniture_tab','callout_go_home','callout_icon_map','callout_imagination_menu','callout_live_help','callout_mini_map','callout_mood','callout_quests','callout_ready_to_save','callout_resource','callout_swatch_drag','callout_swatch_open','callout_toolbar_close','callout_upgrades','camera_icon_small','camera_icon_with_text','carrat_large','cb_checked','cb_unchecked','chassis_flip','chassis_flip_hover','chassis_randomize','chassis_randomize_hover','chat_close','chat_divider','chat_refresh','chat_toggle_arrow','checkmark_crafty','close_decorate_toast','close_gps','close_swatch','close_swatch_hover','close_x_grey','close_x_making_slot','close_x_small','close_x_small_gray','collection_check','contact_add_friend','contact_add_group','contact_arrow','contact_global','contact_global_hover','contact_group','contact_group_hover','contact_help','contact_help_hover','contact_map','contact_map_hover','contact_party','contact_plus','contact_subway','contact_subway_hover','contact_teleport','contact_teleport_hover','contact_trade','contact_trade_hover','crafty_bubbles','crafty_crystal','currants_icon','daily_calendar_icon','daily_coin_icon','decorate_close','decorate_icon','dialog_gripper','edit_disabled','edit_icon','edit_icon_hover','edit_off','edit_on','elevator_disabled','elevator_hover','elevator_normal','emblem_arrow','empty_making_slot','empty_making_slot_small','empty_making_slot_white','empty_making_slot_wide','encyclopedia_link','encyclopedia_link_hover','energy_bolt','energy_mood_gradient','enter_home_door','enter_tower_door','expand_arrow','expand_check','expand_floor','expand_wall','expand_yard_arrow','expand_yard_check','facebook','familiar_dialog_learn_icon','familiar_dialog_quests','familiar_dialog_quests_small','familiar_dialog_set_point','familiar_dialog_teleport','familiar_dialog_teleport_small','feat_badge_small','feed_reply','feed_reply_close','filled_making_slot','find_nearest','find_nearest_disabled','furniture_new_badge','furniture_new_badge_small','furn_credits_large','furn_credits_small','furn_scroll','furn_scroll_disabled','furn_subscriber','furn_zoom','geo_disabled','geo_normal','get_info','get_info_hover','giant_alph','giant_alph_hover','giant_cosma','giant_cosma_hover','giant_friendly','giant_friendly_hover','giant_grendaline','giant_grendaline_hover','giant_humbaba','giant_humbaba_hover','giant_lem','giant_lem_hover','giant_mab','giant_mab_hover','giant_pot','giant_pot_hover','giant_spriggan','giant_spriggan_hover','giant_tii','giant_tii_hover','giant_zille','giant_zille_hover','glitchroid_close','glitchr_discard','glitchr_download','glitchr_publish','glitchr_publish_disabled','god_menu','god_pinned','god_thumb','god_unpinned','guide_slug','hand_of_god_disabled','hand_of_god_off','hand_of_god_on','help_icon','help_icon_disabled','help_icon_large','help_locodeco','hotkeys','imagination_button','imagination_button_clouds','imagination_button_down','imagination_button_hover','imagination_no_menu','imagination_space','iMG_back','iMG_close','img_icon','info_auction','info_tip','info_warn','input_check','input_check_disabled','input_check_hover','int_menu_dis','int_menu_norm','inventory_search_pointy','item_info_currants','item_info_durable','item_info_grow_time','item_info_pack_slot','item_play_button','job_either_arrows','job_group_divider','job_group_hall_bg','job_leaderboard','job_map_bg','lightbulb_off','lightbulb_on','lock_small','logo_glitch','mag_glass','mag_glass_inventory','mag_glass_item_search','mail_compose','mail_compose_hover','mail_currants','mail_inbox_back','mail_inbox_back_hover','mail_item_arrow','mail_item_empty','mail_replied','mail_trash','mail_trash_read','mail_trash_read_hover','mail_trash_red','making_drag_arrow','making_info','making_info_small','map_expand_arrow','map_icon','map_icon_hover','map_icon_shop','map_icon_shrine','map_icon_subway','minus_red','minus_red_small','mood_emoticons','newuser_img_menu','new_day_mountains','notice_add_note_bg','notice_board_bg','notice_board_header_bg','notice_frame_bg','no_sign','pack_slot_empty','pack_slot_full','pack_tool_broken','paper_texture','path_marker','pause_icon','pause_icon_hover','plat_lines_disabled','plat_lines_off','plat_lines_off2','plat_lines_on','player_face_empty','player_face_rays','play_button','play_icon','play_icon_hover','plus_green','plus_green_small','prompt_check','prompt_x','pushpin_sm_blue','pushpin_sm_green','pushpin_sm_red','pushpin_sm_yellow','quarter_bg','quest_book','quest_bubble_active','quest_bubble_complete','quest_requirement','quest_requirement_complete','qurazy_quoin','r3_message_overlay','recenter_disabled','recenter_hover','recenter_link','redeal','redeal_no','remove','renderer_bitmap_disabled','renderer_bitmap_normal','renderer_vector_disabled','renderer_vector_normal','repeating_clouds','resize_swatch','revert_disabled','revert_disabled2','revert_normal','rook_star_bg','rook_star_stars','save_disabled','save_disabled2','save_normal','scroll_arrow','search_mag_glass','share_facebook','share_google','share_pinterest','share_twitter','shelf_level','shelf_trophy','signpost_arm','signpost_friends_base','signpost_friends_cancel','signpost_friends_hover','signpost_friends_icon','signpost_friends_sign_0','signpost_friends_sign_1','signpost_friends_sign_2','signpost_friends_sign_3','signpost_friends_sign_4','signpost_post','signpost_quarter_arm','signpost_quarter_grid','signpost_shadow','skill_book_small','slug_currants_neg','slug_currants_pos','slug_energy_neg','slug_energy_pos','slug_favor_neg','slug_favor_pos','slug_imagination_neg','slug_imagination_pos','slug_mood_neg','slug_mood_pos','slug_xp_neg','slug_xp_pos','solid_arrow','solid_arrow_disabled','solid_arrow_hover','staff_slug','store_currants','store_shelf','store_shelf_new','store_warning','street_cultivate','street_cultivate_disabled','street_cultivate_hover','street_expand','street_expand_disabled','street_expand_hover','street_house_exterior','street_house_exterior_disabled','street_house_exterior_hover','street_house_keys','street_house_keys_disabled','street_house_keys_hover','street_style','street_style_disabled','street_style_hover','street_tower','street_tower_disabled','street_tower_hover','subway_map_star','super_search_no_results','teensy_signpost','teleportation_token_imbued','teleportation_token_unimbued','teleportation_token_unimbued_buymore','teleportation_token_unimbued_coststoken','teleportation_token_unimbued_noskill','teleport_icon','tend_pet','tend_pet_disabled','tend_water','tend_water_disabled','trade_icon','trade_icon_small','trade_lock','transit_subway','transit_subway_hover','trophy_display_slot_empty','twitter','unexpand_wall','upgrade_arrow','upgrade_badge','upgrade_icon','visit_home','visit_home_disabled','visit_home_hover','wardrobe_background','warning','white_arrow','white_arrow_large','word_dismisser_cancel','word_dismisser_cancel_hover','world_map_disabled','world_map_hover','world_map_link','world_map_zoomin_disabled','world_map_zoomin_hover','world_map_zoomin_link']

		public var swfsA:Array = ['achievement_badge','advancer','advancer_triangle','advancer_white','advancer_white_enter','avatar_rain','blue_advancer','checkmark','focus_off','gps_assets','greencheck','hand_redeal','imagination_cards','imagination_clouds','invoking_placeable_indicator_a','invoking_placeable_indicator_b','item_info_burst','level_up_badge','level_up_rays','level_up_words','mini_map_you','overlay_bubble','rays','rooked','rook_attack_FX','spinner','talk_bubble_body','talk_bubble_point','word_progress_bar']

		public var fontsA:Array = ['Helvetica','Helvetica_bold','Helvetica_bold_italic','pf_ronda_seven','VAGRoundedBold','VAGRoundedLight','VAGRoundedLight_bold']

		
		public function Assets():void {
			Security.allowDomain("*");
		}

	}
}
	