package AnyEvent::Filesys::Notify::Role::Linux;

use Moose::Role;
use AnyEvent;
use Linux::Inotify2;
use Carp;

sub _init {
    my $self = shift;

    my $inotify = Linux::Inotify2->new()
      or croak "Unable to create new Linux::Inotify2 object";

    for my $dir ( @{ $self->dirs } ) {
        $inotify->watch(
            $dir,
            &IN_MODIFY | &IN_CREATE | &IN_DELETE | &IN_DELETE_SELF |
              &IN_MOVE_SELF,
            sub { my $e = shift; $self->_process_events($e); } );
    }

    $self->_fs_monitor($inotify);

    $self->_watcher(
        AnyEvent->io(
            fh   => $inotify->fileno,
            poll => 'r',
            cb   => sub { $inotify->poll } ) );

    return 1;
}

1;
