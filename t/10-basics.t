#! perl
#
# This file is part of List-DoubleLinked
#
# This software is copyright (c) 2011 by Leon Timmermans.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;
use Test::Differences;
use Scalar::Util qw/weaken/;

use List::DoubleLinked;

my $list = List::DoubleLinked->new;

ok $list->empty, 'List is empty';

eq_or_diff([$list->flatten], [], 'Flattens to empty array');

is $list->size, 0, 'Size is zero';

$list->push(qw/foo bar baz/);

ok !$list->empty, 'List is no longer empty';

is $list->size, 3, 'Size is three';

is $list->front, 'foo', 'Front is "foo"';

eq_or_diff([$list->flatten], [qw/foo bar baz/], 'List has three members: foo bar baz');

is $list->pop, 'baz', 'Popped off "baz"';

eq_or_diff([$list->flatten], [qw/foo bar/], 'List is now: foo bar');

$list->unshift('quz');

eq_or_diff([ $list->flatten ], [ qw/quz foo bar/ ], 'List is now: quz foo bar');

{
	my $iter = $list->begin;

	is $iter->get, 'quz', 'Begin is "quz"';

	$iter = $iter->next;

	is $iter->get, 'foo', 'Next is "foo"';

	$iter->insert_before(qw/FOO BAR/);

	is $iter->get, 'foo', 'Iterator is still valid after insertion';

	eq_or_diff([ $list->flatten ], [ qw/quz FOO BAR foo bar/ ], 'Inserted: FOO BAR');

	is $iter->previous->remove(), 'BAR', 'Removed "BAR"';

	eq_or_diff([ $list->flatten ], [ qw/quz FOO foo bar/ ], '"BAR" is really gone');

	$iter->insert_after(qw/BUZ QUZ/);

	eq_or_diff([ $list->flatten ], [ qw/quz FOO foo BUZ QUZ bar/ ], 'Inserted BUZ QUZ after foo');

	is $list->back, 'bar', 'back is "bar"';

}

my $ref = [];
$list->push($ref);
weaken $ref;
undef $list;
ok !defined $ref, '$ref should no longer be defined';

