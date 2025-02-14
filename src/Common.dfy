/** A Dafny library with things everyone will find useful.
 *
 * Although Dafny comes with a 'Standard Library',
 * the library is nonetheless nascent,
 * incomplete,
 * and may not contain everything you need.
 * The 'Common' module collects useful datatypes,
 * utility
 * (and related)
 * code that you and others may find useful.
 * The code presented is not necessarily verified code.
 *
 * @Copyright Jan de Muijnck-Hughes 2024,2025
 * @Author Jan de Muijnck-Hughes
 *
 */
module Common
{
  module IO
  {
    method PrintLn(str : string)
    {
      print str, "\n";
    }
  }

  module Data
  {

    /** Data that may or may not be there.
     *
     * You may have heard of 'Option'.
     */
    module Maybe
    {

      datatype Maybe<T>
        = Nothing
        | Just (t : T)
      {
        function fromJust(m : Maybe<T>) : T
          requires Just?
        {
          t
        }
      }
        function maybe<T,A>(m : Maybe<T>, def : A, k : T -> A) : A
        ensures m.Just? ==> maybe(m, def, k) == k(m.t)
        ensures m.Nothing? ==> maybe(m, def, k) == def
        {
          match m {
            case Nothing => def
            case Just(t) => k(t)
          }
        }

        function whenNothing<A> (m : Maybe<A>, def : Maybe<A>) : Maybe<A>
        ensures m.Just? ==> whenNothing(m, def) == m
        ensures m.Nothing? ==> whenNothing(m, def) == def
        {
          maybe(m,def,(a : A) => Just(a))
        }
    }

    /** Encapsulates the result of a computation,
     * thus avoiding the billion 'dollar mistake'.
     *
     * Functional programmers call thus 'Either'
     */
    module Result
    {

      datatype Result<E,T>
        = Failure (e : E)
        | Success (t : T)

        function result<E,T,C>(r : Result<E,T>, f : E -> C, g : T -> C) : C
        {
          match r
          case Failure(e) => f(e)
          case Success(t) => g(t)
        }

    }

    module Seq
    {
      function count<T>(xs : seq<seq<T>>) : nat
      {
        if |xs| == 0
          then 0
          else |xs[0]| + count(xs[1..])
      }

      function fmap<A,B>(f : A -> B, xs : seq<A>) : seq<B>
        ensures |xs| == |fmap(f,xs)|
      {
         if |xs| == 0
          then []
          else [f(xs[0])] + fmap(f,xs[1..])
      }

      function intersperse<T>(xs : seq<T>, c : T) : seq<T>
      {
        if |xs| == 0
          then []
          else if |xs| == 1
               then [xs[0]]
               else [xs[0],c] + intersperse(xs[1..],c)
      }

      function flatten<T>(xs : seq<seq<T>>) : seq<T>
        ensures |flatten(xs)| == count(xs)
      {
        if |xs| == 0
          then []
          else xs[0] + flatten(xs[1..])
      }

      function splitOnHelp<T(==)>(xs : seq<T>, x : seq<T>, heap : seq<T>) : seq<seq<T>>
      {
        if xs == []
          then [heap]
          else if xs[0] in x
               then [heap] + splitOnHelp(xs[1..],x,[])
               else splitOnHelp(xs[1..], x, heap + [xs[0]])
      }

      function splitOn<T(==)>(xs : seq<T>, x : seq<T>) : seq<seq<T>>
      {
        splitOnHelp(xs,x,[])
      }

      function replicate<T>(cnt : nat, c : T) : seq<T>
        ensures |replicate(cnt,c)| == cnt
        ensures forall k :: 0 <= k < |replicate(cnt,c)| ==>  replicate(cnt,c)[k] == c
      {
        if cnt == 0
          then []
          else [c] + replicate(cnt - 1, c)
      }

      import opened Maybe

      //Post condition ensures the implementation
      function head<T>(xs : seq<T>) : Maybe<T>
        ensures xs == [] ==> head(xs).Nothing?
        ensures xs != [] ==> head(xs).Just? && head(xs).t == xs[0]
      {
        if xs == []
          then Nothing
          else Just(xs[0])
      }

      //Ensure correct behavior from implementation
      function tail<T>(xs : seq<T>) : Maybe<(seq<T>)>
        ensures xs == [] ==> tail(xs).Nothing?
        ensures xs != [] ==> tail(xs).Just? && tail(xs).t == xs[1..]
      {
        if xs == []
          then Nothing
          else Just(xs[1..])
      }
      //Ensures the result of the code is correct
      function splitCons<T>(xs : seq<T>) : Maybe<(T,seq<T>)>
        ensures xs == [] ==> splitCons(xs).Nothing?
        ensures xs != [] ==> splitCons(xs).Just? && splitCons(xs).t.0 == xs[0] && splitCons(xs).t.1 == xs[1..]
      {
        if xs == []
          then Nothing
          else Just((xs[0],xs[1..]))
      }

      function singleton<T>(xs : seq<T>) : Maybe<T>
      {
        if xs == []
          then Nothing
        else if |xs| > 1
          then Nothing
          else Just(xs[0])
      }

    }
    /** Utility operations on Strings.
     *
     * Mostly taken from functional program idioms,
     * and based on the fact that in Dafny:
     *
     * ```{.dafny}
     * type string = seq<char>
     * ```
     */
    module String
    {
      import opened Seq

      /** Split a string into sequences.
       *
       * @param str the string that is to be split
       * @param cs  the characters that cause a split.
       */
      function splitOn(str : string, cs : string) : seq<string>
      {
        Seq.splitOn(str,cs)
      }

      function words(s : string) : seq<string>
      {
        splitOn(s,[' '])
      }

      function wordsUn(ws : seq<string>) : string
      {
        flatten(intersperse(ws," "))
      }

      function lines(s : string) : seq<string>
      {
        splitOn(s,['\n', '\r'])
      }

      function linesUn(ws : seq<string>) : string
      {
        flatten(intersperse(ws, "\n"))
      }
    }

    /** Some operations involving nats.
     */
    module Nat
    {
      import opened Maybe
      // If and only if the character is a digit, return the digit.
      function digitFromChar(c : char) : Maybe<nat>
      ensures digitFromChar(c).Just? <==> '0' <= c <= '9'
      {
        match c
        {
        case '0' => Just(0)
        case '1' => Just(1)
        case '2' => Just(2)
        case '3' => Just(3)
        case '4' => Just(4)
        case '5' => Just(5)
        case '6' => Just(6)
        case '7' => Just(7)
        case '8' => Just(8)
        case '9' => Just(9)
        case x => Nothing
        }
      }
      //We dont need to validate this since we validate the root method this uses
      function digitsFromString(s : string) : Maybe<seq<nat>>
      {
        if s == []
        then Just([])
        else maybe(digitFromChar(s[0]),Nothing,
          (c : nat) =>
          maybe(digitsFromString(s[1..]),Nothing,
          (cs : seq<nat>) =>
          Just([c] + cs)
          ))
      }
    }
  }

}
