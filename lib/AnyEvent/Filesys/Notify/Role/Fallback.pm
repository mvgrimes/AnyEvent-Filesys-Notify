package AnyEvent::Filesys::Notify::Role::Fallback;

# ABSTRACT: Fallback method of file watching (check in regular intervals)

use Moose::Role;
use namespace::autoclean;
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

    return 1;
}

1;
