use v6.*;

use List::MoreUtils <reduce_1>;
use Test;

plan 1;

{
    my @values = 2, 4, 6, 5, 3;
    my $product = reduce_1 -> $a, $b { $a * $b }, @values;
    is $product, 720, "the product";
}

# vim: expandtab shiftwidth=4
