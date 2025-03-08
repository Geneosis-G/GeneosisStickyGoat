class DestructibleSActor extends Actor;

var bool triedToDestroy;

function bool TryDestroy()
{
	if(!triedToDestroy && !bDeleteMe && !bPendingDelete)
	{
		triedToDestroy=true;
		if(!Destroy())
		{
			ShutDown();
		}
		return true;
	}
	return false;
}

simulated event ShutDown()
{
	OnDestruction();
	super.ShutDown();
}

simulated event Destroyed()
{
	OnDestruction();
	Super.Destroyed();
}

function OnDestruction();

DefaultProperties
{
	bNoDelete=false
	bStatic=false
}