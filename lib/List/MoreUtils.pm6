use v6.c;

class List::MoreUtils:ver<0.0.1>:auth<cpan:ELIZABETH> {
    our sub any(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        return True if code($_) for @values;
        False
    }
    our sub any_u(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        any(&code,@values) || Nil
    }

    our sub all(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        return False unless code($_) for @values;
        True
    }
    our sub all_u(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        all(&code,@values) && Nil
    }

    our sub none(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        return False if code($_) for @values;
        True
    }
    our sub none_u(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        none(&code,@values) && Nil
    }

    our sub notall(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        return True unless code($_) for @values;
        False
    }
    our sub notall_u(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        notall(&code,@values) || Nil
    }

    our sub one(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        my Int $seen = 0;
        return False unless code($_) && $seen++ for @values;
        so $seen
    }
    our sub one_u(&code, @values --> Bool:D) is export(:SUPPORTED:all) {
        my Int $seen;
        return False unless code($_) && $seen++ for @values;
        $seen ?? True !! Nil
    }

    our sub apply(&code, @values) is export(:SUPPORTED:all) {
        @values.map( -> $_ is copy { code($_) } ).List
    }

    our proto sub insert_after(|) is export(:SUPPORTED:all) {*}
    multi sub insert_after(&code, \insertee, @values --> Nil) {
        for @values.kv -> $key, $value {
            if code($value) {
                @values.splice($key + 1, 1, insertee);
                return
            }
        }
    }
    multi sub insert_after(&code, Pair:D $pair) {
        insert_after(&code, $pair.key, $pair.value)
    }
    multi sub insert_after(&code, *%_ --> Nil) {
        %_.elems > 1
          ?? die "Can only specify one named parameter to 'insert_after'"
          !! insert_after(&code, .key, .value) with %_.head
    }

    our proto sub insert_after_string(|) is export(:SUPPORTED:all) {*}
    multi sub insert_after_string(Str() $string, \insertee, @values --> Nil) {
        for @values.kv -> $key, $value {
            if $value.defined && $value eq $string {
                @values.splice($key + 1, 1, insertee);
                return
            }
        }
    }
    multi sub insert_after_string(Str() $string, Pair:D $pair) {
        insert_after_string($string, $pair.key, $pair.value)
    }
    multi sub insert_after_string(Str() $string , *%_ --> Nil) {
        %_.elems > 1
          ?? die "Can only specify one named parameter to 'insert_after_string'"
          !! insert_after_string($string, .key, .value) with %_.head
    }

    our sub pairwise(&code, @a, @b) is export(:SUPPORTED:all) {
        my $i = -1;
        my @pairwise;
        while ++$i < @a.elems && $i < @b.elems {
            @pairwise.append(code(@a.AT-POS($i), @b.AT-POS($i)).Slip)
        }
        @pairwise
    }

    our sub mesh(**@arrays, :$DONTSLIP) is export(:SUPPORTED:all) {
        my @iterators = @arrays.map: *.iterator;
        my $nr_values = +@iterators;
        my @mesh;
        
        loop {
            my $seen = $nr_values;
            my @values = @iterators.map: {
                my $pulled := .pull-one;
                if $pulled =:= IterationEnd {
                    --$seen;
                    Nil
                }
                else {
                    $pulled
                }
            }
            last unless $seen;
            @mesh.append( $DONTSLIP ?? @values !! @values.Slip )
        }
        @mesh
    }
    our constant &zip is export(:SUPPORTED:all) = &mesh;

    our sub zip6(|c) is export(:SUPPORTED:all) { mesh(|c, :DONTSLIP) }
    our constant &zip_unflatten is export(:SUPPORTED:all) = &zip6;

    our sub listcmp(**@arrays --> Hash:D) is export(:SUPPORTED:all) {
        my %result;
        for @arrays.kv -> $index, @array {
            for @array -> \value {
                with %result{value} {
                    .push($index)
                }
                else {
                    %result.BIND-KEY(value,[$index]);
                }
            }
        }
        %result
    }

    our sub arrayify(**@values) is export(:SUPPORTED:all) {
        my @arrayify;
        multi sub flatten(@values) { flatten($_) for @values }
        multi sub flatten(\value)  { @arrayify.push(value) }

        flatten($_) for @values;
        @arrayify
    }

