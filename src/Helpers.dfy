include "Common.dfy"
module Helpers {
  import opened Common.IO
  import opened Common.Data
  import opened Common.Data.String
  import opened Common.Data.Maybe
  import opened Common.Data.Result
  import opened Common.Data.Seq
  import opened Common.Data.Nat
  predicate isNothing<T>(m: Maybe<T>) {
    match m {
      case Nothing => true
      case Just(_) => false
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
    //Make sure we printed the whole list
    assert i == |sequence|;
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
      invariant forall x :: x in duplicates ==> x in sequence
    {
      if (!(sequence[i] in duplicates) && i < |sequence| - 1 && sequence[i] in sequence[i+1..]) {
        duplicates := duplicates + [sequence[i]];
      }
      i := i + 1;
    }
    assert forall x :: x in duplicates ==> x in sequence;
  }
}
