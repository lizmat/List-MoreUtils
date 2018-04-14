[![Build Status](https://travis-ci.org/lizmat/List-MoreUtils.svg?branch=master)](https://travis-ci.org/lizmat/List-MoreUtils)

NAME
====

List::MoreUtils - Port of Perl 5's List::MoreUtils 0.428

SYNOPSIS
========

    # import specific functions
    use List::MoreUtils <any uniq>;
     
    if any { /foo/ }, uniq @has_duplicates {
        # do stuff
    }
     
    # import everything
    use List::MoreUtils ':all';

DESCRIPTION
===========

List::MoreUtils provides some trivial but commonly needed functionality on lists which is not going to go into `List::Util`.

EXPORTS
=======

Nothing by default. To import all of this module's symbols use the `:all` tag. Otherwise functions can be imported by name as usual:

    use List::MoreUtils :all;
     
    use List::MoreUtils <any firstidx>;

Porting Caveats
===============

Perl 6 does not have the concept of `scalar` and `list` context. Usually, the effect of a scalar context can be achieved by prefixing `+` to the result, which would effectively return the number of elements in the result, which usually is the same as the scalar context of Perl 5 of these functions.

Perl 6 does not have a magic `$a` and `$b`. But they can be made to exist by specifying the correct signature to blocks, specifically "-> $a, $b". These have been used in all examples that needed them. Just using the signature auto-generating `$^a` and `$^b` would be more Perl 6 like. But since we want to keep the documentation as close to the original as possible, it was decided to specifically specify the "-> $a, $b" signatures.

Many functions take a `&code` parameter of a `Block` to be called by the function. Many of these assume **$_** will be set. In Perl 6, this happens automagically if you create a block without a definite or implicit signature:

    say { $_ == 4 }.signature;   # (;; $_? is raw)

which indicates the Block takes an optional parameter that will be aliased as `$_` inside the Block.

Perl 6 also doesn't have a single `undef` value, but instead has `Type Objects`, which could be considered undef values, but with a type annotation. In this module, `Nil` (a special value denoting the absence of a value where there should have been one) is used instead of `undef`.

Also note there are no special parsing rules with regards to blocks in Perl 6. So a comma is **always** required after having specified a block.

The following functions are actually built-ins in Perl 6.

    any all none minmax uniq zip

They mostly provide the same or similar semantics, but there may be subtle differences, so it was decided to not just use the built-ins. If these functions are imported from this library in a scope, they will used instead of the Perl 6 builtins. The easiest way to use both the functions of this library and the Perl 6 builtins in the same scope, is to use the method syntax for the Perl 6 versions.

    my @a = 42,5,2,98792,88;
    {  # Note: imports in Perl 6 are always lexically scoped
        use List::Util <minmax>;
        say minmax @a;  # Ported Perl 5 version
        say @a.minmax;  # Perl 6 version
    }
    say minmax @a;  # Perl 6 version again

Many functions returns either `True` or `False`. These are `Bool`ean objects in Perl 6, rather than just `0` or `1`. However, if you use a Boolean value in a numeric context, they are silently coerced to 0 and 1. So you can still use them in numeric calculations as if they are 0 and 1.

FUNCTIONS
=========

Junctions
---------

### *Treatment of an empty list*

There are two schools of thought for how to evaluate a junction on an empty list:

  * Reduction to an identity (boolean)

  * Result is undefined (three-valued)

In the first case, the result of the junction applied to the empty list is determined by a mathematical reduction to an identity depending on whether the underlying comparison is "or" or "and". Conceptually:

    "any are true"      "all are true"
    --------------      --------------

    2 elements:     A || B || 0         A && B && 1
    1 element:      A || 0              A && 1
    0 elements:     0                   1

In the second case, three-value logic is desired, in which a junction applied to an empty list returns `Nil` rather than `True` or `False`.

Junctions with a `_u` suffix implement three-valued logic. Those without are boolean.

### all BLOCK, LIST

### all_u BLOCK, LIST

Returns True if all items in LIST meet the criterion given through BLOCK. Passes each element in LIST to the BLOCK in turn:

    print "All values are non-negative"
      if all { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, `all` returns True (i.e. no values failed the condition) and `all_u` returns `Nil`.

Thus, `all_u(@list) ` is equivalent to `@list ?? all(@list) !! Nil `.

**Note**: because Perl treats `Nil` as false, you must check the return value of `all_u` with `defined` or you will get the opposite result of what you expect.

### any BLOCK, LIST

### any_u BLOCK, LIST

Returns True if any item in LIST meets the criterion given through BLOCK. Passes each element in LIST to the BLOCK in turn:

    print "At least one non-negative value"
      if any { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, `any` returns False and `any_u` returns `Nil`.

Thus, `any_u(@list) ` is equivalent to `@list ?? any(@list) !! undef `.

### none BLOCK, LIST

### none_u BLOCK, LIST

Logically the negation of `any`. Returns True if no item in LIST meets the criterion given through BLOCK. Passes each element in LIST to the BLOCK in turn:

    print "No non-negative values"
      if none { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, `none` returns True (i.e. no values failed the condition) and `none_u` returns `Nil`.

Thus, `none_u(@list) ` is equivalent to `@list ?? none(@list) !! Nil `.

**Note**: because Perl treats `Nil` as false, you must check the return value of `none_u` with `defined` or you will get the opposite result of what you expect.

### notall BLOCK, LIST

### notall_u BLOCK, LIST

Logically the negation of `all`. Returns True if not all items in LIST meet the criterion given through BLOCK. Passes each element in LIST to the BLOCK in turn:

    print "Not all values are non-negative"
      if notall { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, `notall` returns False and `notall_u` returns `Nil`.

Thus, `notall_u(@list) ` is equivalent to `@list ?? notall(@list) !! Nil `.

### one BLOCK LIST

### one_u BLOCK LIST

Returns True if precisely one item in LIST meets the criterion given through BLOCK. Passes each element in LIST to the BLOCK in turn:

    print "Precisely one value defined"
        if one { defined($_) }, @list;

Returns False otherwise.

For an empty LIST, `one` returns False and `one_u` returns `Nil`.

The expression `one BLOCK LIST` is almost equivalent to `1 == True BLOCK LIST`, except for short-cutting. Evaluation of BLOCK will immediately stop at the second true value seen.

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

