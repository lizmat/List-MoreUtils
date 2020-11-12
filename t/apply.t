use v6.*;
use Test;
use List::MoreUtils <apply>;
%*ENV<RAKUDO_NO_DEPRECATIONS> = True;

plan 6;

my @list = 0 .. 9;
my @list1 = apply { $_++ }, @list;
is-deeply @list,  [0 .. 9],  "original numbers untouched";
is-deeply @list1, [1 .. 10], "returned numbers increased";

@list = (" foo ", " bar ", "     ", "foobar");
@list1 = apply { s:g/^ \s+ | \s+ $// }, @list;
is-deeply @list,  [" foo ", " bar ", "     ", "foobar"],
  "original strings untouched";
is-deeply @list1, ["foo",   "bar",   "",      "foobar"],
  "returned strings stripped";

my $ITEM = apply Scalar, { s:g/^ \s+ | \s+ $// }, @list;
is $ITEM, "foobar", ":scalar returns last item";
my $item = apply { s:g/^ \s+ | \s+ $// }, @list, :scalar;
is $item, "foobar", ":scalar returns last item";

# vim: expandtab shiftwidth=4
