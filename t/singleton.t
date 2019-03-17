use v6.c;
use Test;
use List::MoreUtils <singleton>;
%*ENV<RAKUDO_NO_DEPRECATIONS> = True;

plan 9;

{
    my @s = 1001 .. 1200;
    my @d = |(1 .. 1000) xx 2;
    my @a = |@d, |@s;
    my @u = singleton @a;
    is-deeply @u, @s, "1001 .. 1200 only occur once";
    is singleton( Scalar, @a), 200, 'we got 200 values occurring once';
    is singleton( @a, :scalar), 200, 'we got 200 values occurring once';
}

{
    my @s = "AA" .. "ZZ";
    my @d = |("aa" .. "zz") xx 2;
    my @a = |@d, |@s;
    my @u = singleton @a;
    is-deeply @u, @s, "AA .. ZZ only occur once";
    is singleton( Scalar, @a), 676, 'we got 676 values occurring once';
    is singleton( @a, :scalar), 676, 'we got 676 values occurring once';
}

{
    my @s  = |(1001 .. 1200), |("AA" .. "ZZ");
    my @d  = |(|(1 .. 1000), |("aa" .. "zz")) xx 2;
    my @a  = |@d, |@s;

    my @u  = singleton @a;
    is-deeply @u, @s, "1001 .. 1200, AA .. ZZ only occur once";
    is singleton( Scalar, @a), 200 + 676, 'we got 200 + 676 values occurring once';
    is singleton( @a, :scalar), 200 + 676, 'we got 200 + 676 values occurring once';
}

# vim: ft=perl6 expandtab sw=4