    our sub uniq(@values) is export(:SUPPORTED:all) {
        my %seen;
        my @uniq;

        @uniq.push($_) unless %seen{.defined ?? .Str !! .^name}++ for @values;
        @uniq
    }
    our constant &distinct is export(:SUPPORTED:all) = &uniq;

    our sub singleton(@values is copy) is export(:SUPPORTED:all) {
        my %once;
        my %duplicates;

        for @values.kv -> $index, $_ {
            my $key = .defined ?? .Str !! .^name;
            if %duplicates{$key} {
                @values[$index]:delete;
            }
            elsif %once{$key}:exists {
                @values[%once{$key}:delete]:delete;
                @values[$index]:delete;
                %duplicates{$key} = 1;
            }
            else {
                %once{$key} = $index
            }
        }

        (@values[]:v).List
    }

    our sub duplicates(@values) is export(:SUPPORTED:all) {
        my %seen;
        my @duplicates;

        @duplicates.push($_)
          if %seen{.defined ?? .Str !! .^name}++ == 1 for @values;
        @duplicates
    }

    our sub frequency(@values) is export(:SUPPORTED:all) {
        my %seen;
        %seen{.defined ?? .Str !! .^name}++ for @values;
        %seen.kv.List
    }

    our sub occurrences(@values) is export(:SUPPORTED:all) {
        my %seen;
        %seen{.defined ?? .Str !! .^name}++ for @values;

        my @occurrences;
        @occurrences[.value].push(.key) for %seen;
        @occurrences
    }

    our sub mode(@values, :$scalar) is export(:SUPPORTED:all) {
        my %seen;
        %seen{.defined ?? .Str !! .^name}++ for @values;

        my $max = %seen.values.max;
        if $scalar {
            $max
        }
        else {
            my @mode = %seen.map: .key if .value == $max;
            @mode.unshift($max)
        }
    }

    our sub after(&code, @values) is export(:SUPPORTED:all) {
        my $found = False;
        @values.toggle( { $found || code($_) && $found++ }, :off ).List
    }

    our sub after_incl(&code, @values) is export(:SUPPORTED:all) {
        @values.toggle( &code, :off ).List
    }

    our sub before(&code, @values) is export(:SUPPORTED:all) {
        @values.toggle( { !code($_) } ).List
    }

    our sub before_incl(&code, @values) is export(:SUPPORTED:all) {
        my $looking = True;
        @values.toggle( { $looking && !code($_) || $looking-- } ).List
    }

    our sub part(&code, @values) is export(:SUPPORTED:all) {
        my @part;
        for @values {
            my $index = code($_);
            @part[ $index < 0 ?? @part + $index !! $index].push($_)
        }
        @part
    }

    our sub samples(Int() $count, @values) is export(:SUPPORTED:all) {
        @values.pick($count).List
    }

    our sub natatime($n, @values) is export(:SUPPORTED:all) {
        @values.rotor($n, :partial).List
    }

    our sub firstval(&code, @values) is export(:SUPPORTED:all) {
        @values.first: &code
    }
    our constant &first_value is export(:SUPPORTED:all) = &firstval;

    our sub onlyval(&code, @values) is export(:SUPPORTED:all) {
        my $iterator := @values.grep(&code).iterator;
        my $onlyval := $iterator.pull-one;
        $onlyval =:= IterationEnd
          ?? Nil
          !! $iterator.pull-one =:= IterationEnd
            ?? $onlyval
            !! Nil
    }
    our constant &only_value is export(:SUPPORTED:all) = &onlyval;

    our sub lastval(&code, @values) is export(:SUPPORTED:all) {
        @values.first(&code, :end)
    }
    our constant &last_value is export(:SUPPORTED:all) = &lastval;

    our sub firstres(&code, @values) is export(:SUPPORTED:all) {
        my $firstres :=
          @values.map({ if code($_) -> \val { val } }).iterator.pull-one;
        $firstres =:= IterationEnd ?? Nil !! $firstres
    }
    our constant &first_result is export(:SUPPORTED:all) = &firstres;

