include "Common.dfy"
include "Commands.dfy"
include "ConsoleIO.dfy"
include "Game.dfy"
include "Helpers.dfy"

module CS886 {
  import opened Common.IO
  import opened Common.Data
  import opened Common.Data.String
  import opened Common.Data.Maybe
  import opened Common.Data.Result
  import opened Common.Data.Seq
  import opened Common.Data.Nat
  import opened Commands
  import opened ConsoleIO
  import opened Game
  import opened Helpers

  method {:main} Main()
    decreases *
  {
    REPL(">");
  }

  method REPL(prompt : string)
    decreases *
  {
    var gameState := new Game.create();
    while true
      decreases *
      //invariant !gameState.getIngame() ==> (gameState.getSecret() == [] && gameState.getSelectedTurns() == 0 && gameState.getTurnsTaken() == 0)
      //invariant inGame ==> (|secret| > 4 && selectedTurns >= 4)
      //invariant inGame ==> (turnsTaken < selectedTurns)
      //invariant gameState.getTurnsTaken() >= 0
    {
      print prompt, " ";

      var resp := ReadLine();

      match fromString(resp)
      {
      case Nothing =>
        WriteLine("Invalid command.");

      case Just(cmd) =>
        match cmd
        {
          case Help =>
            runHelp();
          case Quit =>
             if !gameState.getIngame() {
              WriteLine("Exiting game");
              break;
            }
            else {
              WriteLine("Abandoning game, goodbye.");
              break;
            }

          case Play(turns, sequence) =>
            if gameState.getIngame() {
              WriteLine("Already in a game.");
            } else {
              if turns.Just? && sequence.Just? {
                var currentIngame := gameState.getIngame();
                var started := gameState.startGameProcess(turns, sequence, currentIngame);
                if started {
                  gameState.setPlayingGameState(started,sequence,turns);
                }
              } else {
                WriteLine("Invalid command.");
              }
            }
          case Guess(guess) =>
            if isNothing(guess) {
              WriteLine("Invalid command.");
            } else if !gameState.getIngame() {
              WriteLine("Not in a game.");
            } else {
              gameState.processGuess(guess);
            }

          case Stop(args) =>
            if args == [] {
              if !gameState.getIngame() {
                WriteLine("Not playing a game.");
              } else {
                WriteLine("Abandoning game, resetting state.");
                gameState.reset();
              }
            } else {
              WriteLine("Invalid command.");
            }
        }
      }
    }
  }

  method runHelp() {
    WriteLine("Yays & Naes");
    print "\n";
    WriteLine("Commands:");
    print "\n";
    WriteLine(":quit         -- Exit programme");
    WriteLine(":play [n] [s] -- Play a game with `n` tries and a secret sequence `s`");
    WriteLine(":guess [seq]  -- guess the secret");
    WriteLine(":stop         -- end game");
  }
}
