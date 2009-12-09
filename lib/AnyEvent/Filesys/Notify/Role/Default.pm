package AnyEvent::Filesys::Notify::Role::Default;

use Moose::Role;
use AnyEvent;
use Carp;

sub _init {
    my $self = shift;

    $self->_watcher(
        AnyEvent->timer(
            after    => $self->interval,
            interval => $self->interval,
            cb       => sub {
                $self->_process_events();
            } ) ) or croak "Error creating timer: $@";

}

1;
