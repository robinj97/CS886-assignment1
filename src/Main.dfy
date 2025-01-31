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
          case Quit => break;
          case Play => print Play;
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
}
