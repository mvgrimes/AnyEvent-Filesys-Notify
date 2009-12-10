package AnyEvent::Filesys::Notify::Role::Linux;

use Moose::Role;
use AnyEvent;
use Linux::Inotify2;
use Carp;

sub _init {
    my $self = shift;

    my $inotify = Linux::Inotify2->new()
      or croak "Unable to create new Linux::Inotify2 object";

    # Need to add all the subdirs to the watch list, this will catch
    # modifications to files too.
    my $old_fs = $self->_old_fs;
    my @dirs = grep { $old_fs->{$_}->{is_dir} } keys %$old_fs;
    for my $dir (@dirs) {
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
            cb   => sub {
                $inotify->poll;
            } ) );

    return 1;
}

# Need to add newly created sub-dirs to the watch list.
# This is done after filtering. So entire dirs can be ignored efficiently;
around '_process_events' => sub {
    my ( $orig, $self, @e ) = @_;

    my $events = $self->$orig(@e);

    for my $event (@$events) {
        next unless $event->is_dir && $event->is_created;

        $self->_fs_monitor->watch(
            $event->path,
            &IN_MODIFY | &IN_CREATE | &IN_DELETE | &IN_DELETE_SELF |
              &IN_MOVE_SELF,
            sub { my $e = shift; $self->_process_events($e); } );

    }

    return $events;
};

1;
