package Mojolicious::Plugin::Dbix;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use DBIx::Simple;
BEGIN {
    $Mojolicious::Plugin::Dbix::VERSION = '0.01';
}

sub register
{
    my ($plugin, $app, $args) = @_;
    $args ||= {};
    my $ext_dbix = $args->{dbix} if $args->{dbix};

    $app->log->debug("register Mojolicious::Plugin::Dbix dsn: $args->{dsn}");
    unless (ref($app)->can('_dbix'))
    {
        ref($app)->attr('_dbix');
        ref($app)->attr('_dbix_requests_counter' => 0);
    }

    my $max_requests_per_connection = $args->{requests_per_connection} || 100;
    $app->plugins->on(
        before_dispatch => sub {
            my $self = shift;
            my $dbix;
            if ($args->{dbix})
            {
                # external dbix
                $dbix = $args->{dbix};
            }
            elsif (    $self->app->_dbix
                   and $self->app->_dbix_requests_counter < $max_requests_per_connection
                   and $plugin->_check_connected($self->app->_dbix))
            {
                $dbix = $self->app->_dbix;
                $self->app->log->debug("use cached DB connection, requests served: " . $self->app->_dbix_requests_counter);
                $self->app->_dbix_requests_counter($self->app->_dbix_requests_counter + 1);
            }
            else
            {
                # make new connection
                $self->app->log->debug("start new DB connection to DB $args->{dsn}");
                $dbix = DBIx::Simple->connect(
                    $args->{dsn},
                    $args->{username} || '',
                    $args->{password} || '',
                    $args->{dbi_attr} || {}
                );
                unless ($dbix)
                {
                    my $err_msg = "DB connect error. dsn=$args->{dsn}, error: " . $dbix->error;
                    $self->app->log->error($err_msg);
                    
                    # Render exception template
                    $self->render(
                                  status    => 500,
                                  format    => 'html',
                                  template  => 'exception',
                                  exception => $err_msg
                                  );
                    $self->stash(rendered => 1);
                    return;
                }

                if ($args->{'on_connect_do'})
                {
                    if (    ref($args->{'on_connect_do'})
                        and ref($args->{'on_connect_do'}) ne 'ARRAY')
                    {
                        $self->app->log->error('DB connect error on_connect_do param is not arrayref or scalar');
                    }
                    else
                    {
                        eval
                        {
                            if (!ref($args->{'on_connect_do'}))
                            {
                                $dbix->query($args->{'on_connect_do'}) or die $dbix->error;
                            }
                            else
                            {
                                foreach my $do_cmd (@{$args->{'on_connect_do'}})
                                {
                                    $dbix->query($do_cmd) or die $dbix->error;
                                }
                                1;
                            }
                        }
                        or do
                        {
                            my $err_msg = "DB on_connect_do error $@";
                            $self->app->log->error($err_msg);
                            $self->render(
                                          status    => 500,
                                          format    => 'html',
                                          template  => 'exception',
                                          exception => $err_msg
                                          );
                            $self->stash(rendered => 1);
                            return;
                        };
                    }
                }
                
                $self->app->_dbix($dbix);
                $self->app->_dbix_requests_counter(1);
                $self->app->helper(dbix => sub { return shift->app->_dbix; } );
            }
        }
    );

    unless ($args->{no_disconnect})
    {
        $app->plugins->on(
            after_dispatch => sub {
                my $self = shift;
                $self->app->_dbix(0);
                $self->app->_dbix_requests_counter(0);
                if ($self->dbix())
                {
                    $self->dbix->disconnect
                        or $self->app->log->error("Disconnect error " . $self->dbix->error);
                }
                $self->app->log->debug("disconnect from DB $args->{dsn}");
            }
        );
    }
}


sub _check_connected
{
    my $self = shift;
    my $dbix  = shift;
    return unless $dbix;
    return $dbix->dbh->ping();
}
1;
__END__

=head1 NAME

Mojolicious::Plugin::Dbix - DBIx::Simple plugin for Mojolicious

=head1 DESCRIPTION
 
L<Mojolicious::Plugin::Dbix> is a DBIx::Simple plugin for L<Mojolicious>.
It connects to a database and creates L<DBIx::Simple> database handle object with provided parameters.
The L<DBIx::Simple> database handle object accessible via 'dbix' handle.
 
=head1 VERSION
 
version 0.01
 
=head1 SYNOPSIS

  sub startup {
    my $self = shift;

    $self->plugin('dbix', {
              'dsn' => 'dbi:SQLite:dbname=data/sqlite.db',
              'username' => 'test_username',
              'password' => 'TestPassword',
              'no_disconnect' => 1,
              'dbi_attr' => { 'AutoCommit' => 1, 'RaiseError' => 1, 'PrintError' =>1 },
              'on_connect_do' =>[ 'SET NAMES UTF8'],
              'requests_per_connection' => 200
    });
  }

    #in your model class
    # see DBIx::Simple documentation for methods description
    my @result = $self->dbix->query('select * from table')->hashes;

=head1 ATTRIBUTES

=head2 C<dsn> 

The dsn value must begin with "dbi:driver_name:". The driver_name specifies the driver that will be used to make the connection. (Letter case is significant.)
See L<DBI/connect> $data_source description.

=head2 C<username>
 
Database user.

=head2 C<password>

Password for database user.

=head2 C<no_disconnect>

Do not disconnect from database after dispatching. Default is false.

=head2 C<dbi_attr>

See L<DBI/connect> and L<DBI/ATTRIBUTES COMMON TO ALL HANDLES> for more details.

=head2 C<on_connect_do>

Specifies things to do immediately after connecting or re-connecting to the database. Its value may contain:

=over

=item

C<a scalar> This contains one SQL statement to execute.

=item 

C<an array reference> This contains SQL statements to execute in order. Each element contains a string or a code reference that returns a string. 	

=back
   
=head2 C<requests_per_connection>

How much requests served cached persistent connection before reconnect. Default 100.

=head1 SEE ALSO
 
L<DBI> 
 
L<DBIx::Simple>

L<SQL::Abstract>

L<SQL::Interp>
 
L<Mojolicious>  

=head2 TODO

Tests  

=head1 AUTHOR
 
Sergei Mozhaisky, C<< <sergei.mozhaisky at gmail.com> >>

Code based on Mojolicious::Plugin::Dbi by Konstantin Kapitanov, C<< <perlovik at gmail.com> >> 
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2011 Sergei Mozhaisky, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
