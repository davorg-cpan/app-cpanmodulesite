package App::CPANModuleSite;

use MetaCPAN::Client;
use Template;
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
    INCLUDE_PATH => [ './site_src', './tt_lib' ],
    OUTPUT_PATH => './docs',
    WRAPPER => 'page.tt',
    VARIABLES => {
      distribution => $distribution,
      release => $release,
      modules => \@modules,
    },
  }
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

  $self->tt->process('index.tt', undef, 'index.html')
    or die $self->tt->error;
}

1;
