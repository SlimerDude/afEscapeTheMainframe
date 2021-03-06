using afIoc
using gfx
using fwt

** The CreditsScreen takes about a min to scroll through
@Js
class CreditsScreen : GameSeg {
	
	@Inject	private Screen			screen
	@Inject	private FannyImages		images
	@Inject	private FannySounds		sounds
	@Inject	private |->App|			app
	@Inject	private Sequencer		sequencer
			private SineDots		sineDots		:= SineDots()
			private CreditsAnim?	creditsAnim

	
	new make(|This| in) {
		in(this)
	}

	override This onInit() {
		creditsAnim = CreditsAnim(screen, images)
		return this
	}
	
	override Void onKill() { }

	override Void onDraw(Gfx g2d, Int catchUp) {
		sequencer.onBeat(catchUp)

		anyKey := screen.keys.size > 0 || screen.touch.swiped(Key.enter)
		if (anyKey || creditsAnim.finished) {
			app().showTitles(false)
		}

		g2d.clear	//(Models.bgColour)
		sineDots.draw(g2d, catchUp)
		creditsAnim.draw(g2d, catchUp)
	}
}

@Js
class CreditsAnim {
	
	private FannyImages	images
			Int			time	:= 1
	
	private	CreditTwean[]	credits	:= CreditTwean[,]
	private	CreditScroll	creditScroll
	
			Bool		finished

	new make(Screen screen, FannyImages images) {
		this.images = images
		this.creditScroll = CreditScroll(screen)
		initTweans
	}
	
	Void draw(Gfx g2d, Int catchUp) {
		credits.each {
			it.draw(g2d, time)
			it.anim(time, catchUp)
		}
		creditScroll.draw(g2d, time, catchUp)
		time += catchUp
		
		this.finished = creditScroll.finished
	}
	
	Void initTweans() {
		credits = [
			CreditTwean {
				it.title		= "Alien-Factory"
				it.name			= "Presents"
				it.flip			= true
				it.startFrame	= 100
			},
			CreditTwean {
				it.title		= "A Game written in"
				it.name			= "The Fantom Language"
				it.startFrame	= 100 + (250 * 1)
			},
			CreditTwean {
				it.title		= "Featuring"
				it.name			= "Fanny the Fantom"
				it.startFrame	= 100 + (250 * 2)
			},
			CreditTwean {
				it.title		= "in"
				it.name			= "Escape the Mainframe"
				it.startFrame	= 100 + (250 * 3)
			},
			CreditTwean {
				it.title		= "Written by"
				it.name			= "Steve Eynon"
				it.startFrame	= 100 + (250 * 4)
			},
		]
	}
}

@Js
class CreditScroll {
	const	Int spacing	:= 60
	Int		startFrame	:= 100 + (250 * 5)
	Float	startY
	Image?	imgCredits
	Bool	finished
	
	new make(Screen screen) {
		
		imgCredits = Image.makePainted(Size(EscapeTheMainframe.windowSize.w / 2, 1300 + EscapeTheMainframe.windowSize.h)) |g| {
			g2d := screen.gfx(g)
			g2d.clear	//(Models.bgColour)
			
			y := EscapeTheMainframe.windowSize.h
			y = drawCredits(g2d, y, "Alien-Factory", "Presents", true)
			y-= spacing / 2
//			y = drawCredits(g2d, y, "A Game written in", "The Fantom Language")
			y = drawCredits(g2d, y, "Fanny the Fantom", "Escape the Mainframe")
			
			y+=spacing
			
			y = drawCredits(g2d, y, "Game Design", "Steve Eynon\nEmma Eynon")

			y = drawCredits(g2d, y, "Coding / Programming", "Steve Eynon") - spacing
			g2d.drawFont8Centred("aka", y)
			y+=8
			g2d.drawFont16Centred("SlimerDude", y)
			y+=16+spacing
			
			y = drawCredits(g2d, y, "Chip Tunes", "Morgan Hesmondhalgh") - spacing
			g2d.drawFont8Centred("aka", y)
			y+=8
			g2d.drawFont16Centred("ZeroCakes", y)
			y+=16+spacing
			
			y = drawCredits(g2d, y, "Sound Effects", "   Geoff Lee   ") - spacing
			g2d.drawFont8Centred("aka", y)
			y+=8
			g2d.drawFont16Centred("Modulate/QLERIK", y)
			y+=16+spacing

			y = drawCredits(g2d, y, "Cartoon Graphics", "Anibal Ordaz")
			y = drawCredits(g2d, y, "3D Vector Graphics", "Steve Eynon")
//			y = drawCredits(g2d, y, "Stunt Doubles", "Steve Eynon")
			y = drawCredits(g2d, y, "Key Grip", "Tracey Jeapes")

//			y = drawCredits(g2d, y, "Kung Fu Choreography", "Tony Eynon")
			y = drawCredits(g2d, y, "World Record Holder", "Tony Eynon")
			
//			y = drawCredits(g2d, y, "Stunt Doubles", "Sam Jeapes\nElsie Jeapes")
//			y = drawCredits(g2d, y, "Special Thanks To", "Sam Jeapes\nElsie Jeapes")

//			echo(y)
		}

	}

