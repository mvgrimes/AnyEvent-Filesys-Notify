use Test::More tests => 10;

use strict;
use warnings;
use File::Spec;
use lib 't/lib';
$|++;

use TestSupport qw(create_test_files delete_test_files move_test_files
  modify_attrs_on_test_files $dir);

use AnyEvent::Filesys::Notify;
use AnyEvent::Impl::Perl;

create_test_files(qw(one/1));
create_test_files(qw(two/1));
## ls: one/1 two/1

my $cv;
my @expected = ();

my $n = AnyEvent::Filesys::Notify->new(
    dirs => [
        File::Spec->catfile( $dir, 'one' ), File::Spec->catfile( $dir, 'two' )
    ],
    interval => 0.5,
    filter   => sub { shift !~ qr/ignoreme/ },
    cb       => sub {
        is_deeply(
            [ map { $_->type } @_ ], \@expected,
            '... got events: ' . join ',', @expected
        );
        # diag "... @{[ join ',', map { $_->type } @_ ]} == @{[ join ',', @expected ]}";
        $cv->send;
    },
);
isa_ok( $n, 'AnyEvent::Filesys::Notify' );

{
local $TODO = "Tests fail on gnufreebsd for unknown reason, ignoring."
    if $^O =~ /gnuk?freebsd/i;

SKIP: {
    skip "not sure which os we are on", 1 unless $^O =~ /linux|darwin|freebsd/;
    ok( $n->does('AnyEvent::Filesys::Notify::Role::Inotify2'),
        '... with the linux role' )
      if $^O eq 'linux';
    ok( $n->does('AnyEvent::Filesys::Notify::Role::FSEvents'),
        '... with the mac role' )
      if $^O eq 'darwin';
    ok( $n->does('AnyEvent::Filesys::Notify::Role::KQueue'),
        '... with the freebsd role' )
      if $^O eq 'freebsd';
}

my $w =
  AnyEvent->timer( after => 15, cb => sub { die '... events timed out'; } );
diag "This might take a few seconds to run...";

@expected = qw(created created created);
create_test_files(qw(one/2 two/sub/2));
## ls: one/1 one/2 two/1 two/sub/2
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(modified);
create_test_files(qw(one/2));
## ls: one/1 one/2 two/1 two/sub/2
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted);
delete_test_files(qw(two/sub/2));
## ls: one/1 one/2 two/1 two/sub
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(created);
create_test_files(qw(one/ignoreme one/3));
## ls: one/1 one/2 one/ignoreme one/3 two/1 two/sub
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted created);
move_test_files( 'one/3' => 'one/5' );
## ls: one/1 one/2 one/ignoreme one/5 two/1 two/sub
$cv = AnyEvent->condvar;
$cv->recv;

SKIP: {
    skip "skip attr mods on Win32", 1 if $^O eq 'MSWin32';
    @expected = qw(modified modified);
    modify_attrs_on_test_files(qw(two/1 two/sub));
    ## ls: one/1 one/2 one/ignoreme one/5 two/1 two/sub
    $cv = AnyEvent->condvar;
    $cv->recv;
}

$n->filter(qr/onlyme/);
@expected = qw(created);
create_test_files(qw(one/onlyme one/4));
## ls: one/1 one/2 one/ignoreme one/onlyme one/4 one/5 two/1 two/sub
$cv = AnyEvent->condvar;
$cv->recv;

ok( 1, '... arrived' );
}
