# NAME

AnyEvent::Filesys::Notify - An AnyEvent compatible module to monitor files/directories for changes

# VERSION

version 1.10

# SYNOPSIS

    use AnyEvent::Filesys::Notify;

    my $notifier = AnyEvent::Filesys::Notify->new(
        dirs     => [ qw( this_dir that_dir ) ],
        interval => 2.0,             # Optional depending on underlying watcher
        filter   => sub { shift !~ /\.(swp|tmp)$/ },
        cb       => sub {
            my (@events) = @_;
            # ... process @events ...
        },
        parse_events => 1,  # Improves efficiency on certain platforms
    );

    # enter an event loop, see AnyEvent documentation
    Event::loop();

# DESCRIPTION

This module provides a cross platform interface to monitor files and
directories within an [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) event loop. The heavy lifting is done by
[Linux::INotify2](http://search.cpan.org/perldoc?Linux::INotify2) or [Mac::FSEvents](http://search.cpan.org/perldoc?Mac::FSEvents) on their respective O/S. A fallback
which scans the directories at regular intervals is include for other systems.
See ["IMPLEMENTATIONS"](#IMPLEMENTATIONS) for more on the backends.

Events are passed to the callback (specified as a CodeRef to `cb` in the
constructor) in the form of [AnyEvent::Filesys::Notify::Event](http://search.cpan.org/perldoc?AnyEvent::Filesys::Notify::Event)s.

# METHODS

## new()

A constructor for a new AnyEvent watcher that will monitor the files in the
given directories and execute a callback when a modification is detected. 
No action is take until a event loop is entered.

Arguments for new are:

- dirs 

        dirs => [ '/var/log', '/etc' ],

    An ArrayRef of directories to watch. Required.

- interval

        interval => 1.5,   # seconds

    Specifies the time in fractional seconds between file system checks for
    the [AnyEvent::Filesys::Notify::Role::Fallback](http://search.cpan.org/perldoc?AnyEvent::Filesys::Notify::Role::Fallback) implementation.

    Specifies the latency for [Mac::FSEvents](http://search.cpan.org/perldoc?Mac::FSEvents) for the
    `AnyEvent::Filesys::Notify::Role::FSEvents` implementation.

    Ignored for the `AnyEvent::Filesys::Notify::Role::Inotify2` implementation.

- filter

        filter => qr/\.(ya?ml|co?nf|jso?n)$/,
        filter => sub { shift !~ /\.(swp|tmp)$/,

    A CodeRef or Regexp which is used to filter wanted/unwanted events. If this
    is a Regexp, we attempt to match the absolute path name and filter out any
    that do not match. If a CodeRef, the absolute path name is passed as the
    only argument and the event is fired only if there sub returns a true value.

- cb

        cb  => sub { my @events = @_; ... },

    A CodeRef that is called when a modification to the monitored directory(ies) is
    detected. The callback is passed a list of
    [AnyEvent::Filesys::Notify::Event](http://search.cpan.org/perldoc?AnyEvent::Filesys::Notify::Event)s. Required.

- backend

        backend => 'Fallback',
        backend => 'FreeBSD',
        backend => '+My::Filesys::Notify::Role::Backend',

    Force the use of the specified backend. The backend is assumed to have the
    `AnyEvent::Filesys::Notify::Role` prefix, but you can force a fully qualified
    name by prefixing it with a plus. Optional.

- no\_external

        no_external => 1,

    This is retained for backward compatibility. Using `backend =` 'Fallback'>
    is preferred. Force the use of the ["Fallback"](#Fallback) watcher implementation. This is
    not encouraged as the ["Fallback"](#Fallback) implement is very inefficient, but it does
    not require either [Linux::INotify2](http://search.cpan.org/perldoc?Linux::INotify2) nor [Mac::FSEvents](http://search.cpan.org/perldoc?Mac::FSEvents). Optional.

- parse\_events

        parse_events => 1,

    In backends that support it (currently INotify2), parse the events instead of
    rescanning file system for changed `stat()` information. Note, that this might
    cause slight changes in behavior. In particular, the Inotify2 backend will
    generate an additional 'modified' event when a file changes (once when opened
    for write, and once when modified).

# WATCHER IMPLEMENTATIONS

## INotify2 (Linux)

Uses [Linux::INotify2](http://search.cpan.org/perldoc?Linux::INotify2) to monitor directories. Sets up an `AnyEvent->io`
watcher to monitor the `$inotify->fileno` filehandle.

## FSEvents (Mac)

Uses [Mac::FSEvents](http://search.cpan.org/perldoc?Mac::FSEvents) to monitor directories. Sets up an `AnyEvent->io`
watcher to monitor the `$fsevent->watch` filehandle.

## KQueue (FreeBSD/Mac)

Uses [IO::KQueue](http://search.cpan.org/perldoc?IO::KQueue) to monitor directories. Sets up an `AnyEvent->io`
watcher to monitor the `IO::KQueue` object.

__WARNING__ - [IO::KQueue](http://search.cpan.org/perldoc?IO::KQueue) and the `kqueue()` system call require an open
filehandle for every directory and file that is being watched. This makes
it impossible to watch large directory structures (and inefficient to watch
moderately sized directories). The use of the KQueue backend is discouraged.

## Fallback

A simple scan of the watched directories at regular intervals. Sets up an
`AnyEvent->timer` watcher which is executed every `interval` seconds
(or fractions thereof). `interval` can be specified in the constructor to
[AnyEvent::Filesys::Notify](http://search.cpan.org/perldoc?AnyEvent::Filesys::Notify) and defaults to 2.0 seconds.

This is a very inefficient implementation. Use one of the others if possible.

# Why Another Module For File System Notifications

At the time of writing there were several very nice modules that accomplish
the task of watching files or directories and providing notifications about
changes. Two of which offer a unified interface that work on any system:
[Filesys::Notify::Simple](http://search.cpan.org/perldoc?Filesys::Notify::Simple) and [File::ChangeNotify](http://search.cpan.org/perldoc?File::ChangeNotify).

[AnyEvent::Filesys::Notify](http://search.cpan.org/perldoc?AnyEvent::Filesys::Notify) exists because I need a way to simply tie the
functionality those modules provide into an event framework. Neither of the
existing modules seem to work with well with an event loop.
[Filesys::Notify::Simple](http://search.cpan.org/perldoc?Filesys::Notify::Simple) does not supply a non-blocking interface and
[File::ChangeNotify](http://search.cpan.org/perldoc?File::ChangeNotify) requires you to poll an method for new events. You could
fork off a process to run [Filesys::Notify::Simple](http://search.cpan.org/perldoc?Filesys::Notify::Simple) and use an event handler
to watch for notices from that child, or setup a timer to check
[File::ChangeNotify](http://search.cpan.org/perldoc?File::ChangeNotify) at regular intervals, but both of those approaches seem
inefficient or overly complex. Particularly, since the underlying watcher
implementations ([Mac::FSEvents](http://search.cpan.org/perldoc?Mac::FSEvents) and [Linux::INotify2](http://search.cpan.org/perldoc?Linux::INotify2)) provide a filehandle
that you can use and IO event to watch.

This is not slight against the authors of those modules. Both are well 
respected, are certainly finer coders than I am, and built modules which 
are perfect for many situations. If one of their modules will work for you
by all means use it, but if you are already using an event loop, this
module may fit the bill.

# SEE ALSO

Modules used to implement this module [AnyEvent](http://search.cpan.org/perldoc?AnyEvent), [Mac::FSEvents](http://search.cpan.org/perldoc?Mac::FSEvents),
[Linux::INotify2](http://search.cpan.org/perldoc?Linux::INotify2), [Moose](http://search.cpan.org/perldoc?Moose).

Alternatives to this module [Filesys::Notify::Simple](http://search.cpan.org/perldoc?Filesys::Notify::Simple), [File::ChangeNotify](http://search.cpan.org/perldoc?File::ChangeNotify).

# BUGS

Please report any bugs or suggestions at [http://rt.cpan.org/](http://rt.cpan.org/)

Forcing the `IO::KQueue` backend on a Mac does not seem to work.  The
`IO::KQueue` backend seems to be working fine on FreeBSD. I don't have the
experience or time to fix it on a Mac.  I would greatly appreciate any help
troubleshooting this.

# CONTRIBUTORS

Thanks to Gasol Wu <gasol.wu@gmail.com> who contributed the FreeBSD
support for IO::KQueue.

# AUTHOR

Mark Grimes, <mgrimes@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, <mgrimes@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
