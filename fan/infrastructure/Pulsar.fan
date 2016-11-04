using fwt

** Calls listeners every XXXms. Use for animation and game loops.
@Js
class Pulsar {
	private const static Log	log 			:= Log.get(Pulsar#.name)
	
	private Duration 		timeOfNextPulse		:= Duration.now
	private |->|[] 			pulseListeners		:= [,]
	private Duration?		lastOverloadTime
	private Duration?		lastOverloadDuration
	private |->|?			stopCallback
			Duration 		frequency			:= 200ms
			PulsarState 	state				:= PulsarState.stopped	{ private set }
	
	// ---- external methods --------------------------------------------------
	
	Void addListener(Func listener) {
		pulseListeners.add(listener)
	}

	Void clearListeners() {
		pulseListeners.clear
	}

	Void start() {
		timeOfNextPulse = Duration.now + frequency
		state = PulsarState.running
		log.debug("Pulsar firing up in ${frequency.toMillis}ms...")
		pulseIn(frequency)
	}
	
	Void stop(|->|? callback := null) {
		if (state != PulsarState.running) {
			log.warn("Cannot 'stop' if not 'running' : state = ${state}")
			Safe(callback).run
			return
		}
		stopCallback = callback
		state = PulsarState.stopping
	}
	
	Void step() {
		if (state != PulsarState.stopped)
			log.warn("Cannot 'step' if not 'stopped' : state = ${state}")
		else
			pulseNow
	}

	Bool isRunning() {
		return (state == PulsarState.running)
	}
	
	// ---- internal methods --------------------------------------------------
	
	private Void pulseNow() {
		if (state == PulsarState.stopping) {
			state  = PulsarState.stopped
			log.info("Pulsar stopped...")
			Safe(stopCallback).run
			return
		}
		
		pulseListeners.each |listener| {
			Safe(listener).run
		}
		
		timeOfNextPulse  = timeOfNextPulse + frequency
		timeToNextPulse := timeOfNextPulse - Duration.now

		if (timeToNextPulse <= 0ms) {
			logOverloadWarning(timeToNextPulse, Duration.now)
			
			// keep a reasonable positive wait duration
			// timeToNextPulse = 2ms

			// reset time on pulse so we can catch up (we may have been hibernating!)
			timeOfNextPulse = (Duration.now + frequency)
		}
		
		// we may be stopping and stepping...
		if (state != PulsarState.stopped)
			pulseIn(timeToNextPulse)
	}
	
	internal Void logOverloadWarning(Duration timeToNextPulse, Duration now) {
		if (shouldLogOverload(timeToNextPulse, now)) {
			lastOverloadTime 		= now
			lastOverloadDuration	= (timeToNextPulse - 1ms)	// don't log less than this - see tests
			// debug - meh, who cares!?
			log.debug("Computer Overload! Freq down to ${timeToNextPulse.toMillis}ms")			
		}
	}
	
	internal Bool shouldLogOverload(Duration timeToNextPulse, Duration now) {
		if (lastOverloadTime == null) 
			return true;

		if ((now - lastOverloadTime) > 5sec)
			return true
		
		// log warnings that have increased in value so we may know the severity of the overload
		// use '<' as these values are small and typically negative
		if (timeToNextPulse.toMillis < lastOverloadDuration.toMillis)
			return true
		
		return false
	}
	
	private Void pulseIn(Duration when) {
		if (when < 1ms)
			Desktop.callAsync |->| { pulseNow }
		else
			Desktop.callLater(when) |->| { pulseNow }
	}
}

@Js
enum class PulsarState {
	stopped,
	running,
	stopping
}

** A runnable with error handling. The default impl simply logs the error and returns 'null'. 
** Useful for FWT callbacks which have a habit of silently failing.
@Js
internal class Safe {
	private static const Log log := Log.get("Safe")
	
	private |->Obj?|? f
	
	new make(|->Obj?|? f) {
		this.f = f
	}
	
	// TODO: add alternative error handling
	Obj? run() {
		try {
			return f?.call
		} catch (Err e) {
			log.err(e.msg, e)
			return null
		}
	}
}
