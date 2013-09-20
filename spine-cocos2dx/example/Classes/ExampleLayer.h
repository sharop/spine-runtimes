

#ifndef _EXAMPLELAYER_H_
#define _EXAMPLELAYER_H_

#include "cocos2d.h"
#include <spine/spine-cocos2dx.h>

class ExampleLayer: public cocos2d::CCLayer {
private:
	spine::CCSkeletonAnimation* skeletonNode;

public:
	static cocos2d::CCScene* scene ();

	virtual bool init ();
	virtual void update (float deltaTime);

	CREATE_FUNC (ExampleLayer);
};

#endif // _EXAMPLELAYER_H_