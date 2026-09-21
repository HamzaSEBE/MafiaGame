enum GameStatus {
  setup,
  playing,
  gameOver,
}

enum Phase {
  setup,
  roleReveal,
  mafiaReveal,
  night,
  nightMafiaSheikh,
  nightMafiaGirl,
  nightNormalMafia,
  nightCitizensSheikh,
  nightCitizensGirl,
  nightResolution,
  dawn,
  day,
  voting,
  voteResolution,
  elimination,
  triggeredAbility, // e.g. Citizen Boy
  winCheck,
}
