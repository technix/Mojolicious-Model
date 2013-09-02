package Mojolicious::Plugin::Loadmodels;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
BEGIN {
    $Mojolicious::Plugin::Loadmodels::VERSION = '0.1';
}

our %mojo_models;

sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};

    die __PACKAGE__, ": missing 'namespace' in parameters\n"
        unless $args->{namespace};

    my $model_helper = $args->{'helper'} || 'm';
    
    my $namespace  = $args->{'namespace'};
    my $packages = Mojo::Loader->search($namespace);

    # load and init packages
    foreach my $pkg (@{$packages}) {
        Mojo::Loader->load($pkg);
        $pkg =~ /^${namespace}::(.+?)$/ and my $model = $1;
        eval "\$dbix_models{$model} = $pkg->new( \$app )";
    }
    
    # create default model helper
    $app->helper($model_helper => sub {
        my $m = shift;
        if (exists $mojo_models{$m}) {
            return $mojo_models{$m};
        } else {
            $app->log->error("Model $m not found!");
        }
        return;
    });

    # create named model helpers
    if ($args->{'use_names'}) {
        foreach my $model (keys %mojo_models) {
            (my $model_name = $model) =~ s/::/_/g;            
            $app->helper($model_name => sub { $mojo_models{$model} });
        }
    }

    return 1;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Loadmodels - Load Mojolicious models as helpers

=head1 DESCRIPTION
 
L<Mojolicious::Plugin::Loadmodels> is a plugin to load Mojolicious models and create helpers
to operate them. By default it creates helper L<m>, which can be used for model method calls.
Named helpers can be created too.
 
=head1 VERSION
 
version 0.01
 
=head1 SYNOPSIS

  sub startup {
    my $self = shift;
    
    $self->plugin('loadmodels', {
        namespace => 'Example::Model',
        use_names => 0,
    });
    
  }

  # in your controllers
  $app->m('User')->get( { id => 1 } );
    
  # if use_names is set to true
  $app->User->get( { id => 1 } );


=head1 ATTRIBUTES

=head2 C<namespace> 

Default namespace for models. Loadmodels plugin will load all modules within defined namespace.

=head2 C<helper>

If set, changes name of default helper.

=head2 C<use_names>
 
If set to true, named helpers will be created in addition to default helper.
Helpers are named in the same way as modules. Colons will be replaced to underscores
(i.e. Some::Thing will be available as $app->Some_Thing).

=head1 SEE ALSO
  
L<Mojolicious>  

=head1 TODO

Add new features.

=head1 AUTHOR
 
Sergei Mozhaisky, C<< <sergei.mozhaisky at gmail.com> >>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2011 Sergei Mozhaisky, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