    our sub onlyres(&code, @values) is export(:SUPPORTED:all) {
        my $iterator := @values.map({ if code($_) -> \val { val } }).iterator;
        my $onlyres := $iterator.pull-one;

        $onlyres =:= IterationEnd
          ?? Nil
          !! $iterator.pull-one =:= IterationEnd
            ?? $onlyres
            !! Nil
    }
    our constant &only_result is export(:SUPPORTED:all) = &onlyres;

    our sub lastres(&code, @values) is export(:SUPPORTED:all) {
        @values.map({ if code($_) -> \val { val } }).tail
    }
    our constant &last_result is export(:SUPPORTED:all) = &lastres;

    our sub indexes(&code, @values) is export(:SUPPORTED:all) {
        @values.grep( &code, :k ).List
    }

    our sub firstidx(&code, @values) is export(:SUPPORTED:all) {
        @values.first( &code, :k ) // -1
    }
    our constant &first_index is export(:SUPPORTED:all) = &firstidx;

    our sub onlyidx(&code, @values) is export(:SUPPORTED:all) {
        my $iterator := @values.grep( &code, :k ).iterator;
        my $onlyidx := $iterator.pull-one;
        $onlyidx =:= IterationEnd
          ?? -1
          !! $iterator.pull-one =:= IterationEnd
            ?? $onlyidx
            !! -1
    }
    our constant &only_index is export(:SUPPORTED:all) = &onlyidx;

    our sub lastidx(&code, @values) is export(:SUPPORTED:all) {
        @values.first( &code, :k, :end ) // -1
    }
    our constant &last_index is export(:SUPPORTED:all) = &lastidx;

    our sub sort_by(&code, @values) is export(:SUPPORTED:all) {
        @values.sort( { ~code($_) } ).List
    }

    our sub nsort_by(&code, @values) is export(:SUPPORTED:all) {
        @values.sort( { +code($_) } ).List
    }

    our sub qsort(&code, @values) is export(:SUPPORTED:all) {
        @values .= sort( &code ).List
    }

    our sub true(&code, @values) is export(:SUPPORTED:all) {
        my $true = 0;
        ++$true if code($_) for @values;
        $true
    }

    our sub false(&code, @values) is export(:SUPPORTED:all) {
        my $false = 0;
        ++$false unless code($_) for @values;
        $false
    }

    our sub each_array(**@arrays) is export(:SUPPORTED:all) {
        each_arrayref(@arrays)
    }

    our sub each_arrayref(@arrays) is export(:SUPPORTED:all) {
        my $elems = @arrays>>.elems.max;
        my $index = -1;

        {
            if $_ && $_ eq "index" {
                $index
            }
            elsif ++$index < $elems {
                @arrays.map( { $_[$index] } ).List
            }
            else {
                ()
            }
        }
    }

    our sub minmax(@values) is export(:SUPPORTED:all) {
        @values
          ?? ()
          !! (.min,.max) with @values.minmax
    }
    our constant &minmaxstr is export(:SUPPORTED:all) = &minmax;

    sub REDUCE($result is copy, &code, @values) {
        for @values.kv -> $_, $value {
            $result = code($result,$value)
        }
        $result;
    }
    our sub reduce_0(&code,@values) is export(:SUPPORTED:all) {
        REDUCE( 0, &code, @values )
    }
    our sub reduce_1(&code,@values) is export(:SUPPORTED:all) {
        REDUCE( 1, &code, @values )
    }
    our sub reduce_u(&code,@values) is export(:SUPPORTED:all) {
        REDUCE( (), &code, @values )
    }

    our sub bsearch(&code,@values,:$index) is export(:SUPPORTED:all) {
        my $elems = +@values;
        my $i = 0;
        my $j = $elems;

        until $i > $j {
            my $k = ($i + $j) div 2;
            return $index ?? -1 !! Nil if $k >= $elems;

            if code(@values[$k]) -> $rc {
                $rc < 0
                  ?? ($i = $k + 1)
                  !! ($j = $k - 1)
            }
            else {
                return $index ?? $k !! @values[$k]
            }
        }
        $index ?? -1 !! Nil
    }
    our sub bsearchidx(&code,@values) is export(:SUPPORTED:all) {
        bsearch(&code,@values,:index)
    }
    our constant &bsearch_index is export(:SUPPORTED:all) = &bsearchidx;

