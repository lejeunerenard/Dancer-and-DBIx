package bookstore;
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/books/?' => sub {
	debug "HEREHREREH";
	my $bookstore_schema = schema 'bookstore';
	my @books = $bookstore_schema->resultset('Book');
	open(DEBUG, ">> ../debug.txt");
	print DEBUG "Books: ".Dumper(\@books)."\n";
	close DEBUG;
	template 'books_list', { books => \@books };
};

get '/books/add' => sub {
	template 'book_add';
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

sub _perform_search {
	my ($query) = @_;
	my $bookstore_schema = schema 'bookstore';
	my @results;
	# search in authors
	my @authors = $bookstore_schema->resultset('Author')->search({
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
	my @books = $bookstore_schema->resultset('Book')->search({
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
