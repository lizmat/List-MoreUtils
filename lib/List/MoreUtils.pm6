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

  use List::MoreUtils;

=head1 DESCRIPTION

List::MoreUtils is ...

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: ft=perl6 expandtab sw=4
