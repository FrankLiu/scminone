BEGIN {

  # Set the location for SCM Build System modules.
  if (defined($ENV{'SCM_BUILD_SYSTEM'})) {
    push(@INC, $ENV{'SCM_BUILD_SYSTEM'} . '/lib');
  } # if (defined...

  # Add config path to SCM libraries.
  push(@INC,( $ENV{'SCM_BUILD_SYSTEM_CONF'} || $ENV{'SCM_BUILD_SYSTEM'}.'/conf'));

  # Autoflush Standard Error and Output; No Output buffering
  select(STDERR); $| = 1;		# Make unbuffered
  select(STDOUT); $| = 1;		# Make unbuffered

} # end BEGIN

# Indicates that the entire library's symbol table or namespace is labeled
# as compiler.  The compiler will look for any undefined symbols, in the
# calling program, in this package.
package compiler;

use 5.8.4;	# Use Perl 5.8.4 or higher (also for debugging purposes)

