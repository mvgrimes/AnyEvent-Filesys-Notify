use Module::Build;
my $build = Module::Build->new(
    module_name   => 'AnyEvent::Filesys::Notify',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build'         => '0.4004',
    },

    requires => {
        'Moo'                          => 0,
        'MooX::late'                   => 0,
        'MooX::Types::MooseLike::Base' => 0,
        'AnyEvent'                     => 0,
        'Path::Iterator::Rule'         => 0,
        'Cwd'                          => 0,
        'Carp'                         => 0,
        'Try::Tiny'                    => 0,
        'namespace::sweep'             => 0,
        ( $^O eq 'linux'   ? ( 'Linux::Inotify2' => 0 ) : () ),
        ( $^O eq 'darwin'  ? ( 'Mac::FSEvents'   => 0 ) : () ),
        ( $^O eq 'freebsd' ? ( 'IO::KQueue'      => 0 ) : () ),
    },

    test_requires => {
        'Test::More'            => 0.87,
        'Test::Exception'       => 0,
        'Test::Without::Module' => 0,
        'File::Find'            => 0,
        'File::Spec'            => 0,
        'File::Basename'        => 0,
        'File::Temp'            => 0,
        'File::Path'            => 0,
        'autodie'               => 0,
        'Exporter'              => 0,
    },

    meta_merge => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-Filesys-Notify',
            repository => 'http://github.com/mvgrimes/AnyEvent-Filesys-Notify'
        }
    },
);

$build->create_build_script;
