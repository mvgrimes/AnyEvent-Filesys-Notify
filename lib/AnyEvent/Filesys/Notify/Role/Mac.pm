package AnyEvent::Filesys::Notify::Role::Mac;

use Moose::Role;
use AnyEvent;
use Mac::FSEvents;
use Carp;

sub _init {
    my $self = shift;

    $self->_fs_monitor(
        Mac::FSEvents->new( {
                path    => $self->dir,
                latency => $self->interval,
            } ) );

    $self->_watcher(
        AnyEvent->io(
            fh   => $self->_fs_monitor->watch,
            poll => 'r',
            cb   => sub {
                $self->_process_events( $self->_fs_monitor->read_events() );
            } ) );

    return 1;
}

1;
