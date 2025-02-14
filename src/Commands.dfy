include "Common.dfy"
include "Helpers.dfy"

module Commands {

  import opened Common.Data.Maybe
  import opened Common.Data.Seq
  import opened Common.Data.String
  import opened Common.Data.Nat
  import opened Helpers

  datatype CMD
    = Quit
    | Help
    | Play(turns:Maybe<nat>, sequence:Maybe<seq<nat>>)
    | Guess(Maybe<seq<nat>>)
    | Stop(args:seq<string>)

    // No post condition is required as we have checked the root methods.
    function stripColon(s : string) : Maybe<string>
    requires |s| > 0  // Ensure string is non-empty for head operation
    {
      maybe(
      head(s),
      Nothing,
      (res : char) =>
      if res == ':'
        then tail(s)
        else Nothing
      )
    }
    // Might not be necessary but for sanity sake I have added a precondition to match stripColon.
    function preprocess(s:string) : Maybe<(string,seq<string>)>
    requires |s| > 0
    {
      maybe(stripColon(s), Nothing, (res : string) => splitCons(words(res)))
    }

    function processQuit(cmd : string, args : seq<string>) : Maybe<CMD>
    ensures args != [] ==> processQuit(cmd, args) == Nothing  // If there are arguments, return Nothing
    ensures cmd != "quit" ==> processQuit(cmd, args) == Nothing  // If command isn't "quit", return Nothing
    ensures cmd == "quit" && args == [] ==> processQuit(cmd, args) == Just(Quit)  // Only allow quit with no args
    {
      if cmd == "quit" && args == []
      then Just(Quit)
      else Nothing
    }

    function processPlay(cmd : string, args : seq<string>) : Maybe<CMD>
    requires args != []
    requires cmd == "play"
    {
      if |args| == 2
        then
          var turns := stringToNat(args[0]);
          var sequence := digitsFromString(args[1]);
          Just(Play(turns, sequence))
        else Nothing
    }

    function processGuess(cmd :string, args : seq<string>) : Maybe<CMD>
    requires args != []
    requires cmd == "guess"
    {
      var guess := digitsFromString(args[0]);
      Just(Guess(guess))
    }

    function processStop(cmd : string, args : seq<string>) : Maybe<CMD>
    requires cmd == "stop"
    ensures cmd != "stop" ==> processStop(cmd, args) == Nothing  // If command isn't "stop", return Nothing
    ensures cmd == "stop" ==> processStop(cmd, args) == Just(Stop(args))  // If command is "stop", return Stop with args
    {
      if cmd == "stop"
        then Just(Stop(args))
        else Nothing
    }

    function processHelp(cmd : string, args : seq<string>) : Maybe<CMD>
    ensures cmd !in ["help", "h", "?"] ==> processHelp(cmd, args) == Nothing  // If command isn't help, return Nothing
    ensures cmd in ["help", "h", "?"] ==> processHelp(cmd, args) == Just(Help)  // If command is help, return Help
    {
      if cmd in ["help", "h", "?"]
        then Just(Help)
        else Nothing
    }


    function process(cmd : string, args : seq<string>) : Maybe<CMD>
    {
      if cmd == "play" && args != [] then
        processPlay(cmd, args)
      else if cmd == "guess" && args != [] then
        processGuess(cmd, args)
      else if cmd == "stop" && args == [] then
        processStop(cmd, args)
      else if (cmd == "quit" || cmd in ["help", "h", "?"]) && args == [] then
        whenNothing(processQuit(cmd, args), processHelp(cmd, args))
      else
        Nothing
    }

    function fromString(s : string) : Maybe<CMD>
    {
      maybe(
        preprocess(s),
        Nothing,
        (res : (string,seq<string>)) =>
          process(res.0,res.1)
        )
    }
  }
