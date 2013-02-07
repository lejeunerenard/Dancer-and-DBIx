package Authors;
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use HTML::FillInForm;
use Data::Dumper;
use Validate;

prefix '/authors' => sub {

my %tmpl_params;
hook 'before' => sub {
   # Clear tmpl Params;
   %tmpl_params = {};
};

# ==== Book CRUD =====

# Read
get '/?:id?' => sub {
   if ( param 'id' ) {
      $tmpl_params{author} = resultset('Author')->find(param 'id');   # \@{[ ]} will force a list context
      template 'authors/author_single', \%tmpl_params;
   } else {
      $tmpl_params{authors} = \@{[resultset('Author')->all]};   # \@{[ ]} will force a list context
      template 'authors/authors_list', \%tmpl_params;
   }
};

# Create and Update
any ['post', 'put'] => '/?' => sub {
   set serializer => 'JSON';

   my %params = params;
   my $success;

   my $msg = validate_authors( \%params );
   if ($msg->{errors}) {
      return $msg;
   }
   if ( request->method() eq "POST" ) {
      #delete $params{'id'};
      resultset('Author')->create($msg);
      $success = "Author added Successfully";
   } else {
      resultset('Author')->find(param 'id')->update($msg);
      $success = "Author updated Successfully";
   }
   return { success => [ { success => $success } ] };
};
# Delete
get '/delete/:id' => sub {
   resultset('Author')->find(param 'id')->delete();
   redirect '/authors/';
};
del '/:id' => sub {
   resultset('Author')->find(param 'id')->delete();
   redirect '/authors/';
};

# ---- Book Views -----

get '/add/?' => sub {
	template 'authors/author_add', \%tmpl_params;
};

get '/edit/:id' => sub {
	$tmpl_params{books} = \@{[resultset('Book')->all]};   # \@{[ ]} will force a list context
   if (param 'id') { $tmpl_params{author} = resultset('Author')->find(param 'id'); }
   %tmpl_params = (%tmpl_params, %{resultset('Author')->search({ id => param 'id' }, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator',
   })->next});
	fillinform('authors/author_add', \%tmpl_params);
};

}; # End books prefix

# ===== Helper Functions =====

#--- Validate -------------------------------------------------------------  
sub validate_authors {
   my $params = shift;
	my (%sql, $error, @error_list, $stmt);
	
	($sql{'firstname'}, $error) = Validate::val_text( 1, 64, $params->{'firstname'} );
		if ( $error-> { msg } ) { push @error_list, { "firstname" => $error->{ msg } }; }	
	($sql{'lastname'}, $error) = Validate::val_text( 1, 64, $params->{'lastname'} );
		if ( $error-> { msg } ) { push @error_list, { "lastname" => $error->{ msg } }; }	

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
