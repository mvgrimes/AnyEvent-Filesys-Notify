package AnyEvent::Filesys::Notify::Event;

use Moose;

has path => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );

sub is_created {
    return shift->type eq 'created';
}
sub is_modified {
    return shift->type eq 'modified';
}
sub is_deleted {
    return shift->type eq 'deleted';
}

1;
