using fwt::Key
using gfx::Color
using gfx::Rect
using afIoc::Inject
using afIoc::Scope

@Js
class TitleScreen : GameSeg {

	@Inject	private Screen		screen
	@Inject	private FannySounds	sounds
	@Inject	private |->App|		app
	@Inject	private BgGlow		bgGlow
	@Inject	private FannyImages	images
	@Inject	private Sequencer	sequencer
	@Inject	private FannySequencer	fanSeq
			private TitleBg?	titleBg
			private TitleMenu?	titleMenu
			private Duration?	startedAt
	
	new make(|This| in) { in(this) }

	override This onInit() {
		startedAt	= Duration.now
		titleBg		= TitleBg(images)
		titleMenu	= TitleMenu(screen, sounds) {
			menu.add("Start Game")
			menu.add("Training Mode")
			menu.add("Hi-Scores")
			menu.add("About")	//menu.add("Instructions")
			menu.add("Credits")
//			menu.add("Exit")	// don't know how to quit!!!
			tit := it
			go = |high| {
				if (high == 0)
					tit.anyKey = true
				if (high == 1)
					app().showTraining(titleBg.fannyY)
				if (high == 2)
					app().showHiScores
				if (high == 3)
					app().showAbout
				if (high == 4)
					app().showCredits
			}
		}
		return this
	}
	
	This playTune(Bool restart) {
		if (restart) {
			sequencer.onStop
			fanSeq.playTitleTune
			sequencer.onPlay
		}
		return this
	}
	
	This delay(Bool skipIntro, Float? fannyY := null) {
		// note this is nothing to do with waiting for the credits to show!
		titleBg.time = 40	// no need to wait for long
		if (skipIntro)
			titleBg.time = 120
		if (fannyY != null)
			titleBg.fannyY = fannyY
		return this
	}
	
	override Void onKill() { }

	override Void onDraw(Gfx g2d, Int catchUp) {
		sequencer.onBeat(catchUp)

		titleMenu.keys()

		if (titleMenu.anyKey) {			
			level := null as Int
			if (screen.keys.pressed(Key.num1))	level = 1
			if (screen.keys.pressed(Key.num2))	level = 2
			if (screen.keys.pressed(Key.num3))	level = 3
			if (screen.keys.pressed(Key.num4))	level = 4
			if (screen.keys.pressed(Key.num5))	level = 5
			if (screen.keys.pressed(Key.num6))	level = 6
			if (screen.keys.pressed(Key.num7))	level = 7
			if (screen.keys.pressed(Key.num8))	level = 8
			if (screen.keys.pressed(Key.num9))	level = 9
			if (screen.keys.pressed(Key.num0))	level = 10

			if (level != null)
				return app().startGame(level)
			else
				return app().showIntro(titleBg.fannyY)
		}

		if ((Duration.now - startedAt) > 36sec) {
			return app().showCredits()
		}
		
		bgGlow.draw(g2d, catchUp)
		titleBg.draw(g2d)
		
		if (titleBg.time > 105) {
			titleMenu.draw(g2d)
			str := "fantom-lang.org"
//			str := "www.alienfactory.co.uk"
			x := 224 + ((18 - str.size) * 8 / 2)
			g2d.drawFont8(str, x, 278)
		}
	}
	
	private Bool timeEq(Int time, Int val, Int catchUp) {
		time == val || (catchUp > 1 && time < val && (time + catchUp) > val)
	}
}

@Js
class TitleMenu {
	private Screen		screen
	private FannySounds	sounds
	private Int			highlighted	:= 0

	Str[]	menu		:= Str[,]
	Bool	anyKey
	|Int|?	go
	
	new make(Screen screen, FannySounds sounds) {
		this.screen = screen
		this.sounds = sounds
	}
	
	Void draw(Gfx g2d) {
		menu.each |str, i| {
			x := 216 + ((10 - str.size) * 16 / 2)
			y := (11 * 16) + (i * 20) - 16
			
			if (i == highlighted) {
				g2d.brush = Color.gray
				g2d.fillRoundRect(x - 2, y-1, (str.size * 16) + 4, 16+2, 5, 5)
			}
			
			g2d.drawFont16(str, x, y)
		}
	}
	
	Void keys() {
		anyKey = screen.keys.dup {
			remove(Key.up)
			remove(Key.down)
			remove(Key.left)
			remove(Key.right)
			remove(Key.enter)
		}.size > 0
		
		mousePos := screen.mousePos
		if (mousePos != null)
			menu.each |str, i| {
				x := 216 + ((10 - str.size) * 16 / 2)
				y := (11 * 16) + (i * 20) - 16
				
				// add the border width
				if (Runtime.isJs) {
					x += 8
					y += 8
				}
				
				if (Rect(x - 2, y-1, (str.size * 16) + 4, 16+2).contains(mousePos.x, mousePos.y))
					highlighted = i
			}

		if (screen.keys.pressed(Key.up) || screen.touch.swiped(Key.up)) {
			if (highlighted > 0)
				highlighted -= 1
			else
				highlighted = menu.size-1
			sounds.menuMove.play
		}

		if (screen.keys.pressed(Key.down) || screen.touch.swiped(Key.down)) {
			if (highlighted < menu.size-1)
				highlighted += 1
			else
				highlighted = 0
			sounds.menuMove.play
		}

		if (screen.keys.pressed(Key.enter) || screen.touch.swiped(Key.enter)) {
			sounds.menuSelect.play
			go?.call(highlighted)
		}
	}
}
