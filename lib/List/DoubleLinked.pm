#
# This file is part of List-DoubleLinked
#
# This software is copyright (c) 2011 by Leon Timmermans.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package List::DoubleLinked;
BEGIN {
  $List::DoubleLinked::VERSION = '0.003';
}

use strict;
use warnings FATAL => 'all';

use Carp qw/carp/;
use Scalar::Util 'weaken';
use namespace::clean 0.20;
#no autovivication;

sub new {
	my ($class, @items) = @_;
	my $self = bless {
		head => undef,
		tail => undef,
		size => 0,
	}, $class;
	$self->push(@items);
	return $self;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms, ControlStructures::ProhibitCStyleForLoops)

sub push {
	my ($self, @items) = @_;
	for my $item (@items) {
		my $new_tail = {
			item => $item,
			prev => $self->{tail},
			next => undef,
		};
		$self->{tail}{next} = $new_tail if defined $self->{tail};
		$self->{tail}       = $new_tail;
		$self->{head}       = $new_tail if not defined $self->{head};
		$self->{size}++;
	}
	return;
}

sub pop {
	my $self = shift;
	my $ret  = $self->{tail};
	return if not defined $ret;
	$self->{tail} = $ret->{prev};
	$self->{tail}{next} = undef if defined $self->{tail};
	$self->{size}--;
	return $ret->{item};
}

sub unshift {
	my ($self, @items) = @_;
	for my $item (reverse @items) {
		my $new_head = {
			item => $item,
			prev => undef,
			next => $self->{head},
		};
		$self->{head}{prev} = $new_head if defined $self->{head};
		$self->{head}       = $new_head;
		$self->{tail}       = $new_head if not defined $self->{tail};
		$self->{size}++;
	}
	return;
}

sub shift {
	my $self = CORE::shift;
	my $ret  = $self->{head};
	return if not defined $ret;
	$self->{head} = $ret->{next};
	$self->{head}{prev} = undef if defined $self->{tail};
	$self->{size}--;
	return $ret->{item};
}

sub flatten {
	my $self = CORE::shift;
	my @ret;
	for (my $current = $self->{head} ; defined $current ; $current = $current->{next}) {
		CORE::push @ret, $current->{item};
	}
	return @ret;
}

sub front {
	my $self = CORE::shift;
	return defined $self->{head} ? $self->{head}{item} : undef;
}

sub back {
	my $self = CORE::shift;
	return defined $self->{tail} ? $self->{tail}{item} : undef;
}

sub empty {
	my $self = CORE::shift;
	return not $self->{size};
}

sub size {
	my $self = CORE::shift;
	return $self->{size};
}

sub insert_before {
	my ($self, $iter, @items) = @_;
	my $node = $iter->[0];
	for my $item (@items) {
		my $new_node = {
			item => $item,
			prev => $node->{prev},
			next => $node,
		};
		$node->{prev}{next} = $new_node if defined $node->{prev};
		$node->{prev} = $new_node;

		$self->{head} = $node->{next} if defined $self->{head} and $self->{head} == $node;
		$self->{size}++;
	}
	return;
}

sub insert_after {
	my ($self, $iter, @items) = @_;
	my $node = $iter->[0];
	for my $item (@items) {
		my $new_node = {
			item => $item,
			prev => $node,
			next => $node->{next},
		};
		$node->{next}{prev} = $new_node if defined $node->{next};
		$node->{next} = $new_node;

		$self->{tail} = $new_node if defined $self->{tail} and $self->{tail} == $node;
		$node = $new_node;
		$self->{size}++;
	}
	return;
}

sub erase {
	my ($self, $node) = @_;

	$node->{prev}{next} = $node->{next} if defined $node->{prev};
	$node->{next}{prev} = $node->{prev} if defined $node->{next};

	$self->{head} = $node->{next}     if defined $self->{head} and $self->{head} == $node;
	$self->{tail} = $node->{previous} if defined $self->{tail} and $self->{tail} == $node;

	$self->{size}--;
	weaken $node;
	carp 'Node may be leaking' if $node;

	return;
}

sub begin {
	my $self = CORE::shift;
	require List::DoubleLinked::Iterator;

	return List::DoubleLinked::Iterator->new($self, $self->{head});
}

sub end {
	my $self = CORE::shift;
	require List::DoubleLinked::Iterator;

	return List::DoubleLinked::Iterator->new($self->{tail});
}

sub DESTROY {
	my $self    = CORE::shift;
	my $current = $self->{head};
	while ($current) {
		delete $current->{prev};
		$current = delete $current->{next};
		$self->{size}--;
	}
	warn "Size of Linked List is $self->{size}, should be 0 after DESTROY" if $self->{size} != 0;
	return;
}

# ABSTRACT: Double Linked Lists for Perl

1;


__END__
=pod

=head1 NAME

List::DoubleLinked - Double Linked Lists for Perl

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use List::DoubleLinked;
 my $list = List::DoubleLinked->new(qw/foo bar baz/);
 $list->begin->insert_after(qw/quz/);
 $list->end->previous->erase;

=head1 DESCRIPTION

This module provides a double linked list for Perl. You should ordinarily use arrays instead of this, they are faster for almost any usage. However there is a small set of use-cases where linked lists are necessary. While you can use the list as an object directly, for most purposes it's recommended to use iterators. C<begin()> and C<end()> will give you iterators pointing at the start and end of the list.

=head1 METHODS

=head2 new(@elements)

Create a new double linked list. @elements is pushed to the list.

=head2 begin()

Return an L<iterator|List::Double::Linked::Iterator> to the first element of the list.

=head2 end()

Return an L<iterator|List::Double::Linked::Iterator> to the last element of the list.

=head2 flatten()

Return an array containing the same values as the list does. This runs in linear time.

=head2 push(@elements)

Add @elements to the end of the list.

=head2 pop()

Remove an element from the end of the list and return it

=head2 unshift(@elements)

Add @elements to the start of the list.

=head2 shift()

Remove an element from the end of the list and return it

=head2 front()

Return the first element in the list

=head2 back()

Return the last element in the list.

=head2 empty()

Returns true if the list has no elements in it, returns false otherwise.

=head2 size()

Return the length of the list. This runs in linear time.

=head2 erase($iterator)

Remove the element under $iterator.

=head2 insert_before($iterator, @elements)

Insert @elements before $iterator.

=head2 insert_after($iterator, @elements)

Insert @elements after $iterator.

=head1 WTF WHERE YOU THINKING?

This module is a bit an exercise in C programming. I was surprised that I was ever going to need this (and even more surprised no one ever uploaded something like this to CPAN before), but I do. B<I need a data structure that provided me with stable iterators>. I need to be able to splice off any arbitrary element without affecting any other arbitrary element. You can't really implement that using arrays, you need a double linked list for that.

This module is optimized for correctness, both algorithmically as memory wise. It is not optimized for speed. Linked lists in Perl are practically never faster than arrays anyways, so if you're looking at this because you think it will be faster think again. L<splice|perlfunc/"splice"> is your friend.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

