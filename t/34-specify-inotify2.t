use Test::More;

use strict;
use warnings;
use File::Spec;
use lib 't/lib';
$|++;

use TestSupport qw(create_test_files delete_test_files move_test_files
  modify_attrs_on_test_files $dir);

use AnyEvent::Filesys::Notify;
use AnyEvent::Impl::Perl;

unless ( $^O eq 'linux' and eval { require Linux::Inotify2; 1; } ) {
    plan skip_all => 'Test only on Linux with Linux::Inotify2';
} else {
    plan tests => 13;
}

create_test_files(qw(one/1));
create_test_files(qw(two/1));
create_test_files(qw(one/sub/1));
create_test_files(qw(three));
## ls: one/1 one/sub/1 two/1 three

my $cv;
my @expected = ();

my $n = AnyEvent::Filesys::Notify->new(
    dirs => [
        File::Spec->catfile( $dir, 'one' ), File::Spec->catfile( $dir, 'two' ), File::Spec->catfile( $dir, 'three' ),
    ],
    filter => sub { shift !~ qr/ignoreme/ },
    cb     => sub {
        is_deeply(
            [ map { $_->type } @_ ], \@expected,
            '... got events: ' . join ',', @expected
        );
        $cv->send;
    },
    backend => 'Inotify2',
);

isa_ok( $n, 'AnyEvent::Filesys::Notify' );
ok( $n->does('AnyEvent::Filesys::Notify::Role::Inotify2'),
    '... with the Inotify2 role' );

my $w =
  AnyEvent->timer( after => 9, cb => sub { die '... events timed out'; } );
diag "This might take a few seconds to run...";

@expected = qw(modified);
create_test_files(qw(three));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted);
move_test_files( 'three' => 'three_1' );
$cv = AnyEvent->condvar;
$cv->recv;

# Do we get events from sub-dirs
@expected = qw(created);
create_test_files(qw(one/sub/2));
## ls: one/1 one/sub/1 +one/sub/2 two/1
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(created created created);
create_test_files(qw(one/2 two/sub/2));
## ls: one/1 +one/2 one/sub/1 one/sub/2 two/1 +two/sub/2 three_1
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(modified);
create_test_files(qw(one/2));
## ls: one/1 ~one/2 one/sub/1 one/sub/2 two/1 two/sub/2 trhee_1
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted);
delete_test_files(qw(two/sub/2));
## ls: one/1 one/2 one/sub/1 one/sub/2 two/1 two/sub -two/sub/2 three_1
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(created);
create_test_files(qw(one/ignoreme one/3));
## ls: one/1 one/2 +one/ignoreme +one/3 one/sub/1 one/sub/2 two/1 two/sub three_1
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted created);
move_test_files( 'one/3' => 'one/5' );
## ls: one/1 one/2 one/ignoreme -one/3 +one/5 one/sub/1 one/sub/2 two/1 two/sub three_1
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(modified modified);
modify_attrs_on_test_files(qw(two/1 two/sub));
## ls: one/1 one/2 one/ignoreme one/5 one/sub/1 one/sub/2 ~two/1 ~two/sub three_1
$cv = AnyEvent->condvar;
$cv->recv;

$n->filter(qr/onlyme/);
@expected = qw(created);
create_test_files(qw(one/onlyme one/4));
## ls: one/1 one/2 one/ignoreme +one/onlyme +one/4 one/5 one/sub/1 one/sub/2 two/1 two/sub three_1
$cv = AnyEvent->condvar;
$cv->recv;

ok( 1, '... arrived' );
