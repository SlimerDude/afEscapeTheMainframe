using afIoc

@Js
class HiScores {
		static const Int	maxNoOfPositions	:= 100
		static const Int	maxNameSize			:= 12

	@Inject	private	|->App|			app
	@Inject	private	Log				log
	@Inject	private	HiScoreOnline	hiScoresOnline
					HiScore[]		hiScores	:= HiScore[,]
					Bool			editing		:= false
	
	new make(|This| f) {
		f(this)
		
		// set some default scores - in case we go offline
		hiScores = (0..<maxNoOfPositions).toList.map |i->HiScore| {
			HiScore {
				name	= "Slimer"
				score	= 1_000 - (i * 10)
			}
		}
	}
	
	@Operator
	HiScore? getSafe(Int i) {
		hiScores.getSafe(i)
	}
	
	@Operator
	HiScore[] getRange(Range r) {
		hiScores[r]
	}
	
	Int size() {
		hiScores.size
	}
	
	Bool isHiScore(Int score) {
		// come on... you need *some* score to make it to the hi-score table!
		score >= 10 && (size < maxNoOfPositions || score >= hiScores.last.score)
	}
	
	Int newPosition(Int score) {
		pos := hiScores.eachrWhile |his, i| {
			score >= his.score ? null : i + 1
		} ?: 0
		
		hiScores.insert(pos, HiScore {
			it.name	= ""
			it.score = score
		})
		
		if (size > maxNoOfPositions)
			hiScores.removeAt(-1)
		
		return pos
	}

	Void loadScores() {
		hiScoresOnline.loadScores
	}
	
	Void saveScore(HiScore hiScore, Int level) {
		hiScoresOnline.saveScore(hiScore, level)
	}
}


@Js
class HiScore {
	DateTime	when	:= DateTime.now(1sec)
	Str			name
	Int			score
	
	new make(|This| f) { f(this) }
	
	Str toScreenStr(Int i) {
		(i == 100 ? "" : " ") + i.toStr.justr(2) + ") " + score.toStr.justr(4) + name.padl(14, '.') + " "
	}
	
	override Str toStr() {
		"${name} - ${score}"
	}
}
