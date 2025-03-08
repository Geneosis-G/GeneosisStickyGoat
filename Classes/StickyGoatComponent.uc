class StickyGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var StickedActor goatSticker;
var bool isBaaPressed;
var bool isSpecialPressed;
var AttractionField attractField;
var vector movingDirection;
var float movingForce;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		goatSticker=gMe.Spawn(class'StickedActor',gMe,,gMe.Location,gMe.Rotation,, true);
		goatSticker.StickOn(gMe, StickyGoat(myMut));

		attractField=gMe.Spawn(class'AttractionField',gMe,,gMe.Location,gMe.Rotation,, true);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			isSpecialPressed=true;
			if(isBaaPressed)
			{
				StickyExplosion();
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			isBaaPressed=true;
			if(isSpecialPressed)
			{
				StickyExplosion();
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			if(gMe.mIsRagdoll)
			{
				gMe.SetTimer(1.f, false, NameOf(SwitchAttracting), self);
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_Forward", string( newKey ) ) )
		{
			movingDirection.X=1.f;
		}
		if( localInput.IsKeyIsPressed( "GBA_Back", string( newKey ) ) )
		{
			movingDirection.X=-1.f;
		}
		if( localInput.IsKeyIsPressed( "GBA_Right", string( newKey ) ) )
		{
			movingDirection.Y=1.f;
		}
		if( localInput.IsKeyIsPressed( "GBA_Left", string( newKey ) ) )
		{
			movingDirection.Y=-1.f;
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			isSpecialPressed=false;
		}

		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			isBaaPressed=false;
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			if(gMe.IsTimerActive(NameOf(SwitchAttracting), self))
			{
				gMe.ClearTimer(NameOf(SwitchAttracting), self);
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_Forward", string( newKey ) ) )
		{
			movingDirection.X=0.f;
		}
		if( localInput.IsKeyIsPressed( "GBA_Back", string( newKey ) ) )
		{
			movingDirection.X=0.f;
		}
		if( localInput.IsKeyIsPressed( "GBA_Right", string( newKey ) ) )
		{
			movingDirection.Y=0.f;
		}
		if( localInput.IsKeyIsPressed( "GBA_Left", string( newKey ) ) )
		{
			movingDirection.Y=0.f;
		}
	}
}

//Throw away all sticked objects or make goat stick again
function StickyExplosion()
{
	if(goatSticker != none)
	{
		goatSticker.TryDestroyWithMomentum(gMe);
		goatSticker=none;
	}
	else
	{
		goatSticker=gMe.Spawn(class'StickedActor',gMe,,gMe.Location,gMe.Rotation,, true);
		goatSticker.StickOn(gMe, StickyGoat(myMut));
	}
}

function SwitchAttracting()
{
	attractField.SwitchAttracting();
}

function Tick( float deltaTime )
{
	local rotator movementRot;
	local vector v, dir;

	if(!gMe.mIsRagdoll && attractField.isAttracting)
	{
		attractField.SetAttracting(false);
	}

	if(attractField.isAttracting && gMe.Controller != none)
	{
		if(GGLocalPlayer(PlayerController( gMe.Controller ).Player).mIsUsingGamePad)
		{
			movingDirection.X=PlayerController( gMe.Controller ).PlayerInput.aBaseY;
			movingDirection.Y=PlayerController( gMe.Controller ).PlayerInput.aStrafe;
		}

		if(VSize(movingDirection) > 0.1f)
		{
			GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( v, movementRot );
			movementRot.Pitch=0;
			movementRot.Roll=0;
			dir=movingDirection >> movementRot;
			attractField.Move(Normal(dir) * movingForce * deltaTime);
		}
	}
	if(attractField.isAttracting)
	{
		gMe.Velocity=gMe.Velocity * 0.9f;
	}
}

function OnPlayerRespawn( PlayerController respawnController, bool died )
{
	super.OnPlayerRespawn(respawnController, died);

	if(respawnController == gMe.Controller && goatSticker != none)
	{
		goatSticker.TryDestroyWithMomentum(gMe);
		goatSticker=none;
	}
}

defaultproperties
{
	movingForce=400.f
}