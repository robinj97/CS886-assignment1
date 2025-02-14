include "Helpers.dfy"
include "Common.dfy"
include "Commands.dfy"
include "ConsoleIO.dfy"
module Game {
  import opened Helpers
  import opened Common.IO
  import opened Common.Data
  import opened Common.Data.String
  import opened Common.Data.Maybe
  import opened Common.Data.Result
  import opened Common.Data.Seq
  import opened Common.Data.Nat
  import opened Commands
  import opened ConsoleIO
  class Game {
    var inGame:bool
    var turnsTaken:nat
    var secret : seq<nat>
    var selectedTurns:nat

    constructor create() {
      inGame := false;
      turnsTaken := 0;
      secret := [];
      selectedTurns := 0;
    }
    function getIngame():bool
    reads this {
        inGame
    }
    method setIngame(val:bool)
    modifies this {
        inGame := val;
    }

    function getTurnsTaken() : nat
    reads this {
      turnsTaken
    }
    method setTurnsTaken(val:nat)
    modifies this {
        turnsTaken := val;
    }
    method incrementTurnsTaken()
    modifies this
    {
        turnsTaken := turnsTaken + 1;
    }

    function getSecret() : seq<nat>
    reads this {
      secret
    }
    method setSecret(val:seq<nat>)
    modifies this
    {
        secret := val;
    }
    method reset()
    ensures inGame == false
    ensures turnsTaken == 0
    ensures secret == []
    ensures selectedTurns == 0
    {
      inGame := false;
      turnsTaken := 0;
      secret := [];
      selectedTurns := 0;
    }

    function getSelectedTurns() : nat
    reads this {
      selectedTurns
    }
    method setSelectedTurns(val:nat)
    modifies this
    {
      selectedTurns := val;
    }

    method startGameProcess(turns: Maybe<nat>, sequence: Maybe<seq<nat>>, inGame: bool)
    returns (started: bool)
    requires !inGame
    requires turns.Just?
    requires sequence.Just?
    {
      if isNothing(turns) || isNothing(sequence) {
        WriteLine("Invalid command.");
        return false;
      }
      assert turns.Just?;
      assert sequence.Just?;

      var extractedTurns := extractTurns(turns);
      var extractedSequence := extractSequence(sequence);
      if extractedTurns < 4 {
        WriteLine("There should be at least 4 turns.");
        return false;
      }
      if |extractedSequence| < 4 {
        WriteLine("The secret is too short.");
        return false;
      }
      assert |extractedSequence| >= 4;
      var areUnique := areAllElementsUnique(extractedSequence);
      if !areUnique {
        //@TODO: Only return first element from the list?
        var duplicates := getDuplicateElements(extractedSequence);
        WriteLine("The secret contained a repeated character:");
        print duplicates;
        print "\n";
        return false;
      }
      return true;
    }
    method setPlayingGameState(inGame:bool, secret:Maybe<seq<nat>>, selectedTurns:Maybe<nat>)
    modifies this
    requires secret.Just?
    requires selectedTurns.Just?
    requires inGame == true
    {
      this.setIngame(true);
      WriteLine("Game on!");
      var extractedSecret := extractSequence(secret);
      var extractedTurns := extractTurns(selectedTurns);
      this.setSecret(extractedSecret);
      this.setSelectedTurns(extractedTurns);
    }

    method processGuess(guess: Maybe<seq<nat>>) {
      var extractedGuess := extractSequence(guess);
      if extractedGuess == [] || |extractedGuess| != |secret| {
        WriteLine("Guess was the wrong length.");
      } else {
        var finished := handleGuess(extractedGuess, secret);
        if finished {
          this.reset();
        } else if turnsTaken + 1 < selectedTurns {
          this.incrementTurnsTaken();
        } else {
          this.forceEndGame();
        }
      }
    }
    method handleGuess(guess: seq<nat>, secret: seq<nat>)
    returns (finished: bool)
    requires guess != []
    requires |guess| == |secret|
    ensures finished ==> (guess == secret)
    ensures !finished ==> (guess != secret)
    {
      if |guess| != |secret| {
        WriteLine("Guess was the wrong length.");
        return false;
      }

      if guess == secret {
        WriteLine("Congratulations you guessed correctly!");
        return true;
      }
      var yae, nae := evaluateGuess(guess, secret);
      return false;
    }
    method evaluateGuess(guess: seq<nat>, secret: seq<nat>)
    returns (yay: nat, nae: nat)
    requires guess != []
    requires |guess| == |secret|
    ensures yay + nae <= |guess|
    ensures yay <= |guess|
    ensures nae <= |guess|
    //ensures forall i :: 0 <= i < |guess| ==> (guess[i] == secret[i] ==> yay > 0)
    {
      assert |guess| == |secret|;
      yay := 0;
      nae := 0;
      var i := 0;
      while i < |guess|
        decreases |guess| - i
        invariant 0 <= i <= |guess|
        invariant yay + nae <= i
      {
        if guess[i] == secret[i] {
          yay := yay + 1;
        } else if guess[i] in secret {
          nae := nae + 1;
        }
        i := i + 1;
      }
      print guess;
      print " ";
      print yay;
      print " yay ";
      print nae;
      print " nae\n";

      assert yay + nae <= |guess|;
    }
    method forceEndGame() {
      WriteLine("No more turns left!");
      WriteLine("The secret was: ");
      printSequence(secret);
      WriteLine("");
      this.reset();
    }
  }
}
