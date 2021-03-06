using fwt
using gfx
using afIoc

@Js
class EscapeTheMainframe {
	static const Str 	windowTitle	:= "Escape the Mainframe!"
	static const Size 	windowSize 	:= Size(768, 288)

	new make() { }
	
	Window main() {
		// TODO specify offline mode
		
		doMain([AppModule#]) |win| {
			// see https://pacoup.com/2011/06/12/list-of-true-169-resolutions/
			win.size = Runtime.isJs ? windowSize : Size(windowSize.w + 6, windowSize.h + 27)
			win.title = windowTitle
			win.icon = Image(`fan://afEscapeTheMainframe/res/images/fanny-x32.png`)
		}
	}
	
	Window doMain(Type[] modules, |Window, Scope|? onOpen := null) {
		frame := Frame(modules)
		win := Window(null) {
			win := it
			it.resizable = false
			it.add(frame.widget)
			it.onOpen.add  |->| { 
				Desktop.callLater(50ms) |->| {
					frame.startup
					// required, else in JS we have to click in the screen each time it changes!
					win.children.each |w| { w.repaint; w.focus }
				}
			}
			it.onClose.add |->| {
				typeof.pod.log.info("Bye!")
				if (Env.cur.runtime == "js")
					frame.shutdown			
			}
			onOpen?.call(win, frame.scope)
		}
		win.open
		
		if (Env.cur.runtime != "js")
			frame.shutdown
		return win
	}
}
