include "Common.dfy"
include "Commands.dfy"
include "ConsoleIO.dfy"

module CS886 {
  import opened Common.IO
  import opened Common.Data
  import opened Common.Data.String
  import opened Common.Data.Maybe
  import opened Common.Data.Result
  import opened Common.Data.Seq
  import opened Commands
  import opened ConsoleIO

  method {:main} Main()
    decreases *
  {
    REPL(">");
  }

  method REPL(prompt : string)
    decreases *
  {
    var inGame := false;
    var turnsTaken := 0;
    var secret : seq<nat> := [];
    var selectedTurns := 0;
    while true
      decreases *
      invariant !inGame ==> (secret == [] && selectedTurns == 0 && turnsTaken == 0)
      //invariant inGame ==> (|secret| > 4 && selectedTurns >= 4)
      //invariant inGame ==> (turnsTaken < selectedTurns)
      invariant turnsTaken >= 0
    {
      print prompt, " ";

      var resp := ReadLine();
      match fromString(resp)
      {
      case Nothing =>
        continue;

      case Just(cmd) =>
        match cmd
        {
          case Help =>
            runHelp();
          case Quit =>
            if !inGame {
              WriteLine("Exiting game");
              break;
            } else {
              WriteLine("Abandoning game, goodbye.");
              break;
            }

          case Play(turns, sequence) =>
            if inGame {
              WriteLine("Already in a game.");
            } else {
              if turns.Just? && sequence.Just? {
                var started := startGameProcess(turns, sequence, inGame);
                if started {
                  inGame := true;
                  WriteLine("Game on!");
                  secret := extractSequence(sequence);
                  selectedTurns := extractTurns(turns);
                }
              } else {
                WriteLine("Invalid command.");
              }
            }

          case Guess(guess) =>
            if isNothing(guess) {
              WriteLine("Invalid command.");
            } else if !inGame {
              WriteLine("Not in a game.");
            } else {
              var extractedGuess := extractSequence(guess);
              if extractedGuess == [] || |extractedGuess| != |secret| {
                WriteLine("Guess was the wrong length.");
              } else {
                var finished := handleGuess(extractedGuess, secret);
                if finished {
                  inGame := false;
                  turnsTaken := 0;
                  secret := [];
                  selectedTurns := 0;
                } else if turnsTaken + 1 < selectedTurns {
                  turnsTaken := turnsTaken + 1;
                } else {
                  WriteLine("No more turns left!");
                  WriteLine("The secret was: ");
                  printSequence(secret);
                  WriteLine("\n");
                  inGame := false;
                  turnsTaken := 0;
                  secret := [];
                  selectedTurns := 0;
                }
              }
            }

          case Stop(args) =>
            if args == [] {
              if !inGame {
                WriteLine("Not playing a game.");
              } else {
                WriteLine("Abandoning game, resetting state.");
                inGame := false;
                turnsTaken := 0;
                secret := [];
                selectedTurns := 0;
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
    if countElements(extractedSequence) < 4 {
      WriteLine("The secret is too short.");
      return false;
    }
    var areUnique := areAllElementsUnique(extractedSequence);
    if !areUnique {
      var duplicates := getDuplicateElements(extractedSequence);
      WriteLine("The secret contained a repeated character:");
      print duplicates;
      print "\n";
      return false;
    }
    return true;
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
  }

  // Helpers

  predicate isNothing<T>(m: Maybe<T>) {
    match m {
      case Nothing => true
      case Just(_) => false
    }
  }

  function extractSequence(m: Maybe<seq<nat>>): seq<nat>
    requires m.Just?
  {
    match m {
      case Just(value) => value
      case Nothing => []
    }
  }

  function extractTurns(m: Maybe<nat>): nat
    requires m.Just?
  {
    match m {
      case Just(value) => value
      case Nothing => 0
    }
  }

  function countElements<T>(sequence: seq<T>): nat {
    |sequence|
  }

  method printSequence(sequence: seq<nat>)
    requires |sequence| > 0
  {
    var i := 0;
    while i < |sequence|
      decreases |sequence| - i
      invariant 0 <= i <= |sequence|
    {
      print sequence[i];
      i := i + 1;
    }
  }
   // Return true if all elements are unique.
  method areAllElementsUnique(sequence: seq<nat>) returns (unique: bool)
    requires sequence != []
    ensures unique <==> (forall i, j :: 0 <= i < j < |sequence| ==> sequence[i] != sequence[j])
  {
    unique := true;
    var i := 0;
    while i < |sequence|
      decreases |sequence| - i
      invariant 0 <= i <= |sequence|
      invariant (unique ==> (forall k, l :: 0 <= k < l < i ==> sequence[k] != sequence[l]))
      invariant (!unique ==> (i > 0 && exists k, l :: 0 <= k < l < i && sequence[k] == sequence[l]))
    {
      if sequence[i] in sequence[..i] {
        unique := false;
      }
      i := i + 1;
    }
  }
   // Return a sequence of duplicate elements.
  method getDuplicateElements(sequence: seq<nat>) returns (duplicates: seq<nat>)
    requires sequence != []
    //ensures |duplicates| <= |sequence|
    //ensures forall x :: x in duplicates ==> x in sequence
  {
    duplicates := [];
    var i := 0;
    while i < |sequence|
      decreases |sequence| - i
      invariant 0 <= i <= |sequence|
    {
      if (!(sequence[i] in duplicates) && i < |sequence| - 1 && sequence[i] in sequence[i+1..]) {
        duplicates := duplicates + [sequence[i]];
      }
      i := i + 1;
    }
  }
}
