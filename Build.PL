use Module::Build;
my $build = Module::Build->new(
    module_name   => 'AnyEvent::Filesys::Notify',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'Moo'                          => '1.003001',
        'MooX::late'                   => '0.014',
        'MooX::Types::MooseLike::Base' => '0.25',
        'AnyEvent'                     => '7.05',
        'Path::Iterator::Rule'         => '1.005',
        'Cwd'                          => '3.40',
        'Carp'                         => '1.20',
        'Try::Tiny'                    => '0.18',
        'namespace::sweep'             => '0.006',
        ( $^O eq 'linux'  ? ( 'Linux::Inotify2' => '1.22' ) : () ),
        ( $^O eq 'darwin' ? ( 'Mac::FSEvents'   => '0.10' ) : () ),
        ( $^O =~ /bsd/    ? ( 'IO::KQueue'      => '0.34' ) : () ),
    },

    build_requires => {
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
        'Data::Dump'            => 0,
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
