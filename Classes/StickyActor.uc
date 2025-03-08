class StickyActor extends DestructibleSActor;

var StickedActor stickyBase;
var StickedActor stickyTarget;
var instanced GGRB_Handle grabber;
var bool init;

function OnDestruction()
{
	local GGNpc npc;
	
	grabber.ReleaseComponent();
	npc=GGNpc(stickyTarget.stickBase);
	if(npc != none)
	{
		npc.EnableStandUp(class'StickedActor'.const.SOURCE_STICKED);
	}
}

//Set the actor we stick on
function StickTogether(StickedActor sBase, StickedActor sTarget)
{
	local GGNpc npc;
	
	stickyBase=sBase;
	stickyTarget=sTarget;
	
	npc=GGNpc(stickyTarget.stickBase);
	if(npc != none)
	{
		if(!npc.mIsRagdoll)
		{
			npc.SetRagdoll(true);
		}
		npc.DisableStandUp(class'StickedActor'.const.SOURCE_STICKED);
	}
	
	GrabTarget();
	init=true;
}

function GrabTarget()
{
	local vector actPos;
	local GGGrabbableActorInterface grabbableInterface;
	local name boneName;
	
	grabbableInterface = GGGrabbableActorInterface( stickyTarget.stickBase );
	actPos=stickyTarget.stickBase.CollisionComponent.GetPosition();
	boneName = grabbableInterface.GetGrabInfo( actPos );
	grabber.GrabComponent( grabbableInterface.GetGrabbableComponent(), boneName, actPos, false );
}

event Tick( float deltaTime )
{
	super.Tick( deltaTime );
	
	if(!init)
	{
		return;
	}
	
	if(stickyBase == none || stickyBase.bPendingDelete || stickyTarget == none || stickyTarget.bPendingDelete)
	{
		stickyBase.stickyActors.RemoveItem(self);
		TryDestroy();
		return;
	}
	
	grabber.SetLocation(stickyBase.stickBase.CollisionComponent.GetPosition());
	//DrawDebugLine(grabber.Location, grabber.Destination, 255, 255, 255);
}

DefaultProperties
{
	Begin Object class=GGRB_Handle name=ObjectGrabber
        LinearDamping=1.f
        LinearStiffness=2000.f
        AngularDamping=1.f
        AngularStiffness=1.f
    End Object
    grabber=ObjectGrabber
}