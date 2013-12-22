package AnyEvent::Filesys::Notify::Role::FSEvents;

# ABSTRACT: Use Mac::FSEvents to watch for changed files

use Moo::Role;
use MooX::late;
use namespace::sweep;
use AnyEvent;
use Mac::FSEvents;
use Carp;

sub _init {
    my $self = shift;

    # Created a new Mac::FSEvents fs_monitor for each dir to watch
    # TODO: don't add sub-dirs of a watched dir
    my @fs_monitors =
      map { Mac::FSEvents->new( { path => $_, latency => $self->interval, } ) }
      @{ $self->dirs };

    # Create an AnyEvent->io watcher for each fs_monitor
    my @watchers;
    for my $fs_monitor (@fs_monitors) {

        my $w = AE::io $fs_monitor->watch, 0, sub {
            if ( my @events = $fs_monitor->read_events ) {
                $self->_process_events(@events);
            }
        };
        push @watchers, $w;

    }

    $self->_fs_monitor( \@fs_monitors );
    $self->_watcher( \@watchers );
    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::FSEvents - Use Mac::FSEvents to watch for changed files

=head1 VERSION

version 1.14

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
