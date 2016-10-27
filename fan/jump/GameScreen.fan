using fwt::Key
using gfx::Color
using gfx::Rect
using afIoc::Inject
using afIoc::Autobuild

class GameScreen : GameSeg {

	@Inject		private Screen		screen
	@Inject		private |->App|		app
	@Autobuild	private	Funcs		funcs
				private Model?		cube
				private Model?		grid
				private Block[]		blcks	:= Block[,]
				private Fanny?		fany
				private	GameData?	data
	
	new make(|This| in) { in(this) }

	override This onInit() {
		data	= GameData()
		blcks.clear
		cube	= Models.cube
		grid	= Models.grid(data)
		fany	= Models.fanny(data)
		return this
	}

	override Void onDraw(Gfx g2d) {
		keyLogic()
		gameLogic()
		anim()
		draw(g2d)
	}
	
	Void gameLogic() {
		blcks = blcks.exclude { it.killMe }
		
		data.distSinceLastBlock += data.floorSpeed
		data.newBlockPlease = funcs.funcNewBlock(data.level, data.distSinceLastBlock, data.floorSpeed)
		
		if (data.newBlockPlease) {
			data.newBlockPlease 	= false
			data.distSinceLastBlock = 0f

			// FIXME Top block MUST be drawn first! And then fanny in the middle
			blk := funcs.funcBlock(data, data.level, data.distSinceLastBlock)
			blcks.add(blk)
		}
		
		if (!data.dying) {
			fect  := fany.collisionRect
			crash := blcks.any |blck| {
				col := fany.intersects(blck)
				
				if (!col) {
					blck.drawables[0] = Fill(Models.brand_darkBlue)
					blck.drawables[1] = Edge(Models.brand_lightBlue)
					return false
				}
				
				blck.drawables[0] = Fill(Models.block_collide)
				blck.drawables[1] = Edge(Models.brand_white)
				return col
			}
			if (crash && !data.invincible) {
				data.dying = true
				// make transparent
//				blcks.each { it.drawables[0] = Fill(null) }
			}
		}
		
		if (data.dying) {
			data.deathCryIdx++
		}
		
		if (data.deathCryIdx == 220) {
			app().gameOver
		}
	}
	
	Void keyLogic() {
		jump 	:= screen.keys[Key.space] == true || screen.keys[Key.up] == true
		squish	:= screen.keys[Key.down]  == true 
		ghost	:= screen.keys[Key.shift] == true 
		fany.jump(jump)
		fany.squish(squish)
		fany.ghost(ghost)
		
		level := null as Int
		if (screen.keys[Key.num1] == true)	level = 1
		if (screen.keys[Key.num2] == true)	level = 2
		if (screen.keys[Key.num3] == true)	level = 3
		if (screen.keys[Key.num4] == true)	level = 4
		if (screen.keys[Key.num5] == true)	level = 5
		if (screen.keys[Key.num6] == true)	level = 6
		if (screen.keys[Key.num7] == true)	level = 7
		if (screen.keys[Key.num8] == true)	level = 8
		if (screen.keys[Key.num9] == true)	level = 9
		if (screen.keys[Key.num0] == true)	level = 10
		if (level != null) {
			data.level = level
			echo("Level $level")
		}
	}
	
	Void anim() {
		if (!data.dying) {
			grid.anim
			blcks.each { it.anim }
			fany.anim
		}
		cube.anim
	}
	
	Void draw(Gfx g2d) {
		g2d.clear
		g3d := Gfx3d(g2d.offsetCentre).lookAt(camera, target)

		grid.draw(g3d)
		
		// this depends on camera angle
		fannyDrawn	:= false
		fannyXmin	:= fany.xMin
		blcks.each |blck| {	// blks should already X sorted
			if (blck.xMax < fannyXmin)
				blck.draw(g3d)
			else {
				if (!fannyDrawn) {
					fany.draw(g3d)
					fannyDrawn = true
				}
				blck.draw(g3d)
			}
		}
		if (!fannyDrawn) {
			fany.draw(g3d)
		}
		
		cube.draw(g3d)
	

//		if (screen.keys[Key.up] == true)	dy -= ds
//		if (screen.keys[Key.down] == true)	dy += ds
//		if (screen.keys[Key.left] == true)	dx -= ds
//		if (screen.keys[Key.right] == true)	dx += ds
//		ay := dy/500f
//		ax := dx/500f
//		camera = Point3d(0f, 0f, -500f).rotate(ay+0.0f, ax, 0f)
		
		// uncomment to alter camera view
//		delta := 110f + fany.y
//		camera = Point3d(0f, 0f, -500f).translate(0f, delta / 2f, 0f) //{ echo("Cam: $it") }
//		target = Point3d(0f, -75f,  0f).translate(0f, delta / 2f, 0f) //{ echo("Tar: $it") }		
	}
	
	Float dx	:= 0f
	Float dy	:= 0f
	Float ds	:= 1f
	
	Point3d camera	:= Point3d(0f, 0f, -500f) 
	Point3d target	:= Point3d(0f, -75f, 0f)
}