    our sub lower_bound(&code,@values) is export(:SUPPORTED:all) {
        my $count = +@values;
        my $lower = 0;

        while $count > 0 {
            my $step = $count +> 1;

            if code(@values[$lower + $step]) < 0 {
                $lower += $step + 1;
                $count -= $step + 1;
            }
            else {
                $count = $step;
            }
        }
        $lower
    }

    our sub upper_bound(&code,@values) is export(:SUPPORTED:all) {
        my $count = +@values;
        my $upper = 0;

        while $count > 0 {
            my $step = $count +> 1;

            if code(@values[$upper + $step]) <= 0 {
                $upper += $step + 1;
                $count -= $step + 1;
            }
            else {
                $count = $step;
            }
        }
        $upper
    }

    our sub equal_range(&code,@values) is export(:SUPPORTED:all) {
        ( lower_bound(&code,@values), upper_bound(&code,@values) )
    }

    our sub binsert(&code,\item,@values) is export(:SUPPORTED:all) {
        my $lb = lower_bound(&code,@values);
        @values.splice($lb, 0, item);
        $lb
    }
    our constant &bsearch_insert is export(:SUPPORTED:all) = &binsert;

    our sub bremove(&code,@values) is export(:SUPPORTED:all) {
        my $lb = lower_bound(&code,@values);
        @values.splice($lb, 1);
        $lb
    }
    our constant &bsearch_remove is export(:SUPPORTED:all) = &bremove;
}

sub EXPORT(*@args, *%_) {

    if @args {
        my $imports := Map.new( |(EXPORT::SUPPORTED::{ @args.map: '&' ~ * }:p) );
        if $imports != @args {
            die "List::MoreUtils doesn't know how to export: "
              ~ @args.grep( { !$imports{$_} } ).join(', ')
        }
        $imports
    }
    else {
        Map.new
    }
}

=begin pod

=head1 NAME

List::MoreUtils - Port of Perl 5's List::MoreUtils 0.428

=head1 SYNOPSIS

    # import specific functions
    use List::MoreUtils <any uniq>;
 
    if any { /foo/ }, uniq @has_duplicates {
        # do stuff
    }
 
    # import everything
    use List::MoreUtils ':all';

=head1 DESCRIPTION

List::MoreUtils provides some trivial but commonly needed functionality on
lists which is not going to go into C<List::Util>.

=head1 EXPORTS

Nothing by default. To import all of this module's symbols use the C<:all>
tag. Otherwise functions can be imported by name as usual:

    use List::MoreUtils :all;
 
    use List::MoreUtils <any firstidx>;

=head1 Porting Caveats

Perl 6 does not have the concept of C<scalar> and C<list> context.  Usually,
the effect of a scalar context can be achieved by prefixing C<+> to the
result, which would effectively return the number of elements in the result,
which usually is the same as the scalar context of Perl 5 of these functions.

Perl 6 does not have a magic C<$a> and C<$b>.  But they can be made to exist
by specifying the correct signature to blocks, specifically "-> $a, $b".
These have been used in all examples that needed them.  Just using the
signature auto-generating C<$^a> and C<$^b> would be more Perl 6 like.  But
since we want to keep the documentation as close to the original as possible,
it was decided to specifically specify the "-> $a, $b" signatures.

Many functions take a C<&code> parameter of a C<Block> to be called by the
function.  Many of these assume B<$_> will be set.  In Perl 6, this happens
automagically if you create a block without a definite or implicit signature:

  say { $_ == 4 }.signature;   # (;; $_? is raw)

which indicates the Block takes an optional parameter that will be aliased
as C<$_> inside the Block.

Perl 6 also doesn't have a single C<undef> value, but instead has
C<Type Objects>, which could be considered undef values, but with a type
annotation.  In this module, C<Nil> (a special value denoting the absence
of a value where there should have been one) is used instead of C<undef>.

Also note there are no special parsing rules with regards to blocks in Perl 6.
So a comma is B<always> required after having specified a block.

The following functions are actually built-ins in Perl 6.

  any all none minmax uniq zip

