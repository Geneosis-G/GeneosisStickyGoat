class AttractionField extends Actor;

var bool isAttracting;
var ParticleSystem attractEffectTemplate;
var ParticleSystemComponent attractEffect;
var AudioComponent ac;
var SoundCue attractSound;
var float attractForceRadius;
var float attractForcePower;
var GGRadialForceActor attractForceComp;
var instanced GGRB_Handle grabber;
var float maxDistToOwner;
var float distToGround;
var float fallSpeed;

event PostBeginPlay()
{
	local float r, h;

	Super.PostBeginPlay();

	SetPhysics(PHYS_None);
	CollisionComponent=none;

	Owner.GetBoundingCylinder(r, h);
	maxDistToOwner=sqrt(r*r+ h*h);

	attractForceComp = Spawn( class'GGRadialForceActor' );
	attractForceComp.ForceRadius = attractForceRadius;
	attractForceComp.ForceStrength = attractForcePower;
	attractForceComp.SetBase(self);

	attractEffect=WorldInfo.MyEmitterPool.SpawnEmitter(attractEffectTemplate, Location, Rotation, self);
	attractEffect.SetScale( 2.f );
	attractEffect.SetHidden(true);
}

function SwitchAttracting()
{
	SetAttracting(!isAttracting);
}

function SetAttracting(bool attracting)
{
	local vector actPos;
	local GGGrabbableActorInterface grabbableInterface;
	local name boneName;

	if(attracting == isAttracting)
	{
		return;
	}
	isAttracting=attracting;
	attractEffect.SetHidden(!isAttracting);
	attractForceComp.bForceActive=isAttracting;
	if(isAttracting)
	{
		grabbableInterface = GGGrabbableActorInterface( Owner );
		actPos=Owner.CollisionComponent.GetPosition();
		SetLocation(actPos);
		boneName = grabbableInterface.GetGrabInfo( actPos );
		grabber.GrabComponent( grabbableInterface.GetGrabbableComponent(), boneName, actPos, false );
	}
	else
	{
		grabber.ReleaseComponent();
	}
}

event Tick( float deltaTime )
{
	local float curDistToGround;

	super.Tick( deltaTime );

	if(ac == none || ac.IsPendingKill())
	{
		ac=CreateAudioComponent(attractSound, isAttracting);
	}
	if(isAttracting && !ac.IsPlaying())
	{
		ac.Play();
	}
	if(!isAttracting && ac.IsPlaying())
	{
		ac.Stop();
	}

	//Give the correct distance to ground to the field
	curDistToGround=GetDistToGround();
	if(abs(curDistToGround - distToGround) > 0.1f)
	{
		Move(vect(0, 0, 1) * (distToGround-curDistToGround) * deltaTime);
	}

	//Emergency backup
	if(VSize(Location - Owner.Location) > attractForceRadius/2.f)
	{
		SetLocation(Owner.Location);
	}

	grabber.SetLocation(Location);
}

function float GetDistToGround()
{
	local StaticMeshActor hitSMActor;
	local Landscape hitLandscape;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	traceStart=Location;
	traceEnd=Location;
	traceEnd.Z-=fallSpeed;
	foreach TraceActors( class'StaticMeshActor', hitSMActor, hitLocation, hitNormal, traceEnd, traceStart )
	{
		break;
	}
	if(hitSMActor == none)
	{
		hitLocation=traceEnd;
		foreach TraceActors( class'Landscape', hitLandscape, hitLocation, hitNormal, traceEnd, traceStart )
		{
			break;
		}
		if(hitLandscape == none)
		{
			hitLocation=traceEnd;
		}
	}

	return VSize(hitLocation-Location);
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false

	maxDistToOwner=50.f
	attractForceRadius=1000.f
	attractForcePower=-1500.f
	distToGround=100.f
	fallSpeed=400.f

	attractSound=SoundCue'MMO_AMB.Cue.AMB_Instance_Drone_Cue'
	attractEffectTemplate=ParticleSystem'Goat_Effects.Effects.DemonicPower'

	Begin Object class=GGRB_Handle name=ObjectGrabber
        LinearDamping=1.f
        LinearStiffness=2000.f
        AngularDamping=1.f
        AngularStiffness=1.f
    End Object
    grabber=ObjectGrabber
}