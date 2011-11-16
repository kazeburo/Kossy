package Kossy::Validator;

use strict;
use warnings;
use Hash::MultiValue;

our %VALIDATOR = (
    NOT_NULL => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        return if $val eq "";
        return 1;
    },
    CHOICE => sub {
        my ($req, $val, @args) = @_;
        for my $c (@args) {
            if ($c eq $val) {
                return 1;
            }
        }
        return;
    },
    UINT => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        $val =~ /^\d+$/;  
    },
    NATURAL => sub {
        my ($req,$val) = @_;
        return if not defined($val);
        $val =~ /^\d+$/ && $val > 0;
    },
    '@SELECTED_NUM' => sub {
        my ($vals,@args) = @_;
        my ($min,$max) = @args;
        scalar(@$vals) >= $min && scalar(@$vals) <= $max
    },
);

sub check {
    my $class = shift;

    my $req = shift;
    my $rule = shift || [];

    my @errors;
    my $valid = Hash::MultiValue->new;

    for ( my $i=0; $i < @$rule; $i = $i+2 ) {
        my $param = $rule->[$i];
        my $constraints;
        my $param_name = $param;
        $param_name =~ s!^@!!;
        my @vals = $req->param($param_name);
        my $vals = ( $param =~ m!^@! ) ? \@vals : [$vals[-1]];

        if ( ref($rule->[$i+1]) && ref($rule->[$i+1]) eq 'HASH' ) {
            if ( $param !~ m!^@! && !$VALIDATOR{NOT_NULL}->($req,$vals)  && exists $rule->[$i+1]->{default} ) {
                my $default = $rule->[$i+1]->{default};
                $vals = [$default];
            }
            $constraints = $rule->[$i+1]->{rule};
        }
        else {
            $constraints = $rule->[$i+1];
        }

        my $error;
        PARAM_CONSTRAINT: for my $constraint ( @$constraints ) {
            if ( ref($constraint->[0]) eq 'ARRAY' ) {
                my @constraint = @{$constraint->[0]};
                my $constraint_name = shift @constraint;
                die "constraint:$constraint_name not found" if ! exists $VALIDATOR{$constraint_name};
                if ( $constraint_name =~ m!^@! ) {
                    if ( !$VALIDATOR{$constraint_name}->($req,$vals,@constraint) ) {
                        push @errors, $constraint->[1];
                        $error=1;
                        last PARAM_CONSTRAINT;
                    }                    
                }
                else {
                    for my $val ( @$vals ) {
                        if ( !$VALIDATOR{$constraint_name}->($req,$val,@constraint) ) {
                            push @errors, $constraint->[1];
                            $error=1;
                            last PARAM_CONSTRAINT;
                        }
                    }
                }
            }
            elsif ( ref($constraint->[0]) eq 'CODE' ) {
                my @constraint = @{$constraint->[0]};
                my $code = shift @constraint;
                for my $val ( @$vals ) {
                    if ( !$code->($req, $val, @constraint) ) {
                        push @errors, $constraint->[1];
                        $error=1;
                        last PARAM_CONSTRAINT;
                    }
                }
            }
            else {
                die "constraint:".$constraint->[0]." not found" if ! exists $VALIDATOR{$constraint->[0]};
                for my $val ( @$vals ) {
                    if ( ! $VALIDATOR{$constraint->[0]}->($req, $val) ) {
                        push @errors, $constraint->[1];
                        $error=1;
                        last PARAM_CONSTRAINT;
                    }
                }
            }
        }
        $valid->add($param_name,@$vals) unless $error;
    }
    
    Kossy::Validator::Result->new(\@errors,$valid);
}

package Kossy::Validator::Result;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $errors = shift;
    my $valid = shift;
    bless {errors=>$errors,valid=>$valid}, $class;
}

sub has_error {
    my $self = shift;
    return 1 if @{$self->{errors}};
    return;
}

sub messages {
    my $self = shift;
    my @errors = @{$self->{errors}};
    \@errors;
}

sub valid {
    my $self = shift;
    if ( @_ == 2 ) {
        $self->{valid}->add(@_);
        return $_[1];
    }
    elsif ( @_ == 1 ) {
        return $self->{valid}->get($_[0]) if ! wantarray;
        return $self->{valid}->get_all($_[0]);
    }
    $self->{valid};
}

1;

__END__

=head1 NAME

Kossy::Validator - form validator

=head1 SYNOPSIS

  use Kossy

=head1 DESCRIPTION

form validator

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

