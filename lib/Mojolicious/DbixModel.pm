package Mojolicious::DbixModel;
use strict;
use warnings;
use SQL::Interp;

# Base class for Dbix simplified models. Provides $self->db handler for database queries
# and basic database operation methods.

sub new {
    my ($class, $app) = @_;
    my $self = {
        app => $app
    };
    return bless $self, $class;
}

sub db {
    my $self = shift;
    return $self->{'app'}->dbix;
}

# basic operations

sub count {
    my ($self, $condition) = @_;
    my $count;
    if ($condition) {
        $count = $self->db->iquery( 'SELECT COUNT(id) FROM', $self->table, 'WHERE', $condition )->array->[0];
    }
    else {
        $count = $self->db->iquery( 'SELECT COUNT(id) FROM', $self->table )->array->[0];
    }
    return $count;
}

sub records {
    my ($self) = @_;
    my @records = $self->db->iquery( 'SELECT * FROM', $self->table )->hashes;
    return @records;
}

sub insert {
    my ($self, $data_hashref) = @_;
    my $result = $self->db->iquery( 'INSERT INTO', $self->table, $data_hashref );
    return $result;
}

sub get {
    my ($self, $where, $fields_arrayref) = @_;
    my $item;
    if ($fields_arrayref) {
        my $fields_list = join(',', @{$fields_arrayref});
        $item = $self->db->iquery( "SELECT $fields_list FROM", $self->table, 'WHERE', $where, ' LIMIT 1' )->hash;
    }
    else {
        $item = $self->db->iquery( 'SELECT * FROM', $self->table, 'WHERE', $where, ' LIMIT 1' )->hash;
    }
    return $item;
}

sub select {
    my ($self, $where, $fields_arrayref) = @_;
    my @list;
    if ($fields_arrayref) {
        my $fields_list = join(',', @{$fields_arrayref});
        @list = $self->db->iquery( "SELECT $fields_list FROM", $self->table, 'WHERE', $where )->hashes;
    }
    else {
        @list = $self->db->iquery( 'SELECT * FROM', $self->table, 'WHERE', $where )->hashes;
    }
    return @list;
}

sub update {
    my ($self, $where, $data_hashref) = @_;
    my $result = $self->db->iquery( 'UPDATE', $self->table, 'SET', $data_hashref, 'WHERE', $where );
    return $result;
}

sub delete {
    my ($self, $where) = @_;
    my $result = $self->db->iquery( 'DELETE FROM', $self->table, 'WHERE', $where );
    return $result;
}

1;

__END__

=head1 NAME

Mojolicious::DbixModel - base class for Mojolicious models

=head1 DESCRIPTION
 
L<Mojolicious::DbixModel> is a base class for Mojolicious models.

This is just an example. Feel free to write your own implementation of this base class, depending on your needs.
 
=head1 SYNOPSIS

  package Example::Model::User;
  use lib "../..";
  use strict;
  use base 'Mojolicious::DbixModel';

  # Required - base class operates with this value
  # Put table name here
  sub table { "users" }

  # you can define your own methods in addition to default ones
  sub list {
    my $self = shift;
    my @users = $self->db->iquery('SELECT * FROM', $self->table, 'WHERE 1')->hashes;
    return \@users;
  }

  1;

=head1 SEE ALSO
  
L<Mojolicious>  

=head1 AUTHOR
 
Sergei Mozhaisky, C<< <sergei.mozhaisky at gmail.com> >>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2011 Sergei Mozhaisky, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
