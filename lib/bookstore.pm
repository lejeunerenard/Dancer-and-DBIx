package bookstore;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/search' => sub {
    my $query = params->{query};
    my @results = ();
    if (length $query) {
        @results = _perform_search($query);
    }
    template 'search', { query => $query,
                         results => \@results,
                       };
};

true;
