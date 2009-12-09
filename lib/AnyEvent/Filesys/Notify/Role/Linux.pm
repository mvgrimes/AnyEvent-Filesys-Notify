package AnyEvent::Filesys::Notify::Role::Linux;

use Moose::Role;
use AnyEvent;
use Linux::Inotify2;

sub _init {
    my $self = shift;

    my $inotify = Linux::Inotify2->new()
      or croak "Unable to create new Linux::Inotify2 object";

    $inotify->watch(
        $self->dir,
        &IN_MODIFY | &IN_CREATE | &IN_DELETE | &IN_DELETE_SELF | &IN_MOVE_SELF,
        sub { my $e = shift; $self->_process_events($e); } );

    $self->_fs($inotify);
    $self->_watcher(
        AnyEvent->io(
            fh   => $inotify->fileno,
            poll => 'r',
            cb   => sub { $inotify->poll } ) );

}

1;