	private Int drawCredits(Gfx g2d, Int y, Str title, Str name, Bool flip := false) {
		nm := name .splitLines.max |l1, l2| { l1.size <=> l2.size }
		tm := title.splitLines.max |l1, l2| { l1.size <=> l2.size }
		w  := flip ? (tm.size * 16).max(nm.size * 8) + 32 : (tm.size * 8).max(nm.size * 16) + 32
		x1 := (g2d.bounds.w - w) / 2
		x2 := x1 + w
		
		if (flip) {
			g2d.drawFont16Centred(title, y)
			g2d.brush = Models.brand_lightBlue
			g2d.drawLine(x1, y + 18, x2, y + 18)
			g2d.drawFont8Centred(name, y + 21)
		} else {
			g2d.drawFont8Centred(title, y)
			g2d.brush = Models.brand_lightBlue
			g2d.drawLine(x1, y + 10, x2, y + 10)
			g2d.drawFont16Centred(name, y + 13)
		}
		
		return y + 29 + spacing
	}
	
	Void draw(Gfx g2d, Int time, Int catchUp) {
		if (time < startFrame)	return
		
		g2d.g.copyImage(imgCredits, Rect(0, startY.toInt, EscapeTheMainframe.windowSize.w / 2, EscapeTheMainframe.windowSize.h), Rect(EscapeTheMainframe.windowSize.w / 2, 0, EscapeTheMainframe.windowSize.w / 2, EscapeTheMainframe.windowSize.h))
		
		startY += (0.6f * catchUp)
		
		if (startY.toInt >= (imgCredits.size.h - EscapeTheMainframe.windowSize.h))
			finished = true
	}
}

@Js
class CreditTwean : Twean {
	const Int		animSpeed	:= 15

	Str		name
	Str		title
	Bool	flip
	Bool	finished
	
	new make(|This| f) : super(f) {
		startX = -width
		finalX = (EscapeTheMainframe.windowSize.w - width) * 2 / 5
		startY = finalY = 7 * 16
		endFrame = startFrame + animSpeed
	}

	once Int width() {
		flip
			? (title.size * 16).max(name.size * 8) + 32
			: (title.size * 8).max(name.size * 16) + 32
	}
	
	override Void draw(Gfx g2d, Int time) {
		if ((time <= startFrame && easeIn) || finished)
			return

		startF	:= startFrame
		endF	:= endFrame
		if (!easeIn) {
			startF	+= 6
			endF	+= 6
		}
		if ((easeIn && time > startF) || (!easeIn && time < endF)) {
			ratio := easeIn ? 1f : 0f
			if (time >= startF && time <= endF)
				ratio = this.ratio(time, easeIn, startF, endF)
			x := ((finalX - startX) * ratio) + startX
			if (flip) {
				x += (width - (title.size * 16)) / 2
				g2d.drawFont16(title, x.toInt, finalY)
			} else {
				x += (width - (title.size * 8)) / 2
				g2d.drawFont8(title, x.toInt, finalY)				
			}
		}

		startF	= startFrame	+ 3
		endF	= endFrame		+ 3
		if ((easeIn && time > startF) || (!easeIn && time < endF)) {
			ratio := easeIn ? 1f : 0f
			if (time >= startF && time <= endF)
				ratio = this.ratio(time, easeIn, startF, endF)
			x1 := ((finalX - startX) * ratio) + startX
			x2 := x1 + width
			g2d.brush = Models.brand_lightBlue
			if (flip)
				g2d.drawLine(x1.toInt, finalY + 18, x2.toInt, finalY + 18)
			else
				g2d.drawLine(x1.toInt, finalY + 10, x2.toInt, finalY + 10)
		}
		
		startF	= startFrame
		endF	= endFrame
		if (easeIn) {
			startF	+= 6
			endF	+= 6
		}
		if ((easeIn && time > startF) || (!easeIn && time < endF)) {
			ratio := easeIn ? 1f : 0f
			if (time >= startF && time <= endF)
				ratio = this.ratio(time, easeIn, startF, endF)
			x := ((finalX - startX) * ratio) + startX
			if (flip) {
				x += (width - (name.size * 8)) / 2 
				g2d.drawFont8(name, x.toInt, finalY + 21)				
			} else {
				x += (width - (name.size * 16)) / 2 
				g2d.drawFont16(name, x.toInt, finalY + 13)				
			}
		}
	}
	
	Void anim(Int time, Int catchUp) {
		if ((time <= startFrame && easeIn) || finished)
			return

		if (easeIn)
			finalX += catchUp
		else
			startX += catchUp

		if (easeIn && finalX > ((EscapeTheMainframe.windowSize.w * 4 / 5) - width)) {
			easeIn = false
			startX = finalX
			finalX = EscapeTheMainframe.windowSize.w
			
			startFrame	= time
			endFrame	= time + animSpeed
		}
		
		if (!easeIn && time >= (endFrame+10)) {
			finished = true
		}
	}
}
