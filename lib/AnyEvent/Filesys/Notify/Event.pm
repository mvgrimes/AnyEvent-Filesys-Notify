package AnyEvent::Filesys::Notify::Event;

# ABSTRACT: Object to report changes in the monitored filesystem

use Moose;

has path => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );
has is_dir => ( is => 'ro', isa => 'Bool', default => 0 );

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


__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Event - Object to report changes in the monitored filesystem

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use AnyEvent::Filesys::Notify;

    my $notifier = AnyEvent::Filesys::Notify->new(
        dir      => [ qw( this_dir that_dir ) ],
        interval => 2.0,    # Optional depending on underlying watcher
        cb       => sub {
            my (@events) = @_;

            for my $event (@events){
                process_created_file($event->path)  if $event->is_created;
                process_modified_file($event->path) if $event->is_modified;
                process_deleted_file($event->path)  if $event->is_deleted;
            }
        },
    );

=head1 DESCRIPTION

Simple object to encapsulate information about the filesystem modifications.

=head1 METHODS

=head2 path()

    my $modified_file = $event->path();

Returns the path to the modified file.  This is the path as given by the user,
ie not modified by abs_path.

=head2 type()

    my $modificaiton_type = $event->type();

Returns the type of change made to the file or directory. Will be one of
C<created>, C<modified>, or C<deleted>.

=head2 is_dir()

    my $is_dir  = $event->is_dir();

Returns a true value if the path is a directory.

=head2 is_created()

    do_something($event) if $event->is_created;

True if C<$event-E<gt>type eq 'created'>.

=head2 is_modified()

    do_something($event) if $event->is_modified;

True if C<$event-E<gt>type eq 'modified'>.

=head2 is_deleted()

    do_something($event) if $event->is_deleted;

True if C<$event-E<gt>type eq 'deleted'>.

=head1 SEE ALSO

L<AnyEvent::Filesys::Notify::Event>

=head1 BUGS

Please report any bugs or suggestions at L<http://rt.cpan.org/>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
