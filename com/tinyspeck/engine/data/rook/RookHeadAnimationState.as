package com.tinyspeck.engine.data.rook
{
	import com.tinyspeck.engine.spritesheet.AnimationSequenceCommand;

	public class RookHeadAnimationState
	{
		/*****************************************
		 * These values get mapped to animation sequences in RookManager.setRookHead()
		 *****************************************/
		
		public static const IDLE:String = 'IDLE';
		public static const TAUNT:String = 'TAUNT';
		public static const STUNNED:String = 'STUNNED';
		public static const DEAD:String = 'DEAD';
		public static const HIT:String = 'HIT';
		
		/*****************************************
		 * These values are used for rook_head.fla animation sequences
		 *****************************************/
		/*
		from rook_head.fla:
		animations = ['idle1', 'idle2', 'taunt', 'hitAndRecover', 'stun', 'stunned', 'stunnedHit', 'killShot', 'dead', 'angry1', 'angry2', 'angry3'];
		loopers = ['idle1', 'idle2', 'stunned', 'dead'];
		*/
		
		public static const IDLE_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['idle1:3', 'idle2:1', 'idle1:6', 'idle2:1'], true);
		IDLE_ASC.name = 'IDLE_ASC';
		public static const IDLE_ANGRY1_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['angry1:1', 'idle1:3', 'angry1:1', 'idle1:5'], true);
		IDLE_ANGRY1_ASC.name = 'IDLE_ANGRY1_ASC';
		public static const IDLE_ANGRY2_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['angry2:1', 'idle1:3', 'angry2:1', 'idle1:5'], true);
		IDLE_ANGRY2_ASC.name = 'IDLE_ANGRY2_ASC';
		public static const IDLE_ANGRY3_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['angry3:1', 'idle1:3', 'angry3:1', 'idle1:5'], true);
		IDLE_ANGRY3_ASC.name = 'IDLE_ANGRY3_ASC';
		
		/*
		public static const IDLE_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['idle1:1', 'idle2:1', 'idle1:1', 'idle2:1'], true);
		public static const IDLE_ANGRY1_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['angry1:1', 'idle1:1', 'angry1:1', 'idle1:1'], true);
		public static const IDLE_ANGRY2_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['angry2:1', 'idle1:1', 'angry2:1', 'idle1:1'], true);
		public static const IDLE_ANGRY3_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['angry3:1', 'idle1:1', 'angry3:1', 'idle1:1'], true);
		*/
		public static const TAUNT_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['taunt:2'], false);
		TAUNT_ASC.name = 'TAUNT_ASC';
		public static const STUNNED_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['stunned:1'], true);
		STUNNED_ASC.name = 'STUNNED_ASC';
		public static const DEAD_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['dead:1'], false);
		DEAD_ASC.name = 'DEAD_ASC';
		// not stunned yet, hit and then stunned
		public static const HIT_STUNNED_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['stun:1'], false);
		HIT_STUNNED_ASC.name = 'HIT_STUNNED_ASC';
		// not stunned yet, hit and then NOT stunned
		public static const HIT_IDLE_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['hitAndRecover:1'], false);
		HIT_IDLE_ASC.name = 'HIT_IDLE_ASC';
		// already stunned, hit again and then stunned
		public static const STUNNED_HIT_STUNNED_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['stunnedHit:1'], false);
		STUNNED_HIT_STUNNED_ASC.name = 'STUNNED_HIT_STUNNED_ASC';
		// hit and and then dead
		public static const HIT_DEAD_ASC:AnimationSequenceCommand = new AnimationSequenceCommand(['killShot:1'], false);
		HIT_DEAD_ASC.name = 'HIT_DEAD_ASC';
	}
}