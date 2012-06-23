
package IO::Tty::Constant;

use vars qw(@ISA @EXPORT_OK);
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(B0 B110 B115200 B1200 B134 B150 B153600 B1800 B19200 B200 B230400 B2400 B300 B307200 B38400 B460800 B4800 B50 B57600 B600 B75 B76800 B9600 BRKINT BS0 BS1 BSDLY CBAUD CBAUDEXT CBRK CCTS_OFLOW CDEL CDSUSP CEOF CEOL CEOL2 CEOT CERASE CESC CFLUSH CIBAUD CIBAUDEXT CINTR CKILL CLNEXT CLOCAL CNSWTCH CNUL CQUIT CR0 CR1 CR2 CR3 CRDLY CREAD CRPRNT CRTSCTS CRTSXOFF CRTS_IFLOW CS5 CS6 CS7 CS8 CSIZE CSTART CSTOP CSTOPB CSUSP CSWTCH CWERASE DEFECHO DIOC DIOCGETP DIOCSETP DOSMODE ECHO ECHOCTL ECHOE ECHOK ECHOKE ECHONL ECHOPRT EXTA EXTB FF0 FF1 FFDLY FIORDCHK FLUSHO HUPCL ICANON ICRNL IEXTEN IGNBRK IGNCR IGNPAR IMAXBEL INLCR INPCK ISIG ISTRIP IUCLC IXANY IXOFF IXON KBENABLED LDCHG LDCLOSE LDDMAP LDEMAP LDGETT LDGMAP LDIOC LDNMAP LDOPEN LDSETT LDSMAP LOBLK NCCS NL0 NL1 NLDLY NOFLSH OCRNL OFDEL OFILL OLCUC ONLCR ONLRET ONOCR OPOST PAGEOUT PARENB PAREXT PARMRK PARODD PENDIN RCV1EN RTS_TOG TAB0 TAB1 TAB2 TAB3 TABDLY TCDSET TCFLSH TCGETA TCGETS TCIFLUSH TCIOFF TCIOFLUSH TCION TCOFLUSH TCOOFF TCOON TCSADRAIN TCSAFLUSH TCSANOW TCSBRK TCSETA TCSETAF TCSETAW TCSETCTTY TCSETS TCSETSF TCSETSW TCXONC TERM_D40 TERM_D42 TERM_H45 TERM_NONE TERM_TEC TERM_TEX TERM_V10 TERM_V61 TIOCCBRK TIOCCDTR TIOCCONS TIOCEXCL TIOCFLUSH TIOCGETD TIOCGETC TIOCGETP TIOCGLTC TIOCSETC TIOCSETN TIOCSETP TIOCSLTC TIOCGPGRP TIOCGSID TIOCGSOFTCAR TIOCGWINSZ TIOCHPCL TIOCKBOF TIOCKBON TIOCLBIC TIOCLBIS TIOCLGET TIOCLSET TIOCMBIC TIOCMBIS TIOCMGET TIOCMSET TIOCM_CAR TIOCM_CD TIOCM_CTS TIOCM_DSR TIOCM_DTR TIOCM_LE TIOCM_RI TIOCM_RNG TIOCM_RTS TIOCM_SR TIOCM_ST TIOCNOTTY TIOCNXCL TIOCOUTQ TIOCREMOTE TIOCSBRK TIOCSCTTY TIOCSDTR TIOCSETD TIOCSIGNAL TIOCSPGRP TIOCSSID TIOCSSOFTCAR TIOCSTART TIOCSTI TIOCSTOP TIOCSWINSZ TM_ANL TM_CECHO TM_CINVIS TM_LCF TM_NONE TM_SET TM_SNL TOSTOP VCEOF VCEOL VDISCARD VDSUSP VEOF VEOL VEOL2 VERASE VINTR VKILL VLNEXT VMIN VQUIT VREPRINT VSTART VSTOP VSUSP VSWTCH VT0 VT1 VTDLY VTIME VWERASE WRAP XCASE XCLUDE XMT1EN XTABS);

