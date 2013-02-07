package Books;
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use HTML::FillInForm;
use Data::Dumper;
use Validate;

prefix '/books' => sub {

my %tmpl_params;
hook 'before' => sub {
   # Clear tmpl Params;
   %tmpl_params = {};
};

# ==== Book CRUD =====

# Read
get '/?:id?' => sub {
   if ( param 'id' ) {
      $tmpl_params{book} = resultset('Book')->find(param 'id');   # \@{[ ]} will force a list context
      template 'book_single', \%tmpl_params;
   } else {
      $tmpl_params{books} = \@{[resultset('Book')->all]};   # \@{[ ]} will force a list context
      template 'books_list', \%tmpl_params;
   }
};

# Create and Update
any ['post', 'put'] => '/?' => sub {
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
get '/delete/:id' => sub {
   resultset('Book')->find(param 'id')->delete();
   redirect '/books/';
};
del '/:id' => sub {
   resultset('Book')->find(param 'id')->delete();
   redirect '/books/';
};

# ---- Book Views -----

get '/add/?' => sub {
	$tmpl_params{authors} = \@{[resultset('Author')->all]};   # \@{[ ]} will force a list context
	template 'book_add', \%tmpl_params;
};

get '/edit/:id' => sub {
	$tmpl_params{authors} = \@{[resultset('Author')->all]};   # \@{[ ]} will force a list context
   if (param 'id') { $tmpl_params{book} = resultset('Book')->find(param 'id'); }
   %tmpl_params = (%tmpl_params, %{resultset('Book')->search({ id => param 'id' }, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator',
   })->next});
	fillinform('book_add', \%tmpl_params);
};

}; # End books prefix

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

# ===== Helper Functions =====
sub fillinform {
   my $template = shift;
   my $fifvalues = shift;
   my $html = template $template, $fifvalues;
   return HTML::FillInForm->fill( \$html, $fifvalues );
}
