use v6.*;

use List::MoreUtils <firstval first_value>;
use Test;

plan 3;

ok &firstval =:= &first_value, 'is firstval the same as first_value';

is firstval( { $_ > 5 }, (4 .. 9) ), 6, "right first result";
is firstval( { $_ > 5 }, (1 .. 4) ), Nil, 'did we get no result';

# vim: expandtab shiftwidth=4
