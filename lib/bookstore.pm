package bookstore;
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use HTML::FillInForm;
use Data::Dumper;
use Validate;

our $VERSION = '0.1';

my %tmpl_params;
hook 'before' => sub {
   # Clear tmpl Params;
   %tmpl_params = {};
};

# ----- Generate URIs -----
hook 'before_template_render' => sub {
   my $tokens = shift;
       
   $tokens->{'search_books_uri'} = uri_for('/search/');
   $tokens->{'list_books_uri'} = uri_for('/books/');
   $tokens->{'add_book_uri'} = uri_for('/books/add/');
   $tokens->{'list_authors_uri'} = uri_for('/authors/');
   $tokens->{'add_author_uri'} = uri_for('/authors/add/');
   $tokens->{'dashboard'} = uri_for('/');
};

# ===== Home =====
get '/' => sub {
    template 'index';
};

# ==== Load Modules =====
load 'Books.pm', 'Authors.pm';

# ==== Search Function =====
get '/search/?' => sub {
    my $query = params->{query};
    my @results = ();
    if (length $query) {
        @results = _perform_search($query);
    }
    template 'search', { query => $query,
                         results => \@results,
                       };
};

sub _perform_search {
	my ($query) = @_;
	my @results;
	# search in authors
	my @authors = resultset('Author')->search({
		-or => [
			firstname => { like => "%$query%" },
			firstname => { like => "%$query%" },
		]
	});
  push @results, map {
		{ author=> join(' ', $_->firstname, $_->lastname),
			books => [],
		}
	} @authors;
	my %book_results;
	# search in books
	my @books = resultset('Book')->search({
		title => { like => "%$query%" },
	});
	foreach my $book (@books) {
		my $author_name = join(' ', $book->author->firstname, $book->author->lastname);
		push @{$book_results{$author_name}}, $book->title;
	}
	push @results, map {
		{	author => $_,
			books => $book_results{$_},
		}
	} keys %book_results;
	return @results;
}

true;
