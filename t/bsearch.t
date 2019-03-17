use v6.c;
use Test;
use List::MoreUtils <bsearch>;
%*ENV<RAKUDO_NO_DEPRECATIONS> = True;

plan 3066;

my @list = my @in = 1 .. 1000;
for @in -> $elem {
    is bsearch( Scalar, { $_ - $elem }, @list), True,
      "did we find $elem scalarly";
    is bsearch( { $_ - $elem }, @list, :scalar), True,
      "did we find $elem scalarly";
}

for @in -> $elem {
    is-deeply bsearch( { $_ - $elem }, @list ), [$elem],
      "did we find $elem listly";
}

my @out = |(-10 .. 0), |(1001 .. 1011);
for @out -> $elem {
    is bsearch( Scalar, { $_ - $elem }, @list), False,
      "did we fail to find $elem scalarly";
    is bsearch( { $_ - $elem }, @list, :scalar), False,
      "did we fail to find $elem scalarly";
}

for @out -> $elem {
    is-deeply bsearch( { $_ - $elem }, @list), [],
      "did we fail to find $elem listly";
}

# vim: ft=perl6 expandtab sw=4
