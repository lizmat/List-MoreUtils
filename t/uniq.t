use v6.c;
use Test;
use List::MoreUtils <uniq distinct>;
%*ENV<RAKUDO_NO_DEPRECATIONS> = True;

plan 10;

ok &uniq =:= &distinct, 'is uniq the same as distinct';

{
    my @a = |(1 .. 10) xx 2;
    my @u = uniq @a;
    is-deeply @u, [1..10], "1..10 are the uniq values in order";
    is uniq( Scalar, @a), 10, 'we got 10 unique values';
    is uniq( @a, :scalar), 10, 'we got 10 unique values';
}

{
    my @a = |("aa" .. "zz") xx 2;
    my @u = uniq @a;
    is-deeply @u, ["aa" .. "zz"], "aa .. zz are unique";
    is uniq( Scalar, @a), 676, 'we got 676 unique values';
    is uniq( @a, :scalar), 676, 'we got 676 unique values';
}

{
    my @a  = |(|(1 .. 10), |("aa" .. "zz")) xx 2;
    my @u  = uniq @a;
    is-deeply @u, [|(1..10), |("aa".."zz")], "1 .. 10, aa .. zz are unique";
    is uniq( Scalar, @a), 10 + 676, 'we got 10 + 676 values occurring once';
    is uniq( @a, :scalar), 10 + 676, 'we got 10 + 676 values occurring once';
}

# vim: ft=perl6 expandtab sw=4
