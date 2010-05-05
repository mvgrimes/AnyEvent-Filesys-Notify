use Test::More tests => 2;

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Filesys::Notify;

my $notify = AnyEvent::Filesys::Notify->new(
    dirs   => ['samples'],
    filter => sub { 1 },
    cb     => sub { die '... should not exec cb'; },
);
undef $notify;

is( $notify, undef, 'Undefined the AnyEvent::Filesys::Notify obj' );

$SIG{ALRM} = sub { 
    ok( 0, '... the alarm went off, looks like there is a cycle' );
    exit;
};

alarm 3;
AnyEvent->condvar->recv;
alarm 0;

ok( 1, '... we did not block' );

