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
};

# ===== Home =====
get '/' => sub {
    template 'index';
};

# ==== Book CRUD =====

# Read
get '/books/?:id?' => sub {
   if ( param 'id' ) {
      $tmpl_params{book} = resultset('Book')->find(param 'id');   # \@{[ ]} will force a list context
      template 'book_single', \%tmpl_params;
   } else {
      $tmpl_params{books} = \@{[resultset('Book')->all]};   # \@{[ ]} will force a list context
      template 'books_list', \%tmpl_params;
   }
};

# Create and Update
any ['post', 'put'] => '/books' => sub {
   set serializer => 'JSON';

   my %params = params;
   my $success;

   my $msg = validate_books( \%params );
   if ($msg->{errors}) {
      return $msg;
   }
   if ( request->method() eq "POST" ) {
      #delete $params{'id'};
      resultset('Book')->create($msg);
      $success = "Book added Successfully";
   } else {
      resultset('Book')->find(param 'id')->update($msg);
      $success = "Book updated Successfully";
   }
   return { success => [ { success => $success } ] };
};
# Delete
get '/books/delete/:id' => sub {
   resultset('Book')->find(param 'id')->delete();
   redirect '/books/';
};
del '/books/:id' => sub {
   resultset('Book')->find(param 'id')->delete();
   redirect '/books/';
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

#--- Validate -------------------------------------------------------------  
sub validate_books {
   my $params = shift;
	my (%sql, $error, @error_list, $stmt);
	
	($sql{'title'}, $error) = Validate::val_text( 1, 64, $params->{'title'} );
		if ( $error-> { msg } ) { push @error_list, { "title" => $error->{ msg } }; }	
	($sql{'author'}, $error) = Validate::val_selected($params->{'author'} );
		if ( $error-> { msg } ) { push @error_list, { "author" => $error->{ msg } }; }

	for my $key ( keys %sql ) {
		if (not $sql{$key}) { $sql{$key} = ''; } # Set all undefined variables to avoid warnings.
	}
	if (@error_list) {
      return { 'errors' => \@error_list };
   }
	return \%sql;
}

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
