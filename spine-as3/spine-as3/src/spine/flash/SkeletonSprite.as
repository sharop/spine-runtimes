/******************************************************************************
 * Spine Runtime Software License - Version 1.1
 * 
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms in whole or in part, with
 * or without modification, are permitted provided that the following conditions
 * are met:
 * 
 * 1. A Spine Essential, Professional, Enterprise, or Education License must
 *    be purchased from Esoteric Software and the license must remain valid:
 *    http://esotericsoftware.com/
 * 2. Redistributions of source code must retain this license, which is the
 *    above copyright notice, this declaration of conditions and the following
 *    disclaimer.
 * 3. Redistributions in binary form must reproduce this license, which is the
 *    above copyright notice, this declaration of conditions and the following
 *    disclaimer, in the documentation and/or other materials provided with the
 *    distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine.flash {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.getTimer;

import spine.Bone;
import spine.Skeleton;
import spine.SkeletonData;
import spine.Slot;
import spine.atlas.AtlasRegion;
import spine.attachments.RegionAttachment;

public class SkeletonSprite extends Sprite {
	static private var tempPoint:Point = new Point();
	static private var tempMatrix:Matrix = new Matrix();

	private var _skeleton:Skeleton;
	public var timeScale:Number = 1;
	private var lastTime:int;

	public function SkeletonSprite (skeletonData:SkeletonData) {
		Bone.yDown = true;

		_skeleton = new Skeleton(skeletonData);
		_skeleton.updateWorldTransform();

		addEventListener(Event.ENTER_FRAME, enterFrame);
	}

	private function enterFrame (event:Event) : void {
		var time:int = getTimer();
		advanceTime((time - lastTime) / 1000);
		lastTime = time;
	}

	public function advanceTime (delta:Number) : void {
		_skeleton.update(delta * timeScale);

		removeChildren();
		var drawOrder:Vector.<Slot> = skeleton.drawOrder;
		for (var i:int = 0, n:int = drawOrder.length; i < n; i++) {
			var slot:Slot = drawOrder[i];
			var regionAttachment:RegionAttachment = slot.attachment as RegionAttachment;
			if (regionAttachment != null) {
				var wrapper:Sprite = regionAttachment["wrapper"];
				var region:AtlasRegion = AtlasRegion(regionAttachment.rendererObject);
				if (!wrapper) {
					var bitmapData:BitmapData = region.page.rendererObject as BitmapData;
					var regionWidth:Number = region.rotate ? region.height : region.width;
					var regionHeight:Number = region.rotate ? region.width : region.height;
					var regionData:BitmapData = new BitmapData(regionWidth, regionHeight);
					regionData.copyPixels(bitmapData, new Rectangle(region.x, region.y, regionWidth, regionHeight), new Point());

					var bitmap:Bitmap = new Bitmap(regionData);
					bitmap.smoothing = true;

					// Rotate and scale using default registration point (top left corner, y-down, CW) instead of image center.
					bitmap.rotation = -regionAttachment.rotation;
					bitmap.scaleX = regionAttachment.scaleX * (regionAttachment.width / region.width);
					bitmap.scaleY = regionAttachment.scaleY * (regionAttachment.height / region.height);

					// Position using attachment translation, shifted as if scale and rotation were at image center.
					var radians:Number = -regionAttachment.rotation * Math.PI / 180;
					var cos:Number = Math.cos(radians);
					var sin:Number = Math.sin(radians);
					var shiftX:Number = -regionAttachment.width / 2 * regionAttachment.scaleX;
					var shiftY:Number = -regionAttachment.height / 2 * regionAttachment.scaleY;
					if (region.rotate) {
						bitmap.rotation += 90;
						shiftX += regionHeight * (regionAttachment.width / region.width);
					}
					bitmap.x = regionAttachment.x + shiftX * cos - shiftY * sin;
					bitmap.y = -regionAttachment.y + shiftX * sin + shiftY * cos;

					// Use bone as registration point.
					wrapper = new Sprite();
					wrapper.transform.colorTransform = new ColorTransform();
					wrapper.addChild(bitmap);
					regionAttachment["wrapper"] = wrapper;
				}

				wrapper.blendMode = slot.data.additiveBlending ? BlendMode.ADD : BlendMode.NORMAL;

				var colorTransform:ColorTransform = wrapper.transform.colorTransform;
				colorTransform.redMultiplier = skeleton.r * slot.r;
				colorTransform.greenMultiplier = skeleton.g * slot.g;
				colorTransform.blueMultiplier = skeleton.b * slot.b;
				colorTransform.alphaMultiplier = skeleton.a * slot.a;
				wrapper.transform.colorTransform = colorTransform;

				var flipX:int = skeleton.flipX ? -1 : 1;
				var flipY:int = skeleton.flipY ? -1 : 1;

				var bone:Bone = slot.bone;
				wrapper.x = bone.worldX;
				wrapper.y = bone.worldY;
				wrapper.rotation = -bone.worldRotation * flipX * flipY;
				wrapper.scaleX = bone.worldScaleX * flipX;
				wrapper.scaleY = bone.worldScaleY * flipY;
				addChild(wrapper);
			}
		}
	}

	public function get skeleton () : Skeleton {
		return _skeleton;
	}
}

}
