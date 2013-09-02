package SampleApp;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    my $config = $self->plugin( 'JSONConfig' => { file => 'config.json' } ); 

    $self->plugin('dbix' => $config->{'db'});
    $self->plugin('loadmodels' => { namespace => 'SampleApp::Model' });

    $r->route('/')->via('GET')->to('Main#index')->name('main');
}

1;
