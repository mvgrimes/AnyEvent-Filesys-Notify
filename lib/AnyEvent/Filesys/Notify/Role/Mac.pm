package AnyEvent::Filesys::Notify::Role::Mac;

use Moose::Role;
use AnyEvent;
use Mac::FSEvents;

sub _init {
    my $self = shift;

    $self->_fs(
        Mac::FSEvents->new( {
                path    => $self->dir,
                latency => 2.0,
            } ) );

    $self->_watcher(
        AnyEvent->io(
            fh   => $self->_fs->watch,
            poll => 'r',
            cb   => sub {
                $self->_process_events( $self->_fs->read_events() );
            } ) );

}

1;
