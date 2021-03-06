using afIoc
using concurrent

@Js
const class AppModule {

	Void defineServices(RegistryBuilder bob) {
		bob.addService(App#)
		bob.addService(BgGlow#)
		bob.addService(HiScores#)
		bob.addService(FannyImages#)
		bob.addService(FannySounds#)
		bob.addService(FloorCache#)
		bob.addService(BlockCache#)

		bob.addService(Sequencer#)
		bob.addService(FannySequencer#)

		bob.onScopeCreate("uiThread") |Configuration config| {
			config["eagerLoad"] = |->| {
				// maybe put the qname of this class in pod meta -> for a generic gaming infrastructure
				config.scope.serviceByType(App#)

//				config.build(SineApp#)
			}
		}
	}
	
	@Build
	HiScoreOnline buildHiScoreOnline(Scope scope) {
		// use reflection to avoid Js warnings
		Runtime.isJs ? scope.build(HiScoreOnlineJs#) : scope.build(typeof.pod.type("HiScoreOnlineJava"))
	}
}
