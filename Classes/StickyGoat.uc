class StickyGoat extends GGMutator;

var array< StickyGoatComponent > mComponents;
var array<StickedActor> stickedActors;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local StickyGoatComponent stickyComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		stickyComp=StickyGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'StickyGoatComponent', goat.mCachedSlotNr));
		if(stickyComp != none && mComponents.Find(stickyComp) == INDEX_NONE)
		{
			mComponents.AddItem(stickyComp);
		}
	}
}

simulated event Tick( float delta )
{
	local StickyGoatComponent sgc;

	foreach mComponents(sgc)
	{
		sgc.Tick( delta );
	}
	super.Tick( delta );
}

function OnStickedActorAttached(StickedActor newAct)
{
	local StickyGoatComponent sgc;

	foreach mComponents(sgc)
	{
		sgc.gMe.mActorsToIgnoreBlockingBy.AddItem(newAct.stickBase);
		if(sgc.goatSticker == none && newAct.stickBase == sgc.gMe)
		{
			sgc.goatSticker=newAct;
		}

	}
	stickedActors.AddItem(newAct);
}
function OnStickedActorDetached(StickedActor oldAct)
{
	local StickyGoatComponent sgc;

	foreach mComponents(sgc)
	{
		sgc.gMe.mActorsToIgnoreBlockingBy.RemoveItem(oldAct.stickBase);
	}
	stickedActors.RemoveItem(oldAct);
}

//Propagate collision detection to sticked items
function OnCollision( Actor actor0, Actor actor1 )
{
	local StickedActor sa;
	local StickedActor sa0;
	local StickedActor sa1;

	if(!IsStickable(actor0) || !IsStickable(actor1))
	{
		return;
	}

	sa0=none;
	sa1=none;
	foreach stickedActors(sa)
	{
		if(sa.stickBase == actor0)
		{
			sa0=sa;
		}
		if(sa.stickBase == actor1)
		{
			sa1=sa;
		}

		if(sa0 != none && sa1 != none)
		{
			break;
		}
	}

	//If only one actor is sticky, make the other sticky too
	if(sa0 != none && sa1 == none)
	{
		sa1=MakeSticky(actor1);
	}
	if(sa0 == none && sa1 != none)
	{
		sa0=MakeSticky(actor0);
	}

	//Stick actors together
	if(sa0 != none && sa1 != none)
	{
		if(!sa0.StickTo(sa1))
		{
			sa1.StickTo(sa0);
		}
	}
}

function bool IsStickable(Actor act)
{
	//Can't stick to non grabbable items and to interp actors
	return GGGrabbableActorInterface(act) != none && GGInterpActor(act) == none;
}

//Try to make an actor sticky
function StickedActor MakeSticky(Actor act)
{
	local StickedActor sa;

	sa=Spawn(class'StickedActor',act,,act.Location,act.Rotation,, true);
	sa.StickOn(act, self);

	return sa;
}

DefaultProperties
{
	mMutatorComponentClass=class'StickyGoatComponent'
}