package AnyEvent::Filesys::Notify::Role::Fallback;

use Moose::Role;
use namespace::autoclean;
use AnyEvent;
use Carp;
use Scalar::Util qw(weaken);

sub _init {
    my $self = shift;

    my $weak_self = $self;
    weaken $weak_self;
    $self->_watcher(
        AnyEvent->timer(
            after    => $self->interval,
            interval => $self->interval,
            cb       => sub {
                $weak_self->_process_events();
            } ) ) or croak "Error creating timer: $@";

    return 1;
}

1;
