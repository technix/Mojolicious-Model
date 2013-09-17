package SampleApp::Model::User;
use lib "../..";
use parent 'Mojolicious::DbixModel';
use strict;

sub table {
    "users";
}

sub list {
    my ($self) = @_;
    my @users = $self->db->iquery('SELECT * FROM users WHERE 1 ORDER BY id')->hashes;
    return @users;
}

1;
