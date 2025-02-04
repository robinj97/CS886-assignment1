include "Common.dfy"
include "Commands.dfy"
include "ConsoleIO.dfy"

module CS886
{

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
    var secret := [];
    var selectedTurns := 0;
    while true
      decreases *
    {
      print prompt,  " ";

      var resp := ReadLine();
      match fromString(resp)
      {
      case Nothing =>
        continue;

      case Just(cmd) =>
        match cmd
        {
          case Help => runHelp();
          case Quit => {
            if !inGame {
              WriteLine("Exiting game");
              break;
            } else {
              WriteLine("Abandoning game, goodbye.");
              break;
            }
          }
          case Play(turns, sequence) => {
            if inGame {
              WriteLine("Already in a game.");
            } else {
              if turns.Just? && sequence.Just? {
                inGame := startGameProcess(turns, sequence, inGame);
                if inGame {
                  WriteLine("Game on!");
                  secret := extractSequence(sequence);
                  selectedTurns := extractTurns(turns);
                }
              } else {
                WriteLine("Invalid command.");
              }
            }
          }
          case Guess(guess) => {
            if isNothing(guess) {
              WriteLine("Invalid command.");
            } else {
              if !inGame {
              WriteLine("Not in a game.");
            } else {
              var extractedGuess := extractSequence(guess);
              var finished := handleGuess(extractedGuess, secret);
              if (finished) {
                inGame := false;
              } else {
                turnsTaken := turnsTaken + 1;
                if (turnsTaken == selectedTurns) {
                  WriteLine("No more turns left!");
                  WriteLine("The secret was: ");
                  printSequence(secret);
                  WriteLine("\n");
                  inGame := false;
                }
              }
            }
            }
          }
          case Stop(args) => {
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
            }
            else {
              WriteLine("Invalid command.");
            }
          }
        }
      }
    }
  }

  method runHelp()
  {
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
    started := inGame;
    if isNothing(turns) || isNothing(sequence) {
      WriteLine("Invalid command.");
      return;
    }
    assert turns.Just?;
    assert sequence.Just?;

    var extractedTurns := extractTurns(turns);
    var extractedSequence := extractSequence(sequence);
    if (extractedTurns < 4) {
      WriteLine("There should be at least 4 turns.");
      return;
    }
    if (CountElements(extractedSequence) < 4) {
      WriteLine("The secret is too short.");
      return;
    }
    var areElementsUnique := areAllElementsUnique(extractedSequence);
    if (!areElementsUnique) {
      var duplicates := getDuplicateElements(extractedSequence);
      WriteLine("The secret contained a repeated character:");
      print duplicates;
      print "\n";
      return;
    }
    return true;

  }

  // Return true if all elements are unique
  method areAllElementsUnique(sequence: seq<nat>) returns (unique: bool)
  requires sequence != []
  {
    unique := true;
    for i := 0 to |sequence| - 1 {
      if sequence[i] in sequence[..i] {
        unique := false;
        break;
      }
    }
  }

  // Return a sequence of duplicate elements
  method getDuplicateElements(sequence: seq<nat>) returns (duplicates: seq<nat>)
  requires sequence != []
  {
    duplicates := [];
    for i := 0 to |sequence| - 1 {
      if !(sequence[i] in duplicates) {
        // Check if current element appears later in the sequence
        if sequence[i] in sequence[i+1..] {
          duplicates := duplicates + [sequence[i]];
        }
      }
    }
  }

  method handleGuess(guess: seq<nat>, secret: seq<nat>)
  returns (finished: bool)
  {
    if guess == [] {
      WriteLine("Guess was empty.");
      return false;
    }
    if secret == [] {
      WriteLine("Secret was empty.");
      return false;
    }
    if |guess| != |secret| {
      WriteLine("Guess was the wrong length.");
      return false;
    }

    if guess == secret {
      WriteLine("Congratulations you guessed correctly!");
      return true;
    }
    evaluateGuess(guess, secret);
    return false;
  }

  method evaluateGuess(guess: seq<nat>, secret: seq<nat>)
  requires guess != []
  requires |guess| == |secret|
  {
    var yay := 0;
    var nae := 0;
    for i := 0 to |guess| {
      if guess[i] == secret[i] {
        yay := yay + 1;
      } else if guess[i] in secret {
        nae := nae + 1;
      }
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

  method extractSequence(m : Maybe<seq<nat>>)
  returns (ret:seq<nat>)
  requires m.Just?
  {
    match m {
      case Just(value) => ret := value;
      case Nothing => ret := [];
    }
  }

  method extractTurns(m : Maybe<nat>)
  returns (ret:nat)
  requires m.Just?
  ensures ret > -1
  {
    match m {
      case Just(value) => ret := value;
      case Nothing => ret := 0;
    }
  }

  function CountElements<T>(sequence: seq<T>): nat
  {
    |sequence|
  }

  method printSequence(sequence: seq<nat>)
  {
    if sequence == [] {
      print "[]";
    }
    if |sequence| > 0 {
      for i := 0 to |sequence| {
        print sequence[i];
      }
    }
  }
}
