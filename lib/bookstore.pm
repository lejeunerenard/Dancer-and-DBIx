package bookstore;
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use HTML::FillInForm;
use Data::Dumper;

our $VERSION = '0.1';

my %tmpl_params;

# ----- Generate URIs -----
hook 'before_template_render' => sub {
   my $tokens = shift;
       
   $tokens->{'search_books_uri'} = uri_for('/search/');
   $tokens->{'list_books_uri'} = uri_for('/books/');
   $tokens->{'add_book_uri'} = uri_for('/books/add/');
};

# ===== Home =====
get '/' => sub {
    template 'index';
};

# ==== Book CRUD =====

# Read
get '/books/?' => sub {
	$tmpl_params{books} = \@{[resultset('Book')->all]};   # \@{[ ]} will force a list context
	template 'books_list', \%tmpl_params;
};

# Create and Update
any ['post', 'put'] => '/books' => sub {
   my %params = params;
   if (not $params{author}) { delete $params{'author'} }
   if ( request->method() eq "POST" ) {
      #delete $params{'id'};
      resultset('Book')->create(\%params);
   } else {
      resultset('Book')->find(param 'id')->update(\%params);
   }
	template 'book_add', \%tmpl_params;
};

# ---- Book Views -----

get '/books/add/?' => sub {
	$tmpl_params{authors} = \@{[resultset('Author')->all]};   # \@{[ ]} will force a list context
	template 'book_add', \%tmpl_params;
};

get '/books/edit/:id' => sub {
	$tmpl_params{authors} = \@{[resultset('Author')->all]};   # \@{[ ]} will force a list context
   if (param 'id') { $tmpl_params{book} = resultset('Book')->find(param 'id'); }
   %tmpl_params = (%tmpl_params, %{resultset('Book')->search({ id => param 'id' }, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator',
   })->next});
	fillinform('book_add', \%tmpl_params);
};

# ----- Special Search function -----

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

# ===== Helper Functions =====

sub fillinform {
   my $template = shift;
   my $fifvalues = shift;
   my $html = template $template, $fifvalues;
   return HTML::FillInForm->fill( \$html, $fifvalues );
}

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
