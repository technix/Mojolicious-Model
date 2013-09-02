package SampleApp::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    
    my @users = $self->m('User')->list;
    
    $self->stash( users => \@users );
    $self->render();
}

1;
