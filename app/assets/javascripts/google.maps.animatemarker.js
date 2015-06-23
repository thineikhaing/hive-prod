/*

	Class to animate a Google Maps Marker from one LatLng point to another with various easing effects

*/

function MarkerMoveAnimation(marker, options)
{	
	//public vars
	this.name = options.name || 'default'; //optional: you can specify a name for this animation object to keep them apart
	this.marker = marker;
	
	//private vars
	var delay = 33; //how often shall the interval for a animation step be called? (in milliseconds) 33 ~ 30fps, 16 ~ 60fps
	var options = options || { };
	options.from = options.from || null; //The position from where the animation should start (accepts only a google.maps.LatLng object)
	options.to = options.to || null; //The position till where the animation should end (accepts only a google.maps.LatLng object)
	options.duration = options.duration || 1000; //Duration of the animation in milliseconds
	options.effect = options.effect || 'linear'; //Effect name (can be linear, easein, easeout)
	var beginTime; //Date object representing the start time of the animation
	var timePassed; //Difference between beginTime and the current time
	var progress; //Float between 0 and 1 representing the progress of the animation (0 = begin, 1 = end)
	var delta; //Float between 0 and 1 representing a factor by which to multiply to create certain animation effects like easein/out
	var positionDiff; //Object with lat and lng differences of options.from and options.to
	var interval; //holds the setInterval handle when an animation is running
	

	//public methods
	this.stop = function()
	{		
		console.log("animation is stopped.");
		clearInterval(interval);

		if(options.onComplete && typeof options.onComplete === "function") {
            options.onComplete(this);
            console.log("complete animate")
        }

		
	}
	
	this.setFrom = function(point) { options.from = point; this._updatePositionDiff(); }
	
	this.setTo = function(point) { options.to = point; this._updatePositionDiff(); }
	
	this.setDuration = function(milliseconds) { options.duration = milliseconds; }
	
	this.setEffect = function(string) { options.effect = string; }
			
	this.getFrom = function() { return options.from; }

	this.getTo = function() { return options.to; }

	this.getDuration = function() { return options.duration; }

	this.getEffect = function() { return options.effect; }
	
	this.start = function()
	{
		console.log('start');
		
		if(this._check())
		{
			console.log('check is OK');
			beginTime = new Date;
			//console.log("starting animation of "+this.marker.getIcon().url+" from "+options.from.toString()+" to "+options.to.toString());
			this._updatePositionDiff();

			//is there a callback just before we start the animation?
			if(options.onBeforeStart && typeof options.onBeforeStart === "function")
				options.onBeforeStart(this);
	
			//do the actual animation
			interval = setInterval(function(self) { self._animate(); }, delay, this);		
		}
	}


	//private methods

	this._animate = function()
	{		
		timePassed = new Date - beginTime;
		progress = this._progress(timePassed);
		delta = this._delta(progress);
				
		if(progress == 1)
		{
			this.stop();
		}
		else
			this._step(delta);
	}

	this._progress = function(timePassed)
	{
		var p = timePassed / options.duration;
				
		return (p > 1) ? 1 : p;
	}
	
	this._delta = function(progress)
	{
		switch(options.effect)
		{
			case 'linear':
			default:
			return progress;
			break;
			
			case 'easein':
			return Math.pow(progress, 3);
			break;
			
			case 'easeout':
			return 1 - (Math.pow((1 - progress), 3));
			break;
			
		}
	}
	
	this._step = function(delta)
	{
		var newlat = options.from.lat() + (positionDiff.lat * delta);
		var newlng = options.from.lng() + (positionDiff.lng * delta);
				
		this.marker.getServiceObject().setPosition(new google.maps.LatLng(newlat, newlng));

		if(options.onStep && typeof options.onStep === "function")
			options.onStep(this);
	}
	
	
	this._check = function()
	{
		console.log('check');		
		try
		{
			if(!this.marker || !this.marker.getServiceObject().getPosition)
				throw "NoValidMarkerObject";
			if(!options.from || !options.from.lat || !options.to || !options.to.lat)
				throw "NoValidFromToLatLngObjects";
				
			return true;
		}
		catch(error)
		{
			switch(error)
			{
				case "NoValidMarkerObject":
				console.log("Please provide a valid Marker object to perform a Marker Move Animation on");
				break;
				
				case "NoValidFromToLatLngObjects":
				console.log("Please provide a valid LatLng object for both the from and to option parameters to perform a Marker Move Animation");
				break;
				
				default:
				console.log("Unknown Error: "+error);
				break;
			}
			
			this.stop();			
		}		
	}

	this._updatePositionDiff = function() { positionDiff = { lat: (options.to.lat() - options.from.lat()) , lng: (options.to.lng() - options.from.lng()) }; }
	
	//Start the animation!
	
	this.start();
}