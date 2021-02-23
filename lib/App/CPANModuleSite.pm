package App::CPANModuleSite;

use MetaCPAN::Client;
use Template;
use Path::Iterator::Rule;
use Moose;

has distribution => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has metacpan => (
  is => 'ro',
  isa => 'MetaCPAN::Client',
  lazy_build => 1,
);

sub _build_metacpan {
  return MetaCPAN::Client->new;
}

has tt => (
  is => 'ro',
  isa => 'Template',
  lazy_build => 1,
);

sub _build_tt {
  my $self = shift;

  return Template->new($self->tt_config);
}

has tt_config => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

sub _build_tt_config {
  my $self = shift;

  my $release = $self->metacpan->release($self->distribution);
  my $distribution = $self->metacpan->distribution($self->distribution);
  my @modules = map { $self->metacpan->module($_) } @{ $release->provides };

  return {
    INCLUDE_PATH => $self->include_path,,
    OUTPUT_PATH => $self->output_path,,
    ( $self->wrapper ? ( WRAPPER => 'page.tt' ) : () ),
    RELATIVE => 1,
    VARIABLES => {
      distribution => $distribution,
      release => $release,
      modules => \@modules,
    },
  }
}

has site_src => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_site_src {
  return './site_src';
}

has include_path => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy_build => 1,
);

sub _build_include_path {
  my $self = shift;

  return [ $self->site_src, './tt_lib' ];
}

has output_path => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_output_path {
  return './docs';
}

has wrapper => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_wrapper {
  return 'page.tt';
}

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig( distribution => $_[0] );
  } else {
    return $class->$orig(@_);
  }
};

sub run {
  my $self = shift;

  my $finder = Path::Iterator::Rule->new->file;

  for ( $finder->all($self->site_src, { relative => 1 }) ) {
    if (/\.tt$/) {
      $self->process_template($_);
    } else {
      $self->copy_file($_);
    }
  }
}

sub process_template {
  my $self = shift;
  my ($template) = @_;

  my $output = $template =~ s/\.tt$//r;

  $self->tt->process($template, undef, $output)
    or die $self->tt->error;
}

1;
