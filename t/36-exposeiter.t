use Test::More tests => 13;

# I copied this straight from test 35 and modified it. This tests that the added
# feature doesn't break existing behavior, and that the added feature
# actually does something - dave@jetcafe.org

use strict;
use warnings;
use File::Spec;
use lib 't/lib';
$|++;

use TestSupport qw(create_test_files delete_test_files move_test_files
  modify_attrs_on_test_files $dir received_events receive_event);

use AnyEvent::Filesys::Notify;
use AnyEvent::Impl::Perl;

create_test_files(qw(oneone/1 twotwo/1 oneone/sub/1));

# Why does this break on 5.14?
my $n = AnyEvent::Filesys::Notify->new(
    dirs   => [ map { File::Spec->catfile( $dir, $_ ) } qw(oneone twotwo) ],
    cb     => sub   { receive_event(@_) },
    modify_iter => sub { $_[0]->and(sub { $_ !~ /3/; }); },
);
isa_ok( $n, 'AnyEvent::Filesys::Notify' );

SKIP: {
    skip "not sure which os we are on", 1
      unless $^O =~ /linux|darwin|bsd/;
    ok( $n->does('AnyEvent::Filesys::Notify::Role::Inotify2'),
        '... with the linux role' )
      if $^O eq 'linux';
    ok( $n->does('AnyEvent::Filesys::Notify::Role::FSEvents'),
        '... with the mac role' )
      if $^O eq 'darwin';
    ok( $n->does('AnyEvent::Filesys::Notify::Role::KQueue'),
        '... with the bsd role' )
      if $^O =~ /bsd/;
}

diag "This might take a few seconds to run...";

# ls: oneone/1 +oneone/2 oneone/sub/1 twotwo/1
received_events( sub { create_test_files(qw(oneone/2)) },
    'create a file', qw(created) );

# ls: oneone/1 ~oneone/2 oneone/sub/1 twotwo/1
received_events( sub { create_test_files(qw(oneone/2)) },
    'modify a file', qw(modified) );

# ls: oneone/1 -oneone/2 oneone/sub/1 twotwo/1
received_events( sub { delete_test_files(qw(oneone/2)) },
    'delete a file', qw(deleted) );

# ls: oneone/1 oneone/sub/1 +oneone/sub/2 twotwo/1
received_events( sub { create_test_files(qw(oneone/sub/2)) },
    'create a file in subdir', qw(created) );

# ls: oneone/1 oneone/sub/1 ~oneone/sub/2 twotwo/1
received_events( sub { create_test_files(qw(oneone/sub/2)) },
    'modify a file in subdir', qw(modified) );

# ls: oneone/1 oneone/sub/1 -oneone/sub/2 twotwo/1
received_events( sub { delete_test_files(qw(oneone/sub/2)) },
    'delete a file in subdir', qw(deleted) );

# These shouldn't get any events
received_events( sub { create_test_files(qw(oneone/3)) },
    'create a non-tracked file', qw() );

received_events( sub { create_test_files(qw(oneone/sub/3)) },
    'create a non-tracked file in subdir', qw() );


SKIP: {
    skip "skip attr mods on Win32", 1 if $^O eq 'MSWin32';

    # ls: oneone/1 oneone/sub/1 ~twotwo/1
    received_events( sub { modify_attrs_on_test_files(qw(twotwo/1)) },
        'modify attributes', qw(modified) );

    # ls: oneone/1 ~oneone/sub/1 twotwo/1
    received_events( sub { modify_attrs_on_test_files(qw(oneone/sub/1)) },
        'modify attributes in a subdir', qw(modified) );
}

ok( 1, '... arrived' );

