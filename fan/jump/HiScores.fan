using afConcurrent
using afButter
using afIoc
using afIocConfig

class HiScores {
	
	private HiScore[]	hiScores
	
	@Inject	private	|->App|	app
	@Inject	private	Log		log
	
	@Inject { id="hiScores" }	
	private Synchronized	hiScoreThread
	
	@Config { id="hiScores.apiUrl" }
	private	Uri				hiScroreApi
	
	new make(|This| f) {
		f(this)
		
		hiScores = (0..<100).toList.map |i->HiScore| {
			HiScore {
				name	= "Slimer"
				score	= 1_000 - (i * 10)
			}
		}
	}
	
	@Operator
	HiScore get(Int i) {
		hiScores[i]
	}
	
	@Operator
	HiScore[] getRange(Range r) {
		hiScores[r]
	}
	
	Bool isHiScore(Int score) {
		score >= hiScores.last.score
	}
	
	Int newPosition(Int score) {
		pos := hiScores.eachrWhile |his, i| {
			score >= his.score ? null : i + 1
		} ?: 0
		
		hiScores.insert(pos, HiScore {
			it.name	= ""
			it.score = score
		})
		
		hiScores.removeAt(-1)
		
		return pos
	}

	Void loadScores() {
		safeThis := Unsafe(this)
		safeApp  := Unsafe(app())
		hiScoreThread.async |->| {
			that := (HiScores) safeThis.val
			try {
			
				serverScores := Butter.churnOut.get(that.hiScroreApi).body.jsonList
				echo(serverScores)
				
			} catch (Err err) {
				that.log.err("Hi-Score Server Error - ${err.typeof} - ${err.msg}")
				app := (App) safeApp.val
				app.offline = true
			}
		}
	}
}


class HiScore {
	DateTime	when	:= DateTime.now(1sec)
	Str			name
	Int			score
	
	new make(|This| f) { f(this) }
	
	Str toScreenStr(Int i) {
		(i == 100 ? "" : " ") + i.toStr.justr(2) + ") " + score.toStr.justr(5) + name.padl(13, '.') + " "
	}
}