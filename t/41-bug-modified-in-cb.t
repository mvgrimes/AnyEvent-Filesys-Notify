use Test::More tests => 3;

use strict;
use warnings;
use File::Spec;
use lib 't/lib';
$|++;

use TestSupport qw(create_test_files delete_test_files move_test_files
  modify_attrs_on_test_files $dir received_events receive_event);

use AnyEvent::Filesys::Notify;

my $n = AnyEvent::Filesys::Notify->new(
    dirs => [$dir],
    cb   => sub {
        receive_event(@_);

        # This call back deletes any created files
        my $e = $_[0];
        unlink $e->path if $e->type eq 'created';
    },
);
isa_ok( $n, 'AnyEvent::Filesys::Notify' );

# Create a file, which will be delete in the callback
received_events( sub { create_test_files('foo') },
    'create a file', qw(created) );

# Did we get notified of the delete?
received_events( sub { }, 'deleted the file', qw(deleted) );
