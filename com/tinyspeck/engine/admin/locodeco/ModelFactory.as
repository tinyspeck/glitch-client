package com.tinyspeck.engine.admin.locodeco
{
import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
import com.tinyspeck.engine.data.location.Box;
import com.tinyspeck.engine.data.location.Deco;
import com.tinyspeck.engine.data.location.Door;
import com.tinyspeck.engine.data.location.Ladder;
import com.tinyspeck.engine.data.location.PlatformLine;
import com.tinyspeck.engine.data.location.SignPost;
import com.tinyspeck.engine.data.location.Target;
import com.tinyspeck.engine.data.location.Wall;
import com.tinyspeck.engine.view.renderer.DecoAssetManager;

import locodeco.models.BoxModel;
import locodeco.models.DecoModel;
import locodeco.models.DecoModelTypes;
import locodeco.models.DoorModel;
import locodeco.models.LadderModel;
import locodeco.models.LayerModel;
import locodeco.models.PlatformLineModel;
import locodeco.models.SignPostModel;
import locodeco.models.TargetModel;
import locodeco.models.WallModel;
import locodeco.util.TSIDGen;

internal final class ModelFactory
{
	public static function newLocationModelFromAMF(decoModelType:String, amf:Object):AbstractPositionableLocationEntity {
		// build a new Deco; new, unique TSID, but the friendly name
		// (usually last TSID) will be identical to before
		switch (decoModelType) {
			case DecoModelTypes.BOX_TYPE:
				return Box.fromAnonymous(amf, TSIDGen.newTSID('box'));
			case DecoModelTypes.DECO_TYPE:
				return Deco.fromAnonymous(amf, TSIDGen.newTSID(amf.sprite_class));
			case DecoModelTypes.DOOR_TYPE:
				return Door.fromAnonymous(amf, TSIDGen.newTSID('door'));
			case DecoModelTypes.LADDER_TYPE:
				return Ladder.fromAnonymous(amf, TSIDGen.newTSID('ladder'));
			case DecoModelTypes.PLATFORM_LINE_TYPE:
				return PlatformLine.fromAnonymous(amf, TSIDGen.newTSID('plat'));
			case DecoModelTypes.SIGNPOST_TYPE:
				return SignPost.fromAnonymous(amf, TSIDGen.newTSID('signpost'));
			case DecoModelTypes.TARGET_TYPE:
				return Target.fromAnonymous(amf, TSIDGen.newTSID('target'));
			case DecoModelTypes.WALL_TYPE:
				return Wall.fromAnonymous(amf, TSIDGen.newTSID('wall'));
			default:
				throw new Error();
				return null;
		}
	}
	
	public static function newDecoModelFromLocationModel(model:AbstractPositionableLocationEntity, lm:LayerModel):DecoModel {
		if (model is Deco) {
			return newDecoModel(model as Deco, lm);
		} else if (model is Box) {
			return newBoxModel(model as Box, lm);
		} else if (model is Door) {
			return newDoorModel(model as Door, lm);
		} else if (model is Ladder) {
			return newLadderModel(model as Ladder, lm);
		} else if (model is PlatformLine) {
			return newPlatformLineModel(model as PlatformLine, lm);
		} else if (model is SignPost) {
			return newSignpostModel(model as SignPost, lm);
		} else if (model is Target) {
			return newTargetModel(model as Target, lm);
		} else if (model is Wall) {
			return newWallModel(model as Wall, lm);
		} else {
			throw new Error();
			return null;
		}
	}
	
	public static function newBoxModel(box:Box, layerModel:LayerModel):BoxModel {
		const bm:BoxModel = new BoxModel(layerModel);
		bm.updateModel(box);
		return bm;
	}
	
	public static function newDecoModel(deco:Deco, layerModel:LayerModel):DecoModel {
		// hacky place to do this, but we can't do this in DecoModel itself
		// (since it's not part of the client)
		const animatable:Boolean = DecoAssetManager.isInGroup(deco.sprite_class, 'animated');
		
		const dm:DecoModel = new DecoModel(layerModel, animatable);
		dm.updateModel(deco);
		return dm;
	}
	
	public static function newDoorModel(door:Door, lm:LayerModel):DoorModel {
		const dm:DoorModel = new DoorModel(lm);
		dm.updateModel(door);
		return dm;
	}
	
	public static function newLadderModel(ladder:Ladder, layerModel:LayerModel):LadderModel {
		const lm:LadderModel = new LadderModel(layerModel);
		lm.updateModel(ladder);
		return lm;
	}
	
	public static function newPlatformLineModel(platformLine:PlatformLine, layerModel:LayerModel):PlatformLineModel {
		const plm:PlatformLineModel = new PlatformLineModel(layerModel);
		plm.updateModel(platformLine);
		return plm;
	}
	
	public static function newSignpostModel(signpost:SignPost, layerModel:LayerModel):SignPostModel {
		const spm:SignPostModel = new SignPostModel(layerModel);
		spm.updateModel(signpost);
		return spm;
	}
	
	public static function newTargetModel(target:Target, layerModel:LayerModel):TargetModel {
		const tm:TargetModel = new TargetModel(layerModel);
		tm.updateModel(target);
		return tm;
	}
	
	public static function newWallModel(wall:Wall, layerModel:LayerModel):WallModel {
		const wm:WallModel = new WallModel(layerModel);
		wm.updateModel(wall);
		return wm;
	}
}
}