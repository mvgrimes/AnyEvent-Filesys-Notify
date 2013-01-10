package AnyEvent::Filesys::Notify::Role::FSEvents;

# ABSTRACT: Use Mac::FSEvents to watch for changed files

use Moose::Role;
use namespace::autoclean;
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
    $self->_fs_monitor( \@fs_monitors );

    # Create an AnyEvent->io watcher for each fs_monitor
    # Done in a block so we can scope and preserve the $fs_monitor
    my @watchers =
      map {                     ## no critic (ProhibitComplexMappings)
        my $fs_monitor = $_;    # needed to scope $fs_monitor
        AnyEvent->io(
            fh   => $fs_monitor->watch,
            poll => 'r',
            cb   => sub {
                $self->_process_events( $fs_monitor->read_events() );
            } )
      } @fs_monitors;

    $self->_watcher( \@watchers );
    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::FSEvents - Use Mac::FSEvents to watch for changed files

=head1 VERSION

version 0.18

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
