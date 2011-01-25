#
# This file is part of List-DoubleLinked
#
# This software is copyright (c) 2011 by Leon Timmermans.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package List::DoubleLinked::Iterator;
BEGIN {
  $List::DoubleLinked::Iterator::VERSION = '0.003';
}

use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;
use Scalar::Util 'weaken';
use namespace::clean 0.20;

sub new {
	my ($class, $list, $node) = @_;
	my $self = bless [ $node, $list ], $class;
	weaken $self->[0];
	Internals::SvREADONLY(@{$self}, 1);
	return $self;
}

sub get {
	my $self = shift;
	return if not defined $self->[0];
	return $self->[0]{item};
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)

sub next {
	my $self = shift;
	my ($node, $list) = @{$self};
	croak 'Node no longer exists' if not defined $node;
	return __PACKAGE__->new($list, $node->{next});
}

sub previous {
	my $self = shift;
	my ($node, $list) = @{$self};
	croak 'Node no longer exists' if not defined $node;
	return __PACKAGE__->new($list, $node->{prev});
}

sub remove {
	my $self = shift;
	my ($node, $list) = @{$self};
	croak 'Node already removed' if not defined $node;

	my $item = $node->{item};
	weaken $node;
	$list->erase($node);

	return $item;
}

sub insert_before {
	my ($self, @items) = @_;
	my ($node, $list)  = @{$self};
	return $list->insert_before($self, @items);
}

sub insert_after {
	my ($self, @items) = @_;
	my ($node, $list)  = @{$self};
	return $list->insert_after($self, @items);
}

# ABSTRACT: Double Linked List Iterators

1;


__END__
=pod

=head1 NAME

List::DoubleLinked::Iterator - Double Linked List Iterators

=head1 VERSION

version 0.003

=head1 METHODS

=head2 get()

Get the value of the iterator

=head2 next()

Get the next iterator, this does not change the iterator itself.

=head2 previous()

Get the previous iterator, this does not change the iterator.

=head2 remove()

Remove the element from the list. This invalidates the iterator.

=head2 insert_before(@elements)

Insert @elements before the current iterator

=head2 insert_after

Insert @elements after the current iterator

=for Pod::Coverage new

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

