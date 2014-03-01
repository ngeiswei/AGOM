AGOM
====

Lua implementation of the 5 (4 actually) principles of tonal music
from the book A Geometry of Music by Dmitri Tymoczko.

Description
-----------

Implementation of the 5 principles that contribute to make tonal music
work according to Dmitri Tymoczko, recalled here:

1. Conjunct melodic motion
2. Acoustic consonance
3. Harmony consistency
4. Limited macroharmony
5. Centricity

It's kinda of a crude implementation. Harmony consistency isn't
implemented yet and limited macroharmony and centricity are static,
that is their distribution is set once and for all at the start.

The song starts with a totally uniform random distribution of notes,
then during each even pattern, a constraint (except harmony
consistency) is progressively introduced (by what is called a
modulator in the code). The last 2 patterns generate notes according
to a distribution reflecting the 4 implemented constraints.

I didn't implement harmony consistency because no obvious simple
implementation came to my mind. I expect you'd need to consider the
various symmetries described in the book to define the harmony
consistency distance between triples (not difficult but not trivial
either). I'm only a quarter through the book, maybe the author
actually offers precise algorithm.

Usage
-----

Imported in Renoise, executed there, and will generate the partition.
