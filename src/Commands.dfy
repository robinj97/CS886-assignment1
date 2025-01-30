include "Common.dfy"

module Commands {

  import opened Common.Data.Maybe
  import opened Common.Data.Seq
  import opened Common.Data.String
  import opened Common.Data.Nat

  datatype CMD
    = Quit
    | Help

    function stripColon(s : string) : Maybe<string>
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

    function preprocess(s:string) : Maybe<(string,seq<string>)>
    {
      maybe(stripColon(s), Nothing, (res : string) => splitCons(words(res)))
    }

    function processQuit(cmd : string, args : seq<string>) : Maybe<CMD>
    {
      if cmd == "quit"
        then Just(Quit)
        else Nothing
    }

    function processHelp(cmd : string, args : seq<string>) : Maybe<CMD>
    {
      if cmd in ["help", "h", "?"]
        then Just(Help)
        else Nothing
    }


    function process(cmd : string, args : seq<string>) : Maybe<CMD>
    {
      whenNothing(processQuit(cmd,args),
        processHelp(cmd,args))
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
