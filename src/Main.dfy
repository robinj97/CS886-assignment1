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
              WriteLine("Exiting game.");
              break;
            } else {
              WriteLine("Abaooning game, goodbye.");
              break;
            }
          }
          case Play(turns,sequence) => {
            if inGame {
              WriteLine("Cannot start a new game while in game.");
            } else {
              //Maybe change this to a boolean which switches ingame to true
              inGame := startGameProcess(turns, sequence, inGame);
              if (inGame) {
                WriteLine("Game on!");
                secret := extractSequence(sequence);
                selectedTurns := extractTurns(turns);
              }
            }
          }
          case Guess(guess) => {
            if !inGame {
              WriteLine("Not in a game.");
            } else {
              WriteLine("Guessing");
              var extractedGuess := extractSequence(guess);
              var finished := handleGuess(extractedGuess, secret);
              if (finished) {
                inGame := false;
              }
            }
          }
        }
      }
    }
  }

  method runHelp()
  {
    WriteLine("Commands: ");
    WriteLine(":quit         -- Exit programme");
    WriteLine(":play [n] [s] -- Play a game with 'n' tries and a secret sequence 's'");
    WriteLine(":guess [seq]  -- guess the secret");
    WriteLine(":stop         -- end game");
  }

  method startGameProcess(turns:Maybe<nat>, sequence: Maybe<seq<nat>>,inGame: bool)
  returns (started: bool)
  requires !inGame
  {
    started := inGame;
    if isNothing(turns) || isNothing(sequence) {
      WriteLine("Invalid command.");
      return;
    }
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
    return false;
  }
  /* method playGame(turns:nat, sequence:seq<nat>, inGame:bool)
  {
    var secret := sequence;
    var guesses := [];
    var turnsLeft := turns;
    var inGame := true;
    while (turnsLeft > 0)
    {
      var guess := ReadLine();
      match fromString(guess)
      {
      case Nothing =>
        continue;

      case Just(cmd) =>
        match cmd
        {
          case Guess(seq) => {
            if (seq == secret) {
              WriteLine("Congratulations you guessed correctly!");
              inGame := false;
              break;
            } else {
              var result := evaluateGuess(seq, secret);
              turnsLeft := turnsLeft - 1;
              guesses := guesses + [result];
              if (turnsLeft == 0) {
                WriteLine("You lose!");
                inGame := false;
                break;
              }
            }
          }
          case Stop => {
            WriteLine("Game stopped.");
            inGame := false;
            break;
          }
        }
      }
    }
  } */


  // Helpers

  predicate isNothing<T>(m: Maybe<T>) {
  match m {
    case Nothing => true
    case Just(_) => false
    }
  }
  //@TODO: Need to add precondition that sequence is Just.
  method extractSequence(m : Maybe<seq<nat>>)
  returns (ret:seq<nat>)
  {
    match m {
      case Just(value) => ret := value;
      case Nothing => ret := [];
    }
  }
  //TODO: Need to add precondition that turns is Just.
  method extractTurns(m : Maybe<nat>)
  returns (ret:nat)
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
}
