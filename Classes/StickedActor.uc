class StickedActor extends DestructibleSActor;

const SOURCE_STICKED = 0x20;

var StickyGoat owningMut;
var Actor stickBase;
var array<StickedActor> stickedActors;
var array<StickyActor> stickyActors;
var int collisionIndex;
var Actor momentumSource;
var int stickLimit;
var bool destroySelfOnly;

function TryDestroyWithMomentum(optional Actor source=none)
{
	momentumSource=source;
	TryDestroy();
}

function bool TryDestroy()
{
	if(super.TryDestroy())
	{
		owningMut.OnStickedActorDetached(self);
		return true;
	}
	return false;
}

//Remove all sticked actors on destruction
function OnDestruction()
{
	local StickedActor sa;
	local StickyActor link;
	local GGKActor kAct;
	local GGSVehicle vehicle;
	local GGPawn pawn;
	local vector dir;
	local float mass;

	if(destroySelfOnly)
	{
		return;
	}

	//Destroy sticked actors and links too
	foreach stickedActors(sa)
	{
		sa.TryDestroyWithMomentum(momentumSource);
	}
	stickedActors.Length=0;
	foreach stickyActors(link)
	{
		link.TryDestroy();
	}
	stickyActors.Length=0;

	if(GGKactor(stickBase) != none)
	{
		GGKactor(stickBase).SetMassScale( 1.f );
	}

	//Add destruction momentum if needed
	if(momentumSource != none && momentumSource != stickBase)
	{
		mass=1.f;
		dir=Normal(stickBase.CollisionComponent.GetPosition() - momentumSource.CollisionComponent.GetPosition());
		dir.Z=1.f;

		kAct = GGKActor(stickBase);
		vehicle = GGSVehicle(stickBase);
		pawn = GGPawn(stickBase);
		if(kAct != none)
		{
			mass=kAct.StaticMeshComponent.BodyInstance.GetBodyMass();
			//WorldInfo.Game.Broadcast(self, "Mass : " $ mass);
			kAct.ApplyImpulse(dir,  mass*500.f, -dir);
		}
		else if(pawn != none)
		{
			mass=50.f;
			pawn.TakeDamage( 0.f, none, pawn.Location, dir*mass*500.f, class'GGDamageType');
		}
		else if(vehicle != none)
		{
			mass=vehicle.Mass;
			vehicle.AddForce(dir*mass*500.f);
		}
	}
}

//Set the actor we stick on, the owner mutator
function StickOn(Actor act, StickyGoat ownMut)
{
	collisionIndex=0;
	owningMut=ownMut;
	stickBase=act;
	owningMut.OnStickedActorAttached(self);
	if(GGKactor(stickBase) != none)
	{
		GGKactor(stickBase).SetMassScale( 0.5f );
	}
}

//Add an actor we stick to (return false if sa may stick to self)
function bool StickTo(StickedActor sa)
{
	local StickyActor link;

	//Stop sticking if limit reached and colliding with old item
	if(stickLimit >= 0 && stickyActors.Length >= stickLimit)
	{
		return false;
	}

	//Only stick if not already sticked
	if(sa == none || sa == self || stickedActors.Find(sa) != INDEX_NONE)
	{
		return true;
	}

	link=Spawn(class'StickyActor',stickBase,,stickBase.Location,stickBase.Rotation,, true);
	link.StickTogether(self, sa);
	stickyActors.AddItem(link);
	link=Spawn(class'StickyActor',sa.stickBase,,sa.stickBase.Location,sa.stickBase.Rotation,, true);
	link.StickTogether(sa, self);
	sa.stickyActors.AddItem(link);

	stickedActors.AddItem(sa);
	sa.stickedActors.AddItem(self);

	return true;
}

event Tick( float deltaTime )
{
	local StickyActor link;

	super.Tick( deltaTime );

	//If base was destroyed
	if(!triedToDestroy && owningMut != none)
	{
		if(stickBase == none || stickBase.bPendingDelete)
		{
			//Self destroy
			stickedActors.Length=0;
			foreach stickyActors(link)
			{
				link.TryDestroy();
			}
			stickyActors.Length=0;
			destroySelfOnly=true;
			TryDestroy();
		}
	}
}

DefaultProperties
{
	stickLimit=2
}