They mostly provide the same or similar semantics, but there may be subtle
differences, so it was decided to not just use the built-ins.  If these
functions are imported from this library in a scope, they will used instead
of the Perl 6 builtins.  The easiest way to use both the functions of this
library and the Perl 6 builtins in the same scope, is to use the method syntax
for the Perl 6 versions.

    my @a = 42,5,2,98792,88;
    {  # Note: imports in Perl 6 are always lexically scoped
        use List::Util <minmax>;
        say minmax @a;  # Ported Perl 5 version
        say @a.minmax;  # Perl 6 version
    }
    say minmax @a;  # Perl 6 version again

Many functions returns either C<True> or C<False>.  These are C<Bool>ean
objects in Perl 6, rather than just C<0> or C<1>.  However, if you use
a Boolean value in a numeric context, they are silently coerced to 0 and 1.
So you can still use them in numeric calculations as if they are 0 and 1.

=head1 FUNCTIONS

=head2 Junctions

=head3 I<Treatment of an empty list>

There are two schools of thought for how to evaluate a junction on an
empty list:

=item Reduction to an identity (boolean)

=item Result is undefined (three-valued)

In the first case, the result of the junction applied to the empty list is
determined by a mathematical reduction to an identity depending on whether
the underlying comparison is "or" or "and".  Conceptually:

                    "any are true"      "all are true"
                    --------------      --------------
    2 elements:     A || B || 0         A && B && 1
    1 element:      A || 0              A && 1
    0 elements:     0                   1

In the second case, three-value logic is desired, in which a junction
applied to an empty list returns C<Nil> rather than C<True> or C<False>.

Junctions with a C<_u> suffix implement three-valued logic.  Those
without are boolean.

=head3 all BLOCK, LIST

=head3 all_u BLOCK, LIST

Returns True if all items in LIST meet the criterion given through
BLOCK. Passes each element in LIST to the BLOCK in turn:

  print "All values are non-negative"
    if all { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, C<all> returns True (i.e. no values failed the condition)
and C<all_u> returns C<Nil>.

Thus, C<< all_u(@list) >> is equivalent to C<< @list ?? all(@list) !! Nil >>.

B<Note>: because Perl treats C<Nil> as false, you must check the return value
of C<all_u> with C<defined> or you will get the opposite result of what you
expect.

=head3 any BLOCK, LIST

=head3 any_u BLOCK, LIST

Returns True if any item in LIST meets the criterion given through
BLOCK. Passes each element in LIST to the BLOCK in turn:

  print "At least one non-negative value"
    if any { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, C<any> returns False and C<any_u> returns C<Nil>.

Thus, C<< any_u(@list) >> is equivalent to C<< @list ?? any(@list) !! undef >>.

=head3 none BLOCK, LIST

=head3 none_u BLOCK, LIST

Logically the negation of C<any>. Returns True if no item in LIST meets
the criterion given through BLOCK. Passes each element in LIST to the BLOCK
in turn:

  print "No non-negative values"
    if none { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, C<none> returns True (i.e. no values failed the condition)
and C<none_u> returns C<Nil>.

Thus, C<< none_u(@list) >> is equivalent to C<< @list ?? none(@list) !! Nil >>.

B<Note>: because Perl treats C<Nil> as false, you must check the return value
of C<none_u> with C<defined> or you will get the opposite result of what you
expect.

=head3 notall BLOCK, LIST

=head3 notall_u BLOCK, LIST

Logically the negation of C<all>. Returns True if not all items in LIST meet
the criterion given through BLOCK. Passes each element in LIST to the BLOCK
in turn:

  print "Not all values are non-negative"
    if notall { $_ >= 0 }, ($x, $y, $z);

For an empty LIST, C<notall> returns False and C<notall_u> returns C<Nil>.

Thus, C<< notall_u(@list) >> is equivalent to C<< @list ?? notall(@list) !! Nil >>.

=head3 one BLOCK LIST

=head3 one_u BLOCK LIST

Returns True if precisely one item in LIST meets the criterion given through
BLOCK. Passes each element in LIST to the BLOCK in turn:

    print "Precisely one value defined"
        if one { defined($_) }, @list;

Returns False otherwise.

For an empty LIST, C<one> returns False and C<one_u> returns C<Nil>.

The expression C<one BLOCK LIST> is almost equivalent to
C<1 == True BLOCK LIST>, except for short-cutting.  Evaluation of BLOCK will
immediately stop at the second true value seen.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod

# vim: ft=perl6 expandtab sw=4