__END__

=head1 NAME

IO::Tty::Constant - Terminal Constants (autogenerated)

=head1 SYNOPSIS

 use IO::Tty::Constant qw(TIOCNOTTY);
 ...

=head1 DESCRIPTION

This package defines constants usually found in <termio.h> or
<termios.h> (and their #include hierarchy).  Find below an
autogenerated alphabetic list of all known constants and whether they
are defined on your system (prefixed with '+') and have compilation
problems ('o').  Undefined or problematic constants are set to 'undef'.

=head1 DEFINED CONSTANTS

=item +

B0

=item +

B110

=item +

B115200

=item +

B1200

=item +

B134

=item +

B150

=item -

B153600

=item +

B1800

=item +

B19200

=item +

B200

=item +

B230400

=item +

B2400

=item +

B300

=item -

B307200

=item +

B38400

=item +

B460800

=item +

B4800

=item +

B50

=item +

B57600

=item +

B600

=item +

B75

=item -

B76800

=item +

B9600

=item +

BRKINT

=item +

BS0

=item +

BS1

=item +

BSDLY

=item +

CBAUD

=item -

CBAUDEXT

=item -

CBRK

=item -

CCTS_OFLOW

=item +

CDEL

=item +

CDSUSP

=item +

CEOF

=item +

CEOL

=item +

CEOL2

=item +

CEOT

=item +

CERASE

=item +

CESC

=item +

CFLUSH

=item -

CIBAUD

=item -

CIBAUDEXT

=item +

CINTR

=item +

CKILL

=item +

CLNEXT

=item +

CLOCAL

=item -

CNSWTCH

=item +

CNUL

=item +

CQUIT

=item +

CR0

=item +

CR1

=item +

CR2

=item +

CR3

=item +

CRDLY

=item +

CREAD

=item +

CRPRNT

=item +

CRTSCTS

=item +

CRTSXOFF

=item -

CRTS_IFLOW

=item +

CS5

=item +

CS6

=item +

CS7

=item +

CS8

=item +

CSIZE

=item +

CSTART

=item +

CSTOP

=item +

CSTOPB

=item +

CSUSP

=item +

CSWTCH

=item +

CWERASE

=item -

DEFECHO

=item -

DIOC

=item -

DIOCGETP

=item -

DIOCSETP

=item -

DOSMODE

=item +

ECHO

=item +

ECHOCTL

=item +

ECHOE

=item +

ECHOK

=item +

ECHOKE

=item +

ECHONL

=item -

ECHOPRT

=item -

EXTA

=item -

EXTB

=item +

FF0

=item +

FF1

=item +

FFDLY

=item -

FIORDCHK

=item +

FLUSHO

=item +

HUPCL

=item +

ICANON

=item +

ICRNL

=item +

IEXTEN

=item +

IGNBRK

=item +

IGNCR

=item +

IGNPAR

=item +

IMAXBEL

=item +

INLCR

=item +

INPCK

=item +

ISIG

=item +

ISTRIP

=item +

IUCLC

=item +

IXANY

=item +

IXOFF

=item +

IXON

=item -

KBENABLED

=item -

LDCHG

=item -

LDCLOSE

=item -

LDDMAP

=item -

LDEMAP

=item -

LDGETT

=item -

LDGMAP

=item -

LDIOC

=item -

LDNMAP

=item -

LDOPEN

=item -

LDSETT

=item -

LDSMAP

=item -

LOBLK

=item +

NCCS

=item +

NL0

=item +

NL1

=item +

NLDLY

=item +

NOFLSH

=item +

OCRNL

=item +

OFDEL

=item +

OFILL

=item +

OLCUC

=item +

ONLCR

=item +

ONLRET

=item +

ONOCR

=item +

OPOST

=item -

PAGEOUT

=item +

PARENB

=item -

PAREXT

=item +

PARMRK

=item +

PARODD

=item -

PENDIN

=item -

RCV1EN

=item -

RTS_TOG

=item +

TAB0

=item +

TAB1

=item +

TAB2

=item +

TAB3

=item +

TABDLY

=item -

TCDSET

=item +

TCFLSH

=item +

TCGETA

=item -

TCGETS

=item +

TCIFLUSH

=item +

TCIOFF

=item +

TCIOFLUSH

=item +

TCION

=item +

TCOFLUSH

=item +

TCOOFF

=item +

TCOON

=item +

TCSADRAIN

=item +

TCSAFLUSH

=item +

TCSANOW

=item -

TCSBRK

=item +

TCSETA

=item +

TCSETAF

=item +

TCSETAW

=item -

TCSETCTTY

=item -

TCSETS

=item -

TCSETSF

=item -

TCSETSW

=item -

TCXONC

=item -

TERM_D40

=item -

TERM_D42

=item -

TERM_H45

=item -

TERM_NONE

=item -

TERM_TEC

=item -

TERM_TEX

=item -

TERM_V10

=item -

TERM_V61

=item +

TIOCCBRK

=item -

TIOCCDTR

=item -

TIOCCONS

=item -

TIOCEXCL

=item -

TIOCFLUSH

=item -

TIOCGETD

=item -

TIOCGETC

=item -

TIOCGETP

=item -

TIOCGLTC

=item -

TIOCSETC

=item -

TIOCSETN

=item -

TIOCSETP

=item -

TIOCSLTC

=item -

TIOCGPGRP

=item -

TIOCGSID

=item -

TIOCGSOFTCAR

=item +

TIOCGWINSZ

=item -

TIOCHPCL

=item -

TIOCKBOF

=item -

TIOCKBON

=item -

TIOCLBIC

=item -

TIOCLBIS

=item -

TIOCLGET

=item -

TIOCLSET

=item +

TIOCMBIC

=item +

TIOCMBIS

=item +

TIOCMGET

=item +

TIOCMSET

=item +

TIOCM_CAR

=item +

TIOCM_CD

=item +

TIOCM_CTS

=item +

TIOCM_DSR

=item +

TIOCM_DTR

=item -

TIOCM_LE

=item +

TIOCM_RI

=item +

TIOCM_RNG

=item +

TIOCM_RTS

=item -

TIOCM_SR

=item -

TIOCM_ST

=item -

TIOCNOTTY

=item -

TIOCNXCL

=item -

TIOCOUTQ

=item -

TIOCREMOTE

=item +

TIOCSBRK

=item -

TIOCSCTTY

=item -

TIOCSDTR

=item -

TIOCSETD

=item -

TIOCSIGNAL

=item -

TIOCSPGRP

=item -

TIOCSSID

=item -

TIOCSSOFTCAR

=item -

TIOCSTART

=item -

TIOCSTI

=item -

TIOCSTOP

=item +

TIOCSWINSZ

=item -

TM_ANL

=item -

TM_CECHO

=item -

TM_CINVIS

=item -

TM_LCF

=item -

TM_NONE

=item -

TM_SET

=item -

TM_SNL

=item +

TOSTOP

=item -

VCEOF

=item -

VCEOL

=item +

VDISCARD

=item -

VDSUSP

=item +

VEOF

=item +

VEOL

=item +

VEOL2

=item +

VERASE

=item +

VINTR

=item +

VKILL

=item +

VLNEXT

=item +

VMIN

=item +

VQUIT

=item +

VREPRINT

=item +

VSTART

=item +

VSTOP

=item +

VSUSP

=item -

VSWTCH

=item +

VT0

=item +

VT1

=item +

VTDLY

=item +

VTIME

=item +

VWERASE

=item -

WRAP

=item -

XCASE

=item -

XCLUDE

=item -

XMT1EN

=item +

XTABS


=head1 FOR MORE INFO SEE

L<IO::Tty>

=cut

