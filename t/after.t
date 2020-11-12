use v6.*;

use List::MoreUtils <after>;
use Test;

plan 3;

my @x = after * %% 5, (1 .. 9);
is-deeply @x, [6, 7, 8, 9], "after 5";

@x = after { /foo/ }, <bar baz>;
is-deeply @x, [], 'Got the empty list';

@x = after *.starts-with("b"), <bar baz foo>;
is-deeply @x, [<baz foo>], "after /^b/";

# vim: expandtab shiftwidth=4
